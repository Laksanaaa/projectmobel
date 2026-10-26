enum UserRole { manager, akuntan, karyawan }

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

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'].toString(),
      username: json['username'] as String,
      fullName: json['full_name'] as String,
      role: UserRole.values.firstWhere(
        (item) => item.name == json['role'],
        orElse: () => UserRole.karyawan,
      ),
      isActive:
          json['is_active'] == true ||
          json['is_active'] == 1 ||
          json['is_active'] == '1',
      token: json['token'] as String? ?? '',
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

  // Menambahkan toJson() yang mengarah ke toMap()
  Map<String, dynamic> toJson() => toMap();
}
