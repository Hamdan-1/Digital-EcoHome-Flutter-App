import 'package:flutter/foundation.dart';

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
  // No longer uses AiService

  // Cached recommendations and savings potential
  List<Recommendation> _recommendations = [];
  SavingsPotential? _savingsPotential;

  // Usage data by device and type (kept for compatibility, but not used for AI)
  final Map<String, Map<String, dynamic>> _usageData = {};

  RecommendationService();

  /// Get all recommendations
  List<Recommendation> get recommendations => _recommendations;

  /// Get implemented recommendations
  List<Recommendation> get implementedRecommendations =>
      _recommendations.where((r) => r.isImplemented).toList();

  /// Get savings potential (returns a static sample)
  SavingsPotential? get savingsPotential => _savingsPotential;

  /// Initialize with sample recommendations if needed
  void initWithSamples() {
    if (_recommendations.isEmpty) {
      _recommendations = _getSampleRecommendations();
      notifyListeners();
    }
  }

  /// Update usage data for a specific device or category (no longer triggers AI)
  void updateUsageData(String deviceId, Map<String, dynamic> data) {
    _usageData[deviceId] = data;
    // Only use samples
    if (_recommendations.isEmpty) {
      initWithSamples();
    }
  }

  /// Mark a recommendation as implemented or not
  void toggleRecommendationImplementation(int index, bool implemented) {
    if (index >= 0 && index < _recommendations.length) {
      _recommendations[index] = _recommendations[index].copyWith(
        isImplemented: implemented,
      );
      notifyListeners();
      // Optionally, update static savings potential
      _savingsPotential = _getSampleSavingsPotential();
    }
  }

  /// Use only sample recommendations
  void generateRecommendations() {
    initWithSamples();
  }

  /// Use only sample savings potential
  void calculateSavingsPotential() {
    _savingsPotential = _getSampleSavingsPotential();
    notifyListeners();
  }

  // Helper methods

  List<Recommendation> _getSampleRecommendations() {
    return [
      Recommendation(
        title: 'Turn off lights in empty rooms',
        description: 'Switch off lights when not in use to save energy.',
        potentialSavings: 5.0,
        costSavings: 0.75,
        category: 'Lighting',
        difficulty: 'Easy',
      ),
      Recommendation(
        title: 'Lower thermostat by 2°C',
        description: 'Reduce heating/cooling costs by adjusting your thermostat.',
        potentialSavings: 12.0,
        costSavings: 1.80,
        category: 'Heating',
        difficulty: 'Medium',
      ),
      Recommendation(
        title: 'Unplug unused electronics',
        description: 'Eliminate phantom power by unplugging devices.',
        potentialSavings: 3.0,
        costSavings: 0.45,
        category: 'Electronics',
        difficulty: 'Easy',
      ),
    ];
  }

  SavingsPotential _getSampleSavingsPotential() {
    return SavingsPotential(
      monthlySavingsKwh: 25.0,
      monthlySavingsCost: 3.75,
      annualSavingsKwh: 300.0,
      annualSavingsCost: 45.0,
      co2ReductionKg: 132.0,
    );
  }
}
