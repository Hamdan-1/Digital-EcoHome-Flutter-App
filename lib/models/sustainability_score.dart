import 'package:flutter/material.dart';

/// Model for calculating and representing a home's sustainability score
class SustainabilityScore {
  final double score; // 0-100 score
  final List<SustainabilityFactor> factors;
  final List<SustainabilityTip> improvementTips;
  final NeighborhoodRanking neighborhoodRanking;

  const SustainabilityScore({
    required this.score,
    required this.factors,
    required this.improvementTips,
    required this.neighborhoodRanking,
  });

  /// Returns a color representing the score (red to green gradient)
  Color getScoreColor() {
    if (score >= 80) {
      return const Color(0xFF2E7D32); // Dark green for excellent scores
    } else if (score >= 60) {
      return const Color(0xFF4CAF50); // Green for good scores
    } else if (score >= 40) {
      return const Color(0xFFFFC107); // Amber for average scores
    } else if (score >= 20) {
      return const Color(0xFFFF9800); // Orange for below average
    } else {
      return const Color(0xFFF44336); // Red for poor scores
    }
  }

  /// Returns a label describing the score
  String getScoreLabel() {
    if (score >= 80) {
      return 'Excellent';
    } else if (score >= 60) {
      return 'Good';
    } else if (score >= 40) {
      return 'Average';
    } else if (score >= 20) {
      return 'Below Average';
    } else {
      return 'Poor';
    }
  }

  /// Returns the percentage of homes in the neighborhood with a lower score
  String getPercentileLabel() {
    return '${neighborhoodRanking.percentile.toStringAsFixed(0)}% of homes have a lower score';
  }

