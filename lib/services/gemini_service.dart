import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class GeminiService {
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-lite:generateContent';
  final String _apiKey;

  GeminiService({required String apiKey}) : _apiKey = apiKey;

  Future<String> generateContent({
    required String prompt,
    String systemPrompt = '',
    int maxTokens = 300,
    double temperature = 0.7,
  }) async {
    try {
      // Gemini API v1beta does not support 'system' role. Prepend systemPrompt to user prompt if provided.
      String fullPrompt = systemPrompt.isNotEmpty ? ' A$systemPrompt\n$prompt' : prompt;
      final List<Map<String, dynamic>> contents = [
        {'role': 'user', 'parts': [{'text': fullPrompt}]},
      ];

      final response = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': contents,
          'generationConfig': {
            'maxOutputTokens': maxTokens,
            'temperature': temperature,
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
        if (text != null && text is String) {
          return text;
        } else {
          throw Exception('No text found in Gemini response');
        }
      } else {
        debugPrint('Gemini API Error: \\${response.statusCode}: \\${response.body}');
        throw Exception('Failed to get response: \\${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Exception in Gemini service: $e');
      throw Exception('Error communicating with Gemini API: $e');
    }
  }
}
