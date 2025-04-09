import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'openrouter_service.dart';

class AiService {
  final OpenRouterService _openRouterService;

  // Default system prompt focused on energy conservation and eco-home assistance
  static const String defaultSystemPrompt = '''
You are EcoAssistant, an AI assistant specialized in smart home energy conservation and sustainability.
Your purpose is to help users reduce their energy consumption, adopt more sustainable habits, and optimize their home's energy efficiency.
You provide practical, actionable advice tailored to the user's specific situation and devices.
Always be helpful, concise, and focus on realistic, impactful recommendations.
Whenever possible, quantify potential energy and cost savings to motivate users.
Keep responses friendly but direct, prioritizing information that leads to meaningful energy conservation.
''';

  AiService({required String apiKey})
    : _openRouterService = OpenRouterService(apiKey: apiKey);

  /// Generate a response for the AI chat feature
  Future<String> generateChatResponse(String userMessage) async {
    try {
      return await _openRouterService.getTextCompletion(
        prompt: userMessage,
        systemPrompt: defaultSystemPrompt,
        temperature: 0.7,
      );
    } catch (e) {
      debugPrint('Error in AI chat: $e');
      return 'I apologize, but I encountered an issue while processing your request. Please try again later.';
    }
  }

  /// Generate personalized energy-saving recommendations based on usage data
  Future<List<String>> generateRecommendations({
    required Map<String, dynamic> usageData,
    required List<String> deviceTypes,
    int count = 3,
  }) async {
    try {
      // Create a prompt based on the user's usage data and devices
      final prompt = _createRecommendationPrompt(usageData, deviceTypes, count);

      // Get the recommendations from the AI model
      final response = await _openRouterService.getTextCompletion(
        prompt: prompt,
        systemPrompt: defaultSystemPrompt,
        temperature: 0.7,
      );

      // Parse the response into a list of recommendations
      final recommendations = _parseRecommendations(response);
      return recommendations.take(count).toList();
    } catch (e) {
      debugPrint('Error generating recommendations: $e');
      return [
        'Consider turning off lights in unoccupied rooms to save energy.',
        'Adjust your thermostat by a few degrees to reduce heating/cooling costs.',
        'Unplug electronic devices when not in use to eliminate phantom power usage.',
      ];
    }
  }

  /// Calculate potential energy savings based on current usage and recommendations
  Future<Map<String, dynamic>> calculateEnergySavingPotential({
    required Map<String, dynamic> currentUsage,
    required List<String> implementedRecommendations,
  }) async {
    try {
      // Create a prompt to analyze potential savings
      final prompt = _createSavingsPotentialPrompt(
        currentUsage,
        implementedRecommendations,
      );

      // Get the analysis from the AI model
      final response = await _openRouterService.getTextCompletion(
        prompt: prompt,
        systemPrompt: defaultSystemPrompt,
        temperature: 0.3, // Lower temperature for more factual responses
      );

      // Parse the response into savings data
      return _parseSavingsPotential(response);
    } catch (e) {
      debugPrint('Error calculating savings potential: $e');
      // Return conservative default savings estimates
      return {
        'monthlySavingsKwh': 25.0,
        'monthlySavingsCost': 3.75,
        'annualSavingsKwh': 300.0,
        'annualSavingsCost': 45.0,
        'co2ReductionKg': 132.0,
      };
    }
  }

  // Helper methods
  String _createRecommendationPrompt(
    Map<String, dynamic> usageData,
    List<String> deviceTypes,
    int count,
  ) {
    return '''
Based on the following energy usage data and devices, provide exactly $count specific, practical energy-saving recommendations:

Usage Data:
${usageData.entries.map((e) => '- ${e.key}: ${e.value}').join('\n')}

Devices:
${deviceTypes.map((d) => '- $d').join('\n')}

Format each recommendation as a single, actionable item. Keep recommendations concise and specific to the user's situation.
''';
  }

  List<String> _parseRecommendations(String aiResponse) {
    // Split by numbered items, bullet points, or line breaks
    final recommendations =
        aiResponse
            .split(RegExp(r'\n\s*(?:\d+\.\s*|\-\s*|\*\s*)'))
            .where((s) => s.trim().isNotEmpty)
            .map((s) => s.trim())
            .toList();

    return recommendations.isEmpty
        ? ['No recommendations available.']
        : recommendations;
  }

  String _createSavingsPotentialPrompt(
    Map<String, dynamic> currentUsage,
    List<String> implementedRecommendations,
  ) {
    return '''
Calculate potential energy savings for a home with the following current energy usage:
${currentUsage.entries.map((e) => '- ${e.key}: ${e.value}').join('\n')}

The user has already implemented these energy-saving measures:
${implementedRecommendations.map((r) => '- $r').join('\n')}

Provide conservative estimates of:
1. Monthly energy savings (kWh)
2. Monthly cost savings (\$)
3. Annual energy savings (kWh)
4. Annual cost savings (\$)
5. CO2 emissions reduction (kg)

Format your response in JSON like this:
{
  "monthlySavingsKwh": number,
  "monthlySavingsCost": number,
  "annualSavingsKwh": number,
  "annualSavingsCost": number,
  "co2ReductionKg": number
}
''';
  }

  Map<String, dynamic> _parseSavingsPotential(String aiResponse) {
    try {
      // Extract JSON from the response - look for a JSON block
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(aiResponse);
      if (jsonMatch != null) {
        final jsonString = jsonMatch.group(0);
        return jsonDecode(jsonString!);
      }

      // If no JSON found, use regex to extract key numbers
      final monthlySavingsKwh =
          _extractNumber(
            aiResponse,
            r'monthly\s+energy\s+savings.*?(\d+\.?\d*)\s*kWh',
          ) ??
          20.0;
      final monthlySavingsCost =
          _extractNumber(
            aiResponse,
            r'monthly\s+cost\s+savings.*?\$?\s*(\d+\.?\d*)',
          ) ??
          3.0;
      final annualSavingsKwh =
          _extractNumber(
            aiResponse,
            r'annual\s+energy\s+savings.*?(\d+\.?\d*)\s*kWh',
          ) ??
          240.0;
      final annualSavingsCost =
          _extractNumber(
            aiResponse,
            r'annual\s+cost\s+savings.*?\$?\s*(\d+\.?\d*)',
          ) ??
          36.0;
      final co2Reduction =
          _extractNumber(
            aiResponse,
            r'CO2\s+emissions\s+reduction.*?(\d+\.?\d*)\s*kg',
          ) ??
          106.0;

      return {
        'monthlySavingsKwh': monthlySavingsKwh,
        'monthlySavingsCost': monthlySavingsCost,
        'annualSavingsKwh': annualSavingsKwh,
        'annualSavingsCost': annualSavingsCost,
        'co2ReductionKg': co2Reduction,
      };
    } catch (e) {
      debugPrint('Error parsing savings potential: $e');
      return {
        'monthlySavingsKwh': 20.0,
        'monthlySavingsCost': 3.0,
        'annualSavingsKwh': 240.0,
        'annualSavingsCost': 36.0,
        'co2ReductionKg': 106.0,
      };
    }
  }

  double? _extractNumber(String text, String pattern) {
    final match = RegExp(pattern, caseSensitive: false).firstMatch(text);
    if (match != null && match.groupCount >= 1) {
      return double.tryParse(match.group(1)!);
    }
    return null;
  }
}
