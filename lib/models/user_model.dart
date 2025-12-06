class UserModel {
  final String id;
  final String email;
  final String username;
  final String role; // 'user' or 'admin'

  UserModel({
    required this.id,
    required this.email,
    required this.username,
    required this.role,
  });

  factory UserModel.fromMap(String id, Map<String, dynamic> map) {
    return UserModel(
      id: id,
      email: map['email'] ?? '',
      username: map['username'] ?? '',
      role: map['role'] ?? 'user',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'username': username,
      'role': role,
    };
  }
}
