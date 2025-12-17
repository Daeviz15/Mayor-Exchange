import 'transaction.dart';

class TransactionLog {
  final String id;
  final String transactionId;
  final String actorId;
  final TransactionStatus? previousStatus;
  final TransactionStatus newStatus;
  final String? note;
  final DateTime createdAt;

  TransactionLog({
    required this.id,
    required this.transactionId,
    required this.actorId,
    this.previousStatus,
    required this.newStatus,
    this.note,
    required this.createdAt,
  });

  factory TransactionLog.fromJson(Map<String, dynamic> json) {
    return TransactionLog(
      id: json['id'] as String,
      transactionId: json['transaction_id'] as String,
      actorId: json['actor_id'] as String,
      previousStatus: json['previous_status'] != null
          ? TransactionStatus.fromString(json['previous_status'] as String)
          : null,
      newStatus: TransactionStatus.fromString(json['new_status'] as String),
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'transaction_id': transactionId,
      'actor_id': actorId,
      'previous_status': previousStatus?.value,
      'new_status': newStatus.value,
      'note': note,
    };
  }
}
