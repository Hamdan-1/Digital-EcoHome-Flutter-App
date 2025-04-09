import 'dart:async';
import 'package:flutter/foundation.dart';
import 'ai_service.dart';

class Recommendation {
  final String title;
  final String description;
  final double potentialSavings; // in kWh
  final double costSavings; // in currency
  final String category; // e.g., 'Lighting', 'Heating', 'Appliances'
  final String difficulty; // e.g., 'Easy', 'Medium', 'Hard'
  final bool isImplemented;

  Recommendation({
    required this.title,
    required this.description,
    required this.potentialSavings,
    required this.costSavings,
    required this.category,
    required this.difficulty,
    this.isImplemented = false,
  });

  Recommendation copyWith({
    String? title,
    String? description,
    double? potentialSavings,
    double? costSavings,
    String? category,
    String? difficulty,
    bool? isImplemented,
  }) {
    return Recommendation(
      title: title ?? this.title,
      description: description ?? this.description,
      potentialSavings: potentialSavings ?? this.potentialSavings,
      costSavings: costSavings ?? this.costSavings,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      isImplemented: isImplemented ?? this.isImplemented,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'potentialSavings': potentialSavings,
      'costSavings': costSavings,
      'category': category,
      'difficulty': difficulty,
      'isImplemented': isImplemented,
    };
  }

  factory Recommendation.fromJson(Map<String, dynamic> json) {
    return Recommendation(
      title: json['title'],
      description: json['description'],
      potentialSavings: json['potentialSavings'],
      costSavings: json['costSavings'],
      category: json['category'],
      difficulty: json['difficulty'],
      isImplemented: json['isImplemented'] ?? false,
    );
  }
}

class SavingsPotential {
  final double monthlySavingsKwh;
  final double monthlySavingsCost;
  final double annualSavingsKwh;
  final double annualSavingsCost;
  final double co2ReductionKg;

  SavingsPotential({
    required this.monthlySavingsKwh,
    required this.monthlySavingsCost,
    required this.annualSavingsKwh,
    required this.annualSavingsCost,
    required this.co2ReductionKg,
  });

  factory SavingsPotential.fromJson(Map<String, dynamic> json) {
    return SavingsPotential(
      monthlySavingsKwh: json['monthlySavingsKwh'].toDouble(),
      monthlySavingsCost: json['monthlySavingsCost'].toDouble(),
      annualSavingsKwh: json['annualSavingsKwh'].toDouble(),
      annualSavingsCost: json['annualSavingsCost'].toDouble(),
      co2ReductionKg: json['co2ReductionKg'].toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'monthlySavingsKwh': monthlySavingsKwh,
      'monthlySavingsCost': monthlySavingsCost,
      'annualSavingsKwh': annualSavingsKwh,
      'annualSavingsCost': annualSavingsCost,
      'co2ReductionKg': co2ReductionKg,
    };
  }
}

class RecommendationService extends ChangeNotifier {
  final AiService _aiService;

  // Cached recommendations and savings potential
  List<Recommendation> _recommendations = [];
  SavingsPotential? _savingsPotential;

  // Usage data by device and type
  Map<String, Map<String, dynamic>> _usageData = {};

  RecommendationService({required String apiKey})
    : _aiService = AiService(apiKey: apiKey);

  /// Get all recommendations
  List<Recommendation> get recommendations => _recommendations;

  /// Get implemented recommendations
  List<Recommendation> get implementedRecommendations =>
      _recommendations.where((r) => r.isImplemented).toList();

  /// Get savings potential
  SavingsPotential? get savingsPotential => _savingsPotential;

  /// Initialize with sample recommendations if needed
  void initWithSamples() {
    if (_recommendations.isEmpty) {
      _recommendations = _getSampleRecommendations();
      notifyListeners();
    }
  }

  /// Update usage data for a specific device or category
  void updateUsageData(String deviceId, Map<String, dynamic> data) {
    _usageData[deviceId] = data;
    // After updating usage data, we should refresh recommendations
    generateRecommendations();
  }

  /// Mark a recommendation as implemented or not
  void toggleRecommendationImplementation(int index, bool implemented) {
    if (index >= 0 && index < _recommendations.length) {
      _recommendations[index] = _recommendations[index].copyWith(
        isImplemented: implemented,
      );

      notifyListeners();

      // Recalculate savings potential
      calculateSavingsPotential();
    }
  }

