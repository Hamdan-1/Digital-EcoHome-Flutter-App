// Main controller for the IoT simulation system
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../app_state.dart';
import 'simulation_config.dart';
import 'device_behavior.dart';
import 'energy_usage_simulator.dart';
import 'notification_system.dart';
import 'device_discovery.dart';
import 'persistent_storage.dart';

/// Main controller class that coordinates all aspects of the IoT simulation
class IoTSimulationController with ChangeNotifier {
  // Core components of the simulation
  final SimulationConfig config;
  final EnergyUsageSimulator _energySimulator;
  final NotificationSystem _notificationSystem;
  final DeviceDiscoverySimulator _discoverySimulator;
  final IoTPersistentStorage _storage;
  
  // Device behavior simulators
  final Map<String, DeviceBehaviorSimulator> _deviceSimulators = {};
  
  // Device state update timer
  Timer? _deviceUpdateTimer;
  
  // Storage update timer
  Timer? _storageUpdateTimer;
  
  // Flag to track if simulation is running
  bool _isRunning = false;
  
  // Track device connection status
  final Map<String, bool> _deviceConnectionStatus = {};
  
  // Constructor - initializes all simulation components
  IoTSimulationController({SimulationConfig? config}) 
      : config = config ?? SimulationConfig(),
        _energySimulator = EnergyUsageSimulator(config ?? SimulationConfig()),
        _notificationSystem = NotificationSystem(config ?? SimulationConfig()),
        _discoverySimulator = DeviceDiscoverySimulator(config ?? SimulationConfig()),
        _storage = IoTPersistentStorage() {
    
    // Initialize device behavior simulators
    _deviceSimulators['HVAC'] = HVACBehaviorSimulator(this.config);
    _deviceSimulators['Light'] = LightingBehaviorSimulator(this.config);
    _deviceSimulators['Appliance'] = ApplianceBehaviorSimulator(this.config);
    _deviceSimulators['Kitchen'] = ApplianceBehaviorSimulator(this.config);
    _deviceSimulators['Water'] = ApplianceBehaviorSimulator(this.config);
    _deviceSimulators['Entertainment'] = ApplianceBehaviorSimulator(this.config);
  }
  
  // Getters for public properties
  bool get isRunning => _isRunning;
  bool get isScanning => _discoverySimulator.isScanning;
  
  // Initialize the simulation system
  Future<void> initialize() async {
    // Initialize notification system
    await _notificationSystem.initialize();
    
    // Load saved data if available
    await _loadSavedState();
  }
  
  // Start the simulation
  void startSimulation(List<Device> devices, Function(List<Device>) onDevicesUpdated, 
                     Function(EnergyAlert) onAlertGenerated) {
    if (_isRunning) return;
    
    _isRunning = true;
    
    // Start energy usage simulation
    _energySimulator.startSimulation(devices, () {
      // This callback is called when energy data is updated
      notifyListeners();
    });
    
    // Start notification monitoring
    _notificationSystem.startMonitoring(
      devices: devices,
      energySimulator: _energySimulator,
      onAlertGenerated: onAlertGenerated,
    );
    
    // Start device state updates
    _startDeviceStateUpdates(devices, onDevicesUpdated);
    
    // Start periodic storage of simulation state
    _startPeriodicStateSaving(devices);
    
    notifyListeners();
  }
  
  // Stop the simulation
  void stopSimulation() {
    if (!_isRunning) return;
    
    _isRunning = false;
    
    // Stop all simulation components
    _energySimulator.stopSimulation();
    _notificationSystem.stopMonitoring();
    
    // Stop timers
    _deviceUpdateTimer?.cancel();
    _deviceUpdateTimer = null;
    
    _storageUpdateTimer?.cancel();
    _storageUpdateTimer = null;
    
    notifyListeners();
  }
  
