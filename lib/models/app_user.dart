
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
  final String token;

  const AppUser({
    required this.id,
    required this.username,
    required this.fullName,
    required this.role,
    required this.token,
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
      isActive: map['is_active'] == true ||
          map['is_active'] == 1 ||
          map['is_active'] == '1',
      token: map['token'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'full_name': fullName,
      'role': role.name,
      'is_active': isActive,
      'token': token,
    };
  }
}
