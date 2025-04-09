// Device discovery and network simulation
import 'dart:async';
import 'dart:math';
import '../app_state.dart';
import 'simulation_config.dart';

/// Simulates the process of discovering IoT devices on a network
class DeviceDiscoverySimulator {
  final SimulationConfig config;
  final Random random;
  
  // Keep track of discovery sessions
  bool _isScanning = false;
  
  // Completer for async operations
  Completer<List<Device>>? _discoveryCompleter;
  
  DeviceDiscoverySimulator(this.config) : random = config.random;
  
  /// Check if a device discovery session is currently in progress
  bool get isScanning => _isScanning;
  
  /// Start scanning for new devices on the network
  /// Returns a Future that completes with the list of discovered devices
  Future<List<Device>> startDiscovery({
    required List<String> rooms,
    int? durationSeconds,
  }) async {
    if (_isScanning) {
      throw Exception('A device discovery session is already in progress');
    }
    
    _isScanning = true;
    _discoveryCompleter = Completer<List<Device>>();
    
    // Determine scan duration - simulates a real network scan
    final scanDuration = durationSeconds ?? (3 + random.nextInt(5));
    
    // Start the simulated scanning process
    _simulateNetworkScan(rooms, scanDuration);
    
    // Return the future that will complete when discovery is done
    return _discoveryCompleter!.future;
  }
  
  /// Cancel the current discovery session
  void cancelDiscovery() {
    if (_isScanning && !(_discoveryCompleter?.isCompleted ?? true)) {
      _discoveryCompleter?.complete([]);
    }
    _isScanning = false;
  }
  
  /// Simulate the network scanning process
  void _simulateNetworkScan(List<String> rooms, int durationSeconds) async {
    // Generate a list of potentially discoverable devices
    List<Device> potentialDevices = _generatePotentialDevices(rooms);
    
    // Simulate the discovery process with incremental findings
    List<Device> discovered = [];
    
    // Progress steps
    final steps = 4 + random.nextInt(3); // 4-6 steps
    final stepDuration = durationSeconds ~/ steps;
    
    // Simulate network scanning steps
    for (int i = 0; i < steps; i++) {
      // Simulate network delay
      await Future.delayed(Duration(seconds: stepDuration));
      
      // Simulate connection problems occasionally
      if (config.enableDeviceFailures && random.nextDouble() < 0.15) {
        // Simulate a temporary network issue
        await Future.delayed(const Duration(seconds: 2));
        
        // 5% chance of complete failure
        if (random.nextDouble() < 0.05) {
          if (!(_discoveryCompleter?.isCompleted ?? true)) {
            _discoveryCompleter?.completeError(
              Exception('Network scan failed. Please try again.')
            );
            _isScanning = false;
            return;
          }
        }
      }
      
      // Determine how many devices to discover in this step
      int devicesToDiscover = (potentialDevices.length / steps).ceil();
      devicesToDiscover = min(
        devicesToDiscover, 
        potentialDevices.length
      );
      
      if (devicesToDiscover > 0) {
        // Select devices to discover
        List<Device> newlyDiscovered = [];
        for (int j = 0; j < devicesToDiscover; j++) {
          if (potentialDevices.isNotEmpty) {
            final index = random.nextInt(potentialDevices.length);
            newlyDiscovered.add(potentialDevices[index]);
            potentialDevices.removeAt(index);
          }
        }
        
        // Add to discovered devices
        discovered.addAll(newlyDiscovered);
      }
    }
    
    // Complete the discovery process
    _isScanning = false;
    if (!(_discoveryCompleter?.isCompleted ?? true)) {
      _discoveryCompleter?.complete(discovered);
    }
  }
  
  /// Generate a list of potential devices that could be discovered
  List<Device> _generatePotentialDevices(List<String> rooms) {
    List<Device> devices = [];
    
    // Number of devices to generate
    final deviceCount = 5 + random.nextInt(8); // 5-12 devices
    
    for (int i = 0; i < deviceCount; i++) {
      // Randomly select device type and room
      final deviceType = _getRandomDeviceType();
      final room = rooms[random.nextInt(rooms.length)];
      
      // Generate unique ID
      final id = 'new_${DateTime.now().millisecondsSinceEpoch}_$i';
      
      // Create appropriate device based on type
      switch (deviceType) {
        case 'HVAC':
          devices.add(SmartAC(
            id: id,
            name: '$room AC',
            isActive: false,
            currentUsage: 0,
            room: room,
          ));
          break;
        case 'Light':
          devices.add(SmartLight(
            id: id,
            name: '$room Light',
            isActive: false,
            currentUsage: 0,
            room: room,
          ));
          break;
        case 'Appliance':
          // Vary the appliance types
          final applianceType = random.nextInt(3);
          if (applianceType == 0) {
            devices.add(SmartWashingMachine(
              id: id,
              name: '$room Washing Machine',
              isActive: false,
              currentUsage: 0,
              room: room,
            ));
          } else if (applianceType == 1) {
            // Generic fridge
            devices.add(Device(
              id: id,
              name: '$room Refrigerator',
              type: 'Appliance',
              isActive: false,
              currentUsage: 0,
              iconPath: 'kitchen',
              maxUsage: 200.0,
              room: room,
              settings: {
                'temperature': 3,
                'mode': 'Normal',
                'doorOpen': false,
              },
            ));
          } else {
            // Generic appliance
            devices.add(Device(
              id: id,
              name: '$room Dishwasher',
              type: 'Appliance',
              isActive: false,
              currentUsage: 0,
              iconPath: 'opacity',
              maxUsage: 1200.0,
              room: room,
              settings: {
                'cycle': 'Normal',
                'isRunning': false,
                'progress': 0.0,
              },
            ));
          }
          break;
        case 'Entertainment':
          devices.add(Device(
            id: id,
            name: '$room TV',
            type: 'Entertainment',
            isActive: false,
            currentUsage: 0,
            iconPath: 'tv',
            maxUsage: 120.0,
            room: room,
            settings: {
              'volume': 30,
              'channel': 'HDMI 1',
              'brightness': 70,
            },
          ));
          break;
        case 'Water':
          devices.add(Device(
            id: id,
            name: '$room Water Heater',
            type: 'Water',
            isActive: false,
            currentUsage: 0,
            iconPath: 'hot_tub',
            maxUsage: 1500.0,
            room: room,
            settings: {
              'temperature': 55,
              'mode': 'Eco',
            },
          ));
          break;
      }
    }
    
    return devices;
  }
  
  /// Get a random device type with weighted distribution
  String _getRandomDeviceType() {
    final types = [
      'HVAC',
      'Light',
      'Light',  // Weighted higher - more lights
      'Appliance',
      'Appliance',
      'Entertainment',
      'Water',
    ];
    
    return types[random.nextInt(types.length)];
  }
  
  /// Simulate connection attempts to a device
  /// Returns true if connection was successful, false otherwise
  Future<bool> simulateDeviceConnection(Device device) async {
    // Simulate network latency
    final latency = config.getRandomLatency();
    if (latency > 0) {
      await Future.delayed(Duration(milliseconds: latency));
    }
    
    // Check for potential failure
    if (config.enableDeviceFailures && random.nextDouble() < config.deviceFailureProbability) {
      return false;
    }
    
    return true;
  }
}
