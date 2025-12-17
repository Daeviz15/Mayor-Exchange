class KycRequest {
  final String id;
  final String userId;
  final String status; // 'pending', 'in_progress', 'verified', 'rejected'
  final String? identityDocUrl;
  final String? addressDocUrl;
  final String? selfieUrl;
  final String? adminNote;
  final DateTime createdAt;
  final DateTime updatedAt;

  const KycRequest({
    required this.id,
    required this.userId,
    required this.status,
    this.identityDocUrl,
    this.addressDocUrl,
    this.selfieUrl,
    this.adminNote,
    required this.createdAt,
    required this.updatedAt,
  });

  factory KycRequest.fromJson(Map<String, dynamic> json) {
    return KycRequest(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      status: json['status'] as String,
      identityDocUrl: json['identity_doc_url'] as String?,
      addressDocUrl: json['address_doc_url'] as String?,
      selfieUrl: json['selfie_url'] as String?,
      adminNote: json['admin_note'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'status': status,
      'identity_doc_url': identityDocUrl,
      'address_doc_url': addressDocUrl,
      'selfie_url': selfieUrl,
      'admin_note': adminNote,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  KycRequest copyWith({
    String? id,
    String? userId,
    String? status,
    String? identityDocUrl,
    String? addressDocUrl,
    String? selfieUrl,
    String? adminNote,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return KycRequest(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      status: status ?? this.status,
      identityDocUrl: identityDocUrl ?? this.identityDocUrl,
      addressDocUrl: addressDocUrl ?? this.addressDocUrl,
      selfieUrl: selfieUrl ?? this.selfieUrl,
      adminNote: adminNote ?? this.adminNote,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
