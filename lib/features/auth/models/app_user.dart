class AppUser {
  final String id;
  final String email;
  final String? fullName;
  final String? avatarUrl;
  final String? phoneNumber;
  final DateTime? dateOfBirth;
  final String? address;
  final String? country;
  final String? currency;
  final DateTime createdAt;

  AppUser({
    required this.id,
    required this.email,
    this.fullName,
    this.avatarUrl,
    this.phoneNumber,
    this.dateOfBirth,
    this.address,
    this.country,
    this.currency,
    required this.createdAt,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    final metadata = json['user_metadata'] as Map<String, dynamic>?;
    final customAvatar = metadata?['custom_avatar_url'] as String?;
    final defaultAvatar = json['avatar_url'] as String?;

    return AppUser(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String?,
      avatarUrl: (customAvatar != null && customAvatar.isNotEmpty)
          ? customAvatar
          : defaultAvatar,
      phoneNumber: json['phone_number'] as String?,
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.parse(json['date_of_birth'] as String)
          : null,
      address: json['address'] as String?,
      country: json['country'] as String?,
      currency: json['currency'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'phone_number': phoneNumber,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'address': address,
      'country': country,
      'currency': currency,
      'created_at': createdAt.toIso8601String(),
    };
  }

  AppUser copyWith({
    String? id,
    String? email,
    String? fullName,
    String? avatarUrl,
    String? phoneNumber,
    DateTime? dateOfBirth,
    String? address,
    String? country,
    String? currency,
    DateTime? createdAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      address: address ?? this.address,
      country: country ?? this.country,
      currency: currency ?? this.currency,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
