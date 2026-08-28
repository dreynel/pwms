#include <WiFi.h>
#include <WebServer.h>
#include <ArduinoJson.h>
#include <LittleFS.h>
#include <time.h>

// --- Configuration ---
const char* ssid = "Box 2.4G";
const char* password = "boxbox123";
const char* ntpServer = "pool.ntp.org";
const long  gmtOffset_sec = 28800; // Adjust for your timezone (e.g. 28800 for UTC+8)
const int   daylightOffset_sec = 0;

const int relayPin = 12; // Pin connected to the 12v relay
bool motorState = false;
WebServer server(80);

// --- Helpers ---
void printLocalTime() {
  struct tm timeinfo;
  if(!getLocalTime(&timeinfo)){
    Serial.println("Failed to obtain time");
    return;
  }
  Serial.println(&timeinfo, "%A, %B %d %Y %H:%M:%S");
}

String getCurrentTimeStr() {
  struct tm timeinfo;
  if(!getLocalTime(&timeinfo)) return "";
  char timeStr[10];
  strftime(timeStr, sizeof(timeStr), "%I:%M %p", &timeinfo); // Matches Flutter format "10:30 AM"
  return String(timeStr);
}

String getCurrentDayStr() {
  struct tm timeinfo;
  if(!getLocalTime(&timeinfo)) return "";
  char dayStr[10];
  strftime(dayStr, sizeof(dayStr), "%a", &timeinfo); // e.g. "Mon", "Tue"
  return String(dayStr);
}

String getCurrentDateStr() {
  struct tm timeinfo;
  if(!getLocalTime(&timeinfo)) return "";
  char dateStr[12];
  strftime(dateStr, sizeof(dateStr), "%Y-%m-%d", &timeinfo); // e.g. "2026-08-28"
  return String(dateStr);
}

// --- API Handlers ---
void handleStatus() {
  StaticJsonDocument<200> doc;
  doc["motor"] = motorState;
  doc["connected"] = true;
  doc["time"] = getCurrentTimeStr();
  String response;
  serializeJson(doc, response);
  server.send(200, "application/json", response);
}

void handleToggle() {
  if (server.hasArg("plain") == false) {
    server.send(400, "text/plain", "Body not found");
    return;
  }
  StaticJsonDocument<200> doc;
  deserializeJson(doc, server.arg("plain"));
  motorState = doc["state"];
  digitalWrite(relayPin, motorState ? HIGH : LOW);
  server.send(200, "application/json", "{\"status\":\"ok\"}");
}

void handleSchedulesGet() {
  File file = LittleFS.open("/schedules.json", "r");
  if (!file) {
    server.send(200, "application/json", "[]");
    return;
  }
  server.streamFile(file, "application/json");
  file.close();
}

void handleSchedulesPost() {
  if (server.hasArg("plain") == false) {
    server.send(400, "text/plain", "Body not found");
    return;
  }
  File file = LittleFS.open("/schedules.json", "w");
  if (file) {
    file.print(server.arg("plain"));
    file.close();
    server.send(200, "application/json", "{\"status\":\"saved\"}");
  } else {
    server.send(500, "text/plain", "Failed to save");
  }
}

// --- Schedule Execution ---
String lastTriggeredTime = "";

void checkSchedules() {
  static unsigned long lastCheck = 0;
  if (millis() - lastCheck < 30000) return; // Check every 30 seconds
  lastCheck = millis();

  String now = getCurrentTimeStr();
  String currentDay = getCurrentDayStr();
  String currentDate = getCurrentDateStr();

  if (now == lastTriggeredTime) return;

  File file = LittleFS.open("/schedules.json", "r");
  if (!file) return;

  DynamicJsonDocument doc(2048);
  deserializeJson(doc, file);
  file.close();

  JsonArray schedules = doc.as<JsonArray>();
  for (JsonObject s : schedules) {
    String sTime = s["time"].as<String>();
    bool enabled = s["enabled"] | true;
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
    
    if (enabled && match && sTime == now) {
      Serial.println("Schedule Triggered: " + sTime);
      lastTriggeredTime = now;
      motorState = true;
      digitalWrite(relayPin, HIGH);
    }
  }
}

void setup() {
  Serial.begin(115200);
  pinMode(relayPin, OUTPUT);
  digitalWrite(relayPin, LOW);

  if(!LittleFS.begin(true)){
    Serial.println("An Error has occurred while mounting LittleFS");
  }

  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(1000);
    Serial.println("Connecting to WiFi...");
  }
  Serial.println(WiFi.localIP());

  configTime(gmtOffset_sec, daylightOffset_sec, ntpServer);

  server.on("/status", HTTP_GET, handleStatus);
  server.on("/toggle", HTTP_POST, handleToggle);
  server.on("/schedules", HTTP_GET, handleSchedulesGet);
  server.on("/schedules", HTTP_POST, handleSchedulesPost);

  server.begin();
}

void loop() {
  server.handleClient();
  checkSchedules();
}
