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

const int relayPin = 23; // Pin connected to the 12v relay
bool motorState = false;
unsigned long motorRunDurationMs = 0;
unsigned long motorTurnOnTime = 0;
bool isMotorRunningOnSchedule = false;

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

// --- Logging System ---
void writeLog(String event) {
  DynamicJsonDocument doc(4096);
  File inFile = LittleFS.open("/logs.json", "r");
  if (inFile) {
    deserializeJson(doc, inFile);
    inFile.close();
  }

  JsonArray logs;
  if (doc.is<JsonArray>()) {
    logs = doc.as<JsonArray>();
  } else {
    logs = doc.to<JsonArray>();
  }

  if (logs.size() >= 40) {
    logs.remove(0);
  }

  JsonObject newLog = logs.createNestedObject();
  newLog["time"] = getCurrentDayStr() + " " + getCurrentTimeStr();
  newLog["event"] = event;

  File outFile = LittleFS.open("/logs.json", "w");
  if (outFile) {
    serializeJson(doc, outFile);
    outFile.close();
  }
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
  bool newState = doc["state"];
  
  if (motorState != newState) {
    motorState = newState;
    digitalWrite(relayPin, motorState ? HIGH : LOW);
    writeLog(motorState ? "Motor ON (Manual)" : "Motor OFF (Manual)");
  }
  
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

void handleLogsGet() {
  File file = LittleFS.open("/logs.json", "r");
  if (!file) {
    server.send(200, "application/json", "[]");
    return;
  }
  server.streamFile(file, "application/json");
  file.close();
}

void handleLogsDelete() {
  LittleFS.remove("/logs.json");
  server.send(200, "application/json", "{\"status\":\"deleted\"}");
}

// --- Schedule Execution ---
String lastTriggeredTime = "";

void checkSchedules() {
  static unsigned long lastCheck = 0;
  if (millis() - lastCheck < 30000) return; // Check every 30 seconds
  lastCheck = millis();

  String now = getCurrentTimeStr();
  String currentDay = getCurrentDayStr();
  
  // Prevent double trigger if we haven't moved on to the next minute
  // We assume here that scheduled tasks run at most once per day for that specific hour:minute string
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
    int durationMinutes = s["duration"] | 1; // Default to 1 minute if not provided
    
    bool match = false;
    if (type == "calendar" || s.containsKey("date")) {
      String sDate = s["date"].as<String>();
      if (sDate == currentDate) {
        match = true;
      }
        for (JsonVariant v : daysConfig) {
          String dayVal = v.as<String>();
          if (dayVal == "Daily" || dayVal == currentDay) {
            match = true;
            break;
          }
          ? "Motor ON (Calendar Sched)" 
          : "Motor ON (Recurring Sched)";
      writeLog(logMsg);
      
      isMotorRunningOnSchedule = true;
      motorRunDurationMs = durationMinutes * 60000UL;
    }
  }
}

void setup() {
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
  server.on("/logs", HTTP_GET, handleLogsGet);
  server.on("/logs", HTTP_DELETE, handleLogsDelete);

  server.begin();
}

void loop() {
  server.handleClient();
  checkSchedules();
  
  // Handle automatic turn off if the motor was started by schedule
  if (isMotorRunningOnSchedule) {
    if (millis() - motorTurnOnTime >= motorRunDurationMs) {
      isMotorRunningOnSchedule = false;
      motorState = false;
      digitalWrite(relayPin, LOW);
      writeLog("Motor OFF (Schedule Finished)");
      Serial.println("Schedule duration ended. Motor turned OFF.");
    }
  }
}
