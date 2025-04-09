// Persistent storage for device states and energy usage history
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_state.dart';
import 'energy_usage_simulator.dart';

/// Manages persistent storage of simulated IoT data
class IoTPersistentStorage {
  // Keys for SharedPreferences
  static const String _devicesKey = 'simulated_devices';
  static const String _dailyEnergyKey = 'energy_daily_history';
  static const String _hourlyEnergyKey = 'energy_hourly_data';
  static const String _deviceEnergyKey = 'device_energy_usage';
  static const String _alertsKey = 'energy_alerts';
  static const String _lastUpdateKey = 'last_update_timestamp';
  
  // Save the current device states
  Future<bool> saveDeviceStates(List<Device> devices) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Convert devices to JSON
      final List<Map<String, dynamic>> deviceMaps = devices.map((device) {
        return {
          'id': device.id,
          'name': device.name,
          'type': device.type,
          'isActive': device.isActive,
          'currentUsage': device.currentUsage,
          'iconPath': device.iconPath,
          'maxUsage': device.maxUsage,
          'room': device.room,
          'settings': device.settings,
          'usageHistory': device.usageHistory,
        };
      }).toList();
      
      // Save as JSON string
      final String devicesJson = jsonEncode(deviceMaps);
      await prefs.setString(_devicesKey, devicesJson);
      
      // Save last update timestamp
      await prefs.setInt(_lastUpdateKey, DateTime.now().millisecondsSinceEpoch);
      
