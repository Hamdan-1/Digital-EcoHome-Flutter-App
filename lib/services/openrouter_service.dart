import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class OpenRouterService {
  static const String _baseUrl =
      'https://openrouter.ai/api/v1/chat/completions';
  final String _apiKey;

  OpenRouterService({required String apiKey}) : _apiKey = apiKey;
  Future<Map<String, dynamic>> generateCompletion({
    required String prompt,
    String model = 'meta-llama/llama-3.2-1b-instruct',
    String systemPrompt = '',
    int maxTokens = 300,
    double temperature = 0.7,
  }) async {
    try {
      final messages = <Map<String, dynamic>>[];

      if (systemPrompt.isNotEmpty) {
        messages.add({'role': 'system', 'content': systemPrompt});
      }

      messages.add({'role': 'user', 'content': prompt});

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
          'HTTP-Referer':
              'digital-ecohome-app.com', // Replace with your actual URL
          'X-Title': 'Digital EcoHome',
        },
        body: jsonEncode({
          'model': model,
          'messages': messages,
          'max_tokens': maxTokens,
          'temperature': temperature,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        debugPrint(
          'OpenRouter API Error: ${response.statusCode}: ${response.body}',
        );
        throw Exception('Failed to get response: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Exception in OpenRouter service: $e');
      throw Exception('Error communicating with AI service: $e');
    }
  }

  Future<String> getTextCompletion({
    required String prompt,
    String model = 'meta-llama/llama-3.2-1b-instruct',
    String systemPrompt = '',
    int maxTokens = 300,
    double temperature = 0.7,
  }) async {
    try {
      final response = await generateCompletion(
        prompt: prompt,
        model: model,
        systemPrompt: systemPrompt,
        maxTokens: maxTokens,
        temperature: temperature,
      );

      return response['choices'][0]['message']['content'] as String;
    } catch (e) {
      debugPrint('Error getting text completion: $e');
      return 'Sorry, I encountered an error while processing your request.';
    }
  }
}
