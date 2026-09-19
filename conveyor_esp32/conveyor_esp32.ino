#include <WiFi.h>
#include <HTTPClient.h>
#include <WiFiClientSecure.h>
#include <ArduinoJson.h>
#include <time.h>

// --- Wi-Fi & Cloud Hostinger Configuration ---
const char* ssid = "Box 2.4G";
const char* password = "boxbox123";

// Your Live Hostinger API Endpoint URL
const char* serverUrl = "https://darkslateblue-hawk-354006.hostingersite.com";

// NTP Time Configuration
const char* ntpServer = "pool.ntp.org";
const long  gmtOffset_sec = 28800; // Adjust for your timezone (e.g. 28800 for UTC+8)
const int   daylightOffset_sec = 0;

// Hardware Pin Configuration
const int relayPin = 23; // GPIO Pin connected to relay (or 12)
bool motorState = false;

// Scheduling & Duration State
unsigned long motorRunDurationMs = 0;
unsigned long motorTurnOnTime = 0;
bool isMotorRunningOnSchedule = false;
String lastTriggeredTime = "";

// Cloud Sync Timer
unsigned long lastSyncTime = 0;
const unsigned long syncIntervalMs = 1000; // ⚡ Sync every 1 second for near-instant response

// Forward declaration
void checkSchedules(JsonArray schedules);
void syncWithCloud(String logEventToSend = "");

// --- Time Helpers ---
String getCurrentTimeStr() {
  struct tm timeinfo;
  if (!getLocalTime(&timeinfo)) return "";
  char timeStr[10];
  strftime(timeStr, sizeof(timeStr), "%I:%M %p", &timeinfo); // Matches format "10:30 AM"
  return String(timeStr);
}

String getCurrentDayStr() {
  struct tm timeinfo;
  if (!getLocalTime(&timeinfo)) return "";
  char dayStr[10];
  strftime(dayStr, sizeof(dayStr), "%a", &timeinfo); // e.g. "Mon", "Tue"
  return String(dayStr);
}

String getCurrentDateStr() {
  struct tm timeinfo;
  if (!getLocalTime(&timeinfo)) return "";
  char dateStr[12];
  strftime(dateStr, sizeof(dateStr), "%Y-%m-%d", &timeinfo); // e.g. "2026-08-29"
  return String(dateStr);
}

// --- Cloud Sync with Hostinger PHP Backend ---
void syncWithCloud(String logEventToSend) {
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("[WIFI] Not connected. Skipping cloud sync.");
    return;
  }

  HTTPClient http;
  String syncUrl = String(serverUrl);
  if (!syncUrl.endsWith("/")) syncUrl += "/";
  syncUrl += "device_sync.php";

  bool isHttps = syncUrl.startsWith("https://");
  WiFiClientSecure secureClient;
  WiFiClient regularClient;

  if (isHttps) {
    secureClient.setInsecure(); // Connect over HTTPS without strict SSL certificate check
    secureClient.setTimeout(5000);
    http.begin(secureClient, syncUrl);
  } else {
    regularClient.setTimeout(5000);
    http.begin(regularClient, syncUrl);
  }

  http.setTimeout(5000);
  http.addHeader("Content-Type", "application/json");

  StaticJsonDocument<256> reqDoc;
  reqDoc["actual_motor_state"] = motorState;
  if (logEventToSend.length() > 0) {
    reqDoc["log_event"] = logEventToSend;
    reqDoc["log_time"] = getCurrentDayStr() + " " + getCurrentTimeStr();
  }

  String reqBody;
  serializeJson(reqDoc, reqBody);

  Serial.println("[HTTP] Syncing with cloud: " + syncUrl);
  int httpCode = http.POST(reqBody);
  Serial.printf("[HTTP] Code: %d\n", httpCode);

  if (httpCode == HTTP_CODE_OK) {
    String resBody = http.getString();
    Serial.println("[HTTP] Response: " + resBody);
    DynamicJsonDocument resDoc(4096);
    DeserializationError error = deserializeJson(resDoc, resBody);

    if (!error) {
      // 1. Sync Motor State from Cloud (Manual Toggle from App)
      bool targetMotorState = resDoc["target_motor_state"] | false;
      Serial.printf("[STATE] Current: %s | Target from DB: %s\n", 
                    motorState ? "ON" : "OFF", 
                    targetMotorState ? "ON" : "OFF");

      if (motorState != targetMotorState && !isMotorRunningOnSchedule) {
        motorState = targetMotorState;
        digitalWrite(relayPin, motorState ? HIGH : LOW);
        Serial.println(motorState ? "[RELAY] Motor turned ON" : "[RELAY] Motor turned OFF");
      }

      // 2. Check and Execute Schedules from Cloud
      JsonArray schedules = resDoc["schedules"].as<JsonArray>();
      checkSchedules(schedules);
    } else {
      Serial.println("[JSON] Parse error: " + String(error.c_str()));
    }
  } else {
    Serial.printf("[HTTP] Failed! Code: %d\n", httpCode);
  }

  http.end();
}