  // Toggle a device's active status
  Future<bool> toggleDevice(Device device, Function(Device) onDeviceUpdated) async {
    // Simulate network latency
    final latency = config.getRandomLatency();
    if (latency > 0) {
      await Future.delayed(Duration(milliseconds: latency));
    }
    
    // Check for potential connection failure
    if (config.enableDeviceFailures && 
        config.random.nextDouble() < config.deviceFailureProbability) {
      return false;
    }
    
    // Create the updated device with toggled state
    Device updatedDevice;
    if (device is SmartAC) {
      updatedDevice = SmartAC(
        id: device.id,
        name: device.name,
        isActive: !device.isActive,
        currentUsage: !device.isActive ? device.maxUsage * 0.8 : 0,
        room: device.room,
      );
    } else if (device is SmartLight) {
      updatedDevice = SmartLight(
        id: device.id,
        name: device.name,
        isActive: !device.isActive,
        currentUsage: !device.isActive ? device.maxUsage * 0.8 : 0,
        room: device.room,
      );
    } else if (device is SmartWashingMachine) {
      updatedDevice = SmartWashingMachine(
        id: device.id,
        name: device.name,
        isActive: !device.isActive,
        currentUsage: !device.isActive ? device.maxUsage * 0.1 : 0, // Standby mode
        room: device.room,
      );
    } else {
      updatedDevice = Device(
        id: device.id,
        name: device.name,
        type: device.type,
        isActive: !device.isActive,
        currentUsage: !device.isActive ? device.maxUsage * 0.8 : 0,
        iconPath: device.iconPath,
        maxUsage: device.maxUsage,
        usageHistory: device.usageHistory,
        room: device.room,
        settings: device.settings,
      );
    }
    
    // Notify about the device update
    onDeviceUpdated(updatedDevice);
    
    return true;
  }
  
  // Update device settings
  Future<bool> updateDeviceSettings(
    Device device, 
    Map<String, dynamic> newSettings,
    Function(Device) onDeviceUpdated
  ) async {
    // Simulate network latency
    final latency = config.getRandomLatency();
    if (latency > 0) {
      await Future.delayed(Duration(milliseconds: latency));
    }
    
    // Check for potential connection failure
    if (config.enableDeviceFailures && 
        config.random.nextDouble() < config.deviceFailureProbability) {
      return false;
    }
    
    // Get the appropriate simulator for this device type
    final simulator = _deviceSimulators[device.type] ?? 
                     _deviceSimulators['Appliance']!;
    
    // Create updated device with new settings
    Device updatedDevice;
    if (device is SmartAC) {
      updatedDevice = SmartAC(
        id: device.id,
        name: device.name,
        isActive: device.isActive,
        currentUsage: device.currentUsage,
        room: device.room,
      );
      
      // Update settings
      final settings = Map<String, dynamic>.from(updatedDevice.settings!);
      settings.addAll(newSettings);
      updatedDevice.settings!.clear();
      updatedDevice.settings!.addAll(settings);
      
    } else if (device is SmartLight) {
      updatedDevice = SmartLight(
        id: device.id,
        name: device.name,
        isActive: device.isActive,
        currentUsage: device.currentUsage,
        room: device.room,
      );
      
      // Update settings
      final settings = Map<String, dynamic>.from(updatedDevice.settings!);
      settings.addAll(newSettings);
      updatedDevice.settings!.clear();
      updatedDevice.settings!.addAll(settings);
      
    } else if (device is SmartWashingMachine) {
      updatedDevice = SmartWashingMachine(
        id: device.id,
        name: device.name,
        isActive: device.isActive,
        currentUsage: device.currentUsage,
        room: device.room,
      );
      
      // Update settings
      final settings = Map<String, dynamic>.from(updatedDevice.settings!);
      settings.addAll(newSettings);
      updatedDevice.settings!.clear();
      updatedDevice.settings!.addAll(settings);
      
    } else {
      // Generic device
      final currentSettings = device.settings ?? {};
      final updatedSettings = Map<String, dynamic>.from(currentSettings)
        ..addAll(newSettings);
      
      updatedDevice = Device(
        id: device.id,
        name: device.name,
        type: device.type,
        isActive: device.isActive,
        currentUsage: device.currentUsage,
        iconPath: device.iconPath,
        maxUsage: device.maxUsage,
        usageHistory: device.usageHistory,
        room: device.room,
        settings: updatedSettings,
      );
    }
    
    // Update device usage based on new settings if device is active
    if (updatedDevice.isActive) {
      updatedDevice = await simulator.updateDeviceState(updatedDevice);
    }
    
    // Notify about the device update
    onDeviceUpdated(updatedDevice);
    
    return true;
  }
  
