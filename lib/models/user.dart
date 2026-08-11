enum UserRole { systemAdmin, companyAdmin, countStaff }

UserRole userRoleFromString(String value) {
  switch (value) {
    case 'system_admin':
      return UserRole.systemAdmin;
    case 'company_admin':
      return UserRole.companyAdmin;
    case 'count_staff':
      return UserRole.countStaff;
    default:
      throw ArgumentError('Bilinmeyen rol: $value');
  }
}

class AppUser {
  final int id;
  final String name;
  final String username;
  final UserRole role;
  final int? companyId;

  AppUser({
    required this.id,
    required this.name,
    required this.username,
    required this.role,
    this.companyId,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as int,
      name: json['name'] as String,
      username: json['username'] as String,
      role: userRoleFromString(json['role'] as String),
      companyId: json['company_id'] as int?,
    );
  }
}