      return true;
    } catch (e) {
      print('Error saving device states: $e');
      return false;
    }
  }
  
  // Load saved device states
  Future<List<Device>?> loadDeviceStates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check if we have saved device states
      if (!prefs.containsKey(_devicesKey)) {
        return null;
      }
      
      final String? devicesJson = prefs.getString(_devicesKey);
      if (devicesJson == null) return null;
      
      // Decode JSON
      final List<dynamic> deviceMaps = jsonDecode(devicesJson);
      
      // Convert to Device objects
      List<Device> devices = deviceMaps.map<Device>((map) {
        final String type = map['type'];
        
        // Create appropriate device type
        if (type == 'HVAC') {
          return SmartAC(
            id: map['id'],
            name: map['name'],
            isActive: map['isActive'],
            currentUsage: map['currentUsage'],
            room: map['room'],
          );
        } else if (type == 'Light') {
          return SmartLight(
            id: map['id'],
            name: map['name'],
            isActive: map['isActive'],
            currentUsage: map['currentUsage'],
            room: map['room'],
          );
        } else if (type == 'Appliance' && map['name'].contains('Washing Machine')) {
          return SmartWashingMachine(
            id: map['id'],
            name: map['name'],
            isActive: map['isActive'],
            currentUsage: map['currentUsage'],
            room: map['room'],
          );
        } else {
          // Generic device
          return Device(
            id: map['id'],
            name: map['name'],
            type: map['type'],
            isActive: map['isActive'],
            currentUsage: map['currentUsage'],
            iconPath: map['iconPath'],
            maxUsage: map['maxUsage'],
            room: map['room'],
            settings: map['settings'] != null ? 
              Map<String, dynamic>.from(map['settings']) : null,
            usageHistory: map['usageHistory'] != null ?
              List<double>.from(map['usageHistory']) : null,
          );
        }
      }).toList();
      
      return devices;
    } catch (e) {
      print('Error loading device states: $e');
      return null;
    }
  }
  
  // Save energy usage history
  Future<bool> saveEnergyHistory(Map<DateTime, double> dailyUsage, 
                                List<double> hourlyData,
                                Map<String, Map<String, double>> deviceUsage) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Convert daily usage data (serialize DateTime keys)
      final Map<String, double> serializedDaily = {};
      dailyUsage.forEach((key, value) {
        serializedDaily[key.toIso8601String()] = value;
      });
      
      // Serialize device usage data
      final Map<String, Map<String, double>> serializedDeviceUsage = {};
      deviceUsage.forEach((dateStr, typeMap) {
        serializedDeviceUsage[dateStr] = typeMap;
      });
      
      // Save as JSON
      await prefs.setString(_dailyEnergyKey, jsonEncode(serializedDaily));
      await prefs.setString(_hourlyEnergyKey, jsonEncode(hourlyData));
      await prefs.setString(_deviceEnergyKey, jsonEncode(serializedDeviceUsage));
      
      return true;
    } catch (e) {
      print('Error saving energy history: $e');
      return false;
    }
  }
  
  // Load energy usage history
  Future<Map<String, dynamic>?> loadEnergyHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check if we have saved energy data
      if (!prefs.containsKey(_dailyEnergyKey) || 
          !prefs.containsKey(_hourlyEnergyKey)) {
        return null;
      }
      
      // Load JSON strings
      final String? dailyJson = prefs.getString(_dailyEnergyKey);
      final String? hourlyJson = prefs.getString(_hourlyEnergyKey);
      final String? deviceUsageJson = prefs.getString(_deviceEnergyKey);
      
      if (dailyJson == null || hourlyJson == null) return null;
      
      // Parse JSON
      final Map<String, dynamic> dailyData = jsonDecode(dailyJson);
      final List<dynamic> hourlyData = jsonDecode(hourlyJson);
      
      // Convert back to appropriate types
      final Map<DateTime, double> dailyUsage = {};
      dailyData.forEach((key, value) {
        dailyUsage[DateTime.parse(key)] = value.toDouble();
      });
      
      final List<double> hourlyUsage = hourlyData.map<double>((e) => e.toDouble()).toList();
      
      // Parse device usage if available
      Map<String, Map<String, double>> deviceUsage = {};
      if (deviceUsageJson != null) {
        final Map<String, dynamic> deviceData = jsonDecode(deviceUsageJson);        deviceData.forEach((dateStr, typeMapDynamic) {
          final typeMap = (typeMapDynamic as Map<String, dynamic>).map(
            (key, value) => MapEntry(key, value is num ? value.toDouble() : 0.0)
          );
          deviceUsage[dateStr] = typeMap;
        });
      }
      
      return {
        'dailyUsage': dailyUsage,
        'hourlyUsage': hourlyUsage,
        'deviceUsage': deviceUsage,
      };
    } catch (e) {
      print('Error loading energy history: $e');
      return null;
    }
  }
  
  // Save energy alerts
  Future<bool> saveEnergyAlerts(List<EnergyAlert> alerts) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Convert alerts to maps
      final List<Map<String, dynamic>> alertMaps = alerts.map((alert) {
        return {
          'message': alert.message,
          'time': alert.time.toIso8601String(),
          'isRead': alert.isRead,
        };
      }).toList();
      
      // Save as JSON
      await prefs.setString(_alertsKey, jsonEncode(alertMaps));
      
      return true;
    } catch (e) {
      print('Error saving energy alerts: $e');
      return false;
    }
  }
  
  // Load energy alerts
  Future<List<EnergyAlert>?> loadEnergyAlerts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check if we have saved alerts
      if (!prefs.containsKey(_alertsKey)) {
        return null;
      }
      
      final String? alertsJson = prefs.getString(_alertsKey);
      if (alertsJson == null) return null;
      
      // Parse JSON
      final List<dynamic> alertMaps = jsonDecode(alertsJson);
      
      // Convert to EnergyAlert objects
      List<EnergyAlert> alerts = alertMaps.map<EnergyAlert>((map) {
        return EnergyAlert(
          message: map['message'],
          time: DateTime.parse(map['time']),
          isRead: map['isRead'],
        );
      }).toList();
      
      return alerts;
    } catch (e) {
      print('Error loading energy alerts: $e');
      return null;
    }
  }
    // Save larger data to a file (for more extensive histories)
  Future<bool> saveDataToFile(String filename, Map<String, dynamic> data) async {
    try {
      // Instead of using path_provider, we'll use shared preferences for all storage
      final prefs = await SharedPreferences.getInstance();
      
      // Convert to JSON and store in shared preferences
      await prefs.setString('file_$filename', jsonEncode(data));
      
      return true;
    } catch (e) {
      print('Error saving data to file: $e');
      return false;
    }
  }
  
  // Load larger data from a file
  Future<Map<String, dynamic>?> loadDataFromFile(String filename) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check if data exists
      if (!prefs.containsKey('file_$filename')) {
        return null;
      }
      
      // Read and parse JSON
      final String? contents = prefs.getString('file_$filename');
      if (contents == null) return null;
      
      final Map<String, dynamic> data = jsonDecode(contents);
      
      return data;
    } catch (e) {
      print('Error loading data from file: $e');
      return null;
    }
  }
  
  // Get the timestamp of the last update
  Future<DateTime?> getLastUpdateTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (!prefs.containsKey(_lastUpdateKey)) {
        return null;
      }
      
      final int? timestamp = prefs.getInt(_lastUpdateKey);
      if (timestamp == null) return null;
      
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    } catch (e) {
      print('Error getting last update time: $e');
      return null;
    }
  }
}