  /// Calculate a user's sustainability score based on multiple factors
  static SustainabilityScore calculate({
    required double averageDailyEnergyKwh,
    required int activeDevicesCount,
    required bool hasSolarPanels,
    required bool hasSmartThermostat,
    required bool usesLedLighting,
    required double peakHourUsagePercent,
    required List<double> recentDailyUsage, // Last 7 days of usage in kWh
  }) {
    // Base score starts at 50 (average)
    double baseScore = 50.0;

    // Create a list to store contributing factors
    final List<SustainabilityFactor> factors = [];

    // Factor 1: Daily energy consumption (higher usage = lower score)
    // Average US home uses ~30 kWh per day, so we'll use that as a baseline
    double energyFactor = 0;
    if (averageDailyEnergyKwh <= 10) {
      // Excellent energy usage
      energyFactor = 20;
    } else if (averageDailyEnergyKwh <= 20) {
      // Good energy usage
      energyFactor = 15;
    } else if (averageDailyEnergyKwh <= 30) {
      // Average energy usage
      energyFactor = 10;
    } else if (averageDailyEnergyKwh <= 40) {
      // Above average energy usage
      energyFactor = 0;
    } else {
      // High energy usage
      energyFactor = -10;
    }
    baseScore += energyFactor;
    factors.add(
      SustainabilityFactor(
        name: 'Energy Consumption',
        score: energyFactor,
        description:
            'Your daily energy usage is ${_getEnergyUsageDescription(averageDailyEnergyKwh)}',
        icon: Icons.bolt,
      ),
    );

    // Factor 2: Solar panels
    double solarFactor = hasSolarPanels ? 15 : 0;
    baseScore += solarFactor;
    factors.add(
      SustainabilityFactor(
        name: 'Renewable Energy',
        score: solarFactor,
        description:
            hasSolarPanels
                ? 'You\'re using solar power to offset your energy consumption'
                : 'Consider adding solar panels to your home',
        icon: Icons.wb_sunny,
      ),
    );

    // Factor 3: Smart thermostat
    double thermostatFactor = hasSmartThermostat ? 10 : 0;
    baseScore += thermostatFactor;
    factors.add(
      SustainabilityFactor(
        name: 'Smart Climate Control',
        score: thermostatFactor,
        description:
            hasSmartThermostat
                ? 'Your smart thermostat helps optimize heating and cooling'
                : 'A smart thermostat can reduce HVAC energy usage by 10-15%',
        icon: Icons.thermostat,
      ),
    );

    // Factor 4: LED lighting
    double lightingFactor = usesLedLighting ? 5 : -5;
    baseScore += lightingFactor;
    factors.add(
      SustainabilityFactor(
        name: 'Energy Efficient Lighting',
        score: lightingFactor,
        description:
            usesLedLighting
                ? 'LED lighting reduces energy usage for lighting by up to 75%'
                : 'Switching to LED lighting can significantly reduce energy usage',
        icon: Icons.lightbulb,
      ),
    );

    // Factor 5: Peak hour usage
    double peakHourFactor = 0;
    if (peakHourUsagePercent <= 20) {
      peakHourFactor = 10;
    } else if (peakHourUsagePercent <= 40) {
      peakHourFactor = 5;
    } else if (peakHourUsagePercent <= 60) {
      peakHourFactor = 0;
    } else if (peakHourUsagePercent <= 80) {
      peakHourFactor = -5;
    } else {
      peakHourFactor = -10;
    }
    baseScore += peakHourFactor;
    factors.add(
      SustainabilityFactor(
        name: 'Peak Hour Usage',
        score: peakHourFactor,
        description:
            'You use ${peakHourUsagePercent.toStringAsFixed(0)}% of your energy during peak hours',
        icon: Icons.access_time,
      ),
    );

    // Factor 6: Usage trend (improving or worsening)
    double trendFactor = 0;
    if (recentDailyUsage.length >= 3) {
      // Calculate trend by comparing more recent days to earlier days
      double recentAvg =
          recentDailyUsage
              .sublist(recentDailyUsage.length - 3)
              .reduce((a, b) => a + b) /
          3;
      double earlierAvg =
          recentDailyUsage.sublist(0, 3).reduce((a, b) => a + b) / 3;

      double percentChange = ((recentAvg - earlierAvg) / earlierAvg) * 100;

      if (percentChange <= -15) {
        trendFactor = 15; // Significant improvement
      } else if (percentChange <= -5) {
        trendFactor = 10; // Moderate improvement
      } else if (percentChange <= 5) {
        trendFactor = 5; // Slight improvement or stable
      } else if (percentChange <= 15) {
        trendFactor = -5; // Moderate worsening
      } else {
        trendFactor = -10; // Significant worsening
      }

      baseScore += trendFactor;
      factors.add(
        SustainabilityFactor(
          name: 'Usage Trend',
          score: trendFactor,
          description: _getTrendDescription(percentChange),
          icon: percentChange <= 0 ? Icons.trending_down : Icons.trending_up,
        ),
      );
    }

    // Ensure score stays within 0-100 range
    double finalScore = baseScore.clamp(0.0, 100.0);

    // Generate improvement tips based on the factors
    List<SustainabilityTip> tips = _generateImprovementTips(
      hasSolarPanels: hasSolarPanels,
      hasSmartThermostat: hasSmartThermostat,
      usesLedLighting: usesLedLighting,
      peakHourUsagePercent: peakHourUsagePercent,
      energyUsage: averageDailyEnergyKwh,
    );

    // Generate simulated neighborhood ranking
    NeighborhoodRanking ranking = _generateNeighborhoodRanking(finalScore);

    return SustainabilityScore(
      score: finalScore,
      factors: factors,
      improvementTips: tips,
      neighborhoodRanking: ranking,
    );
  }

  // Helper method to describe energy usage
  static String _getEnergyUsageDescription(double averageDailyEnergyKwh) {
    if (averageDailyEnergyKwh <= 10) {
      return 'excellent (${averageDailyEnergyKwh.toStringAsFixed(1)} kWh/day)';
    } else if (averageDailyEnergyKwh <= 20) {
      return 'good (${averageDailyEnergyKwh.toStringAsFixed(1)} kWh/day)';
    } else if (averageDailyEnergyKwh <= 30) {
      return 'average (${averageDailyEnergyKwh.toStringAsFixed(1)} kWh/day)';
    } else if (averageDailyEnergyKwh <= 40) {
      return 'above average (${averageDailyEnergyKwh.toStringAsFixed(1)} kWh/day)';
    } else {
      return 'high (${averageDailyEnergyKwh.toStringAsFixed(1)} kWh/day)';
    }
  }

