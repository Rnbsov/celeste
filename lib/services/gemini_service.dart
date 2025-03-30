import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_gemini/flutter_gemini.dart';

class GeminiService {
  static late Gemini _gemini;
  static bool _isInitialized = false;

  // Initialize Gemini with your API key
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'] ?? "";

      if (apiKey.isEmpty) {
        throw Exception('Gemini API key not found in environment variables');
      }

      // Initialize the Gemini instance
      Gemini.init(apiKey: apiKey);
      _gemini = Gemini.instance;

      _isInitialized = true;
      debugPrint('Gemini initialized successfully');
    } catch (e) {
      debugPrint('Error initializing Gemini: $e');
      rethrow;
    }
  }

  // Get a response from Gemini's garden assistant model
  static Future<String> getGardenAssistantResponse(String userMessage) async {
    try {
      debugPrint('Sending to Gemini: $userMessage');

      if (!_isInitialized) {
        await initialize();
      }

      final prompt = '''
You are an expert garden assistant who helps users care for their plants.
Provide helpful, concise advice about gardening, plant care, and growing.
Focus on practical tips and solutions to common plant problems.
If asked about anything unrelated to plants or gardening, politely redirect
the conversation back to plant care topics.
Keep responses under 150 words.

User question: $userMessage
''';

      final result = await _gemini.prompt(parts: [Part.text(prompt)]);

      final responseText =
          result?.output ??
          "I'm having trouble connecting to my plant database right now. Could you try again in a moment?";

      debugPrint('Gemini response: $responseText');

      return responseText;
    } catch (e) {
      debugPrint('Error getting response from Gemini: $e');
      return "I'm having trouble connecting to my plant database right now. Could you try again in a moment?";
    }
  }

  // For chat conversations (maintains history)
  static Future<String> chatWithGardener(
    List<Content> history,
    String userMessage,
  ) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      // Add system prompt as first message if history is empty
      if (history.isEmpty) {
        history.add(
          Content(
            parts: [
              Parts(
                text:
                    '''You are an expert garden assistant who helps users care for their plants.
Provide helpful, concise advice about gardening, plant care, and growing.
Focus on practical tips and solutions to common plant problems.
Keep responses under 150 words.''',
              ),
            ],
            role: 'model',
          ),
        );
      }

      // Add user message
      history.add(Content(parts: [Parts(text: userMessage)], role: 'user'));

      final response = await _gemini.chat(history);

      // Add response to history
      if (response?.content != null) {
        history.add(response!.content!);
      }

      final parts = response?.content?.parts;
      final responseText =
          (parts != null && parts.isNotEmpty && parts.first is Parts)
              ? (parts.first as Parts).text
              : "I'm having trouble with our conversation. Let's try again.";

      return responseText ??
          "I'm having trouble connecting to my plant database right now. Could you try again in a moment?";
    } catch (e) {
      debugPrint('Error in chat: $e');
      return "I'm having trouble connecting right now. Could you try again in a moment?";
    }
  }
}
