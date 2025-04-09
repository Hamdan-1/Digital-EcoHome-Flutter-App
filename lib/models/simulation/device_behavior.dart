// Models for device behavior simulation
import 'dart:math';
import '../app_state.dart';
import 'simulation_config.dart';

/// Base class for device behavior simulation
abstract class DeviceBehaviorSimulator {
  final SimulationConfig config;
  final Random random;
  
  DeviceBehaviorSimulator(this.config) : random = config.random;
  
  /// Update the device state based on its type and current settings
  Future<Device> updateDeviceState(Device device);
  
  /// Calculate realistic energy usage for the device
  double calculateEnergyUsage(Device device);
  
  /// Simulate a device control action with potential latency and failures
  Future<bool> simulateDeviceControl({
    required bool Function() action,
    String? actionType,
  }) async {
    // Simulate network latency
    final latency = config.getRandomLatency();
    if (latency > 0) {
      await Future.delayed(Duration(milliseconds: latency));
    }
    
    // Check for potential failure
    if (config.willDeviceActionFail()) {
      return false;
    }
    
    // Execute the actual action
    return action();
  }
}

/// Simulator for HVAC devices (AC, heaters)
class HVACBehaviorSimulator extends DeviceBehaviorSimulator {
  HVACBehaviorSimulator(super.config);
  