  // Helper method to describe usage trend
  static String _getTrendDescription(double percentChange) {
    if (percentChange <= -15) {
      return 'Your energy usage has significantly decreased recently';
    } else if (percentChange <= -5) {
      return 'Your energy usage has been decreasing';
    } else if (percentChange <= 5) {
      return 'Your energy usage has been stable';
    } else if (percentChange <= 15) {
      return 'Your energy usage has been increasing';
    } else {
      return 'Your energy usage has significantly increased recently';
    }
  }

  // Generate improvement tips based on the user's current setup
  static List<SustainabilityTip> _generateImprovementTips({
    required bool hasSolarPanels,
    required bool hasSmartThermostat,
    required bool usesLedLighting,
    required double peakHourUsagePercent,
    required double energyUsage,
  }) {
    List<SustainabilityTip> tips = [];

    // Solar panel tip
    if (!hasSolarPanels) {
      tips.add(
        const SustainabilityTip(
          title: 'Install Solar Panels',
          description:
              'Reduce grid dependency and lower your carbon footprint.',
          detailedDescription:
              'Solar panels convert sunlight into electricity, significantly reducing your reliance on fossil fuel-based energy from the grid. While the initial investment can be substantial, long-term savings on electricity bills and potential government incentives often make it a worthwhile investment. Consider getting quotes from local installers to assess feasibility for your home.',
          impact: 'High Impact',
          icon: Icons.wb_sunny,
        ),
      );
    }

    // Smart thermostat tip
    if (!hasSmartThermostat) {
      tips.add(
        const SustainabilityTip(
          title: 'Install a Smart Thermostat',
          description: 'Optimize heating/cooling schedules automatically.',
          detailedDescription:
              'Smart thermostats learn your schedule and preferences, adjusting the temperature automatically to save energy when you\'re away or asleep. Many models allow remote control via smartphone apps and provide energy usage reports. They can reduce HVAC energy consumption by 10-15% annually.',
          impact: 'Medium Impact',
          icon: Icons.thermostat,
        ),
      );
    }

    // LED lighting tip
    if (!usesLedLighting) {
      tips.add(
        const SustainabilityTip(
          title: 'Switch to LED Lighting',
          description: 'LEDs use up to 75% less energy and last much longer.',
          detailedDescription:
              'Light Emitting Diodes (LEDs) are highly energy-efficient compared to traditional incandescent or halogen bulbs. Replacing your home\'s most frequently used bulbs with LEDs offers quick energy savings. They also have a significantly longer lifespan, reducing replacement frequency and waste.',
          impact: 'Medium Impact',
          icon: Icons.lightbulb,
        ),
      );
    }

    // Peak hour usage tip
    if (peakHourUsagePercent > 40) {
      tips.add(
        const SustainabilityTip(
          title: 'Shift Usage Away From Peak Hours',
          description: 'Run major appliances during off-peak times.',
          detailedDescription:
              'Peak hours (usually late afternoon/early evening) are when electricity demand is highest, often relying on less efficient power plants and potentially costing more depending on your utility plan. Running large appliances like dishwashers, washing machines, and dryers during off-peak hours (e.g., overnight) reduces grid strain and can lower your bills.',
          impact: 'Medium Impact',
          icon: Icons.access_time,
        ),
      );
    }

    // High energy usage tips
    if (energyUsage > 30) {
      tips.add(
        const SustainabilityTip(
          title: 'Perform an Energy Audit',
          description: 'Identify energy waste sources in your home.',
          detailedDescription:
              'An energy audit helps pinpoint where your home is losing energy (e.g., poor insulation, air leaks, inefficient appliances). You can hire a professional or use DIY guides and tools (like thermal cameras) to assess areas for improvement. Addressing these issues can lead to significant energy savings.',
          impact: 'High Impact',
          icon: Icons.search,
        ),
      );

      tips.add(
        const SustainabilityTip(
          title: 'Upgrade to Energy Star Appliances',
          description:
              'Replace old appliances with certified efficient models.',
          detailedDescription:
              'Energy Star certified appliances meet strict energy efficiency guidelines set by the EPA. When replacing refrigerators, washing machines, dishwashers, etc., look for the Energy Star label to ensure lower energy consumption and operating costs over the appliance\'s lifetime.',
          impact: 'High Impact',
          icon: Icons.kitchen,
        ),
      );
    }

    // Add some general tips if we don't have many specific ones
    if (tips.length < 3) {
      tips.add(
        const SustainabilityTip(
          title: 'Improve Home Insulation',
          description: 'Reduce heating/cooling costs with better insulation.',
          detailedDescription:
              'Proper insulation in your attic, walls, floors, and crawl spaces is crucial for maintaining comfortable temperatures and reducing the workload on your HVAC system. Check insulation levels and consider adding more if needed. Sealing air leaks around windows, doors, and ductwork also significantly improves efficiency.',
          impact: 'High Impact',
          icon: Icons.home,
        ),
      );

      tips.add(
        const SustainabilityTip(
          title: 'Install Smart Power Strips',
          description: 'Eliminate phantom power draw from idle devices.',
          detailedDescription:
              'Many electronics continue to draw power even when turned off (phantom load). Smart power strips can automatically cut power to devices that are not in use (e.g., turning off peripherals when the computer is shut down) or allow you to control outlets remotely, reducing wasted energy.',
          impact: 'Low Impact',
          icon: Icons.power,
        ),
      );
    }

    return tips;
  }