  // Start the device discovery process
  Future<List<Device>> discoverDevices(List<String> rooms) async {
    if (_discoverySimulator.isScanning) {
      throw Exception('A device discovery session is already in progress');
    }
    
    // Start the discovery process
    return _discoverySimulator.startDiscovery(rooms: rooms);
  }
  
  // Cancel the current discovery session
  void cancelDiscovery() {
    _discoverySimulator.cancelDiscovery();
  }
  
  // Simulate connecting to a discovered device
  Future<bool> connectToDevice(Device device) async {
    return _discoverySimulator.simulateDeviceConnection(device);
  }
  
  // Start timer to periodically update device states
  void _startDeviceStateUpdates(List<Device> devices, 
                               Function(List<Device>) onDevicesUpdated) {
    // Cancel any existing timer
    _deviceUpdateTimer?.cancel();
    
    // Start a new timer for device state updates
    _deviceUpdateTimer = Timer.periodic(
      Duration(seconds: config.deviceStateUpdateIntervalSeconds),
      (_) => _updateDeviceStates(devices, onDevicesUpdated),
    );
  }
  
  // Update all device states
  Future<void> _updateDeviceStates(List<Device> devices, 
                                 Function(List<Device>) onDevicesUpdated) async {
    if (!_isRunning || devices.isEmpty) return;
    
    // Create a new list for updated devices
    List<Device> updatedDevices = [];
    
    // Update each device's state based on its type
    for (final device in devices) {
      if (!device.isActive) {
        // Inactive devices don't need simulation updates
        updatedDevices.add(device);
        continue;
      }
      
      // Get the appropriate simulator for this device type
      final simulator = _deviceSimulators[device.type] ?? 
                       _deviceSimulators['Appliance']!;
      
      // Update the device state
      final updatedDevice = await simulator.updateDeviceState(device);
      updatedDevices.add(updatedDevice);
    }
    
    // Notify about updated devices
    onDevicesUpdated(updatedDevices);
  }
  
  // Start periodic state saving
  void _startPeriodicStateSaving(List<Device> devices) {
    // Cancel any existing timer
    _storageUpdateTimer?.cancel();
    
    // Start a new timer for storage updates
    _storageUpdateTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _saveSimulationState(devices),
    );
  }
  
  // Save current simulation state
  Future<void> _saveSimulationState(List<Device> devices) async {
    if (!_isRunning) return;
    
    // Save device states
    await _storage.saveDeviceStates(devices);
    
    // TODO: Add energy history saving
    // This would require additional methods to access the energy data from the simulator
  }
  
  // Load saved state
  Future<void> _loadSavedState() async {
    // For now, we'll just load the last update time
    // In a complete implementation, you would load all saved state
    
    final lastUpdate = await _storage.getLastUpdateTime();
    if (lastUpdate != null) {
      print('Last simulation state saved: ${lastUpdate.toIso8601String()}');
    }
  }
  
  // Access to energy usage data
  double getTodayUsage() => _energySimulator.getTodayUsage();
  double getYesterdayUsage() => _energySimulator.getYesterdayUsage();
  double getWeeklyUsage() => _energySimulator.getWeeklyUsage();
  double getMonthlyUsage() => _energySimulator.getMonthlyUsage();
  List<double> getHourlyUsageData() => _energySimulator.getHourlyUsageData();
  
  // Get energy breakdown by device type
  Map<String, double> getDeviceTypeBreakdown() {
    return _energySimulator.getCurrentDeviceBreakdown();
  }
  
  // Clean up resources when done
  @override
  void dispose() {
    stopSimulation();
    super.dispose();
  }
}
