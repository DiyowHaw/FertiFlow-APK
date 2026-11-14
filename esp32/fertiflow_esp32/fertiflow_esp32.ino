/*
 * FertiFlow ESP32 — Smart Farming Controller (Full Final Code)
 * ============================================================
 */

#include <Wire.h>
#include <LiquidCrystal_I2C.h>
#include <DHT.h>
#include <RTClib.h>
#include <WiFi.h>
#include <Firebase_ESP_Client.h>

#include "addons/TokenHelper.h"
#include "addons/RTDBHelper.h"

// ==========================================
// KONFIGURASI UMUM
// ==========================================
#define WIFI_SSID         "Wahahahaha"
#define WIFI_PASSWORD     "123456788"
#define FIREBASE_API_KEY  "AIzaSyBcsHxz_JM37Z_a6s7ZVy4hfxEsSgaK1z0"
#define FIREBASE_DB_URL   "fertiflow-88493-default-rtdb.asia-southeast1.firebasedatabase.app"

// ==========================================
// PIN DEFINITION
// ==========================================
#define I2C_SDA              22
#define I2C_SCL              21
#define DHTPIN               4
#define DHTTYPE              DHT22
#define TRIG                 5
#define ECHO                 18
#define SOIL                 34
#define CH1_POMPA_AIR        19
#define CH2_SOLENOID_A       25
#define CH3_SOLENOID_B       23
#define CH4_POMPA_PESTISIDA  26

// ==========================================
// BATAS SENSOR & LOGIKA RELAY
// Modul relay aktif LOW: LOW = Hidup, HIGH = Mati
// ==========================================
#define SOIL_BASAH     1800
#define SOIL_KERING    2200
#define SOIL_DARURAT   2500
#define AIR_MINIMAL    20
#define RELAY_ON       LOW
#define RELAY_OFF      HIGH

// ==========================================
// OBJEK & VARIABEL GLOBAL
// ==========================================
LiquidCrystal_I2C lcd(0x27, 16, 2); // Ganti ke 0x3F jika scanner mendeteksi 0x3F
DHT dht(DHTPIN, DHTTYPE);
RTC_DS3231 rtc;

FirebaseData fbData;
FirebaseData fbStream; 
FirebaseAuth auth;
FirebaseConfig config;

int distance = -1;
int soilValue = 0;
int soilPersen = 0;

bool siramPagi = false;
bool siramSore = false;

// Status Relay Murni
bool statusPompaAir       = false;
bool statusSolenoidA      = false;
bool statusSolenoidB      = false;
bool statusPompaPestisida = false;
bool statusAutoMode       = false;

unsigned long lastSensorPush = 0;
const unsigned long SENSOR_INTERVAL = 6000;

// ==========================================
// FUNGSI RELAY
// ==========================================
void semuaOFF() {
  digitalWrite(CH1_POMPA_AIR, RELAY_OFF);
  digitalWrite(CH2_SOLENOID_A, RELAY_OFF);
  digitalWrite(CH3_SOLENOID_B, RELAY_OFF);
  digitalWrite(CH4_POMPA_PESTISIDA, RELAY_OFF);
}

void updateHardwareRelay() {
  // Pompa pestisida otomatis HIDUP jika Solenoid A ATAU Solenoid B aktif
  bool pompaPestOn = statusPompaPestisida || statusSolenoidA || statusSolenoidB;

  // Output fisik ke modul relay
  digitalWrite(CH1_POMPA_AIR, statusPompaAir ? RELAY_ON : RELAY_OFF);
  digitalWrite(CH2_SOLENOID_A, statusSolenoidA ? RELAY_ON : RELAY_OFF);
  digitalWrite(CH3_SOLENOID_B, statusSolenoidB ? RELAY_ON : RELAY_OFF);
  digitalWrite(CH4_POMPA_PESTISIDA, pompaPestOn ? RELAY_ON : RELAY_OFF);

  Serial.printf("[HARDWARE] PompaAir:%d | SolA:%d | SolB:%d | PompaPest:%d\n",
                statusPompaAir, statusSolenoidA, statusSolenoidB, pompaPestOn);

  if (statusPompaAir || pompaPestOn) {
    lcd.setCursor(0, 0); 
    lcd.print("SISTEM AKTIF    ");
  } else {
    lcd.setCursor(0, 0); 
    lcd.print("FertiFlow v2    ");
  }
}

