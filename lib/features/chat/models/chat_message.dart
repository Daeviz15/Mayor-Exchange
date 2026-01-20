/// Chat Message Model
/// Represents a message in a transaction chat
class ChatMessage {
  final String id;
  final String transactionId;
  final String senderId;
  final String senderType; // 'user', 'admin', 'system'
  final String message;
  final List<String> attachments;
  final bool isRead;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.transactionId,
    required this.senderId,
    required this.senderType,
    required this.message,
    this.attachments = const [],
    this.isRead = false,
    required this.createdAt,
  });

  bool get isFromAdmin => senderType == 'admin';
  bool get isFromUser => senderType == 'user';
  bool get isSystemMessage => senderType == 'system';

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      transactionId: json['transaction_id'] as String,
      senderId: json['sender_id'] as String,
      senderType: json['sender_type'] as String,
      message: json['message'] as String,
      attachments: _parseAttachments(json['attachments']),
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  static List<String> _parseAttachments(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return [];
  }

  Map<String, dynamic> toJson() {
    return {
      'transaction_id': transactionId,
      'sender_id': senderId,
      'sender_type': senderType,
      'message': message,
      'attachments': attachments,
    };
  }
}