  /// Generate personalized recommendations based on usage data
  Future<void> generateRecommendations() async {
    try {
      if (_usageData.isEmpty) {
        // If no usage data, keep existing recommendations or use samples
        if (_recommendations.isEmpty) {
          initWithSamples();
        }
        return;
      }

      // Convert usage data to format expected by AI service
      final Map<String, dynamic> formattedUsageData = {};
      for (final entry in _usageData.entries) {
        final deviceId = entry.key;
        final data = entry.value;
        // Extract relevant metrics for AI processing
        if (data.containsKey('dailyUsage')) {
          formattedUsageData['${deviceId}_dailyUsage'] = data['dailyUsage'];
        }
        if (data.containsKey('weeklyUsage')) {
          formattedUsageData['${deviceId}_weeklyUsage'] = data['weeklyUsage'];
        }
        if (data.containsKey('peakHours')) {
          formattedUsageData['${deviceId}_peakHours'] = data['peakHours'];
        }
      }

      // Get device types for more targeted recommendations
      final deviceTypes = _usageData.keys.toList();

      // Get raw recommendations from AI
      final List<String> rawRecommendations = await _aiService
          .generateRecommendations(
            usageData: formattedUsageData,
            deviceTypes: deviceTypes,
            count: 5, // Request 5 recommendations
          );

      // Process raw recommendations into structured format
      _recommendations = _processRawRecommendations(rawRecommendations);

      notifyListeners();

      // Calculate potential savings based on new recommendations
      calculateSavingsPotential();
    } catch (e) {
      debugPrint('Error generating recommendations: $e');
      // Fallback to sample recommendations in case of error
      if (_recommendations.isEmpty) {
        initWithSamples();
      }
    }
  }

  /// Calculate potential energy savings based on current usage and implemented recommendations
  Future<void> calculateSavingsPotential() async {
    try {
      // Format current usage data
      final Map<String, dynamic> currentUsage = {};
      for (final entry in _usageData.entries) {
        final deviceId = entry.key;
        final data = entry.value;

        // Extract energy usage metrics
        if (data.containsKey('monthlyUsage')) {
          currentUsage['${deviceId}_monthlyUsage'] =
              '${data['monthlyUsage']} kWh';
        } else if (data.containsKey('weeklyUsage')) {
          // Convert weekly to monthly
          final double weekly =
              data['weeklyUsage'] is double
                  ? data['weeklyUsage']
                  : double.tryParse(data['weeklyUsage'].toString()) ?? 0.0;
          currentUsage['${deviceId}_monthlyUsage'] =
              '${(weekly * 4.3).toStringAsFixed(2)} kWh';
        }
      }

      // Default to total household if no detailed data
      if (currentUsage.isEmpty) {
        currentUsage['totalHomeMonthlyUsage'] = '850 kWh';
      }

      // Get implemented recommendations as text
      final List<String> implementedRecommendationTexts =
          implementedRecommendations.map((r) => r.title).toList();

      // Get savings potential analysis from AI
      final Map<String, dynamic> savingsPotentialData = await _aiService
          .calculateEnergySavingPotential(
            currentUsage: currentUsage,
            implementedRecommendations: implementedRecommendationTexts,
          );

      // Create SavingsPotential object
      _savingsPotential = SavingsPotential.fromJson(savingsPotentialData);

      notifyListeners();
    } catch (e) {
      debugPrint('Error calculating savings potential: $e');
      // Use default values if error occurs
      _savingsPotential = SavingsPotential(
        monthlySavingsKwh: 25.0,
        monthlySavingsCost: 3.75,
        annualSavingsKwh: 300.0,
        annualSavingsCost: 45.0,
        co2ReductionKg: 132.0,
      );
      notifyListeners();
    }
  }

  // Helper methods

