// Models for configuring the IoT simulation behavior
import 'dart:math';

/// Configuration for the IoT device simulation
class SimulationConfig {
  // Global simulation settings
  final bool enableRealisticLatency;
  final bool enableDeviceFailures;
  final double deviceFailureProbability;
  final bool enablePeakHourPatterns;
  final bool enableWeatherEffects;
  
  // Latency settings
  final int minLatencyMs;
  final int maxLatencyMs;
  
  // Update intervals
  final int deviceStateUpdateIntervalSeconds;
  final int energyDataUpdateIntervalSeconds;
  final int notificationCheckIntervalMinutes;
  
  // Energy usage patterns
  final Map<String, double> peakHourMultipliers;
  final Map<String, double> deviceTypePeakHourEffects;
  
  // Random generator for the simulation
  final Random random;
  
  SimulationConfig({
    this.enableRealisticLatency = true,
    this.enableDeviceFailures = true,
    this.deviceFailureProbability = 0.05, // 5% chance of failure
    this.enablePeakHourPatterns = true,
    this.enableWeatherEffects = true,
    this.minLatencyMs = 100,
    this.maxLatencyMs = 2000,
    this.deviceStateUpdateIntervalSeconds = 3,
    this.energyDataUpdateIntervalSeconds = 10,
    this.notificationCheckIntervalMinutes = 15,
    Map<String, double>? peakHourMultipliers,
    Map<String, double>? deviceTypePeakHourEffects,
    Random? random,
  }) : 
    peakHourMultipliers = peakHourMultipliers ?? _defaultPeakHourMultipliers(),
    deviceTypePeakHourEffects = deviceTypePeakHourEffects ?? _defaultDeviceTypePeakHourEffects(),
    random = random ?? Random();
  
  // Get a random latency value in milliseconds
  int getRandomLatency() {
    if (!enableRealisticLatency) return 0;
    return minLatencyMs + random.nextInt(maxLatencyMs - minLatencyMs);
  }
  
  // Check if a device action will fail based on the failure probability
  bool willDeviceActionFail() {
    if (!enableDeviceFailures) return false;
    return random.nextDouble() < deviceFailureProbability;
  }
  
  // Get the current energy usage multiplier based on time of day
  double getCurrentEnergyMultiplier() {
    if (!enablePeakHourPatterns) return 1.0;
    
    final now = DateTime.now();
    final hour = now.hour;
    
    // Get the multiplier for the current hour, defaulting to 1.0
    return peakHourMultipliers['$hour'] ?? 1.0;
  }
  
  // Get device-specific multiplier based on type and time of day
  double getDeviceTypeMultiplier(String deviceType) {
    if (!enablePeakHourPatterns) return 1.0;
    
    final now = DateTime.now();
    final hour = now.hour;
    
    // Base hour multiplier
    final hourMultiplier = peakHourMultipliers['$hour'] ?? 1.0;
    
    // Device type specific effect
    final typeEffect = deviceTypePeakHourEffects[deviceType] ?? 1.0;
    
    return hourMultiplier * typeEffect;
  }
  
  // Default peak hour multipliers for a typical household
  static Map<String, double> _defaultPeakHourMultipliers() {
    return {
      // Night (reduced usage)
      '0': 0.6, '1': 0.5, '2': 0.5, '3': 0.5, '4': 0.6, '5': 0.7,
      // Morning peak
      '6': 1.2, '7': 1.4, '8': 1.3, '9': 1.1,
      // Midday
      '10': 0.9, '11': 0.9, '12': 1.0, '13': 1.0, '14': 0.9, '15': 0.9, '16': 1.0,
      // Evening peak
      '17': 1.3, '18': 1.5, '19': 1.6, '20': 1.4, '21': 1.2,
      // Late evening
      '22': 0.9, '23': 0.7,
    };
  }
  
  // Device type specific effects during peak hours
  static Map<String, double> _defaultDeviceTypePeakHourEffects() {
    return {
      'HVAC': 1.3,      // AC/Heating usage spikes during peak hours
      'Light': 1.5,     // Lights heavily used during evening peak
      'Appliance': 1.2, // Appliances moderately affected
      'Entertainment': 1.4, // Entertainment devices used more in evening
      'Water': 1.1,     // Water heating slightly affected
      'Kitchen': 1.3,   // Kitchen appliances more used during meal times
    };
  }
  
  // Clone with partial updates
  SimulationConfig copyWith({
    bool? enableRealisticLatency,
    bool? enableDeviceFailures,
    double? deviceFailureProbability,
    bool? enablePeakHourPatterns,
    bool? enableWeatherEffects,
    int? minLatencyMs,
    int? maxLatencyMs,
    int? deviceStateUpdateIntervalSeconds,
    int? energyDataUpdateIntervalSeconds,
    int? notificationCheckIntervalMinutes,
    Map<String, double>? peakHourMultipliers,
    Map<String, double>? deviceTypePeakHourEffects,
  }) {
    return SimulationConfig(
      enableRealisticLatency: enableRealisticLatency ?? this.enableRealisticLatency,
      enableDeviceFailures: enableDeviceFailures ?? this.enableDeviceFailures,
      deviceFailureProbability: deviceFailureProbability ?? this.deviceFailureProbability,
      enablePeakHourPatterns: enablePeakHourPatterns ?? this.enablePeakHourPatterns,
      enableWeatherEffects: enableWeatherEffects ?? this.enableWeatherEffects,
      minLatencyMs: minLatencyMs ?? this.minLatencyMs,
      maxLatencyMs: maxLatencyMs ?? this.maxLatencyMs,
      deviceStateUpdateIntervalSeconds: deviceStateUpdateIntervalSeconds ?? this.deviceStateUpdateIntervalSeconds,
      energyDataUpdateIntervalSeconds: energyDataUpdateIntervalSeconds ?? this.energyDataUpdateIntervalSeconds,
      notificationCheckIntervalMinutes: notificationCheckIntervalMinutes ?? this.notificationCheckIntervalMinutes,
      peakHourMultipliers: peakHourMultipliers ?? this.peakHourMultipliers,
      deviceTypePeakHourEffects: deviceTypePeakHourEffects ?? this.deviceTypePeakHourEffects,
      random: random,
    );
  }
}
