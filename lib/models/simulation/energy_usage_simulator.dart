// Energy usage simulation for the application
import 'dart:math';
import 'dart:async';
import '../app_state.dart';
import 'simulation_config.dart';
import 'device_behavior.dart';

class EnergyUsageSimulator {
  final SimulationConfig config;
  final Random random;
  
  // Historical usage data
  Map<DateTime, double> _dailyUsageData = {};
  Map<DateTime, Map<String, double>> _deviceDailyUsage = {};
  
  // Current day usage 
  double _currentDayUsage = 0.0;
  Map<String, double> _currentDeviceDayUsage = {};
  
  // Hourly usage tracking
  List<double> _hourlyUsage = List.filled(24, 0.0);
  
  // Timer for updating energy data
  Timer? _energyUpdateTimer;
  
  EnergyUsageSimulator(this.config) : random = config.random {
    // Pre-populate with some historical data
    _generateHistoricalData();
  }
  
  // Start the energy usage simulation
  void startSimulation(List<Device> devices, Function() onUpdate) {
    // Cancel any existing timer
    _energyUpdateTimer?.cancel();
    
    // Start a new timer that periodically updates energy usage
    _energyUpdateTimer = Timer.periodic(
      Duration(seconds: config.energyDataUpdateIntervalSeconds), 
      (_) {
        _updateEnergyUsage(devices);
        onUpdate();
      }
    );
  }
  
  // Stop the simulation
  void stopSimulation() {
    _energyUpdateTimer?.cancel();
    _energyUpdateTimer = null;
  }
  
  // Generate simulated historical energy usage data
  void _generateHistoricalData() {
    final now = DateTime.now();
    
    // Generate daily data for past 90 days
    for (int i = 1; i <= 90; i++) {
      final date = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      
      // Base usage with weekend pattern (higher on weekends)
      double baseUsage = 12.0 + random.nextDouble() * 4.0;
      
      // Weekend adjustment
      if (date.weekday == DateTime.saturday || date.weekday == DateTime.sunday) {
        baseUsage *= 1.2;
      }
      
      // Seasonal pattern (higher in summer and winter for AC/heating)
      // This is a simplified model - could be expanded based on location
      final month = date.month;
      if (month == 12 || month == 1 || month == 2) {
        // Winter months
        baseUsage *= 1.3;
      } else if (month == 6 || month == 7 || month == 8) {
        // Summer months
        baseUsage *= 1.4;
      }
      
      // Random variation
      final variation = 0.9 + random.nextDouble() * 0.2; // 0.9 to 1.1
      _dailyUsageData[date] = baseUsage * variation;
      
      // Device breakdown for this day
      Map<String, double> deviceUsage = {
        'HVAC': baseUsage * 0.45 * variation,        // 45% from HVAC
        'Appliance': baseUsage * 0.25 * variation,   // 25% from appliances
        'Light': baseUsage * 0.15 * variation,       // 15% from lighting
        'Water': baseUsage * 0.10 * variation,       // 10% from water heating
        'Other': baseUsage * 0.05 * variation,       // 5% from miscellaneous
      };
      
      _deviceDailyUsage[date] = deviceUsage;
    }
  }
  
  // Update energy usage based on current device states
  void _updateEnergyUsage(List<Device> devices) {
    if (devices.isEmpty) return;
    
    final now = DateTime.now();
    final hour = now.hour;
    
    // Calculate power usage at this moment
    double currentPowerUsage = 0.0;
    Map<String, double> deviceTypePower = {};
    
    // Sum up power usage from all active devices
    for (final device in devices) {
      if (device.isActive) {
        final devicePower = device.currentUsage / 1000.0; // Convert W to kW
        currentPowerUsage += devicePower;
        
        // Track by device type
        deviceTypePower[device.type] = (deviceTypePower[device.type] ?? 0.0) + devicePower;
      }
    }
    
    // Add small base load for always-on devices (0.1 to 0.2 kW)
    final baseLoad = 0.1 + (random.nextDouble() * 0.1);
    currentPowerUsage += baseLoad;
    deviceTypePower['Other'] = (deviceTypePower['Other'] ?? 0.0) + baseLoad;
    
    // Update hourly usage (kWh = kW * hours)
    // We're assuming each update represents ~10 seconds of usage
    final hoursElapsed = config.energyDataUpdateIntervalSeconds / 3600;
    final energyUsed = currentPowerUsage * hoursElapsed;
    
    // Update hourly tracking
    _hourlyUsage[hour] += energyUsed;
    
    // Update daily usage
    _currentDayUsage += energyUsed;
    
    // Update device type breakdown
    for (final type in deviceTypePower.keys) {
      final typeEnergy = deviceTypePower[type]! * hoursElapsed;
      _currentDeviceDayUsage[type] = (_currentDeviceDayUsage[type] ?? 0.0) + typeEnergy;
    }
    
    // Every midnight, save the current day's data and reset
    final midnightCheck = DateTime(now.year, now.month, now.day);
    if (!_dailyUsageData.containsKey(midnightCheck)) {
      // Archive yesterday's data
      final yesterday = midnightCheck.subtract(const Duration(days: 1));
      
      // Only if we have data to archive
      if (_currentDayUsage > 0) {
        _dailyUsageData[yesterday] = _currentDayUsage;
        _deviceDailyUsage[yesterday] = Map.from(_currentDeviceDayUsage);
        
        // Reset current day tracking
        _currentDayUsage = 0.0;
        _currentDeviceDayUsage.clear();
        _hourlyUsage = List.filled(24, 0.0);
      }
    }
  }
  
