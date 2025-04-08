import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
// Add import for the AppSettings models
import 'settings/app_settings.dart';
import 'settings/user_preferences.dart';
import 'settings/home_configuration.dart';
import 'settings/device_management.dart';
import 'settings/advanced_settings.dart';

class Device {
  final String id;
  final String name;
  final String type;
  bool isActive;
  double currentUsage;
  final String iconPath;
  final List<double> usageHistory;
  final double maxUsage; // Maximum wattage when device is active
  final String room; // Added room information
  final Map<String, dynamic>? settings; // For storing device-specific settings

  Device({
    required this.id,
    required this.name,
    required this.type,
    required this.isActive,
    required this.currentUsage,
    required this.iconPath,
    required this.maxUsage,
    this.room = 'Unknown',
    this.settings,
    List<double>? usageHistory,
  }) : usageHistory = usageHistory ?? List.generate(24, (_) => 0.0);
}

// New classes for specific device types
class SmartAC extends Device {
  SmartAC({
    required String id,
    required String name,
    required bool isActive,
    required double currentUsage,
    required String room,
  }) : super(
         id: id,
         name: name,
         type: 'HVAC',
         isActive: isActive,
         currentUsage: currentUsage,
         iconPath: 'ac_unit',
         maxUsage: 1800.0,
         room: room,
         settings: {
           'temperature': 24,
           'fanSpeed': 'Medium',
           'mode': 'Cool',
           'timerHours': 0,
         },
       );
}

class SmartWashingMachine extends Device {
  SmartWashingMachine({
    required String id,
    required String name,
    required bool isActive,
    required double currentUsage,
    required String room,
  }) : super(
         id: id,
         name: name,
         type: 'Appliance',
         isActive: isActive,
         currentUsage: currentUsage,
         iconPath: 'local_laundry_service',
         maxUsage: 700.0,
         room: room,
         settings: {
           'cycle': 'Normal',
           'temperature': 'Warm',
           'spinSpeed': 'Medium',
           'remainingMinutes': 45,
           'progress': 0.0,
           'isRunning': false,
         },
       );
}

class SmartLight extends Device {
  SmartLight({
    required String id,
    required String name,
    required bool isActive,
    required double currentUsage,
    required String room,
  }) : super(
         id: id,
         name: name,
         type: 'Light',
         isActive: isActive,
         currentUsage: currentUsage,
         iconPath: 'lightbulb',
         maxUsage: 60.0,
         room: room,
         settings: {
           'brightness': 80,
           'colorTemperature': 4000,
           'scene': 'Normal',
           'isRGB': true,
           'color': 0xFFFFFFFF,
         },
       );
}

class EnergyTip {
  final String title;
  final String description;
  final IconData icon;

  EnergyTip({
    required this.title,
    required this.description,
    required this.icon,
  });
}

class EnergyAlert {
  final String message;
  final DateTime time;
  final bool isRead;

  EnergyAlert({required this.message, required this.time, this.isRead = false});
}

class AppState extends ChangeNotifier {
  // Simulated current power usage
  double _currentPowerUsage = 0.0; // Will be calculated from active devices
  final Random _random = Random();
  Timer? _usageUpdateTimer;

  // 24-hour usage data (hourly readings)
  List<double> _hourlyUsageData = [];

  // Energy cost settings
  double _energyRate = 0.15; // $0.15 per kWh

  // Yesterday's usage for comparison
  double _yesterdayUsage = 18.7; // kWh
  double _todayEstimatedUsage = 16.2; // kWh

  // Energy tips
  int _currentTipIndex = 0;
  final List<EnergyTip> _energyTips = [
    EnergyTip(
      title: 'Optimize Your Thermostat',
      description:
          'Set your thermostat to 78°F in summer and 68°F in winter to save up to 10% on your energy bill.',
      icon: Icons.thermostat,
    ),
    EnergyTip(
      title: 'Unplug Idle Electronics',
      description:
          'Devices on standby can account for up to 10% of your home energy use. Unplug them when not in use.',
      icon: Icons.power,
    ),
    EnergyTip(
      title: 'Use LED Lighting',
      description:
          'Replace incandescent bulbs with LEDs to use up to 75% less energy and last 25 times longer.',
      icon: Icons.lightbulb,
    ),
    EnergyTip(
      title: 'Run Full Loads',
      description:
          'Only run your dishwasher and washing machine with full loads to maximize energy efficiency.',
      icon: Icons.local_laundry_service,
    ),
    EnergyTip(
      title: 'Maintain Your HVAC',
      description:
          'Regularly replace filters and schedule annual maintenance to keep your HVAC system running efficiently.',
      icon: Icons.hvac,
    ),
  ];

