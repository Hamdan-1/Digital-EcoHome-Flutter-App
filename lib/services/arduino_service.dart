import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

// --- Model Class for Sensor Data ---
class SensorData {
  final int gas;
  final int light;
  final int soil;
  final int water;
  final int pir; // 0 or 1

  SensorData({
    this.gas = 0,
    this.light = 0,
    this.soil = 0,
    this.water = 0,
    this.pir = 0,
  });

  // Factory constructor to parse from the Arduino string format
  factory SensorData.fromRawString(String dataString) {
    int gas = 0, light = 0, soil = 0, water = 0, pir = 0;
    try {
      List<String> pairs = dataString.split(',');
      for (String pair in pairs) {
        List<String> kv = pair.split('=');
        if (kv.length == 2) {
          String key = kv[0].trim();
          int? value = int.tryParse(kv[1].trim());
          if (value != null) {
            switch (key) {
              case 'GAS': gas = value; break;
              case 'LIGHT': light = value; break;
              case 'SOIL': soil = value; break;
              case 'WATER': water = value; break;
              case 'PIR': pir = value; break;
            }
          }
        }
      }
    } catch (e) {
      print("Error parsing sensor data string '$dataString': $e");
      // Return default values on error
    }
    return SensorData(gas: gas, light: light, soil: soil, water: water, pir: pir);
  }

  // Method to convert back to a map if needed elsewhere
  Map<String, dynamic> toMap() {
    return {
      'GAS': gas,
      'LIGHT': light,
      'SOIL': soil,
      'WATER': water,
      'PIR': pir,
    };
  }

  @override
  String toString() {
    return 'SensorData(GAS: $gas, LIGHT: $light, SOIL: $soil, WATER: $water, PIR: $pir)';
  }
}


// --- Arduino Service ---
class ArduinoService extends ChangeNotifier {
  Socket? _socket;
  String? _serverIp;
  final int _port = 80; // Port defined in Arduino sketch
  bool _isConnected = false;
  StreamSubscription? _socketSubscription;
  final StringBuffer _receiveBuffer = StringBuffer(); // Buffer for incoming data

  // Sensor data - now using the model class
  SensorData _sensorData = SensorData(); // Initialize with default values

  // Error handling state
  String? _errorMessage;
  bool _hasError = false;

  // --- Getters ---
  bool get isConnected => _isConnected;
  SensorData get sensorData => _sensorData;
  String? get errorMessage => _errorMessage;
  bool get hasError => _hasError;

  // --- Connection Management ---

  Future<bool> connect(String ipAddress) async {
    if (_isConnected) {
      print('Already connected.');
      _clearError(); // Clear any previous error on successful reconnect attempt
      return true;
    }
    _serverIp = ipAddress;
    print('Attempting to connect to $_serverIp:$_port...');
    _clearError(); // Clear previous errors before attempting connection

    try {
      _socket = await Socket.connect(_serverIp!, _port, timeout: Duration(seconds: 5));
      _isConnected = true;
      print('Connected to Arduino at ${_socket?.remoteAddress.address}:${_socket?.remotePort}');

      // Listen for data from the Arduino
      _socketSubscription = _socket!.listen(
        _handleData,
        onError: _handleError, // Use centralized error handler
        onDone: _handleDisconnect,
        cancelOnError: true, // Disconnect stream on error
      );

      // Request initial sensor data upon connection
      requestSensorUpdate(); // Use the specific method

      notifyListeners();
      return true;
    } catch (e) {
      print('Connection failed: $e');
      _setError('Connection failed: ${e.toString()}'); // Set user-friendly error
      _isConnected = false;
      _socket = null;
      _serverIp = null;
      // notifyListeners(); // _setError already notifies
      return false;
    }
  }

  void disconnect() {
    if (!_isConnected) return;
    print('Disconnecting...');
    _socketSubscription?.cancel();
    _socket?.destroy(); // Close and destroy the socket
    _handleDisconnect(); // Ensure state is updated
  }

  // --- Error State Management ---

  void _setError(String message) {
    _errorMessage = message;
    _hasError = true;
    notifyListeners();
  }

  void _clearError() {
    if (_hasError) {
      _errorMessage = null;
      _hasError = false;
      notifyListeners();
    }
  }

  // --- Data Handling ---

  void _handleData(Uint8List data) {
    final incomingString = utf8.decode(data);
    _receiveBuffer.write(incomingString);
    // print('Received raw chunk: "$incomingString", Buffer: "${_receiveBuffer.toString()}"');

    String bufferString = _receiveBuffer.toString();
    int newlineIndex;
    while ((newlineIndex = bufferString.indexOf('\n')) != -1) {
      final completeLine = bufferString.substring(0, newlineIndex + 1);
      final response = completeLine.trim();

      if (response.isNotEmpty) {
         print('Processing line: "$response"');
         _clearError(); // Clear error on receiving any valid data
        _parseResponse(response);
      }
      bufferString = bufferString.substring(newlineIndex + 1);
    }
    _receiveBuffer.clear();
    _receiveBuffer.write(bufferString);
    // print('Remaining in buffer: "${_receiveBuffer.toString()}"');
  }


