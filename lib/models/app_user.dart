
enum UserRole {
  manager,
  akuntan,
  karyawan,
}

class AppUser {
  final String id;
  final String username;
  final String fullName;
  final UserRole role;
  final bool isActive;

  const AppUser({
    required this.id,
    required this.username,
    required this.fullName,
    required this.role,
    this.isActive = true,
  });

  String get roleName {
    switch (role) {
      case UserRole.manager:
        return 'Manager';
      case UserRole.akuntan:
        return 'Akuntan';
      case UserRole.karyawan:
        return 'Karyawan';
    }
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'].toString(),
      username: map['username'] as String,
      fullName: map['full_name'] as String,
      role: UserRole.values.firstWhere(
        (item) => item.name == map['role'],
        orElse: () => UserRole.karyawan,
      ),
      isActive: map['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'full_name': fullName,
      'role': role.name,
      'is_active': isActive,
    };
  }
}
