// --- Debug Flag ---
// Set to 1 to enable Serial print debugging, 0 to disable
#define DEBUG 1

// Includes for WiFi, Servos, and LCD
#include <WiFiS3.h>
#include <Servo.h>
#include <Wire.h>
#include <LiquidCrystal_I2C.h>

// --- WiFi Configuration ---
// IMPORTANT: Replace with your network credentials!
char ssid[] = "Hamdan";       // your network SSID (name)
char pass[] = "Hamdan2025";   // your network password
int keyIndex = 0;                 // your network key Index number (needed only for WEP)
int status = WL_IDLE_STATUS;      // the WiFi radio's status
WiFiServer server(80);            // Initialize the server on port 80
WiFiClient client;                // Client object to handle connections

// --- Hardware Pin Definitions ---
// Servos
const int DOOR_SERVO_PIN = 9;
const int WINDOW_SERVO_PIN = 10;
Servo doorServo;
Servo windowServo;
const int DOOR_LOCKED_ANGLE = 0;
const int DOOR_UNLOCKED_ANGLE = 100; // As per original code logic

// LEDs
const int YELLOW_LED_PIN = 5; // PWM capable, but used as digital on/off
const int WHITE_LED_PIN = 13; // Built-in LED

// Fan
const int FAN_PIN_A = 7; // Digital control pin
const int FAN_PIN_B = 6; // PWM control pin for speed

// Buzzer
const int BUZZER_PIN = 3;

// Sensors
const int GAS_SENSOR_PIN = A0;
const int LIGHT_SENSOR_PIN = A1;
const int SOIL_SENSOR_PIN = A2;
const int WATER_SENSOR_PIN = A3;
const int PIR_SENSOR_PIN = 2;

// LCD
LiquidCrystal_I2C lcd(0x27, 16, 2); // I2C address 0x27, 16 column and 2 rows

// --- Global Variables ---
const int MAX_COMMAND_LENGTH = 100;       // Maximum length for incoming commands
char commandBuffer[MAX_COMMAND_LENGTH];   // Buffer for incoming command chars
int commandIndex = 0;                     // Current index in commandBuffer
bool commandComplete = false;             // Flag for completed command

unsigned long previousSensorReadMillis = 0; // Timer for sensor reading
const long sensorReadInterval = 2000;     // Read sensors every 2 seconds

// Global variables for non-blocking buzzer (alarm and simple tone)
unsigned long buzzerTimer = 0;
unsigned long buzzerStopTime = 0; // Time when a simple tone should stop
int buzzerState = 0; // 0: off, 1: alarm_tone1, 2: alarm_pause1, 3: alarm_tone2, 4: alarm_pause2, 5: simple_tone_on
const int BUZZER_TONE1_FREQ = 1000;
const int BUZZER_TONE2_FREQ = 1500;
const int BUZZER_ALARM_TONE_DURATION = 200;
const int BUZZER_ALARM_PAUSE_DURATION = 50;
const int BUZZER_SIMPLE_TONE_FREQ = 500;
const int BUZZER_SIMPLE_TONE_DURATION = 500; // Duration for BUZZER:ON

// Global variables for non-blocking WiFi status LED blinking
unsigned long wifiLedTimer = 0;
bool wifiLedState = false; // false: off, true: on
const long WIFI_LED_BLINK_INTERVAL = 500; // Blink every 500ms when connected

