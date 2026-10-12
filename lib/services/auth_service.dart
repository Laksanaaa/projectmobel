
import '../models/app_user.dart';

class AuthService {
  // Akun contoh untuk pengujian lokal.
  // Jangan gunakan penyimpanan password seperti ini
  // untuk aplikasi yang dipakai secara nyata.
  final List<_DemoAccount> _accounts = [
    _DemoAccount(
      user: const AppUser(
        id: '1',
        username: 'manager',
        fullName: 'Manager Café',
        role: UserRole.manager,
      ),
      password: 'manager123',
    ),
    _DemoAccount(
      user: const AppUser(
        id: '2',
        username: 'akuntan',
        fullName: 'Akuntan Café',
        role: UserRole.akuntan,
      ),
      password: 'akuntan123',
    ),
    _DemoAccount(
      user: const AppUser(
        id: '3',
        username: 'karyawan',
        fullName: 'Karyawan Café',
        role: UserRole.karyawan,
      ),
      password: 'karyawan123',
    ),
  ];

  Future<AppUser?> login({
    required String username,
    required String password,
  }) async {
    final normalizedUsername = username.trim();

    for (final account in _accounts) {
      if (account.user.username == normalizedUsername &&
          account.password == password &&
          account.user.isActive) {
        return account.user;
      }
    }

    return null;
  }
}

class _DemoAccount {
  final AppUser user;
  final String password;

  const _DemoAccount({
    required this.user,
    required this.password,
  });
}
