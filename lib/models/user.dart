class User {
  final String username;
  final String email;
  final int roleId;
  final bool changePasswordRequired;

  User({
    required this.username,
    required this.email,
    required this.roleId,
    required this.changePasswordRequired,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      roleId: json['role_id'] ?? json['roleId'] ?? 0,
      changePasswordRequired: json['change_password_required'] ?? false,
    );
  }
} 