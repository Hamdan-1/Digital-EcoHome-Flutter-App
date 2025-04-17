import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../pages/chat_history_page.dart';
import 'package:provider/provider.dart';
import '../services/ai_service.dart';
import '../widgets/optimized_loading_indicator.dart'; // Import OptimizedLoadingIndicator

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({required this.text, required this.isUser, DateTime? timestamp})
    : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'text': text,
    'isUser': isUser,
    'timestamp': timestamp.toIso8601String(),
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    text: json['text'] as String,
    isUser: json['isUser'] as bool,
    timestamp: DateTime.parse(json['timestamp'] as String),
  );
}

class AiChatMenu extends StatefulWidget {
  const AiChatMenu({super.key});

  @override
  State<AiChatMenu> createState() => _AiChatMenuState();
}

class _AiChatMenuState extends State<AiChatMenu>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isComposing = false;
  bool _isLoading = false;

  // Predefined quick suggestions for energy saving topics
  final List<String> _quickSuggestions = [
    'How can I reduce my energy bill?',
    'Tips for saving energy with my appliances',
    'Smart home automation for energy efficiency',
    'Best practices for heating and cooling',
    'How to interpret my energy usage data',
  ];

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleSubmitted(String text, AiService aiService) {
    _textController.clear();

    // Don't allow empty messages
    if (text.trim().isEmpty) return;

    // Add the user message to the chat
    setState(() {
      _isComposing = false;
      _isLoading = true;
      _messages.add(ChatMessage(text: text, isUser: true));
    });

    // Scroll to the bottom
    _scrollToBottom();

    // Get response from AI
    aiService
        .generateChatResponse(text)
        .then((response) {
          setState(() {
            _isLoading = false;
            _messages.add(ChatMessage(text: response, isUser: false));
          });

          // Scroll to show the new message
          _scrollToBottom();
        })
        .catchError((error) {
          setState(() {
            _isLoading = false;
            _messages.add(
              ChatMessage(
                text: 'Sorry, I encountered an error. Please try again later.',
                isUser: false,
              ),
            );
          });

          // Scroll to show the error message
          _scrollToBottom();
        });
  }

  void _scrollToBottom() {
    // Add a slight delay to ensure the list has been built
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _saveSession() async {
    if (_messages.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final sessions = prefs.getStringList('chat_sessions') ?? [];
    final sessionJson = jsonEncode(_messages.map((m) => m.toJson()).toList());
    sessions.add(sessionJson);
    // keep only latest 5
    if (sessions.length > 5) {
      sessions.removeAt(0);
    }
    await prefs.setStringList('chat_sessions', sessions);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Chat session saved')));
  }

  Future<void> _openHistory() async {
    final result = await Navigator.push<List<ChatMessage>>(
      context,
      MaterialPageRoute(builder: (_) => const ChatHistoryPage()),
    );
    if (result != null) {
      setState(() {
        _messages.clear();
        _messages.addAll(result);
      });
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final theme = Theme.of(context);
    final aiService = Provider.of<AiService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('EcoAssistant AI Chat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'View chat history',
            onPressed: _openHistory,
          ),
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Save current chat',
            onPressed: _saveSession,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear chat history',
            onPressed: () {
              setState(() {
                _messages.clear();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Welcome message if chat is empty
          if (_messages.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                color: theme.colorScheme.surfaceContainerHighest,
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.eco_outlined,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Welcome to EcoAssistant!',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'I can help you with energy-saving tips, answer questions about sustainability, '
                        'and provide guidance on optimizing your home\'s energy efficiency.',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Try asking:',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            _quickSuggestions.map((suggestion) {
                              return ActionChip(
                                label: Text(suggestion),
                                avatar: const Icon(
                                  Icons.lightbulb_outline,
                                  size: 16,
                                ),
                                onPressed: () {
                                  _handleSubmitted(suggestion, aiService);
                                },
                              );
                            }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Chat messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(8.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessage(message, theme);
              },
            ),
          ),

          // Loading indicator
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  // Replace CircularProgressIndicator with OptimizedLoadingIndicator
                  OptimizedLoadingIndicator(
                    size: 24, // Match original SizedBox size
                    color: theme.colorScheme.secondary, // Use original color
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'EcoAssistant is thinking...',
                    style: TextStyle(
                      color: theme.colorScheme.secondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),

          // Divider before input field
          Divider(height: 1.0, color: theme.dividerColor),

          // Quick suggestions if there are messages
          if (_messages.isNotEmpty)
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final suggestion in _quickSuggestions)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ActionChip(
                        label: Text(
                          suggestion,
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                        onPressed: () {
                          _handleSubmitted(suggestion, aiService);
                        },
                      ),
                    ),
                ],
              ),
            ),

          // Message input field
          Container(
            decoration: BoxDecoration(color: theme.colorScheme.surface),
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    onChanged: (text) {
                      setState(() {
                        _isComposing = text.isNotEmpty;
                      });
                    },
                    onSubmitted: (text) {
                      _handleSubmitted(text, aiService);
                    },
                    decoration: InputDecoration(
                      hintText: 'Ask about energy savings...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24.0),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest
                          .withAlpha(
                            (0.5 * 255).round(),
                          ), // Corrected alpha calculation
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 10.0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8.0),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  child: IconButton(
                    icon: const Icon(Icons.send),
                    color:
                        _isComposing
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface.withAlpha(
                              (0.5 * 255).round(),
                            ),
                    onPressed:
                        _isComposing
                            ? () => _handleSubmitted(
                              _textController.text,
                              aiService,
                            )
                            : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(ChatMessage message, ThemeData theme) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar for AI messages
          if (!isUser)
            CircleAvatar(
              backgroundColor: theme.colorScheme.primary,
              child: const Icon(Icons.eco, color: Colors.white, size: 18),
            ),

          const SizedBox(width: 8.0),

          // Message content
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 10.0,
              ),
              decoration: BoxDecoration(
                color:
                    isUser
                        ? theme.colorScheme.primary.withAlpha(
                          (0.1 * 255).round(),
                        )
                        : theme.colorScheme.secondaryContainer.withAlpha(
                          (0.3 * 255).round(),
                        ),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16.0),
                  topRight: const Radius.circular(16.0),
                  bottomLeft: Radius.circular(isUser ? 16.0 : 0.0),
                  bottomRight: Radius.circular(isUser ? 0.0 : 16.0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Message text
                  Text(
                    message.text,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),

                  // Timestamp
                  const SizedBox(height: 4.0),
                  Text(
                    _formatTimestamp(message.timestamp),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(
                        (0.6 * 255).round(),
                      ),
                      fontSize: 10.0,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 8.0),

          // Avatar for user messages (empty space for alignment)
          if (isUser)
            const CircleAvatar(
              backgroundColor: Colors.transparent,
              child: Icon(Icons.person, color: Colors.transparent),
            ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(
      timestamp.year,
      timestamp.month,
      timestamp.day,
    );

    final time =
        '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';

    if (messageDate == today) {
      return 'Today, $time';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday, $time';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}, $time';
    }
  }

  @override
  bool get wantKeepAlive => true;
}