// --- Setup Function ---
void setup() {
#if DEBUG
  Serial.begin(9600); // Initialize serial for debugging
  while (!Serial); // Wait for serial port to connect (needed for some boards like Leonardo)
  Serial.println("Serial communication initialized."); // Added diagnostic print
#endif

#if DEBUG
  Serial.println("\n\n--- Digital EcoHome System Booting Up ---"); // Added newlines for clarity

  Serial.println("Checking WiFi Module Firmware..."); // Added diagnostic print
  String fv = WiFi.firmwareVersion(); // String usage here is acceptable as it's only in setup
  if (fv < WIFI_FIRMWARE_LATEST_VERSION) {
    Serial.println("!!! Please upgrade the WiFi firmware !!!");
    Serial.print("Current version: "); Serial.println(fv);
    Serial.print("Latest version: "); Serial.println(WIFI_FIRMWARE_LATEST_VERSION);
  } else {
    Serial.print("WiFi Firmware Version: "); Serial.println(fv);
  }

  // Attempt to connect to WiFi network - Prioritize WiFi connection
  Serial.print("\nAttempting to connect to SSID: "); // Added diagnostic print
  Serial.println(ssid);
#endif

  int attemptCount = 0;
  while (status != WL_CONNECTED) {
    attemptCount++;
#if DEBUG
    Serial.print("\nAttempt "); Serial.print(attemptCount); Serial.print(": Connecting to "); Serial.print(ssid); // Added diagnostic print
#endif
    status = WiFi.begin(ssid, pass); // Start connection attempt

    // Wait up to 10 seconds for connection
    unsigned long startAttemptTime = millis();
    while (millis() - startAttemptTime < 10000) { // 10s timeout per attempt
        status = WiFi.status(); // Check the status
        if (status == WL_CONNECTED) {
            break; // Exit inner loop if connected
        }
        delay(50); // Reduced delay slightly while checking status
    }
#if DEBUG
    Serial.println(); // Newline after dots or connection
#endif

    if (status != WL_CONNECTED) {
#if DEBUG
        Serial.print("Connection Failed! Status Code: "); // Added diagnostic print
        printWifiStatusCode(status); // Print detailed status
        Serial.println(" Retrying in 1 second..."); // Updated message
#endif
        delay(1000); // Keep a short retry delay
    }
  }

#if DEBUG
  // WiFi connection successful
  Serial.println("\n--------------------"); // Separator for clarity
  Serial.print("Connected to "); // Added diagnostic print
  Serial.println(ssid); // Confirm connected network name
  Serial.println("--------------------");
  printWifiStatus(); // Print connection details
#endif

  // Turn off steady LED and prepare for blinking
  digitalWrite(WHITE_LED_PIN, LOW);
  wifiLedState = false; // Start with LED off for blinking
  wifiLedTimer = millis(); // Initialize timer for blinking

  // Initialize other components AFTER WiFi is connected
#if DEBUG
  Serial.println("Initializing LCD..."); // Added diagnostic print
#endif
  lcd.init();
  lcd.backlight();
  lcd.setCursor(0, 0);
  lcd.print("System Ready"); // Keep this generic message
#if DEBUG
  Serial.println("LCD initialized."); // Added diagnostic print
#endif

#if DEBUG
  Serial.println("Initializing Servos..."); // Added diagnostic print
#endif
  doorServo.attach(DOOR_SERVO_PIN);
  windowServo.attach(WINDOW_SERVO_PIN);
  doorServo.write(DOOR_LOCKED_ANGLE); // Default: Door locked
  windowServo.write(0);             // Default: Window closed
#if DEBUG
  Serial.println("Servos Initialized."); // Added diagnostic print
#endif

#if DEBUG
  Serial.println("Initializing Yellow LED..."); // Added diagnostic print
#endif
  pinMode(YELLOW_LED_PIN, OUTPUT);
  digitalWrite(YELLOW_LED_PIN, LOW);  // Default off
#if DEBUG
  Serial.println("Yellow LED Initialized."); // Added diagnostic print
#endif

#if DEBUG
  Serial.println("Initializing Fan Pins..."); // Added diagnostic print
#endif
  pinMode(FAN_PIN_A, OUTPUT);
  pinMode(FAN_PIN_B, OUTPUT);
  digitalWrite(FAN_PIN_A, LOW); // Set default state for fan off
  analogWrite(FAN_PIN_B, 0);    // Set default state for fan off
#if DEBUG
  Serial.println("Fan Pins Initialized."); // Added diagnostic print
#endif

#if DEBUG
  Serial.println("Initializing Buzzer Pin..."); // Added diagnostic print
#endif
  pinMode(BUZZER_PIN, OUTPUT);
  noTone(BUZZER_PIN); // Ensure buzzer is off
#if DEBUG
  Serial.println("Buzzer Pin Initialized."); // Added diagnostic print
#endif

#if DEBUG
  Serial.println("Initializing Sensor Pins..."); // Added diagnostic print
#endif
  pinMode(PIR_SENSOR_PIN, INPUT); // PIR sensor pin as input
  // Analog pins are input by default (A0, A1, A2, A3)
#if DEBUG
  Serial.println("Sensor Pins Initialized."); // Added diagnostic print
#endif

  // Start the server
  server.begin();
#if DEBUG
  Serial.println("Server started"); // Added diagnostic print
#endif

#if DEBUG
  Serial.println("System setup complete."); // Added diagnostic print
// Indicate system readiness with a short beep
  tone(BUZZER_PIN, 1000); // Play a tone (e.g., 1000 Hz)
  delay(200);            // for 200 milliseconds
  noTone(BUZZER_PIN);    // Stop the tone
#endif
}

