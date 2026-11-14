enum UserRole {
  tourist('tourist', 'Traveler'),
  admin('admin', 'Curator');

  const UserRole(this.apiValue, this.displayName);

  final String apiValue;
  final String displayName;

  static UserRole fromApi(String? value) {
    return switch (value) {
      'admin' => UserRole.admin,
      _ => UserRole.tourist,
    };
  }
}

class User {
  const User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String email;
  final String fullName;
  final UserRole role;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory User.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final email = json['email'];
    final fullName = json['fullName'];
    final role = json['role'];

    if (id is! num || email is! String || fullName is! String) {
      throw const FormatException('The user payload is incomplete.');
    }

    return User(
      id: id.toInt(),
      email: email,
      fullName: fullName,
      role: UserRole.fromApi(role is String ? role : null),
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  static DateTime? _parseDate(Object? value) {
    return value is String ? DateTime.tryParse(value) : null;
  }
}