// --- Check Schedules downloaded from Cloud ---
void checkSchedules(JsonArray schedules) {
  String nowTime = getCurrentTimeStr();
  String currentDay = getCurrentDayStr();
  String currentDate = getCurrentDateStr();

  if (nowTime == "" || nowTime == lastTriggeredTime) return;

  for (JsonObject s : schedules) {
    String sTime = s["time"].as<String>();
    bool enabled = s["enabled"] | true;
    int durationMinutes = s["duration"] | 1;
    String type = s["type"].as<String>();

    bool match = false;
    if (type == "calendar" || s.containsKey("date")) {
      String sDate = s["date"].as<String>();
      if (sDate == currentDate) {
        match = true;
      }
    } else {
      JsonArray daysConfig = s["days"].as<JsonArray>();
      if (daysConfig.isNull() || daysConfig.size() == 0) {
        match = true;
      } else {
        for (JsonVariant v : daysConfig) {
          String dayVal = v.as<String>();
          if (dayVal == "Daily" || dayVal == currentDay) {
            match = true;
            break;
          }
        }
      }
    }

    if (enabled && match && sTime == nowTime) {
      Serial.println("[SCHEDULE] Triggered: " + sTime);
      lastTriggeredTime = nowTime;

      motorState = true;
      digitalWrite(relayPin, HIGH);

      isMotorRunningOnSchedule = true;
      motorTurnOnTime = millis();
      motorRunDurationMs = durationMinutes * 60000UL;

      String logMsg = (type == "calendar") ? "Motor ON (Calendar Sched)" : "Motor ON (Recurring Sched)";
      syncWithCloud(logMsg);
    }
  }
}

void setup() {
  Serial.begin(115200);
  pinMode(relayPin, OUTPUT);
  digitalWrite(relayPin, LOW);

  Serial.println("\nConnecting to Wi-Fi...");
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nWi-Fi Connected! Local IP: " + WiFi.localIP().toString());

  configTime(gmtOffset_sec, daylightOffset_sec, ntpServer);
  Serial.println("Synchronizing NTP Time...");
  delay(2000);

  // Initial cloud sync
  syncWithCloud("ESP32 Connected Online");
}

void loop() {
  // 1. Periodic Cloud Heartbeat & Sync (every 1 second for near-instant response)
  if (millis() - lastSyncTime >= syncIntervalMs) {
    lastSyncTime = millis();
    syncWithCloud();
  }

  // 2. Handle automatic turn-off when schedule duration finishes
  if (isMotorRunningOnSchedule) {
    if (millis() - motorTurnOnTime >= motorRunDurationMs) {
      isMotorRunningOnSchedule = false;
      motorState = false;
      digitalWrite(relayPin, LOW);
      Serial.println("[SCHEDULE] Duration finished. Motor turned OFF.");
      syncWithCloud("Motor OFF (Schedule Finished)");
    }
  }

  // 3. Wi-Fi Auto-reconnect if lost
  if (WiFi.status() != WL_CONNECTED) {
    WiFi.reconnect();
    delay(1000);
  }
}