// ==========================================
// FIREBASE STREAM CALLBACK
// ==========================================
void streamCallback(FirebaseStream data) {
  String path = data.dataPath();
  Serial.printf("[STREAM IN] Path: %s | Type: %s\n", path.c_str(), data.dataType().c_str());

  if (data.dataType() == "boolean") {
    bool val = data.boolData();
    if (path == "/pompaAir" || path == "/pompa_air") statusPompaAir = val;
    else if (path == "/solenoidA" || path == "/solenoid_a") statusSolenoidA = val;
    else if (path == "/solenoidB" || path == "/solenoid_b") statusSolenoidB = val;
    else if (path == "/pompaPestisida" || path == "/pompa_pestisida") statusPompaPestisida = val;
    else if (path == "/autoMode" || path == "/auto_mode") statusAutoMode = val;
  } 
  else if (data.dataType() == "json") {
    FirebaseJson *json = data.jsonObjectPtr();
    FirebaseJsonData res;

    if (json->get(res, "pompaAir")) statusPompaAir = res.boolValue;
    if (json->get(res, "pompa_air")) statusPompaAir = res.boolValue;

    if (json->get(res, "solenoidA")) statusSolenoidA = res.boolValue;
    if (json->get(res, "solenoid_a")) statusSolenoidA = res.boolValue;

    if (json->get(res, "solenoidB")) statusSolenoidB = res.boolValue;
    if (json->get(res, "solenoid_b")) statusSolenoidB = res.boolValue;

    if (json->get(res, "pompaPestisida")) statusPompaPestisida = res.boolValue;
    if (json->get(res, "pompa_pestisida")) statusPompaPestisida = res.boolValue;

    if (json->get(res, "autoMode")) statusAutoMode = res.boolValue;
    if (json->get(res, "auto_mode")) statusAutoMode = res.boolValue;
  }
  
  updateHardwareRelay();
}

void streamTimeoutCallback(bool timeout) {
  if (timeout) Serial.println("[STREAM] Timeout, menyambung kembali...");
}

// ==========================================
// BACA SENSOR & IRIGASI OTOMATIS
// ==========================================
void bacaUltrasonik() {
  digitalWrite(TRIG, LOW);
  delayMicroseconds(2);
  digitalWrite(TRIG, HIGH);
  delayMicroseconds(10);
  digitalWrite(TRIG, LOW);
  
  long d = pulseIn(ECHO, HIGH, 15000); 
  distance = (d <= 0) ? -1 : (int)(d * 0.034 / 2);
}

void siramTanamanOtomatis() {
  if (!statusAutoMode) return;
  if (statusPompaAir || statusPompaPestisida || statusSolenoidA || statusSolenoidB) return;

  bacaUltrasonik();
  if (distance > 0 && distance > AIR_MINIMAL) {
    digitalWrite(CH1_POMPA_AIR, RELAY_OFF);
    lcd.setCursor(0, 0); 
    lcd.print("AIR HABIS!      ");
    Serial.println("[AUTO] Tangki air menipis!");
    return;
  }

  Serial.println("[AUTO] Menjalankan penyiraman otomatis...");
  digitalWrite(CH1_POMPA_AIR, RELAY_ON);
  lcd.setCursor(0, 0); 
  lcd.print("Siram Otomatis  ");

  for (int i = 0; i < 50; i++) {
    if (!statusAutoMode || statusPompaPestisida || statusSolenoidA || statusSolenoidB) break;
    delay(100);
  }

  digitalWrite(CH1_POMPA_AIR, RELAY_OFF);
  updateHardwareRelay();
}

void pushSensor(float suhu, float hum) {
  if (!Firebase.ready()) return;

  soilPersen = constrain(map(soilValue, 2500, 1500, 0, 100), 0, 100);

  FirebaseJson json;
  json.set("suhu",            isnan(suhu) ? 0.0 : suhu);
  json.set("humidity",        isnan(hum)  ? 0.0 : hum);
  json.set("soilValue",       soilValue);
  json.set("soilPersen",      soilPersen);
  json.set("waterDistanceCm", distance);
  json.set("lastUpdate/.sv",  "timestamp");

  Firebase.RTDB.setJSON(&fbData, "/fertiflow/sensors", &json);
}

