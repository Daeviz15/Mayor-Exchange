class AppUser {
  final String id;
  final String email;
  final String? firstName;
  final String? lastName;
  final DateTime createdAt;

  AppUser({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    required this.createdAt,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      email: json['email'] as String,
      firstName: json['full_name'] as String?,
      lastName: json['last_name'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'created_at': createdAt.toIso8601String(),
    };
  }

  AppUser copyWith({
    String? id,
    String? email,
    String? fullName,
    DateTime? createdAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: fullName ?? firstName,
      lastName: lastName ?? lastName,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