  List<Recommendation> _processRawRecommendations(
    List<String> rawRecommendations,
  ) {
    // Map of categories by common keywords
    final categoryKeywords = {
      'Lighting': ['light', 'lamp', 'bulb', 'LED', 'lumens'],
      'Heating': ['heat', 'thermostat', 'temperature', 'HVAC', 'furnace'],
      'Cooling': ['cool', 'AC', 'air condition', 'fan', 'ventilation'],
      'Appliances': [
        'appliance',
        'refrigerator',
        'washer',
        'dryer',
        'dishwasher',
      ],
      'Electronics': [
        'electronic',
        'computer',
        'TV',
        'standby',
        'charger',
        'device',
      ],
      'Water': ['water', 'shower', 'tap', 'toilet', 'leak'],
      'Insulation': ['insulate', 'seal', 'draft', 'window', 'door'],
    };

    final result = <Recommendation>[];

    // Assign a difficulty value to each recommendation
    final difficultyWords = {
      'Easy': ['simple', 'easy', 'quick', 'immediately', 'just'],
      'Medium': ['moderate', 'some', 'replace', 'adjust', 'modify'],
      'Hard': [
        'significant',
        'install',
        'upgrade',
        'major',
        'renovate',
        'professional',
      ],
    };

    for (final rawRec in rawRecommendations) {
      // Skip empty recommendations
      if (rawRec.isEmpty) continue;

      // Extract title (first sentence or up to 60 chars)
      final title = rawRec.split('.').first.trim();

      // Rest of the text is description
      String description = rawRec;
      if (title.length < rawRec.length) {
        description = rawRec.substring(title.length + 1).trim();
      }

      // Determine category based on keywords
      String category = 'Other';
      for (final entry in categoryKeywords.entries) {
        if (entry.value.any(
          (keyword) => rawRec.toLowerCase().contains(keyword.toLowerCase()),
        )) {
          category = entry.key;
          break;
        }
      }

      // Determine difficulty
      String difficulty = 'Medium';
      for (final entry in difficultyWords.entries) {
        if (entry.value.any(
          (keyword) => rawRec.toLowerCase().contains(keyword.toLowerCase()),
        )) {
          difficulty = entry.key;
          break;
        }
      }

      // Generate somewhat realistic savings estimates based on category
      double baseSavings = 0.0;
      switch (category) {
        case 'Lighting':
          baseSavings =
              5.0 +
              (10.0 *
                  (difficulty == 'Easy'
                      ? 0.5
                      : difficulty == 'Medium'
                      ? 1.0
                      : 1.5));
          break;
        case 'Heating':
          baseSavings =
              15.0 +
              (15.0 *
                  (difficulty == 'Easy'
                      ? 0.5
                      : difficulty == 'Medium'
                      ? 1.0
                      : 2.0));
          break;
        case 'Cooling':
          baseSavings =
              10.0 +
              (15.0 *
                  (difficulty == 'Easy'
                      ? 0.5
                      : difficulty == 'Medium'
                      ? 1.0
                      : 2.0));
          break;
        case 'Appliances':
          baseSavings =
              8.0 +
              (7.0 *
                  (difficulty == 'Easy'
                      ? 0.5
                      : difficulty == 'Medium'
                      ? 1.0
                      : 2.0));
          break;
        default:
          baseSavings =
              5.0 +
              (5.0 *
                  (difficulty == 'Easy'
                      ? 0.5
                      : difficulty == 'Medium'
                      ? 1.0
                      : 1.5));
      }

      // Add some randomness to make it look more natural
      final randomFactor =
          0.8 + (DateTime.now().millisecond % 40) / 100; // 0.8 to 1.2
      final potentialSavings = baseSavings * randomFactor;

      // Calculate cost savings (assuming $0.15 per kWh)
      final costSavings = potentialSavings * 0.15;

      result.add(
        Recommendation(
          title: title,
          description: description,
          potentialSavings: potentialSavings,
          costSavings: costSavings,
          category: category,
          difficulty: difficulty,
        ),
      );
    }

    // Sort by potential savings (highest first)
    result.sort((a, b) => b.potentialSavings.compareTo(a.potentialSavings));

    return result;
  }

  List<Recommendation> _getSampleRecommendations() {
    return [
      Recommendation(
        title: 'Replace incandescent bulbs with LED lighting',
        description:
            'LED bulbs use up to 80% less energy than traditional incandescent bulbs and last up to 25 times longer. This simple change can save significant energy in frequently used rooms.',
        potentialSavings: 14.5,
        costSavings: 2.18,
        category: 'Lighting',
        difficulty: 'Easy',
      ),
      Recommendation(
        title: 'Adjust thermostat settings by 2-3 degrees',
        description:
            'In winter, lower your thermostat by 2-3°F, and in summer, raise it by 2-3°F. This small change can reduce your heating and cooling costs by up to 10% annually.',
        potentialSavings: 45.0,
        costSavings: 6.75,
        category: 'Heating',
        difficulty: 'Easy',
      ),
      Recommendation(
        title: 'Unplug electronics when not in use',
        description:
            'Many devices continue to draw power even when turned off. Unplug chargers, entertainment systems, and small appliances when not in use to eliminate this "phantom" or standby power consumption.',
        potentialSavings: 12.0,
        costSavings: 1.80,
        category: 'Electronics',
        difficulty: 'Easy',
      ),
      Recommendation(
        title: 'Install a programmable thermostat',
        description:
            'A programmable thermostat automatically adjusts your home\'s temperature when you\'re asleep or away, saving energy without sacrificing comfort when you\'re active at home.',
        potentialSavings: 82.0,
        costSavings: 12.30,
        category: 'Heating',
        difficulty: 'Medium',
      ),
      Recommendation(
        title: 'Use cold water for laundry',
        description:
            'Up to 90% of energy used by washing machines goes to heating water. Switching to cold water washes can significantly reduce energy use while still cleaning clothes effectively with modern detergents.',
        potentialSavings: 9.8,
        costSavings: 1.47,
        category: 'Appliances',
        difficulty: 'Easy',
      ),
    ];
  }
}