// ==========================================
// SETUP & LOOP
// ==========================================
void setup() {
  Serial.begin(115200);

  // Inisialisasi pin I2C eksplisit untuk ESP32
  Wire.begin(I2C_SDA, I2C_SCL);

  pinMode(TRIG, OUTPUT);
  pinMode(ECHO, INPUT);
  pinMode(SOIL, INPUT);
  
  pinMode(CH1_POMPA_AIR, OUTPUT); digitalWrite(CH1_POMPA_AIR, RELAY_OFF);
  pinMode(CH2_SOLENOID_A, OUTPUT); digitalWrite(CH2_SOLENOID_A, RELAY_OFF);
  pinMode(CH3_SOLENOID_B, OUTPUT); digitalWrite(CH3_SOLENOID_B, RELAY_OFF);
  pinMode(CH4_POMPA_PESTISIDA, OUTPUT); digitalWrite(CH4_POMPA_PESTISIDA, RELAY_OFF);

  // Inisialisasi layar LCD
  lcd.init();
  lcd.backlight();
  lcd.setCursor(0, 0); 
  lcd.print("FertiFlow v2");
  lcd.setCursor(0, 1); 
  lcd.print("Connecting WiFi");

  dht.begin();
  if (!rtc.begin()) Serial.println("[WARN] RTC Tidak Terdeteksi!");

  WiFi.setAutoReconnect(true);
  WiFi.persistent(true);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  
  Serial.print("[WiFi] Menghubungkan");
  int wifiRetry = 0;
  while (WiFi.status() != WL_CONNECTED && wifiRetry < 30) {
    Serial.print(".");
    delay(300);
    wifiRetry++;
  }

  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\n[WiFi] Terhubung! IP: " + WiFi.localIP().toString());
  } else {
    Serial.println("\n[WiFi] Gagal konek, restart ESP...");
    ESP.restart();
  }

  config.api_key = FIREBASE_API_KEY;
  config.database_url = FIREBASE_DB_URL;
  auth.user.email = "";
  auth.user.password = "";
  Firebase.signUp(&config, &auth, "", "");

  config.token_status_callback = tokenStatusCallback;
  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);

  if (!Firebase.RTDB.beginStream(&fbStream, "/fertiflow/relay")) {
    Serial.println("[FB] Gagal inisialisasi stream: " + fbStream.errorReason());
  }
  Firebase.RTDB.setStreamCallback(&fbStream, streamCallback, streamTimeoutCallback);

  Firebase.RTDB.setBool(&fbData, "/fertiflow/status", true);

  lcd.clear();
  lcd.setCursor(0, 0); 
  lcd.print("System Ready");
  delay(1000);
  lcd.clear();
  updateHardwareRelay();
}

void loop() {
  unsigned long ms = millis();

  if (ms - lastSensorPush >= SENSOR_INTERVAL) {
    DateTime now = rtc.now();
    float suhu = dht.readTemperature();
    float hum  = dht.readHumidity();
    soilValue  = analogRead(SOIL);
    bacaUltrasonik();

    if (statusAutoMode) {
      if (soilValue >= SOIL_KERING) {
        siramTanamanOtomatis();
      }

      if (now.hour() == 7 && now.minute() == 0 && !siramPagi) {
        if (soilValue >= SOIL_KERING) siramTanamanOtomatis();
        siramPagi = true;
      }
      if (now.hour() == 17 && now.minute() == 0 && !siramSore) {
        if (soilValue >= SOIL_KERING) siramTanamanOtomatis();
        siramSore = true;
      }
      if (now.hour() == 0 && now.minute() == 0) {
        siramPagi = false;
        siramSore = false;
      }
    }

    pushSensor(suhu, hum);
    
    lcd.setCursor(0, 1);
    lcd.printf("S:%d%% Air:%dcm  ", soilPersen, distance);

    lastSensorPush = ms;
  }
}