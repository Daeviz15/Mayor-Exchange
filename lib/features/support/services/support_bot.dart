import '../models/faq_item.dart';

/// Rule-based Support Bot Service
/// Provides automated responses based on keyword matching
class SupportBot {
  /// Get bot response for a user query
  static BotResponse getResponse(String query) {
    if (query.trim().isEmpty) {
      return BotResponse(
        message: 'How can I help you today? Try asking about:',
        suggestions: [
          'Transaction status',
          'Gift card rates',
          'Payment delays',
          'Filing a dispute',
        ],
      );
    }

    final lowerQuery = query.toLowerCase();

    // Check for escalation keywords first
    if (_needsEscalation(lowerQuery)) {
      return BotResponse(
        message:
            'I understand you need to speak with our support team. Let me connect you with a human agent who can help you better.',
        needsEscalation: true,
        escalationReason: _getEscalationReason(lowerQuery),
      );
    }

    // Find matching FAQ items
    final matches = _findMatches(lowerQuery);

    if (matches.isEmpty) {
      return BotResponse(
        message:
            'I\'m not sure I understand. Could you try rephrasing your question, or choose from these common topics:',
        suggestions: [
          'Check transaction status',
          'Gift card rates',
          'Payment not received',
          'File a dispute',
        ],
      );
    }

    // Return the best match
    final bestMatch = matches.first;
    final otherTopics = matches.skip(1).take(2).map((m) => m.question).toList();

    return BotResponse(
      message: bestMatch.answer,
      relatedQuestions: otherTopics,
      faqId: bestMatch.id,
    );
  }

  /// Find FAQ items matching the query
  static List<FaqItem> _findMatches(String lowerQuery) {
    final scored = <FaqItem, int>{};

    for (final faq in FaqData.items) {
      int score = 0;

      // Check keywords
      for (final keyword in faq.keywords) {
        if (lowerQuery.contains(keyword.toLowerCase())) {
          score += 10;
        }
      }

      // Check question text
      final questionWords = faq.question.toLowerCase().split(' ');
      for (final word in questionWords) {
        if (word.length > 3 && lowerQuery.contains(word)) {
          score += 5;
        }
      }

      // Add priority boost
      score += faq.priority;

      if (score > 0) {
        scored[faq] = score;
      }
    }

    // Sort by score descending
    final sorted = scored.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.map((e) => e.key).toList();
  }

  /// Check if query indicates need for human escalation
  static bool _needsEscalation(String lowerQuery) {
    const escalationKeywords = [
      'speak to human',
      'talk to agent',
      'customer service',
      'real person',
      'manager',
      'urgent',
      'emergency',
      'stolen',
      'fraud',
      'scam',
      'legal',
      'lawyer',
      'police',
    ];

    for (final keyword in escalationKeywords) {
      if (lowerQuery.contains(keyword)) {
        return true;
      }
    }
    return false;
  }

  /// Get escalation reason
  static String _getEscalationReason(String lowerQuery) {
    if (lowerQuery.contains('fraud') ||
        lowerQuery.contains('scam') ||
        lowerQuery.contains('stolen')) {
      return 'security_concern';
    }
    if (lowerQuery.contains('urgent') || lowerQuery.contains('emergency')) {
      return 'urgent_request';
    }
    if (lowerQuery.contains('legal') ||
        lowerQuery.contains('lawyer') ||
        lowerQuery.contains('police')) {
      return 'legal_matter';
    }
    return 'human_requested';
  }

  /// Get greeting message
  static String getGreeting() {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : (hour < 18 ? 'Good afternoon' : 'Good evening');
    return '$greeting! I\'m here to help you with any questions about Mayor Exchange. How can I assist you today?';
  }
}

/// Bot Response Model
class BotResponse {
  final String message;
  final List<String> suggestions;
  final List<String> relatedQuestions;
  final bool needsEscalation;
  final String? escalationReason;
  final String? faqId;

  BotResponse({
    required this.message,
    this.suggestions = const [],
    this.relatedQuestions = const [],
    this.needsEscalation = false,
    this.escalationReason,
    this.faqId,
  });
}
