/// FAQ Item Model
/// Represents a frequently asked question with its answer
class FaqItem {
  final String id;
  final String question;
  final String answer;
  final List<String> keywords;
  final String category;
  final int priority;

  const FaqItem({
    required this.id,
    required this.question,
    required this.answer,
    this.keywords = const [],
    this.category = 'general',
    this.priority = 0,
  });
}

/// Predefined FAQ data for the support bot
class FaqData {
  static const List<FaqItem> items = [
    // Transaction Status
    FaqItem(
      id: 'status_check',
      question: 'How do I check my transaction status?',
      answer:
          'Go to the History tab in the app, then tap on any transaction to view its full status and details.',
      keywords: ['status', 'check', 'transaction', 'history', 'track'],
      category: 'transactions',
      priority: 10,
    ),
    FaqItem(
      id: 'pending_time',
      question: 'How long do transactions take to process?',
      answer:
          'Most transactions are processed within 5-30 minutes during business hours. Gift card sales may take up to 24 hours for verification.',
      keywords: ['time', 'long', 'pending', 'wait', 'process', 'duration'],
      category: 'transactions',
      priority: 9,
    ),

    // Gift Cards
    FaqItem(
      id: 'gc_rates',
      question: 'What are the current gift card rates?',
      answer:
          'Gift card rates vary by brand and type (physical vs e-code). Check the Sell Gift Card section to see current rates for each card.',
      keywords: ['rate', 'rates', 'gift card', 'price', 'value'],
      category: 'gift_cards',
      priority: 8,
    ),
    FaqItem(
      id: 'gc_rejected',
      question: 'Why was my gift card rejected?',
      answer:
          'Gift cards may be rejected if: the code is invalid, already redeemed, the image is unclear, or the card is from an unsupported region. Please ensure your card is valid and unused.',
      keywords: ['rejected', 'declined', 'why', 'gift card', 'invalid'],
      category: 'gift_cards',
      priority: 7,
    ),

    // Payment
    FaqItem(
      id: 'payment_methods',
      question: 'What payment methods do you support?',
      answer:
          'We support bank transfers for all NGN payouts. Crypto withdrawals are also available for supported currencies.',
      keywords: ['payment', 'method', 'bank', 'transfer', 'payout'],
      category: 'payments',
      priority: 6,
    ),
    FaqItem(
      id: 'payment_delay',
      question: 'Why hasn\'t my payment arrived?',
      answer:
          'Bank transfers typically arrive within 1-24 hours depending on your bank. If your payment is delayed beyond this, please contact support with your transaction ID.',
      keywords: ['payment', 'delay', 'arrived', 'receive', 'bank'],
      category: 'payments',
      priority: 7,
    ),

    // Account
    FaqItem(
      id: 'kyc',
      question: 'Do I need to verify my identity?',
      answer:
          'KYC verification is optional but recommended. Verified users enjoy higher transaction limits and faster processing.',
      keywords: ['kyc', 'verify', 'identity', 'verification', 'document'],
      category: 'account',
      priority: 5,
    ),

    // Disputes
    FaqItem(
      id: 'dispute_file',
      question: 'How do I file a dispute?',
      answer:
          'To file a dispute, go to your transaction history, select the transaction, and tap "Open Chat" to speak with our support team. Provide any relevant evidence.',
      keywords: ['dispute', 'problem', 'issue', 'complain', 'help'],
      category: 'disputes',
      priority: 10,
    ),

    // Security
    FaqItem(
      id: 'security',
      question: 'Is my money safe?',
      answer:
          'Yes! We use bank-level encryption and secure storage for all transactions. Your funds are protected and we never store sensitive card details.',
      keywords: ['safe', 'secure', 'security', 'protect', 'trust'],
      category: 'security',
      priority: 6,
    ),
  ];
}
