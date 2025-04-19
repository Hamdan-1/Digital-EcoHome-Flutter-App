import 'package:flutter/foundation.dart';
import 'gemini_service.dart';

class AiService {
  final GeminiService _geminiService;

  // Default system prompt focused on energy conservation and eco-home assistance
  static const String defaultSystemPrompt = '''
You are EcoAssistant, an AI for smart home energy efficiency.
Provide concise, actionable tips to reduce energy use and costs.
Include approximate savings when possible.
Keep responses clear and to the point.
''';

  AiService({required String apiKey})
    : _geminiService = GeminiService(apiKey: apiKey);

  /// Generate a response for the AI chat feature (user chat only)
  Future<String> generateChatResponse(String userMessage) async {
    try {
      return await _geminiService.generateContent(
        prompt: userMessage,
        systemPrompt: defaultSystemPrompt,
        temperature: 0.7,
      );
    } catch (e) {
      debugPrint('Error in AI chat: $e');
      return 'I apologize, but I encountered an issue while processing your request. Please try again later.';
    }
  }
}
