import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../services/support_bot.dart';

/// Support Chat Screen with Bot
/// Provides automated support with FAQ-based responses
class SupportChatScreen extends StatefulWidget {
  const SupportChatScreen({super.key});

  @override
  State<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends State<SupportChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    // Add bot greeting
    _addBotMessage(SupportBot.getGreeting());
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addBotMessage(String message,
      {List<String>? suggestions, bool isEscalation = false}) {
    setState(() {
      _messages.add(_ChatMessage(
        text: message,
        isUser: false,
        suggestions: suggestions ?? [],
        isEscalation: isEscalation,
      ));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;

    // Add user message
    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _isTyping = true;
    });
    _messageController.clear();
    _scrollToBottom();

    // Simulate bot thinking time
    Future.delayed(const Duration(milliseconds: 800), () {
      final response = SupportBot.getResponse(text);

      setState(() => _isTyping = false);

      _addBotMessage(
        response.message,
        suggestions: response.suggestions.isNotEmpty
            ? response.suggestions
            : response.relatedQuestions,
        isEscalation: response.needsEscalation,
      );

      if (response.needsEscalation) {
        // Show escalation dialog after delay
        Future.delayed(const Duration(seconds: 1), () {
          _showEscalationDialog(response.escalationReason);
        });
      }
    });
  }

  void _showEscalationDialog(String? reason) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: const Text('Connect with Support',
            style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          'Would you like to connect with a human support agent? They will be able to assist you further.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Not Now'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'Support request submitted. We\'ll be in touch soon!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange),
            child: const Text('Connect Now',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundCard,
        title: const Text('Support',
            style: TextStyle(color: AppColors.textPrimary)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isTyping) {
                  return _buildTypingIndicator();
                }
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),

          // Input
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.backgroundCard,
              border: Border(top: BorderSide(color: Colors.white10)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(color: Colors.white),
                      onSubmitted: _sendMessage,
                      decoration: InputDecoration(
                        hintText: 'Ask a question...',
                        hintStyle: TextStyle(color: AppColors.textSecondary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: AppColors.backgroundDark,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _sendMessage(_messageController.text),
                    icon:
                        const Icon(Icons.send, color: AppColors.primaryOrange),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(_ChatMessage message) {
    return Column(
      crossAxisAlignment:
          message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(12),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.8,
          ),
          decoration: BoxDecoration(
            color: message.isUser
                ? AppColors.primaryOrange
                : (message.isEscalation
                    ? Colors.orange.shade900
                    : AppColors.backgroundCard),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(message.isUser ? 16 : 4),
              bottomRight: Radius.circular(message.isUser ? 4 : 16),
            ),
          ),
          child: Text(
            message.text,
            style: TextStyle(
              color: message.isUser ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
        // Suggestions/Quick Replies
        if (!message.isUser && message.suggestions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: message.suggestions.map((suggestion) {
                return GestureDetector(
                  onTap: () => _sendMessage(suggestion),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.primaryOrange),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      suggestion,
                      style: const TextStyle(
                          color: AppColors.primaryOrange, fontSize: 12),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDot(0),
            _buildDot(1),
            _buildDot(2),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: AppColors.textSecondary,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final List<String> suggestions;
  final bool isEscalation;

  _ChatMessage({
    required this.text,
    required this.isUser,
    this.suggestions = const [],
    this.isEscalation = false,
  });
}