  @override
  Future<Device> updateDeviceState(Device device) async {
    if (!device.isActive) return device;
    if (device.type != 'HVAC') return device;
    
    // Get the device settings
    final settings = device.settings ?? {};
    final targetTemp = settings['temperature'] as int? ?? 24;
    // final mode = settings['mode'] as String? ?? 'Cool'; // Unused variable
    final fanSpeed = settings['fanSpeed'] as String? ?? 'Medium';
    
    // Calculate usage based on settings and time of day
    double newUsage = device.currentUsage;
    
    // Apply time-of-day effects
    final timeMultiplier = config.getDeviceTypeMultiplier('HVAC');
    
    // Temperature affects usage - further from ambient, more energy used
    final ambientTemp = _getSimulatedAmbientTemperature();
    final tempDifference = (ambientTemp - targetTemp).abs();
    
    // Base usage calculation
    double baseUsage = device.maxUsage * 0.6; // 60% of max as baseline
    
    // Adjust for temperature differential
    baseUsage += (tempDifference * 30); // Each degree difference adds power
    
    // Adjust for fan speed
    switch (fanSpeed) {
      case 'Low':
        baseUsage *= 0.8;
        break;
      case 'Medium':
        // No adjustment for medium
        break;
      case 'High':
        baseUsage *= 1.2;
        break;
      case 'Auto':
        // Auto mode is more efficient
        baseUsage *= 0.9;
        break;
    }
    
    // Apply time-of-day multiplier
    baseUsage *= timeMultiplier;
    
    // Add random fluctuation
    final fluctuation = (random.nextDouble() * 100) - 50; // -50W to +50W
    newUsage = baseUsage + fluctuation;
    
    // Clamp usage to realistic limits
    newUsage = newUsage.clamp(device.maxUsage * 0.1, device.maxUsage);
    
    // Cycle simulation - HVAC cycles on and off
    // For realistic cycling behavior based on target temp
    final shouldCycle = random.nextDouble() > 0.95; // 5% chance to cycle
    if (shouldCycle) {
      // If usage is high, cycle down; if low, cycle up
      if (newUsage > device.maxUsage * 0.7) {
        newUsage = device.maxUsage * 0.2; // Cycle down
      } else if (newUsage < device.maxUsage * 0.3) {
        newUsage = device.maxUsage * 0.8; // Cycle up
      }
    }
    
    // Create updated device
    if (device is SmartAC) {
      return SmartAC(
        id: device.id,
        name: device.name,
        isActive: device.isActive,
        currentUsage: newUsage,
        room: device.room,
      );
    }
    
    // Generic device update
    return Device(
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
  
  @override
  double calculateEnergyUsage(Device device) {
    if (!device.isActive) return 0;
    
    // Convert the current usage from watts to kWh for a typical time period
    // (e.g., for one hour)
    return device.currentUsage / 1000; // W to kW
  }
  
  // Simulate ambient temperature based on time of day
  double _getSimulatedAmbientTemperature() {
    final now = DateTime.now();
    final hour = now.hour;
    
    // Base temperature with diurnal cycle (coolest at 4-5 AM, warmest at 2-3 PM)
    double baseTemp;
    if (hour >= 0 && hour < 6) {
      // Early morning (coldest)
      baseTemp = 18.0 + random.nextDouble() * 2.0;
    } else if (hour >= 6 && hour < 12) {
      // Morning (warming up)
      baseTemp = 20.0 + random.nextDouble() * 3.0;
    } else if (hour >= 12 && hour < 18) {
      // Afternoon (warmest)
      baseTemp = 24.0 + random.nextDouble() * 4.0;
    } else {
      // Evening (cooling down)
      baseTemp = 22.0 + random.nextDouble() * 2.0;
    }
    
    return baseTemp;
  }
  
  // Helper method to update usage history
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
}

/// Simulator for Lighting devices
class LightingBehaviorSimulator extends DeviceBehaviorSimulator {
  LightingBehaviorSimulator(super.config);
  
  @override
  Future<Device> updateDeviceState(Device device) async {
    if (!device.isActive) return device;
    if (device.type != 'Light') return device;
    
    // Get the device settings
    final settings = device.settings ?? {};
    final brightness = settings['brightness'] as int? ?? 80;
    final isRGB = settings['isRGB'] as bool? ?? false;
    
    // Calculate usage based on settings and time of day
    double newUsage = device.currentUsage;
    
    // Apply time-of-day effects
    final timeMultiplier = config.getDeviceTypeMultiplier('Light');
    
    // Base usage calculation - directly proportional to brightness
    // High-efficiency LED lights use less power
    double baseUsage = (device.maxUsage * brightness / 100);
    
    // RGB lights use slightly more power
    if (isRGB) {
      baseUsage *= 1.2;
    }
    
    // Apply time-of-day multiplier
    baseUsage *= timeMultiplier;
    
    // Add random fluctuation
    final fluctuation = (random.nextDouble() * 5) - 2.5; // -2.5W to +2.5W
    newUsage = baseUsage + fluctuation;
    
    // Clamp usage to realistic limits
    newUsage = newUsage.clamp(0, device.maxUsage);
    
    // Create updated device
    if (device is SmartLight) {
      return SmartLight(
        id: device.id,
        name: device.name,
        isActive: device.isActive,
        currentUsage: newUsage,
        room: device.room,
      );
    }
    
    // Generic device update
    return Device(
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
  
  @override
  double calculateEnergyUsage(Device device) {
    if (!device.isActive) return 0;
    
    // Convert the current usage from watts to kWh for a typical time period
    return device.currentUsage / 1000; // W to kW
  }
  
  // Helper method to update usage history
  List<double> _updateUsageHistory(List<double> history, double currentValue) {
    List<double> newHistory = List<double>.from(history);
    
    if (newHistory.isNotEmpty) {
      newHistory.removeAt(0);
      newHistory.add(currentValue);
    }
    
    return newHistory;
  }
}

/// Simulator for Kitchen and Appliance devices
class ApplianceBehaviorSimulator extends DeviceBehaviorSimulator {
  ApplianceBehaviorSimulator(super.config);
  
  @override
  Future<Device> updateDeviceState(Device device) async {
    if (!device.isActive) return device;
    if (device.type != 'Appliance' && device.type != 'Kitchen') return device;
    
    // final settings = device.settings ?? {}; // Unused variable
    double newUsage = device.currentUsage;
    
    // Different behavior based on device name
    if (device.name.contains('Refrigerator')) {
      newUsage = _simulateRefrigerator(device);
    } else if (device.name.contains('Washing Machine') || 
             (device is SmartWashingMachine)) {
      newUsage = _simulateWashingMachine(device);
    } else if (device.name.contains('Dishwasher')) {
      newUsage = _simulateDishwasher(device);
    } else {
      // Generic appliance behavior
      final timeMultiplier = config.getDeviceTypeMultiplier('Appliance');
      
      // Base usage with time multiplier
      double baseUsage = device.currentUsage * timeMultiplier;
      
      // Add random fluctuation
      final fluctuation = (random.nextDouble() * 20) - 10; // -10W to +10W
      newUsage = baseUsage + fluctuation;
      
      // Clamp usage to realistic limits
      newUsage = newUsage.clamp(device.maxUsage * 0.1, device.maxUsage);
    }
    
    // Create updated device
    if (device is SmartWashingMachine) {
      return SmartWashingMachine(
        id: device.id,
        name: device.name,
        isActive: device.isActive,
        currentUsage: newUsage,
        room: device.room,
      );
    }
    
    // Generic device update
    return Device(
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
  
  @override
  double calculateEnergyUsage(Device device) {
    if (!device.isActive) return 0;
    
    // Convert the current usage from watts to kWh
    return device.currentUsage / 1000; // W to kW
  }
  
  // Simulate refrigerator with compressor cycles
  double _simulateRefrigerator(Device device) {
    // Refrigerators cycle between high and low power states
    final timeMultiplier = config.getDeviceTypeMultiplier('Kitchen');
    
    // Decide if we're in a compressor cycle
    final inCompressorCycle = random.nextDouble() > 0.7; // 30% time in high power cycle
    
    double newUsage;
    if (inCompressorCycle) {
      // High power cycle (compressor running)
      newUsage = device.maxUsage * 0.7 * timeMultiplier;
      
      // Add random fluctuation
      final fluctuation = (random.nextDouble() * 20) - 10;
      newUsage += fluctuation;
    } else {
      // Low power cycle (just maintaining)
      newUsage = device.maxUsage * 0.2 * timeMultiplier;
      
      // Add random fluctuation
      final fluctuation = (random.nextDouble() * 5) - 2.5;
      newUsage += fluctuation;
    }
    
    // Clamp usage to realistic limits
    return newUsage.clamp(device.maxUsage * 0.1, device.maxUsage);
  }
  
  // Simulate washing machine with cycles
  double _simulateWashingMachine(Device device) {
    if (!device.isActive) return 0;
    
    final settings = device.settings ?? {};
    final isRunning = settings['isRunning'] as bool? ?? false;
    if (!isRunning) return 10.0; // Standby power
    
    final cycle = settings['cycle'] as String? ?? 'Normal';
    final progress = settings['progress'] as double? ?? 0.0;
    
    // Washing machines have different power usage during different stages
    // of their wash cycle
    double baseUsage;
    
    if (progress < 0.2) {
      // Fill stage - low power
      baseUsage = device.maxUsage * 0.3;
    } else if (progress < 0.4) {
      // Wash stage - medium to high power
      baseUsage = device.maxUsage * 0.7;
    } else if (progress < 0.6) {
      // Rinse stage - medium power
      baseUsage = device.maxUsage * 0.5;
    } else if (progress < 0.8) {
      // Spin stage - highest power
      baseUsage = device.maxUsage * 0.9;
    } else {
      // Final spin - high power
      baseUsage = device.maxUsage * 0.8;
    }
    
    // Adjust for cycle type
    switch (cycle) {
      case 'Quick':
        baseUsage *= 1.1; // Quick uses more power but for less time
        break;
      case 'Heavy':
        baseUsage *= 1.2; // Heavy duty uses more power
        break;
      case 'Delicate':
        baseUsage *= 0.8; // Delicate uses less power
        break;
    }
    
    // Add random fluctuation
    final fluctuation = (random.nextDouble() * 30) - 15;
    final newUsage = baseUsage + fluctuation;
    
    // Clamp usage to realistic limits
    return newUsage.clamp(device.maxUsage * 0.1, device.maxUsage);
  }
  
  // Simulate dishwasher with cycles
  double _simulateDishwasher(Device device) {
    if (!device.isActive) return 0;
    
    // Similar behavior to washing machine but with different power profile
    final settings = device.settings ?? {};
    final isRunning = settings['isRunning'] as bool? ?? false;
    if (!isRunning) return 5.0; // Standby power
    
    final cycle = settings['cycle'] as String? ?? 'Normal';
    final progress = settings['progress'] as double? ?? 0.0;
    
    double baseUsage;
    
    if (progress < 0.3) {
      // Pre-rinse - moderate power for water pump
      baseUsage = device.maxUsage * 0.5;
    } else if (progress < 0.6) {
      // Main wash - high power for heating water
      baseUsage = device.maxUsage * 0.9;
    } else if (progress < 0.8) {
      // Rinse - moderate power
      baseUsage = device.maxUsage * 0.6;
    } else {
      // Dry cycle - high power for heating element
      baseUsage = device.maxUsage * 0.8;
    }
    
    // Adjust for cycle type
    switch (cycle) {
      case 'Eco':
        baseUsage *= 0.7; // Eco uses less power
        break;
      case 'Heavy':
        baseUsage *= 1.2; // Heavy uses more power
        break;
      case 'Quick':
        baseUsage *= 0.9; // Quick is slightly more efficient
        break;
    }
    
    // Add random fluctuation
    final fluctuation = (random.nextDouble() * 25) - 12.5;
    final newUsage = baseUsage + fluctuation;
    
    // Clamp usage to realistic limits
    return newUsage.clamp(device.maxUsage * 0.1, device.maxUsage);
  }
  
  // Helper method to update usage history
  List<double> _updateUsageHistory(List<double> history, double currentValue) {
    List<double> newHistory = List<double>.from(history);
    
    if (newHistory.isNotEmpty) {
      newHistory.removeAt(0);
      newHistory.add(currentValue);
    }
    
    return newHistory;
  }
}
