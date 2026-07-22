/// 用户信息模型
class User {
  final String id;
  final String email;
  final String name;
  final String role;
  final bool mustResetPassword;

  const User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.mustResetPassword = false,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      mustResetPassword: json['mustResetPassword'] == 1 ||
          json['mustResetPassword'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'role': role,
        'mustResetPassword': mustResetPassword,
      };
}