  // Generate simulated neighborhood ranking data
  static NeighborhoodRanking _generateNeighborhoodRanking(double userScore) {
    // Simulate a neighborhood with 100 homes
    // Create a normal distribution centered around 50
    List<double> neighborhoodScores = List.generate(100, (index) {
      // Create a bell curve distribution
      double randomValue = 50 + (index - 50) * 0.8 + (index % 17 - 8) * 2;
      return randomValue.clamp(0.0, 100.0);
    });

    // Sort scores to find user's ranking
    neighborhoodScores.sort();

    // Find position of user's score
    int position = 0;
    for (int i = 0; i < neighborhoodScores.length; i++) {
      if (userScore > neighborhoodScores[i]) {
        position = i + 1;
      }
    }

    // Calculate percentile (percentage of homes with lower scores)
    double percentile = (position / neighborhoodScores.length) * 100;

    // Get nearby scores for chart display
    int startIdx = (position - 5).clamp(0, neighborhoodScores.length - 10);
    List<double> nearbyScores = neighborhoodScores.sublist(
      startIdx,
      startIdx + 10,
    );

    return NeighborhoodRanking(
      position: position,
      totalHomes: neighborhoodScores.length,
      percentile: percentile,
      averageScore:
          neighborhoodScores.reduce((a, b) => a + b) /
          neighborhoodScores.length,
      neighborhoodScores: nearbyScores,
    );
  }
}

/// Model for a factor that contributes to the sustainability score
class SustainabilityFactor {
  final String name;
  final double score; // The points this factor contributes to overall score
  final String description;
  final IconData icon;

  const SustainabilityFactor({
    required this.name,
    required this.score,
    required this.description,
    required this.icon,
  });

  bool get isPositive => score >= 0;
}

/// Model for a tip to improve sustainability score
class SustainabilityTip {
  final String title;
  final String description;
  final String detailedDescription; // Added field for more details
  final String impact; // "High Impact", "Medium Impact", "Low Impact"
  final IconData icon;

  const SustainabilityTip({
    required this.title,
    required this.description,
    required this.detailedDescription, // Added required parameter
    required this.impact,
    required this.icon,
  });

  Color getImpactColor() {
    switch (impact) {
      case 'High Impact':
        return const Color(0xFF2E7D32); // Dark green
      case 'Medium Impact':
        return const Color(0xFF4CAF50); // Green
      case 'Low Impact':
        return const Color(0xFF8BC34A); // Light green
      default:
        return const Color(0xFF4CAF50); // Default green
    }
  }
}

/// Model for neighborhood sustainability ranking
class NeighborhoodRanking {
  final int position; // User's position in the neighborhood
  final int totalHomes; // Total number of homes in the neighborhood
  final double percentile; // Percentage of homes with lower scores
  final double averageScore; // Average score in the neighborhood
  final List<double>
  neighborhoodScores; // Sample of nearby scores for visualization

  const NeighborhoodRanking({
    required this.position,
    required this.totalHomes,
    required this.percentile,
    required this.averageScore,
    required this.neighborhoodScores,
  });

  String get ranking => '$position out of $totalHomes';
}