// --- Main Loop ---
void loop() {
  unsigned long currentMillis = millis(); // Get current time once per loop

  // Listen for incoming clients
  WiFiClient newClient = server.available();
  if (newClient) { // If a new client connects
#if DEBUG
    Serial.println("New client connected.");
#endif
    // If a new client connects, we will now just accept it and replace the old one.
    // The old client will be implicitly handled by the new connection taking over.
    // This prevents the explicit "Disconnecting old client" message and potential race conditions.
    client = newClient; // Store the new client
    client.println("Welcome Client!"); // Send a welcome message
    commandIndex = 0; // Reset command buffer index
    commandBuffer[0] = '\0'; // Null-terminate the buffer
    commandComplete = false;
  }

  // Handle data from the connected client
  if (client && client.connected()) { // If the client is connected
    while (client.available()) { // Read all available data
      char c = client.read(); // Read a byte
#if DEBUG
      Serial.write(c); // Echo to serial monitor for debugging
#endif

      if (c == '\n') { // If newline is received, command is complete
        commandComplete = true;
      } else if (c != '\r') { // Ignore carriage return
        if (commandIndex < MAX_COMMAND_LENGTH - 1) { // Prevent buffer overflow
          commandBuffer[commandIndex++] = c; // Add char to buffer
          commandBuffer[commandIndex] = '\0'; // Keep buffer null-terminated
        } else {
          Serial.println("WARN: Command buffer overflow!");
          // Handle overflow: maybe clear buffer and reject command?
          commandIndex = 0;
          commandBuffer[0] = '\0';
          commandComplete = false; // Discard potentially corrupt command
        }
      }
    }
  } else {
      // If the client is not connected or has disconnected
      if (client) { // Check if client object exists before stopping
#if DEBUG
          Serial.println("Client disconnected.");
#endif
          client.stop();
          // Optional: Reset states if needed when client disconnects
          commandIndex = 0;
          commandBuffer[0] = '\0';
          commandComplete = false;
      }
  }

  // Process complete command
  if (commandComplete) {
#if DEBUG
    Serial.print("Received command: ");
    Serial.println(commandBuffer);
#endif
    parseCommand(commandBuffer); // Pass the char buffer
    commandIndex = 0; // Reset buffer index
    commandBuffer[0] = '\0'; // Clear the command buffer
    commandComplete = false;
  }

  // Periodically read sensors (only if client is connected to potentially send data)
  if (client && client.connected() && currentMillis - previousSensorReadMillis >= sensorReadInterval) {
    previousSensorReadMillis = currentMillis;
    // Optionally send sensor data periodically or wait for GET_SENSORS command
    // sendSensorData(); // Uncomment to send periodically
  }

  // Non-blocking buzzer handling (alarm and simple tone)
  if (buzzerState != 0) {
    switch (buzzerState) {
      case 1: // Alarm Tone 1
        if (currentMillis - buzzerTimer >= BUZZER_ALARM_TONE_DURATION) {
          noTone(BUZZER_PIN);
          buzzerState = 2; // Move to alarm pause 1
          buzzerTimer = currentMillis;
        }
        break;
      case 2: // Alarm Pause 1
        if (currentMillis - buzzerTimer >= BUZZER_ALARM_PAUSE_DURATION) {
          tone(BUZZER_PIN, BUZZER_TONE2_FREQ); // Start alarm tone 2
          buzzerState = 3; // Move to alarm tone 2
          buzzerTimer = currentMillis;
        }
        break;
      case 3: // Alarm Tone 2
        if (currentMillis - buzzerTimer >= BUZZER_ALARM_TONE_DURATION) {
          noTone(BUZZER_PIN);
          buzzerState = 4; // Move to alarm pause 2
          buzzerTimer = currentMillis;
        }
        break;
      case 4: // Alarm Pause 2
        if (currentMillis - buzzerTimer >= BUZZER_ALARM_PAUSE_DURATION) {
          // Sequence complete, repeat
          buzzerState = 1; // Repeat the alarm sequence
          buzzerTimer = currentMillis;
          tone(BUZZER_PIN, BUZZER_TONE1_FREQ); // Start alarm tone 1 again
        }
        break;
      case 5: // Simple Tone On
        if (currentMillis >= buzzerStopTime) {
          noTone(BUZZER_PIN); // Stop the tone
          buzzerState = 0; // Set state to off
        }
        break;
    }
  }

  // Removed small delay to improve responsiveness.
  // The loop should now run continuously, processing commands and checking sensors.
}

