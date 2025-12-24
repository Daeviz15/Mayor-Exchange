enum TransactionType {
  buyCrypto('buy_crypto'),
  sellCrypto('sell_crypto'),
  buyGiftCard('buy_giftcard'),
  sellGiftCard('sell_giftcard'),
  deposit('deposit'),
  withdrawal('withdrawal');

  final String value;
  const TransactionType(this.value);

  factory TransactionType.fromString(String value) {
    return TransactionType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => throw Exception('Unknown TransactionType: $value'),
    );
  }
}

enum TransactionStatus {
  pending('pending'),
  claimed('claimed'),
  paymentPending('payment_pending'), // Added
  verificationPending('verification_pending'), // Added
  completed('completed'),
  rejected('rejected'),
  cancelled('cancelled');

  final String value;
  const TransactionStatus(this.value);

  factory TransactionStatus.fromString(String value) {
    return TransactionStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => throw Exception('Unknown TransactionStatus: $value'),
    );
  }

  bool get isActive =>
      this != completed && this != rejected && this != cancelled;
}

class TransactionModel {
  final String id;
  final String userId;
  final String? adminId;
  final TransactionType type;
  final TransactionStatus status;
  final double amountFiat;
  final double? amountCrypto;
  final String currencyPair;
  final String? proofImagePath;
  final Map<String, dynamic> details;
  final DateTime createdAt;
  final DateTime updatedAt;

  TransactionModel({
    required this.id,
    required this.userId,
    this.adminId,
    required this.type,
    required this.status,
    required this.amountFiat,
    this.amountCrypto,
    required this.currencyPair,
    required this.details,
    this.proofImagePath,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      adminId: json['admin_id'] as String?,
      type: TransactionType.fromString(json['type'] as String),
      status: TransactionStatus.fromString(json['status'] as String),
      amountFiat: (json['amount_fiat'] as num).toDouble(),
      amountCrypto: (json['amount_crypto'] as num?)?.toDouble(),
      currencyPair: json['currency_pair'] as String,
      details: json['details'] as Map<String, dynamic>,
      proofImagePath: json['proof_image_path'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'admin_id': adminId,
      'type': type.value,
      'status': status.value,
      'amount_fiat': amountFiat,
      'amount_crypto': amountCrypto,
      'currency_pair': currencyPair,
      'details': details,
      'proof_image_path': proofImagePath,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  TransactionModel copyWith({
    String? id,
    String? userId,
    String? adminId,
    TransactionType? type,
    TransactionStatus? status,
    double? amountFiat,
    double? amountCrypto,
    String? currencyPair,
    Map<String, dynamic>? details,
    String? proofImagePath,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      adminId: adminId ?? this.adminId,
      type: type ?? this.type,
      status: status ?? this.status,
      amountFiat: amountFiat ?? this.amountFiat,
      amountCrypto: amountCrypto ?? this.amountCrypto,
      currencyPair: currencyPair ?? this.currencyPair,
      details: details ?? this.details,
      proofImagePath: proofImagePath ?? this.proofImagePath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