  // Get energy usage for different time periods
  double getTodayUsage() {
    return _currentDayUsage;
  }
  
  double getYesterdayUsage() {
    final yesterday = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    ).subtract(const Duration(days: 1));
    
    return _dailyUsageData[yesterday] ?? 0.0;
  }
  
  double getWeeklyUsage() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    double total = _currentDayUsage;
    
    // Sum up the previous 6 days
    for (int i = 1; i <= 6; i++) {
      final date = today.subtract(Duration(days: i));
      total += _dailyUsageData[date] ?? 0.0;
    }
    
    return total;
  }
  
  double getMonthlyUsage() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    double total = _currentDayUsage;
    
    // Sum up the previous 29 days (for a total of 30 days)
    for (int i = 1; i <= 29; i++) {
      final date = today.subtract(Duration(days: i));
      total += _dailyUsageData[date] ?? 0.0;
    }
    
    return total;
  }
  
  // Get hourly data for charts
  List<double> getHourlyUsageData() {
    return List<double>.from(_hourlyUsage);
  }
  
  // Get device type breakdown for the current day
  Map<String, double> getCurrentDeviceBreakdown() {
    return Map<String, double>.from(_currentDeviceDayUsage);
  }
  
  // Get historical data for a specific time range
  List<MapEntry<DateTime, double>> getHistoricalData({
    required DateTime start,
    required DateTime end,
  }) {
    final filteredData = _dailyUsageData.entries
        .where((entry) => entry.key.isAfter(start) && entry.key.isBefore(end))
        .toList();
    
    // Sort by date
    filteredData.sort((a, b) => a.key.compareTo(b.key));
    
    return filteredData;
  }
  
  // Check for unusual energy usage patterns
  List<EnergyAnomaly> detectAnomalies() {
    List<EnergyAnomaly> anomalies = [];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Get average daily usage over the past week
    double weekAvg = 0.0;
    int count = 0;
    
    for (int i = 1; i <= 7; i++) {
      final date = today.subtract(Duration(days: i));
      if (_dailyUsageData.containsKey(date)) {
        weekAvg += _dailyUsageData[date]!;
        count++;
      }
    }
    
    if (count > 0) {
      weekAvg /= count;
      
      // Check if today's usage is much higher than average
      if (_currentDayUsage > weekAvg * 1.5 && _currentDayUsage > 5.0) {
        anomalies.add(
          EnergyAnomaly(
            type: AnomalyType.highUsage,
            description: 'Today\'s energy usage is ${(((_currentDayUsage / weekAvg) - 1) * 100).toStringAsFixed(0)}% higher than your weekly average.',
            severity: AnomalySeverity.medium,
            timestamp: now,
          )
        );
      }
      
      // Check if current hour usage is unusually high
      final currentHour = now.hour;
      
      // Get average for this hour over past week
      double hourlyAvg = 0.0;
      int hourCount = 0;
      
      // For simplicity, we'll assume hourly data is available in the simulation
      if (_hourlyUsage[currentHour] > 3.0) {
        anomalies.add(
          EnergyAnomaly(
            type: AnomalyType.spike,
            description: 'Unusual energy spike detected at ${currentHour}:00.',
            severity: AnomalySeverity.high,
            timestamp: now,
          )
        );
      }
    }
    
    return anomalies;
  }
}

// Types of energy usage anomalies
enum AnomalyType {
  spike,      // Sudden increase in usage
  highUsage,  // Higher than normal overall usage
  unusual,    // Unusual pattern
  deviceMalfunction,  // Device using more energy than expected
  standby,    // High standby power
}

// Severity levels for anomalies
enum AnomalySeverity {
  low,
  medium,
  high,
}

// Energy anomaly detection model
class EnergyAnomaly {
  final AnomalyType type;
  final String description;
  final AnomalySeverity severity;
  final DateTime timestamp;
  
  EnergyAnomaly({
    required this.type,
    required this.description,
    required this.severity,
    required this.timestamp,
  });
}