// --- Command Parsing Function ---
// Parses commands received in the format "CMD" or "CMD:VALUE"
void parseCommand(char* command) {
  // Trim leading/trailing whitespace (simple version)
  while (isspace(*command)) command++; // Skip leading whitespace
  char* end = command + strlen(command) - 1;
  while (end > command && isspace(*end)) end--; // Trim trailing whitespace
  *(end + 1) = '\0';

  if (strlen(command) == 0) return; // Ignore empty commands

  char* value = strchr(command, ':'); // Find the colon separator
  char* cmdName = command;
  char* cmdValue = NULL;

  if (value != NULL) {
    *value = '\0'; // Null-terminate the command name part
    cmdValue = value + 1; // Point to the start of the value part
  } else {
    // No colon, command is the whole string, value is empty
    cmdValue = ""; // Point to an empty string
  }

  // Convert command name to uppercase for case-insensitive comparison
  for (char* p = cmdName; *p; ++p) *p = toupper(*p);

#if DEBUG
  Serial.print("Parsed CMD: "); Serial.print(cmdName);
  Serial.print(", VAL: "); Serial.println(cmdValue);
#endif

  // --- Actuator Commands ---
  if (strcmp(cmdName, "LCD") == 0) {
    updateLCD(cmdValue); // updateLCD still expects String, needs update or conversion
  } else if (strcmp(cmdName, "WINDOW") == 0) {
    int angle = atoi(cmdValue); // Use atoi for char* to int conversion
    setWindowServo(angle);
  } else if (strcmp(cmdName, "DOOR") == 0) {
    if (strcmp(cmdValue, "LOCK") == 0) setDoorServo(true);
    else if (strcmp(cmdValue, "UNLOCK") == 0) setDoorServo(false);
  } else if (strcmp(cmdName, "FAN") == 0) {
    if (strcmp(cmdValue, "ON") == 0) setFan(true, -1); // Keep current speed if just turning on
    else if (strcmp(cmdValue, "OFF") == 0) setFan(false, 0);
  } else if (strcmp(cmdName, "FAN_SPEED") == 0) {
    int speed = atoi(cmdValue); // Use atoi
    setFan(true, speed); // Assume setting speed also turns it on
  } else if (strcmp(cmdName, "LED_YELLOW") == 0) {
    if (strcmp(cmdValue, "ON") == 0) setLED(YELLOW_LED_PIN, true);
    else if (strcmp(cmdValue, "OFF") == 0) setLED(YELLOW_LED_PIN, false);
  } else if (strcmp(cmdName, "LED_WHITE") == 0) {
    if (strcmp(cmdValue, "ON") == 0) setLED(WHITE_LED_PIN, true);
    else if (strcmp(cmdValue, "OFF") == 0) setLED(WHITE_LED_PIN, false);
  } else if (strcmp(cmdName, "BUZZER") == 0) {
    if (strcmp(cmdValue, "ON") == 0) {
        // Start non-blocking simple tone
        buzzerState = 5; // Set state to simple tone on
        buzzerStopTime = millis() + BUZZER_SIMPLE_TONE_DURATION; // Calculate stop time
        tone(BUZZER_PIN, BUZZER_SIMPLE_TONE_FREQ); // Start the tone
#if DEBUG
        Serial.println("Buzzer ON (non-blocking)");
#endif
        if (client && client.connected()) client.println("ACK: Buzzer ON");
    } else if (strcmp(cmdValue, "OFF") == 0) {
        noTone(BUZZER_PIN);
        buzzerState = 0; // Reset state
#if DEBUG
        Serial.println("Buzzer OFF");
#endif
        if (client && client.connected()) client.println("ACK: Buzzer OFF");
    } else if (strcmp(cmdValue, "ALARM") == 0) {
        // Start the non-blocking alarm sequence
        buzzerState = 1; // Start with alarm tone 1
        buzzerTimer = millis(); // Record start time
        tone(BUZZER_PIN, BUZZER_TONE1_FREQ); // Start alarm tone 1
#if DEBUG
        Serial.println("Buzzer ALARM started");
#endif
        if (client && client.connected()) client.println("ACK: Buzzer ALARM");
    } else {
#if DEBUG
      Serial.print("Error: Invalid Buzzer action '");
      Serial.print(cmdValue);
      Serial.println("'");
#endif
      if (client && client.connected()) client.println("ERROR: Invalid Buzzer action");
    }
  }
  // --- Sensor Request ---
  else if (strcmp(cmdName, "GET_SENSORS") == 0) {
    sendSensorData();
  }
  // --- Unknown Command ---
  else {
    if (client && client.connected()) {
      client.print("ERROR: Unknown command '");
      client.print(cmdName);
      client.println("'");
    }
#if DEBUG
    Serial.print("Unknown command: ");
    Serial.println(cmdName);
#endif
  }
}


