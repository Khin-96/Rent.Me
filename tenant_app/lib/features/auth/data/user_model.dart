class UserModel {
  final String id;
  final String email;
  final String name;
  final String role;
  final String? phone;
  final String? avatarUrl;
  final bool isVerified;
  final bool verificationBadge;

  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.phone,
    this.avatarUrl,
    required this.isVerified,
    required this.verificationBadge,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      role: json['role'] as String,
      phone: json['phone'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      isVerified: json['isVerified'] as bool? ?? false,
      verificationBadge: json['verificationBadge'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'role': role,
        'phone': phone,
        'avatarUrl': avatarUrl,
        'isVerified': isVerified,
        'verificationBadge': verificationBadge,
      };
}
