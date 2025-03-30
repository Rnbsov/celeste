import 'package:flutter/material.dart';
import 'package:myapp/services/gemini_service.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:async';
import '../services/gemini_service.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();

  bool _isListening = false;
  bool _isSpeaking = false;
  bool _isProcessing = false;
  String _recognizedText = "";

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _initTts();
    _initAI();

    // Add welcome message
    _addBotMessage(
      "Hi! I'm your garden assistant powered by AI. How can I help you today?",
    );
  }

  // Initialize OpenAI
  Future<void> _initAI() async {
    try {
      await GeminiService.initialize();
    } catch (e) {
      debugPrint('Failed to initialize Gemini AI: $e');
    }
  }

  // Initialize speech recognition
  Future<void> _initSpeech() async {
    try {
      debugPrint('Initializing speech recognition...');
      bool available = await _speech.initialize(
        onStatus: (status) {
          debugPrint('Speech status: $status');
          if (status == 'notListening') {
            setState(() {
              _isListening = false;
            });
          }
        },
        onError: (error) {
          debugPrint('Speech error: $error');
          setState(() {
            _isListening = false;
          });
          _showError("Speech recognition error: $error");
        },
        debugLogging: true,
      );

      debugPrint('Speech recognition available: $available');
      if (!available) {
        _showError("Speech recognition not available on this device");
      }
    } catch (e) {
      debugPrint('Exception during speech init: $e');
      _showError("Failed to initialize speech recognition: $e");
    }
  }

  // Initialize text to speech
  Future<void> _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.5);

    _flutterTts.setCompletionHandler(() {
      setState(() {
        _isSpeaking = false;
      });
    });
  }

  // Start listening to speech
  void _startListening() async {
    if (!_isListening) {
      _recognizedText = "";
      try {
        // Don't initialize again, use the already initialized instance
        bool available = await _speech.initialize();
        debugPrint('Speech available: $available');

        if (available) {
          setState(() {
            _isListening = true;
          });

          await _speech.listen(
            onResult: (result) {
              debugPrint('Speech result: ${result.recognizedWords}');
              setState(() {
                _recognizedText = result.recognizedWords;
                _textController.text = _recognizedText;
              });
            },
            listenFor: Duration(seconds: 30),
            pauseFor: Duration(seconds: 5),
            partialResults: true,
            onSoundLevelChange: (level) => debugPrint('Sound level: $level'),
            cancelOnError: true,
            listenMode: stt.ListenMode.confirmation,
          );
        } else {
          _showError("Speech recognition unavailable");
        }
      } catch (e) {
        debugPrint('Exception during listening: $e');
        _isListening = false;
        _showError("Failed to start listening: $e");
      }
    }
  }

  // Stop listening to speech
  void _stopListening() async {
    if (_isListening) {
      await _speech.stop();
      setState(() {
        _isListening = false;
        // If we have recognized text, send it
        if (_recognizedText.isNotEmpty) {
          _handleSubmit(_recognizedText);
          _textController.clear();
        }
      });
    }
  }

  // Speak text aloud
  Future<void> _speak(String text) async {
    if (_isSpeaking) {
      await _flutterTts.stop();
    }

    setState(() {
      _isSpeaking = true;
    });

    await _flutterTts.speak(text);
  }

  // Add a user message to the chat
  void _addUserMessage(String message) {
    setState(() {
      _messages.insert(0, ChatMessage(text: message, isUser: true));
    });
  }

  // Add a bot message to the chat
  void _addBotMessage(String message) {
    setState(() {
      _messages.insert(0, ChatMessage(text: message, isUser: false));
    });

    // Read the response aloud
    _speak(message);
  }

  // Show error message
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // Handle sending a message
  void _handleSubmit(String text) async {
    if (text.trim().isEmpty) return;

    _addUserMessage(text);

    // Clear text field
    _textController.clear();

    // Show processing state
    setState(() {
      _isProcessing = true;
    });

    try {
      // Get response from OpenAI instead of local logic
      final response = await GeminiService.getGardenAssistantResponse(text);

      setState(() {
        _isProcessing = false;
      });

      _addBotMessage(response);
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });

      _addBotMessage(
        "I'm having trouble connecting to my plant database. Let's try again later.",
      );

      _showError("Error getting response: $e");
    }
  }

  // Generate bot responses based on user input
  // This is a simple rule-based response system
  Future<String> _getResponseWithFallback(String userMessage) async {
    try {
      return await GeminiService.getGardenAssistantResponse(userMessage);
    } catch (e) {
      debugPrint('Error with OpenAI, using fallback: $e');
      return _getBotResponse(userMessage);
    }
  }

  // Replace the incomplete _getBotResponse method with this implementation:

  // Fallback bot response method for when API fails
  String _getBotResponse(String userMessage) {
    final lowercaseMessage = userMessage.toLowerCase();

    // Plant care responses
    if (lowercaseMessage.contains('water') ||
        lowercaseMessage.contains('watering')) {
      return "Most plants need consistent watering. Check the soil moisture level - water when the top inch feels dry. Be careful not to overwater as this can lead to root rot. For indoor plants, check twice a week, and for outdoor plants, monitor based on weather conditions.";
    }

    if (lowercaseMessage.contains('fertilize') ||
        lowercaseMessage.contains('nutrients') ||
        lowercaseMessage.contains('food')) {
      return "Most plants benefit from fertilizer during their growing season. For vegetables, use a balanced fertilizer every 3-4 weeks. Houseplants should be fertilized monthly during spring and summer, but less in fall and winter. Organic options include compost tea, worm castings, and fish emulsion.";
    }

    if (lowercaseMessage.contains('sunlight') ||
        lowercaseMessage.contains('light') ||
        lowercaseMessage.contains('sun')) {
      return "Different plants have different light requirements. Vegetables and fruiting plants typically need 6-8 hours of direct sunlight. Herbs can often manage with 4-6 hours. Many houseplants prefer bright, indirect light. Look for signs like stretching toward light sources or pale leaves if your plant needs more light.";
    }

    if (lowercaseMessage.contains('pest') ||
        lowercaseMessage.contains('insects') ||
        lowercaseMessage.contains('bug')) {
      return "For pest control, try natural remedies first like neem oil or insecticidal soap. Maintain good air circulation around plants and remove affected leaves promptly. You can also introduce beneficial insects like ladybugs or use sticky traps. Always inspect new plants before bringing them home.";
    }

    if (lowercaseMessage.contains('yellow') ||
        lowercaseMessage.contains('leaves') ||
        lowercaseMessage.contains('wilting')) {
      return "Yellow leaves can indicate several issues: overwatering, underwatering, nutrient deficiency, or insufficient light. Check the moisture level first - the soil should be damp but not soggy. Also check light conditions and consider if the plant needs nutrients. Brown leaf tips often indicate low humidity or salt buildup from fertilizer.";
    }

    if (lowercaseMessage.contains('soil') ||
        lowercaseMessage.contains('potting') ||
        lowercaseMessage.contains('dirt')) {
      return "Good soil is essential for healthy plants. Most plants prefer well-draining soil with organic matter. For indoor plants, use quality potting mix. For vegetables, garden soil amended with compost works well. Consider the specific needs of your plant - succulents need sandy soil while ferns prefer more organic matter.";
    }

    if (lowercaseMessage.contains('repot') ||
        lowercaseMessage.contains('transplant') ||
        lowercaseMessage.contains('pot')) {
      return "Repot plants when they become root bound or every 1-2 years. Choose a pot 1-2 inches larger than the current one with drainage holes. Spring is generally the best time to repot. Water the plant a day before to reduce shock, and handle roots gently during the process.";
    }

    // Plant types responses
    if (lowercaseMessage.contains('vegetable')) {
      return "Vegetables generally need 6-8 hours of sunlight, consistent watering, and regular feeding. Most grow best in well-draining soil enriched with compost. Common beginner-friendly vegetables include lettuce, radishes, and cherry tomatoes. Rotate crops yearly to prevent soil depletion and disease.";
    }

    if (lowercaseMessage.contains('herb')) {
      return "Herbs are generally low-maintenance plants that prefer well-draining soil. Most herbs need at least 4-6 hours of sunlight and moderate watering. Basil, mint, and chives are excellent for beginners. Many herbs actually produce more aromatic oils when slightly stressed, so don't overwater or overfertilize.";
    }

    if (lowercaseMessage.contains('fruit')) {
      return "Fruit plants often need full sun (6+ hours daily), consistent watering, and regular feeding. Many fruits require pollinators, so consider planting flowers nearby. Container-friendly fruits include strawberries, blueberries, and dwarf citrus varieties. Patience is key, as many fruit plants take years to produce.";
    }

    if (lowercaseMessage.contains('succulent') ||
        lowercaseMessage.contains('cactus')) {
      return "Succulents thrive on neglect! They need well-draining soil (cactus mix), infrequent watering (when soil is completely dry), and plenty of light. Common problems include overwatering and insufficient light. They're perfect for those who travel or forget to water plants regularly.";
    }

    if (lowercaseMessage.contains('indoor') ||
        lowercaseMessage.contains('houseplant')) {
      return "Indoor plants add life to your space while cleaning the air. Popular low-maintenance options include snake plants, pothos, and ZZ plants. Most prefer bright, indirect light and moderate watering when the top inch of soil is dry. Increase humidity with a pebble tray or humidifier for tropical varieties.";
    }

    // Seasonal advice
    if (lowercaseMessage.contains('winter') ||
        lowercaseMessage.contains('cold')) {
      return "Winter plant care involves reducing watering and fertilizing, as plants grow slower. Move houseplants away from cold drafts and provide humidity in heated homes. Protect outdoor plants with mulch around the base. Some plants may enter dormancy and drop leaves - this is normal, not a sign of death.";
    }

    if (lowercaseMessage.contains('summer') ||
        lowercaseMessage.contains('hot')) {
      return "Summer plant care often means more frequent watering, especially during heat waves. Water in the morning to reduce evaporation and fungal issues. Provide shade for sensitive plants during peak afternoon heat. Container plants may need daily watering in very hot weather.";
    }

    // General inquiries
    if (lowercaseMessage.contains('hello') || lowercaseMessage.contains('hi')) {
      return "Hello there! I'm your garden assistant. What would you like to know about your plants today? I can help with watering advice, pest control, plant selection, or troubleshooting common plant problems.";
    }

    if (lowercaseMessage.contains('thanks') ||
        lowercaseMessage.contains('thank you')) {
      return "You're welcome! Happy gardening! Feel free to ask if you need more plant advice in the future.";
    }

    if (lowercaseMessage.contains('beginner') ||
        lowercaseMessage.contains('start') ||
        lowercaseMessage.contains('new to') ||
        lowercaseMessage.contains('first time')) {
      return "For beginners, start with hardy plants like snake plants, pothos, herbs, or radishes. Choose the right location with appropriate light, use good quality soil, and don't overwater. Begin with a few plants and expand as you gain confidence. Remember that even experienced gardeners lose plants sometimes!";
    }

    // Default response
    return "I'm not sure about that specific plant question. Could you ask something about watering, fertilizing, light needs, pest control, or a specific type of plant? I'm here to help with all your gardening needs!";
  }

  Widget _buildAiIndicator() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.auto_awesome,
            size: 14,
            color: Theme.of(context).colorScheme.primary,
          ),
          SizedBox(width: 4),
          Text(
            "AI-Powered",
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Garden Assistant'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          // Toggle for TTS
          IconButton(
            icon: Icon(_isSpeaking ? Icons.volume_up : Icons.volume_off),
            onPressed: () {
              setState(() {
                if (_isSpeaking) {
                  _flutterTts.stop();
                  _isSpeaking = false;
                } else {
                  // Speak last bot message
                  for (var message in _messages) {
                    if (!message.isUser) {
                      _speak(message.text);
                      break;
                    }
                  }
                }
              });
            },
            tooltip: _isSpeaking ? 'Mute responses' : 'Speak responses',
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat messages area
          Expanded(
            child:
                _messages.isEmpty
                    ? _buildEmptyState(theme)
                    : ListView.builder(
                      padding: const EdgeInsets.all(8.0),
                      reverse: true, // Display from bottom to top
                      itemCount: _messages.length,
                      itemBuilder: (_, index) => _messages[index],
                    ),
          ),

          // Processing indicator
          if (_isProcessing)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    children: [
                      Text(
                        "AI thinking",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      _buildLoadingDots(),
                    ],
                  ),
                ],
              ),
            ),

          // Speech recognition indicator
          if (_isListening)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.mic, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    "Listening...",
                    style: TextStyle(color: theme.colorScheme.primary),
                  ),
                ],
              ),
            ),

          // Input area
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  offset: const Offset(0, -2),
                  blurRadius: 4,
                  color: Colors.black.withOpacity(0.1),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  // Message input field
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        hintText: 'Ask about your plants...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surface,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      onSubmitted: (text) => _handleSubmit(text),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Voice input button
                  GestureDetector(
                    onTapDown: (_) => _startListening(),
                    onTapUp: (_) => _stopListening(),
                    onTapCancel: () => _stopListening(),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color:
                            _isListening
                                ? theme.colorScheme.primary
                                : theme.colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isListening ? Icons.mic : Icons.mic_none,
                        color:
                            _isListening
                                ? Colors.white
                                : theme.colorScheme.primary,
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Send button
                  IconButton(
                    icon: const Icon(Icons.send),
                    color: Theme.of(context).colorScheme.primary,
                    onPressed: () {
                      _handleSubmit(_textController.text);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Empty state widget
  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: theme.colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Ask me anything about your plants!',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 24),
          Text('Try asking:', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          _buildSuggestionChip('How often should I water my herbs?', theme),
          _buildSuggestionChip(
            'Why are my plant leaves turning yellow?',
            theme,
          ),
          _buildSuggestionChip('What vegetables are easy to grow?', theme),
        ],
      ),
    );
  }

  // Suggestion chip widget
  Widget _buildSuggestionChip(String text, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: ActionChip(
        avatar: Icon(Icons.chat, color: theme.colorScheme.primary, size: 18),
        label: Text(text),
        onPressed: () => _handleSubmit(text),
      ),
    );
  }

  // Add this method for animated dots:
  Widget _buildLoadingDots() {
    return Text(
      "...",
      style: TextStyle(
        color: Theme.of(context).colorScheme.primary,
        fontStyle: FontStyle.italic,
      ),
    );
  }
}

// Chat message bubble widget
class ChatMessage extends StatelessWidget {
  final String text;
  final bool isUser;

  const ChatMessage({super.key, required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) _buildAvatar(context),

          Flexible(
            child: Container(
              margin: EdgeInsets.only(
                left: isUser ? 64.0 : 8.0,
                right: isUser ? 8.0 : 64.0,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 10.0,
              ),
              decoration: BoxDecoration(
                color:
                    isUser
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                text,
                style: TextStyle(
                  color:
                      isUser
                          ? Colors.white
                          : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),

          if (isUser) const SizedBox(width: 8.0),
        ],
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    return CircleAvatar(
      backgroundColor: Theme.of(context).colorScheme.primary,
      child: const Icon(Icons.eco, color: Colors.white),
    );
  }
}