// --- Helper Functions ---

// TODO: Update updateLCD to accept char* or convert cmdValue before calling
void updateLCD(const char* text) { // Changed parameter to const char*
  lcd.clear();
  lcd.setCursor(0, 0);
  int len = strlen(text);
  if (len > 16) {
    char line1[17]; // Buffer for first line + null terminator
    strncpy(line1, text, 16);
    line1[16] = '\0';
    lcd.print(line1);
    lcd.setCursor(0, 1);
    lcd.print(text + 16); // Print the rest starting from the 17th char
  } else {
    lcd.print(text);
  }
#if DEBUG
  Serial.print("LCD Updated: "); Serial.println(text);
#endif
  if (client && client.connected()) client.println("ACK: LCD Updated");
}

void setWindowServo(int angle) {
  angle = constrain(angle, 0, 180); // Ensure angle is within bounds
  windowServo.write(angle);
#if DEBUG
  Serial.print("Window Servo set to: "); Serial.println(angle);
#endif
  if (client && client.connected()) client.println("ACK: Window set");
}

void setDoorServo(bool lock) {
  if (lock) {
    doorServo.write(DOOR_LOCKED_ANGLE);
#if DEBUG
    Serial.println("Door Locked");
#endif
    if (client && client.connected()) client.println("ACK: Door Locked");
  } else {
    doorServo.write(DOOR_UNLOCKED_ANGLE);
#if DEBUG
    Serial.println("Door Unlocked");
#endif
    if (client && client.connected()) client.println("ACK: Door Unlocked");
  }
}

void setFan(bool on, int speed) {
  if (on) {
    speed = constrain(speed, 0, 255); // Ensure speed is within bounds
    if (speed < 0) { // If speed wasn't specified with ON command, use a default or last known? Let's use a moderate default.
        speed = 150;
    }
    if (speed == 0) { // If speed is 0, turn off
        setFan(false, 0);
        return;
    }
    digitalWrite(FAN_PIN_A, LOW); // Direction control (adjust if fan spins wrong way)
    analogWrite(FAN_PIN_B, speed); // PWM speed control
#if DEBUG
    Serial.print("Fan ON, Speed: "); Serial.println(speed);
#endif
    if (client && client.connected()) client.println("ACK: Fan ON");

  } else { // Turn fan off
    digitalWrite(FAN_PIN_A, LOW);
    analogWrite(FAN_PIN_B, 0);
#if DEBUG
    Serial.println("Fan OFF");
#endif
    if (client && client.connected()) client.println("ACK: Fan OFF");
  }
}

