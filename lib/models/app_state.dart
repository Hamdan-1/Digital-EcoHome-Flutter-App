import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'data_status.dart'; // Import the new DataStatus enum
// Add import for the AppSettings models
import 'settings/app_settings.dart';
import 'settings/user_preferences.dart';
import 'settings/home_configuration.dart';
import 'settings/device_management.dart';
import 'settings/advanced_settings.dart';
// Import IoT simulation components
import 'simulation/iot_simulation_controller.dart';
import 'simulation/simulation_config.dart';
import 'gamification.dart'; // Import the new gamification models

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
    required super.id,
    required super.name,
    required super.isActive,
    required super.currentUsage,
    required super.room,
  }) : super(
         type: 'HVAC',
         iconPath: 'ac_unit',
         maxUsage: 1800.0,
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
    required super.id,
    required super.name,
    required super.isActive,
    required super.currentUsage,
    required super.room,
  }) : super(
         type: 'Appliance',
         iconPath: 'local_laundry_service',
         maxUsage: 700.0,
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
    required super.id,
    required super.name,
    required super.isActive,
    required super.currentUsage,
    required super.room,
  }) : super(
         type: 'Light',
         iconPath: 'lightbulb',
         maxUsage: 60.0,
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
 // --- Demo Mode State Removed ---

 // --- Navigation State ---
 int _currentNavigationIndex = 0; // Default to Dashboard (index 0)

  // --- Regular State ---
  // IoT Simulation Controller
  late IoTSimulationController _iotSimulation;

  // Simulated current power usage
  double _currentPowerUsage = 0.0; // Will be calculated from active devices
  final Random _random = Random();
  Timer? _usageUpdateTimer;

  // 24-hour usage data (hourly readings)
  List<double> _hourlyUsageData = [];

  // Energy cost settings
  final double _energyRate = 0.15; // $0.15 per kWh

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
  final List<Device> _devices = [
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
  // Replace _isScanning with status enum
  DataStatus _discoveryStatus = DataStatus.initial;
  String? _discoveryError;

  // Device list status
  DataStatus _devicesStatus = DataStatus.initial;
  String? _devicesError;

  // Removed _isUpdatingDevice flag - will handle locally in UI

  // App settings
  AppSettings _appSettings = AppSettings();

  // Gamification State
  GamificationState _gamificationState = GamificationState();
  final List<Achievement> _allAchievements =
      _initializeAchievements(); // Define all possible achievements

  AppState() {
    // Initialize the IoT simulation controller with custom configuration
    _iotSimulation = IoTSimulationController(
      config: SimulationConfig(
        enableRealisticLatency: true,
        enableDeviceFailures: true,
        deviceFailureProbability: 0.05, // 5% chance of failure
        enablePeakHourPatterns: true,
        enableWeatherEffects: true,
        deviceStateUpdateIntervalSeconds: 3,
        energyDataUpdateIntervalSeconds: 10,
        notificationCheckIntervalMinutes: 15,
      ),
    );

    // Initialize the controller and set initial device loading status
    _devicesStatus = DataStatus.loading;
    _initializeSimulation();

    // Calculate initial power usage based on active devices
    _recalculateTotalPowerUsage();

    // Initialize 24-hour data with simulated values
    _generateHourlyData();

    // Start timer to update current power usage randomly
    _startUsageSimulation();

    // Rotate energy tips every minute
    _startTipRotation();

    // Initialize Gamification (load saved state or set defaults)
    _loadGamificationState(); // Placeholder for loading saved state
    _generateInitialChallenges(); // Generate some starting challenges
    _startGamificationUpdateTimer(); // Start timer for streaks/challenges
  }

  // Initialize the IoT simulation
  Future<void> _initializeSimulation() async {
    // Initialize the simulation controller
    await _iotSimulation.initialize();

    // Start the simulation with our current devices
    _iotSimulation.startSimulation(
      _devices,
      _handleDevicesUpdated,
      _handleAlertGenerated,
    );
  }

  // Callback when devices are updated by the simulation
  void _handleDevicesUpdated(List<Device> updatedDevices) {
    try {
      // Update device states from the simulation
      // Use a map for efficient lookup if list gets very large
      final deviceMap = {for (var d in _devices) d.id: d};
      for (final updatedDevice in updatedDevices) {
        if (deviceMap.containsKey(updatedDevice.id)) {
           // Find index and update (or replace if immutable)
           final index = _devices.indexWhere((d) => d.id == updatedDevice.id);
           if (index != -1) {
              _devices[index] = updatedDevice;
           }
        } else {
          // Handle case where simulation reports a device not in our list? Log warning?
          debugPrint("AppState: Received update for unknown device ID: ${updatedDevice.id}");
        }
      }

      // Update energy usage values from simulation
      _todayUsage = _iotSimulation.getTodayUsage();
      _weeklyUsage = _iotSimulation.getWeeklyUsage();
      _monthlyUsage = _iotSimulation.getMonthlyUsage();
      _hourlyUsageData = _iotSimulation.getHourlyUsageData();
      _yesterdayUsage = _iotSimulation.getYesterdayUsage();
      _todayEstimatedUsage = _todayUsage; // Use actual usage as estimate

      // Recalculate total power usage
      _recalculateTotalPowerUsage();

      // Update device list status
      _devicesStatus = _devices.isEmpty ? DataStatus.empty : DataStatus.success;
      _devicesError = null; // Clear any previous error

    } catch (e, stackTrace) {
       debugPrint("AppState: Error handling device updates: $e\n$stackTrace");
       _devicesStatus = DataStatus.error;
       _devicesError = "Failed to process device updates.";
       // Optionally generate a user-facing alert as well
       _handleAlertGenerated(EnergyAlert(message: _devicesError!, time: DateTime.now()));
    } finally {
       notifyListeners();
    }
  }

  // Callback when a new alert is generated
  void _handleAlertGenerated(EnergyAlert alert) {
    _energyAlerts.insert(0, alert);
    // Keep only the most recent 20 alerts
    if (_energyAlerts.length > 20) {
      _energyAlerts.removeLast();
    }
    notifyListeners();
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
 List<Device> get devices => _devices; // Removed demo mode check
  List<Device> get discoveredDevices => _discoveredDevices;
  DataStatus get discoveryStatus => _discoveryStatus; // Use status instead of bool
  String? get discoveryError => _discoveryError;
  DataStatus get devicesStatus => _devicesStatus;
  String? get devicesError => _devicesError;
  List<String> get rooms => _rooms;
  // Removed isUpdatingDevice getter
  double get todayUsage => _todayUsage;
  double get weeklyUsage => _weeklyUsage;
 double get monthlyUsage => _monthlyUsage;
 double get currentPowerUsage => _currentPowerUsage; // Removed demo mode check
 List<double> get hourlyUsageData => _hourlyUsageData; // Removed demo mode check
 // Comment related to removed demo mode
  double get energyRate => _energyRate;
  double get yesterdayUsage => _yesterdayUsage;
  double get todayEstimatedUsage => _todayEstimatedUsage;
  EnergyTip get currentTip => _energyTips[_currentTipIndex];
  List<EnergyAlert> get energyAlerts => _energyAlerts;
  AppSettings get appSettings => _appSettings;
  GamificationState get gamificationState => _gamificationState;
 List<Achievement> get allAchievements => _allAchievements;
 int get currentNavigationIndex => _currentNavigationIndex;

  bool isUsageLowerThanYesterday() {
    return _todayEstimatedUsage < _yesterdayUsage;
  }

  double usageDifferencePercent() {
    final difference = (_todayEstimatedUsage - _yesterdayUsage).abs();
    return (difference / _yesterdayUsage) * 100;
  }

  // Placeholder for potential future logic
  // Toggle device status
  Future<void> toggleDevice(String id) async {
    final index = _devices.indexWhere((device) => device.id == id);
    if (index != -1) {
      final device = _devices[index];
      bool wasActive = device.isActive;

      // Use simulation controller to toggle the device with realistic latency and failures
      bool success = await _iotSimulation.toggleDevice(device, (updatedDevice) {
        // Update the device in our list
        _devices[index] = updatedDevice;

        // Recalculate total power usage
        _recalculateTotalPowerUsage();

        notifyListeners();

        // Gamification: Award points for turning OFF a high-usage device
        if (wasActive &&
            !updatedDevice.isActive &&
            updatedDevice.maxUsage > 500) {
          _addPoints(5, "Turned off ${updatedDevice.name}");
        }
        // Gamification: Penalty for turning ON during peak hours? (Optional)
        // final hour = DateTime.now().hour;
        // if (!wasActive && updatedDevice.isActive && hour >= 16 && hour <= 21) {
        //   _addPoints(-2, "Turned on ${updatedDevice.name} during peak");
        // }
      });

      // If the toggle failed (simulated network error), notify the user
      if (!success) {
        _handleAlertGenerated(
          EnergyAlert(
            message: 'Failed to connect to ${device.name}. Please try again.',
            time: DateTime.now(),
          ),
        );
      }
    }
  }

  // Add new device
  void addDevice(Device device) {
    _devices.add(device);
    notifyListeners();
  }

  // Remove device
  Future<void> removeDevice(String id) async {
    final deviceIndex = _devices.indexWhere((d) => d.id == id);
    if (deviceIndex != -1) {
      // final device = _devices[deviceIndex]; // Unused variable removed

      // Simulate network latency for removing a device
      if (_iotSimulation.config.enableRealisticLatency) {
        final latency = _iotSimulation.config.getRandomLatency();
        await Future.delayed(Duration(milliseconds: latency));
      }

      // Remove device
      _devices.removeAt(deviceIndex);

      notifyListeners();
    }
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

  // Simulate device discovery using advanced simulation
  Future<void> scanForDevices() async {
    // Prevent concurrent scans
    if (_discoveryStatus == DataStatus.loading) return;

    _discoveryStatus = DataStatus.loading;
    _discoveredDevices = []; // Clear previous results
    _discoveryError = null; // Clear previous error
    notifyListeners();

    try {
      // Use the device discovery simulator
      final discovered = await _iotSimulation.discoverDevices(
        _rooms.toList(), // Pass available rooms
      );

      _discoveredDevices = discovered;
      // Set status based on results
      _discoveryStatus = _discoveredDevices.isEmpty ? DataStatus.empty : DataStatus.success;

    } catch (e, stackTrace) {
      debugPrint("AppState: Device scan failed: $e\n$stackTrace");
      _discoveryStatus = DataStatus.error;
      // Provide a more user-friendly error message
      _discoveryError = 'Device scan failed. Please check network connection and try again.';
      _discoveredDevices = []; // Ensure list is empty on error

      // Also generate an alert for the user
      _handleAlertGenerated(
        EnergyAlert(
          message: _discoveryError!,
          time: DateTime.now(),
        ),
      );
    } finally {
      // Ensure status is not loading anymore, even if an unexpected error occurred
      if (_discoveryStatus == DataStatus.loading) {
         _discoveryStatus = DataStatus.error; // Assume error if still loading here
         _discoveryError = 'An unexpected error occurred during device scan.';
      }
      notifyListeners();
    }
  }

  // Add a discovered device to user's devices with realistic connection simulation
  Future<void> addDiscoveredDevice(String id) async {
    final deviceIndex = _discoveredDevices.indexWhere((d) => d.id == id);
    if (deviceIndex != -1) {
      final device = _discoveredDevices[deviceIndex];

      // Simulate connection to the device (may succeed or fail)
      bool connectionSuccess = await _iotSimulation.connectToDevice(device);

      if (connectionSuccess) {
        // Add device to user's devices
        _devices.add(device);
        _discoveredDevices.removeAt(deviceIndex);

        // Add a success notification
        _handleAlertGenerated(
          EnergyAlert(
            message: 'Successfully connected to ${device.name}',
            time: DateTime.now(),
          ),
        );
      } else {
        // Add a failure notification
        _handleAlertGenerated(
          EnergyAlert(
            message: 'Failed to connect to ${device.name}. Please try again.',
            time: DateTime.now(),
          ),
        );
      }

      notifyListeners();
    }
  }

  // Simulate device setting update with advanced simulation controller
  Future<bool> updateDeviceSettings(
    String id,
    Map<String, dynamic> newSettings,
  ) async {
    // Note: Loading state for this action should ideally be handled locally in the UI
    // that triggers the update (e.g., show a spinner on the specific control).
    // This method now focuses on performing the update and returning success/failure.

    final deviceIndex = _devices.indexWhere((d) => d.id == id);
    if (deviceIndex != -1) {
      final device = _devices[deviceIndex];

      try {
        // Use the IoT simulation controller
        bool success = await _iotSimulation.updateDeviceSettings(
          device,
          newSettings,
          (updatedDevice) {
            // Success callback: Update the device in our list
            _devices[deviceIndex] = updatedDevice;
            _recalculateTotalPowerUsage(); // Recalculate usage if settings affect it
            notifyListeners(); // Notify UI about the data change
          },
        );

        if (!success) {
           // Handle simulation-reported failure (e.g., network error)
           _handleAlertGenerated(EnergyAlert(message: "Failed to update settings for ${device.name}.", time: DateTime.now()));
        }
        return success;

      } catch (e, stackTrace) {
        debugPrint("AppState: Error updating device settings: $e\n$stackTrace");
        _handleAlertGenerated(EnergyAlert(message: "Error updating settings for ${device.name}.", time: DateTime.now()));
        return false; // Indicate failure
      }
    }
    return false; // Device not found
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

  // Sustainability metrics calculation methods
  double calculateAverageDailyUsage() {
    // Calculate average over the past week (or use simulated data)
    return _todayUsage;
  }

  int getActiveDevicesCount() {
    return _devices.where((device) => device.isActive).length;
  }

  bool hasSolarPanels() {
    // Check if solar panels are configured in the home configuration
    return _appSettings.homeConfiguration.hasSolarPanels;
  }

  bool hasSmartThermostat() {
    // Check if smart thermostat exists in devices
    return _devices.any(
      (device) =>
          device.type == 'HVAC' &&
          device.settings != null &&
          device.settings!.containsKey('temperature'),
    );
  }

  bool usesLedLighting() {
    // Check if LED lighting is configured
    return _appSettings.homeConfiguration.usesLedLighting;
  }

  double calculatePeakHourUsagePercent() {
    // Calculate percentage of energy used during peak hours (typically 4pm-9pm)
    // This is a simplified calculation for demo purposes
    if (_hourlyUsageData.isEmpty) return 50.0;

    double totalUsage = _hourlyUsageData.reduce((a, b) => a + b);
    if (totalUsage <= 0) return 50.0;

    // Get current hour and calculate appropriate peak hours
    final now = DateTime.now();
    final currentHour = now.hour;

    // Calculate peak hour indices in the hourly data (last 24 hours)
    List<int> peakHourIndices = [];
    for (int i = 0; i < _hourlyUsageData.length; i++) {
      // Map index to hour of day
      int hour = (currentHour - 23 + i) % 24;
      // Consider 4pm-9pm (16-21) as peak hours
      if (hour >= 16 && hour <= 21) {
        peakHourIndices.add(i);
      }
    }

    // Calculate usage during peak hours
    double peakUsage = 0;
    for (int i in peakHourIndices) {
      if (i < _hourlyUsageData.length) {
        peakUsage += _hourlyUsageData[i];
      }
    }

    // Calculate percentage
    return (peakUsage / totalUsage) * 100;
  }

  List<double> getRecentDailyUsage() {
    // Return the last 7 days of daily usage (simulated data)
    return [
      _yesterdayUsage * 0.95,
      _yesterdayUsage * 1.05,
      _yesterdayUsage * 0.9,
      _yesterdayUsage * 1.1,
      _yesterdayUsage * 1.0,
      _yesterdayUsage * 0.98,
      _todayUsage,
    ];
  }

  @override
  void dispose() {
    // Stop the timers
    _usageUpdateTimer?.cancel();

    // Stop the IoT simulation
    _iotSimulation.stopSimulation();

    super.dispose();
  }

  // --- Gamification Logic ---

  void _loadGamificationState() {
    // Placeholder: Load saved gamification state from persistent storage (e.g., SharedPreferences)
    // For now, use default state.
    _gamificationState = GamificationState(
      // Example initial state
      points: 120,
      streakDays: 3,
      lastStreakUpdate: DateTime.now().subtract(Duration(days: 1)),
      earnedAchievements:
          _allAchievements
              .where((a) => a.id == 'first_login')
              .map((a) => a.copyWith(earned: true))
              .toList(),
    );
  }

  void _saveGamificationState() {
    // Placeholder: Save current gamification state to persistent storage
  }

  static List<Achievement> _initializeAchievements() {
    return const [
      Achievement(
        id: 'first_login',
        name: 'Welcome Aboard!',
        description: 'Logged in for the first time.',
        icon: Icons.door_front_door,
        pointsReward: 50,
      ),
      Achievement(
        id: 'first_score',
        name: 'Score Explorer',
        description: 'Checked your sustainability score.',
        icon: Icons.insights,
        pointsReward: 20,
      ),
      Achievement(
        id: 'streak_3',
        name: 'Getting Started',
        description: 'Maintained a 3-day saving streak.',
        icon: Icons.local_fire_department,
        pointsReward: 100,
      ),
      Achievement(
        id: 'streak_7',
        name: 'Consistent Saver',
        description: 'Maintained a 7-day saving streak.',
        icon: Icons.whatshot,
        pointsReward: 250,
      ),
      Achievement(
        id: 'challenge_1',
        name: 'Challenge Accepted',
        description: 'Completed your first challenge.',
        icon: Icons.flag,
        pointsReward: 75,
      ),
      Achievement(
        id: 'challenge_5',
        name: 'Challenge Master',
        description: 'Completed 5 challenges.',
        icon: Icons.emoji_events,
        pointsReward: 300,
      ),
      Achievement(
        id: 'solar_user',
        name: 'Solar Powered',
        description: 'Using solar panels.',
        icon: Icons.wb_sunny,
        pointsReward: 500,
      ),
      Achievement(
        id: 'led_user',
        name: 'LED Illuminator',
        description: 'Using LED lighting.',
        icon: Icons.lightbulb,
        pointsReward: 150,
      ),
      Achievement(
        id: 'thermostat_user',
        name: 'Climate Controller',
        description: 'Using a smart thermostat.',
        icon: Icons.thermostat,
        pointsReward: 200,
      ),
      Achievement(
        id: 'off_peak_hero',
        name: 'Off-Peak Hero',
        description: 'Significantly reduced peak hour usage.',
        icon: Icons.access_time_filled,
        pointsReward: 250,
      ),
    ];
  }

  void _generateInitialChallenges() {
    // Generate some simple starting challenges if none are active
    if (_gamificationState.activeChallenges.isEmpty) {
      List<Challenge> challenges = [
        Challenge(
          id: 'daily_usage_1',
          title: 'Reduce Daily Usage',
          description: 'Use less than 15 kWh today.',
          type: ChallengeType.daily,
          pointsReward: 50,
          icon: Icons.trending_down,
          expiryDate: DateTime.now().add(Duration(days: 1)),
          targetValue: 15.0,
          unit: 'kWh',
        ),
        Challenge(
          id: 'peak_avoid_1',
          title: 'Avoid Peak Hours',
          description: 'Keep peak hour usage below 30% today.',
          type: ChallengeType.daily,
          pointsReward: 75,
          icon: Icons.access_time,
          expiryDate: DateTime.now().add(Duration(days: 1)),
          targetValue: 30.0,
          unit: '%',
        ),
      ];
      _gamificationState = _gamificationState.copyWith(
        activeChallenges: challenges,
      );
    }
  }

  void _startGamificationUpdateTimer() {
    // Timer to check streaks and challenge status periodically (e.g., every hour)
    Timer.periodic(const Duration(hours: 1), (timer) {
      _updateStreakCounter();
      _updateChallengeProgress();
      _checkAchievements();
      _saveGamificationState(); // Save state periodically
      notifyListeners();
    });
  }

  void _updateStreakCounter() {
    // Example streak logic: Did the user improve or maintain good usage yesterday?
    final now = DateTime.now();
    final lastUpdate = _gamificationState.lastStreakUpdate;

    if (lastUpdate == null || now.difference(lastUpdate).inDays >= 1) {
      bool streakContinued =
          _yesterdayUsage <
          25.0; // Example: Streak continues if yesterday < 25 kWh

      int currentStreak = _gamificationState.streakDays;
      DateTime newLastUpdate = DateTime(
        now.year,
        now.month,
        now.day,
      ); // Mark today as updated

      if (streakContinued) {
        // If it's been exactly one day since last update, increment streak
        if (lastUpdate != null &&
            newLastUpdate.difference(lastUpdate).inDays == 1) {
          currentStreak++;
        } else {
          // Otherwise, start a new streak of 1 day
          currentStreak = 1;
        }
      } else {
        // If streak condition not met, reset streak unless it was already updated today
        if (lastUpdate == null ||
            newLastUpdate.difference(lastUpdate).inDays >= 1) {
          currentStreak = 0;
        }
      }

      _gamificationState = _gamificationState.copyWith(
        streakDays: currentStreak,
        lastStreakUpdate: newLastUpdate,
      );
    }
  }

  void _updateChallengeProgress() {
    List<Challenge> updatedChallenges = List.from(
      _gamificationState.activeChallenges,
    );
    bool challengesChanged = false;

    for (int i = 0; i < updatedChallenges.length; i++) {
      Challenge challenge = updatedChallenges[i];
      if (challenge.status == ChallengeStatus.active) {
        // Check expiry
        if (DateTime.now().isAfter(challenge.expiryDate)) {
          challenge.status = ChallengeStatus.failed;
          challengesChanged = true;
          continue;
        }

        // Update progress based on challenge type (example logic)
        double currentProgress = 0.0;
        if (challenge.id == 'daily_usage_1') {
          // Progress is inverse of usage compared to target (lower is better)
          currentProgress = 1.0 - (_todayUsage / challenge.targetValue);
        } else if (challenge.id == 'peak_avoid_1') {
          // Progress is inverse of peak usage % compared to target
          double peakPercent = calculatePeakHourUsagePercent();
          currentProgress = 1.0 - (peakPercent / challenge.targetValue);
        }
        // Clamp progress between 0 and 1
        challenge.progress = currentProgress.clamp(0.0, 1.0);

        // Check completion
        if (challenge.progress >= 1.0) {
          challenge.status = ChallengeStatus.completed;
          _addPoints(challenge.pointsReward, "Challenge: ${challenge.title}");
          challengesChanged = true;
          _checkAchievements(
            challengeCompleted: true,
          ); // Check if completing this triggers an achievement
        }
        updatedChallenges[i] = challenge; // Update the list
      }
    }

    if (challengesChanged) {
      _gamificationState = _gamificationState.copyWith(
        activeChallenges: updatedChallenges,
      );
      // Optionally, generate new challenges to replace completed/failed ones
      // _generateNewChallengesIfNeeded();
    }
  }

  void _addPoints(int pointsToAdd, String reason) {
    int newPoints = _gamificationState.points + pointsToAdd;
    int currentLevel = _gamificationState.calculateLevel();
    _gamificationState = _gamificationState.copyWith(points: newPoints);
    int newLevel = _gamificationState.calculateLevel();

    // Handle level up
    if (newLevel > currentLevel) {
      _handleAlertGenerated(
        EnergyAlert(
          message: "Level Up! You reached Level $newLevel!",
          time: DateTime.now(),
        ),
      );
      // Placeholder: Add level up rewards?
    }

    // print(
    //   "Points added: $pointsToAdd for $reason. Total: $newPoints",
    // ); // Debug log removed
  }

  void _checkAchievements({
    bool scoreChecked = false,
    bool challengeCompleted = false,
  }) {
    List<Achievement> currentlyEarned = List.from(
      _gamificationState.earnedAchievements,
    );
    bool achievementEarned = false;

    for (Achievement achievement in _allAchievements) {
      // Check if already earned
      if (currentlyEarned.any((earned) => earned.id == achievement.id)) {
        continue;
      }

      // Check conditions for earning the achievement
      bool earnedNow = false;
      switch (achievement.id) {
        case 'first_score':
          earnedNow = scoreChecked;
          break;
        case 'streak_3':
          earnedNow = _gamificationState.streakDays >= 3;
          break;
        case 'streak_7':
          earnedNow = _gamificationState.streakDays >= 7;
          break;
        case 'challenge_1':
          // Earned when the first challenge is completed
          earnedNow =
              challengeCompleted &&
              _gamificationState.activeChallenges
                      .where((c) => c.status == ChallengeStatus.completed)
                      .length ==
                  1;
          break;
        case 'challenge_5':
          earnedNow =
              _gamificationState.activeChallenges
                  .where((c) => c.status == ChallengeStatus.completed)
                  .length >=
              5;
          break;
        case 'solar_user':
          earnedNow = hasSolarPanels();
          break;
        case 'led_user':
          earnedNow = usesLedLighting();
          break;
        case 'thermostat_user':
          earnedNow = hasSmartThermostat();
          break;
        case 'off_peak_hero':
          earnedNow =
              calculatePeakHourUsagePercent() < 20.0; // Example threshold
          break;
        // Add cases for other achievements
      }

      if (earnedNow) {
        currentlyEarned.add(achievement.copyWith(earned: true));
        _addPoints(
          achievement.pointsReward,
          "Achievement: ${achievement.name}",
        );
        _handleAlertGenerated(
          EnergyAlert(
            message: "Achievement Unlocked: ${achievement.name}!",
            time: DateTime.now(),
          ),
        );
        achievementEarned = true;
      }
    }

    if (achievementEarned) {
      _gamificationState = _gamificationState.copyWith(
        earnedAchievements: currentlyEarned,
      );
    }
  }

  // Call this when the score page is viewed
  void userViewedScorePage() {
    _checkAchievements(scoreChecked: true);
  }

 // --- End Gamification Logic ---

 // --- Demo Mode Methods Removed ---

 // --- Navigation Control ---

 /// Navigates the main bottom navigation bar to the specified page index.
 void navigateToPageIndex(int index, int pageCount) {
   // Check if the index is valid and different from the current one.
   if (index >= 0 && index < pageCount && index != _currentNavigationIndex) {
     _currentNavigationIndex = index;
     notifyListeners();
   }
 }

}