  // Energy alerts
  final List<EnergyAlert> _energyAlerts = [
    EnergyAlert(
      message: 'Unusual energy spike detected at 2 PM',
      time: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    EnergyAlert(
      message: 'Kitchen refrigerator using 15% more energy than usual',
      time: DateTime.now().subtract(const Duration(hours: 6)),
    ),
    EnergyAlert(
      message: 'Living room AC has been running for 8 hours',
      time: DateTime.now().subtract(const Duration(hours: 1)),
    ),
  ];

  // Sample devices data with realistic power consumption values
  List<Device> _devices = [
    Device(
      id: '1',
      name: 'Air Conditioner',
      type: 'HVAC',
      isActive: true,
      currentUsage: 1200.0,
      iconPath: 'ac_unit',
      maxUsage: 1500.0,
      usageHistory: List.generate(24, (index) => Random().nextDouble() * 1500),
    ),
    Device(
      id: '2',
      name: 'Refrigerator',
      type: 'Appliance',
      isActive: true,
      currentUsage: 150.0,
      iconPath: 'kitchen',
      maxUsage: 200.0,
      usageHistory: List.generate(
        24,
        (index) => 100 + Random().nextDouble() * 100,
      ),
    ),
    Device(
      id: '3',
      name: 'Washing Machine',
      type: 'Appliance',
      isActive: false,
      currentUsage: 0.0,
      iconPath: 'local_laundry_service',
      maxUsage: 500.0,
      usageHistory: List.generate(
        24,
        (index) =>
            Random().nextDouble() < 0.2 ? 500 + Random().nextDouble() * 200 : 0,
      ),
    ),
    Device(
      id: '4',
      name: 'Living Room Lights',
      type: 'Light',
      isActive: true,
      currentUsage: 60.0,
      iconPath: 'lightbulb',
      maxUsage: 100.0,
      usageHistory: List.generate(24, (index) {
        // Simulate lights being on in the evening and night
        if (index > 17 || index < 6) {
          return 40 + Random().nextDouble() * 40;
        }
        return Random().nextDouble() < 0.1
            ? 40 + Random().nextDouble() * 40
            : 0;
      }),
    ),
    Device(
      id: '5',
      name: 'Water Heater',
      type: 'Water',
      isActive: true,
      currentUsage: 800.0,
      iconPath: 'hot_tub',
      maxUsage: 1200.0,
      usageHistory: List.generate(24, (index) {
        // Simulate water heater usage patterns
        if (index > 5 && index < 9) {
          return 500 + Random().nextDouble() * 500; // Morning usage
        }
        if (index > 17 && index < 22) {
          return 500 + Random().nextDouble() * 500; // Evening usage
        }
        return 100 + Random().nextDouble() * 100; // Standby
      }),
    ),
  ];

  // Energy usage summary
  double _todayUsage = 12.4;
  double _weeklyUsage = 78.3;
  double _monthlyUsage = 310.7;

  // Available rooms in the house
  final List<String> _rooms = [
    'Living Room',
    'Kitchen',
    'Bedroom',
    'Bathroom',
    'Office',
    'Garage',
    'Basement',
  ];

  // Discovered but not yet added devices
  List<Device> _discoveredDevices = [];
  bool _isScanning = false;

  // Device settings update simulation
  bool _isUpdatingDevice = false;

  // App settings
  AppSettings _appSettings = AppSettings();

  AppState() {
    // Calculate initial power usage based on active devices
    _recalculateTotalPowerUsage();

    // Initialize 24-hour data with simulated values
    _generateHourlyData();

    // Start timer to update current power usage randomly
    _startUsageSimulation();

    // Rotate energy tips every minute
    _startTipRotation();
  }

  void _startUsageSimulation() {
    _usageUpdateTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      // Update individual device usage values with small fluctuations
      _updateDeviceUsages();

      // Update hourly data to simulate real-time changes
      _updateHourlyData();

      // Recalculate total power usage based on updated device values
      _recalculateTotalPowerUsage();

      notifyListeners();
    });
  }

  void _startTipRotation() {
    Timer.periodic(const Duration(minutes: 1), (timer) {
      _currentTipIndex = (_currentTipIndex + 1) % _energyTips.length;
      notifyListeners();
    });
  }

  void _generateHourlyData() {
    final now = DateTime.now();
    final currentHour = now.hour;

    _hourlyUsageData = List.generate(24, (index) {
      // Calculate hour of the day (0-23)
      final hour = (currentHour - 23 + index) % 24;

      // Create a realistic pattern based on time of day
      double baseValue;

      // Night time (low usage)
      if (hour >= 0 && hour < 6) {
        baseValue = 1.0 + (_random.nextDouble() * 0.5);
      }
      // Morning peak
      else if (hour >= 6 && hour < 10) {
        baseValue = 2.0 + (_random.nextDouble() * 1.0);
      }
      // Midday moderate
      else if (hour >= 10 && hour < 17) {
        baseValue = 1.8 + (_random.nextDouble() * 0.7);
      }
      // Evening peak (highest usage)
      else if (hour >= 17 && hour < 22) {
        baseValue = 2.5 + (_random.nextDouble() * 1.3);
      }
      // Late evening (decreasing)
      else {
        baseValue = 1.5 + (_random.nextDouble() * 0.8);
      }

      return baseValue;
    });
  }

  // Calculate total power usage from all active devices
  void _recalculateTotalPowerUsage() {
    double total = 0.0;
    for (var device in _devices) {
      if (device.isActive) {
        total += device.currentUsage / 1000; // Convert watts to kilowatts
      }
    }

    // Add small base load for always-on devices (0.2 to 0.3 kW)
    total += 0.2 + (_random.nextDouble() * 0.1);

    _currentPowerUsage = total;
  }

  void _updateDeviceUsages() {
    for (int i = 0; i < _devices.length; i++) {
      var device = _devices[i];
      if (device.isActive) {
        // Add small random fluctuations to device usage
        double fluctuation = 0;

        switch (device.type) {
          case 'HVAC':
            fluctuation = (_random.nextDouble() * 200) - 100;
            break;
          case 'Appliance':
            fluctuation = (_random.nextDouble() * 30) - 15;
            break;
          case 'Light':
            fluctuation = (_random.nextDouble() * 10) - 5;
            break;
          case 'Water':
            fluctuation = (_random.nextDouble() * 100) - 50;
            break;
        }

        // Update the current usage with fluctuation
        double newUsage = device.currentUsage + fluctuation;

        // Ensure usage stays within realistic bounds (5% to 100% of max when on)
        if (newUsage < device.maxUsage * 0.05) {
          newUsage = device.maxUsage * 0.05;
        } else if (newUsage > device.maxUsage) {
          newUsage = device.maxUsage;
        }

        // Create a new device with updated usage
        _devices[i] = Device(
          id: device.id,
          name: device.name,
          type: device.type,
          isActive: device.isActive,
          currentUsage: newUsage,
          iconPath: device.iconPath,
          maxUsage: device.maxUsage,
          usageHistory: _updateUsageHistory(device.usageHistory, newUsage),
          room: device.room,
          settings: device.settings,
        );
      }
    }
  }

  List<double> _updateUsageHistory(List<double> history, double currentValue) {
    // Create a new list to avoid mutation issues
    List<double> newHistory = List<double>.from(history);

    // Remove oldest value and add new one
    if (newHistory.isNotEmpty) {
      newHistory.removeAt(0);
      newHistory.add(currentValue);
    }

    return newHistory;
  }

  void _updateHourlyData() {
    // Update hourly data to simulate real-time changes by shifting values
    if (_hourlyUsageData.isNotEmpty) {
      _hourlyUsageData.removeAt(0);

      // Add new value based on current power usage with small variation
      double variation = (_random.nextDouble() * 0.4) - 0.2; // -0.2 to +0.2 kW
      _hourlyUsageData.add(_currentPowerUsage + variation);
    }
  }

  // Calculate daily energy cost based on current usage rate
  double calculateDailyCost() {
    return _currentPowerUsage * 24 * _energyRate;
  }

  // Getters
  List<Device> get devices => _devices;
  List<Device> get discoveredDevices => _discoveredDevices;
  List<String> get rooms => _rooms;
  bool get isScanning => _isScanning;
  bool get isUpdatingDevice => _isUpdatingDevice;
  double get todayUsage => _todayUsage;
  double get weeklyUsage => _weeklyUsage;
  double get monthlyUsage => _monthlyUsage;
  double get currentPowerUsage => _currentPowerUsage;
  List<double> get hourlyUsageData => _hourlyUsageData;
  double get energyRate => _energyRate;
  double get yesterdayUsage => _yesterdayUsage;
  double get todayEstimatedUsage => _todayEstimatedUsage;
  EnergyTip get currentTip => _energyTips[_currentTipIndex];
  List<EnergyAlert> get energyAlerts => _energyAlerts;
  AppSettings get appSettings => _appSettings;

  bool isUsageLowerThanYesterday() {
    return _todayEstimatedUsage < _yesterdayUsage;
  }

  double usageDifferencePercent() {
    final difference = (_todayEstimatedUsage - _yesterdayUsage).abs();
    return (difference / _yesterdayUsage) * 100;
  }

  // Toggle device status
  void toggleDevice(String id) {
    final index = _devices.indexWhere((device) => device.id == id);
    if (index != -1) {
      final device = _devices[index];
      final newIsActive = !device.isActive;

      // Determine the new current usage based on activation state
      final newUsage =
          newIsActive
              ? (device.currentUsage > 0
                  ? device.currentUsage
                  : device.maxUsage * 0.8)
              : 0.0;

      // Update the device with new active state and usage
      _devices[index] = Device(
        id: device.id,
        name: device.name,
        type: device.type,
        isActive: newIsActive,
        currentUsage: newUsage,
        iconPath: device.iconPath,
        maxUsage: device.maxUsage,
        usageHistory: device.usageHistory,
        room: device.room,
        settings: device.settings,
      );

      // Recalculate total power usage based on the new device state
      _recalculateTotalPowerUsage();

      notifyListeners();
    }
  }

  // Add new device
  void addDevice(Device device) {
    _devices.add(device);
    notifyListeners();
  }

  // Remove device
  void removeDevice(String id) {
    _devices.removeWhere((device) => device.id == id);
    notifyListeners();
  }

  // Mark alert as read
  void markAlertAsRead(int index) {
    if (index < _energyAlerts.length) {
      _energyAlerts[index] = EnergyAlert(
        message: _energyAlerts[index].message,
        time: _energyAlerts[index].time,
        isRead: true,
      );
      notifyListeners();
    }
  }

  // Simulate device discovery
  Future<void> scanForDevices() async {
    if (_isScanning) return;

    _isScanning = true;
    _discoveredDevices = [];
    notifyListeners();

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 3));

    // Generate random discovered devices
    final existingIds = _devices.map((d) => d.id).toSet();
    final Random random = Random();

    // Generate 8-10 random devices
    final deviceCount = random.nextInt(3) + 8; // 8-10 devices

    for (int i = 0; i < deviceCount; i++) {
      final deviceType = random.nextInt(
        3,
      ); // 0: AC, 1: WashingMachine, 2: Light
      final roomIndex = random.nextInt(_rooms.length);
      final room = _rooms[roomIndex];
      final id = 'new_${DateTime.now().millisecondsSinceEpoch}_$i';

      // Skip if somehow we generated a duplicate ID
      if (existingIds.contains(id)) continue;

      switch (deviceType) {
        case 0:
          _discoveredDevices.add(
            SmartAC(
              id: id,
              name: '$room AC',
              isActive: false,
              currentUsage: 0,
              room: room,
            ),
          );
          break;
        case 1:
          _discoveredDevices.add(
            SmartWashingMachine(
              id: id,
              name: '$room Washing Machine',
              isActive: false,
              currentUsage: 0,
              room: room,
            ),
          );
          break;
        case 2:
          _discoveredDevices.add(
            SmartLight(
              id: id,
              name: '$room Light',
              isActive: false,
              currentUsage: 0,
              room: room,
            ),
          );
          break;
      }
    }

    _isScanning = false;
    notifyListeners();
  }

  // Add a discovered device to user's devices
  void addDiscoveredDevice(String id) {
    final deviceIndex = _discoveredDevices.indexWhere((d) => d.id == id);
    if (deviceIndex != -1) {
      final device = _discoveredDevices[deviceIndex];
      _devices.add(device);
      _discoveredDevices.removeAt(deviceIndex);
      notifyListeners();
    }
  }

  // Simulate device setting update with network delay
  Future<bool> updateDeviceSettings(
    String id,
    Map<String, dynamic> newSettings,
  ) async {
    _isUpdatingDevice = true;
    notifyListeners();

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 1500));

    final deviceIndex = _devices.indexWhere((d) => d.id == id);
    if (deviceIndex != -1) {
      final device = _devices[deviceIndex];
      final currentSettings = device.settings ?? {};

      // Create updated settings map
      final updatedSettings = Map<String, dynamic>.from(currentSettings)
        ..addAll(newSettings);

      // Create a new device with updated settings
      Device updatedDevice;

      if (device is SmartAC) {
        updatedDevice = SmartAC(
          id: device.id,
          name: device.name,
          isActive: device.isActive,
          currentUsage: _calculateNewUsage(device, updatedSettings),
          room: device.room,
        );
        (updatedDevice as SmartAC).settings!.addAll(updatedSettings);
      } else if (device is SmartWashingMachine) {
        updatedDevice = SmartWashingMachine(
          id: device.id,
          name: device.name,
          isActive: device.isActive,
          currentUsage: _calculateNewUsage(device, updatedSettings),
          room: device.room,
        );
        (updatedDevice as SmartWashingMachine).settings!.addAll(
          updatedSettings,
        );
      } else if (device is SmartLight) {
        updatedDevice = SmartLight(
          id: device.id,
          name: device.name,
          isActive: device.isActive,
          currentUsage: _calculateNewUsage(device, updatedSettings),
          room: device.room,
        );
        (updatedDevice as SmartLight).settings!.addAll(updatedSettings);
      } else {
        // Generic device
        updatedDevice = Device(
          id: device.id,
          name: device.name,
          type: device.type,
          isActive: device.isActive,
          currentUsage: _calculateNewUsage(device, updatedSettings),
          iconPath: device.iconPath,
          maxUsage: device.maxUsage,
          room: device.room,
          settings: updatedSettings,
          usageHistory: device.usageHistory,
        );
      }

      _devices[deviceIndex] = updatedDevice;
      _isUpdatingDevice = false;
      notifyListeners();

      // Using Random() class properly
      final randomGenerator = Random();
      // Simulate success with 95% probability
      final success = randomGenerator.nextDouble() > 0.05;
      return success;
    }

    _isUpdatingDevice = false;
    notifyListeners();
    return false;
  }

  // Calculate new power usage based on settings changes
  double _calculateNewUsage(Device device, Map<String, dynamic> newSettings) {
    if (!device.isActive) return 0.0;

    final random = Random();
    double baseUsage = device.currentUsage;

    if (device is SmartAC) {
      // Temperature affects power usage
      final int? newTemp = newSettings['temperature'] as int?;
      final String? newFanSpeed = newSettings['fanSpeed'] as String?;

      if (newTemp != null) {
        // Higher temps in cooling mode use less power
        final oldTemp = device.settings!['temperature'] as int;
        final tempDiff = (oldTemp - newTemp).abs();
        baseUsage += (newTemp < oldTemp) ? (tempDiff * 50) : -(tempDiff * 30);
      }

      if (newFanSpeed != null) {
        switch (newFanSpeed) {
          case 'Low':
            baseUsage = baseUsage * 0.8;
            break;
          case 'Medium':
            // No change for medium
            break;
          case 'High':
            baseUsage = baseUsage * 1.2;
            break;
          case 'Auto':
            baseUsage = baseUsage * 0.9;
            break;
        }
      }
    } else if (device is SmartWashingMachine) {
      final String? newCycle = newSettings['cycle'] as String?;
      final String? newTemp = newSettings['temperature'] as String?;

      if (newCycle != null) {
        switch (newCycle) {
          case 'Quick':
            baseUsage = device.maxUsage * 0.7;
            break;
          case 'Normal':
            baseUsage = device.maxUsage * 0.8;
            break;
          case 'Heavy':
            baseUsage = device.maxUsage * 0.95;
            break;
          case 'Delicate':
            baseUsage = device.maxUsage * 0.6;
            break;
        }
      }

      if (newTemp != null) {
        switch (newTemp) {
          case 'Cold':
            baseUsage = baseUsage * 0.7;
            break;
          case 'Warm':
            baseUsage = baseUsage * 0.9;
            break;
          case 'Hot':
            baseUsage = baseUsage * 1.1;
            break;
        }
      }
    } else if (device is SmartLight) {
      final int? newBrightness = newSettings['brightness'] as int?;

      if (newBrightness != null) {
        // Brightness directly affects power usage
        final oldBrightness = device.settings!['brightness'] as int;
        baseUsage = (device.maxUsage * newBrightness / 100);
      }
    }

    // Add some small random fluctuation
    baseUsage += (random.nextDouble() * 10) - 5;

    // Ensure we stay within device limits
    return baseUsage.clamp(0, device.maxUsage);
  }

  // Get available rooms
  List<String> getRooms() {
    final Set<String> uniqueRooms = _rooms.toSet();

    // Also add any rooms from existing devices
    for (final device in _devices) {
      if (device.room.isNotEmpty) {
        uniqueRooms.add(device.room);
      }
    }

    return uniqueRooms.toList()..sort();
  }

  // Update methods for different settings components
  void updateUserPreferences(UserPreferences preferences) {
    _appSettings = _appSettings.copyWith(userPreferences: preferences);
    notifyListeners();
  }

  void updateHomeConfiguration(HomeConfiguration configuration) {
    _appSettings = _appSettings.copyWith(homeConfiguration: configuration);
    notifyListeners();
  }

  void updateDeviceManagement(DeviceManagement management) {
    _appSettings = _appSettings.copyWith(deviceManagement: management);
    notifyListeners();
  }

  void updateAdvancedSettings(AdvancedSettings settings) {
    _appSettings = _appSettings.copyWith(advancedSettings: settings);
    notifyListeners();
  }

  void updateAboutSettings(AboutSettings settings) {
    _appSettings = _appSettings.copyWith(aboutSettings: settings);
    notifyListeners();
  }

  // Helper methods related to settings

  // Apply temperature unit to a value
  double applyTemperatureUnit(double celsius) {
    if (_appSettings.userPreferences.temperatureUnit == 'Fahrenheit') {
      return (celsius * 9 / 5) + 32;
    }
    return celsius;
  }

  // Format temperature with correct unit
  String formatTemperature(double celsius) {
    double value = applyTemperatureUnit(celsius);
    String unit =
        _appSettings.userPreferences.temperatureUnit == 'Fahrenheit'
            ? '°F'
            : '°C';
    return '${value.toStringAsFixed(1)}$unit';
  }

  // Calculate energy cost based on kWh and current price settings
  double calculateEnergyCost(double kWh) {
    return kWh * _appSettings.userPreferences.energyPricePerKwh;
  }

  // Format currency based on current settings
  String formatCurrency(double amount) {
    String symbol;
    switch (_appSettings.userPreferences.currency) {
      case 'USD':
        symbol = '\$';
        break;
      case 'EUR':
        symbol = '€';
        break;
      case 'GBP':
        symbol = '£';
        break;
      case 'JPY':
        symbol = '¥';
        break;
      case 'CAD':
        symbol = 'CA\$';
        break;
      case 'AUD':
        symbol = 'A\$';
        break;
      case 'CNY':
        symbol = '¥';
        break;
      case 'INR':
        symbol = '₹';
        break;
      case 'AED':
        symbol = 'AED';
        break;
      case 'SAR':
        symbol = 'SAR';
        break;
      default:
        symbol = '\$';
    }

    return '$symbol${amount.toStringAsFixed(2)}';
  }

  @override
  void dispose() {
    _usageUpdateTimer?.cancel();
    super.dispose();
  }
}