  void _parseResponse(String response) {
     // print('Parsing response: "$response"'); // Already logged in _handleData
     if (response.startsWith("SENSORS:")) {
       _updateSensorData(response.substring(8)); // Remove "SENSORS:" prefix
     } else if (response.startsWith("ACK:")) {
       print("Acknowledgement received: ${response.substring(4)}");
       // Handle acknowledgements if needed (e.g., confirm command success)
     } else if (response.startsWith("ERROR:")) {
       final errorMsg = "Arduino Error: ${response.substring(6)}";
       print(errorMsg);
       _setError(errorMsg); // Set error state for UI
     } else if (response.startsWith("Welcome Client!")) {
        print("Received welcome message from Arduino."); // Ignore welcome message here
     }
     else {
       print("Unknown response format: $response");
       // Optionally set an error for unknown responses if critical
       // _setError("Received unknown data from Arduino: $response");
     }
  }

 void _updateSensorData(String dataString) {
    try {
      _sensorData = SensorData.fromRawString(dataString); // Use the factory constructor
      print("Updated Sensor Data: $_sensorData");
      notifyListeners(); // Notify listeners about sensor data update
    } catch (e) {
      // Error is already printed within the factory constructor
      _setError("Failed to parse sensor data."); // Set generic error for UI
    }
  }


  void _handleError(error, StackTrace stackTrace) {
    // This handles socket-level errors (e.g., connection reset)
    print('Socket error: $error');
    print(stackTrace);
    _setError('Socket error: ${error.toString()}'); // Set user-friendly error
    _isConnected = false; // Ensure connection status is false
    _socketSubscription?.cancel();
    _socket = null;
    _serverIp = null;
    _receiveBuffer.clear();
    _sensorData = SensorData(); // Reset sensor data
    // notifyListeners(); // _setError already notifies
  }

  void _handleDisconnect() {
    // This is called when the socket is closed gracefully (by remote or local)
    print('Disconnected from Arduino.');
    if (_isConnected) { // Only update state if we thought we were connected
      _isConnected = false;
      _socketSubscription?.cancel();
      _socket = null;
      _serverIp = null;
      _receiveBuffer.clear();
      _sensorData = SensorData(); // Reset sensor data
      _clearError(); // Clear any errors on graceful disconnect
      notifyListeners();
    }
  }

  // --- Sending Commands ---

  void sendCommand(String command) {
    if (!_isConnected || _socket == null) {
      print('Not connected. Cannot send command: $command');
      _setError('Not connected. Please connect first.'); // Inform UI
      return;
    }
    try {
      print('Sending command: $command');
      _socket!.writeln(command); // Use writeln to add newline
      // await _socket!.flush(); // Flush might not be necessary with writeln, test if needed
      _clearError(); // Clear error on successful send attempt
    } catch (e) {
      print('Error sending command "$command": $e');
      _setError('Failed to send command: ${e.toString()}'); // Set error state
      // Consider if disconnection is needed here based on error type
    }
  }

  // --- Specific Control Methods ---
  // (These remain largely the same, just call the updated sendCommand)

  void updateLcd(String text) {
    text = text.replaceAll('\n', ' ').replaceAll('\r', '');
    sendCommand('LCD:$text');
  }

  void setWindowAngle(double angle) {
    int angleInt = angle.clamp(0, 180).round();
    sendCommand('WINDOW:$angleInt');
  }

  void setDoor(bool lock) {
    sendCommand(lock ? 'DOOR:LOCK' : 'DOOR:UNLOCK');
  }

  void setFan(bool on) {
     sendCommand(on ? 'FAN:ON' : 'FAN:OFF');
  }

  void setFanSpeed(double speed) {
    int speedInt = speed.clamp(0, 255).round();
    sendCommand('FAN_SPEED:$speedInt');
  }

   void setLed(String color, bool on) {
     color = color.toUpperCase();
     if (color == 'YELLOW' || color == 'WHITE') {
       sendCommand('LED_$color:${on ? 'ON' : 'OFF'}');
     } else {
       print("Error: Invalid LED color '$color'");
       _setError("Invalid LED color specified."); // Inform UI
     }
   }

   void triggerBuzzer(String action) {
     action = action.toUpperCase();
     if (action == 'ON' || action == 'OFF' || action == 'ALARM') {
        sendCommand('BUZZER:$action');
     } else {
       print("Error: Invalid Buzzer action '$action'");
       _setError("Invalid Buzzer action specified."); // Inform UI
     }
   }

   void requestSensorUpdate() {
     sendCommand("GET_SENSORS");
   }

  @override
  void dispose() {
    disconnect(); // Ensure disconnection on dispose
    super.dispose();
  }
}