void setLED(int pin, bool on) {
  digitalWrite(pin, on ? HIGH : LOW);
  const char* ledName = (pin == YELLOW_LED_PIN) ? "Yellow" : "White"; // Use const char*
#if DEBUG
  Serial.print(ledName); Serial.print(" LED "); Serial.println(on ? "ON" : "OFF");
#endif
   if (client && client.connected()) {
       client.print("ACK: "); client.print(ledName); client.println(on ? " LED ON" : " LED OFF");
   }
}

void readSensors(int &gas, int &light, int &soil, int &water, int &pir) {
  gas = analogRead(GAS_SENSOR_PIN);
  light = analogRead(LIGHT_SENSOR_PIN);
  soil = analogRead(SOIL_SENSOR_PIN);
  water = analogRead(WATER_SENSOR_PIN);
  pir = digitalRead(PIR_SENSOR_PIN); // Digital read for PIR
}

void sendSensorData() {
  if (!client || !client.connected()) return; // Don't send if no client

  int gasVal, lightVal, soilVal, waterVal, pirVal;
  readSensors(gasVal, lightVal, soilVal, waterVal, pirVal);

  // Send data as a simple key-value string using char array and sprintf
  // Example: "SENSORS:GAS=XXX,LIGHT=YYY,SOIL=ZZZ,WATER=WWW,PIR=P"
  char dataBuffer[100]; // Ensure buffer is large enough
  snprintf(dataBuffer, sizeof(dataBuffer), "SENSORS:GAS=%d,LIGHT=%d,SOIL=%d,WATER=%d,PIR=%d",
           gasVal, lightVal, soilVal, waterVal, pirVal);

  client.println(dataBuffer);
#if DEBUG
  Serial.print("Sent data: "); Serial.println(dataBuffer);
#endif
}

// --- WiFi Status Function ---
#if DEBUG // Only compile this function if DEBUG is enabled
void printWifiStatus() {
  // print the SSID of the network you're attached to:
  Serial.print("  SSID: "); // Indent for clarity
  Serial.println(WiFi.SSID());

  // print your board's IP address:
  IPAddress ip = WiFi.localIP();
  Serial.print("  IP Address: "); // Indent for clarity
  Serial.println(ip);

  // print the received signal strength:
  long rssi = WiFi.RSSI();
  Serial.print("  Signal strength (RSSI): "); // Indent for clarity
  Serial.print(rssi);
  Serial.println(" dBm");
}
#endif // End of printWifiStatus()

// Helper function to print descriptive WiFi status
#if DEBUG // Only compile this function if DEBUG is enabled
void printWifiStatusCode(int statusCode) {
  Serial.print(statusCode);
  switch (statusCode) {
    case WL_NO_SHIELD: Serial.print(" (No WiFi shield present)"); break;
    case WL_IDLE_STATUS: Serial.print(" (Idle)"); break;
    case WL_NO_SSID_AVAIL: Serial.print(" (No SSID available)"); break;
    case WL_SCAN_COMPLETED: Serial.print(" (Scan Completed)"); break;
    case WL_CONNECTED: Serial.print(" (Connected)"); break;
    case WL_CONNECT_FAILED: Serial.print(" (Connection failed)"); break;
    case WL_CONNECTION_LOST: Serial.print(" (Connection lost)"); break;
    case WL_DISCONNECTED: Serial.print(" (Disconnected)"); break;
    case WL_AP_LISTENING: Serial.print(" (AP Listening)"); break;
    case WL_AP_CONNECTED: Serial.print(" (AP Connected)"); break;
    case WL_AP_FAILED: Serial.print(" (AP Failed)"); break;
    // Removed WL_PROVISIONING and WL_PROVISIONING_FAILED as they might not be defined in all library versions
    default: Serial.print(" (Unknown Status)"); break;
  }
}

#endif // End of printWifiStatusCode()
