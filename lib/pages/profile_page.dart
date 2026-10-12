
import 'package:flutter/material.dart';

import '../models/app_user.dart';
import 'login_page.dart';

class ProfilePage extends StatelessWidget {
  final AppUser user;

  const ProfilePage({
    super.key,
    required this.user,
  });

  void _logout(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Konfirmasi Logout'),
          content: const Text(
            'Apakah kamu yakin ingin keluar dari akun ini?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();

                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute<void>(
                    builder: (_) => const LoginPage(),
                  ),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Keluar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Saya'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),

              const CircleAvatar(
                radius: 52,
                backgroundColor: Color(0xFFE9DDD1),
                child: Icon(
                  Icons.person_rounded,
                  size: 60,
                  color: Color(0xFF6F4E37),
                ),
              ),

              const SizedBox(height: 16),

              Text(
                user.fullName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                user.roleName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF6F4E37),
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 28),

              const Text(
                'Informasi Akun',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 14),

              _buildInfoTile(
                icon: Icons.badge_outlined,
                title: 'Nama Lengkap',
                value: user.fullName,
              ),

              _buildInfoTile(
                icon: Icons.person_outline,
                title: 'Username',
                value: user.username,
              ),

              _buildInfoTile(
                icon: Icons.work_outline,
                title: 'Role',
                value: user.roleName,
              ),

              _buildInfoTile(
                icon: Icons.verified_user_outlined,
                title: 'Status Akun',
                value: user.isActive ? 'Aktif' : 'Nonaktif',
              ),

              const SizedBox(height: 28),

              ElevatedButton.icon(
                onPressed: () => _logout(context),
                icon: const Icon(Icons.logout),
                label: const Text('Keluar dari Akun'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(
          color: Color(0xFFE9E1D8),
        ),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: const Color(0xFF6F4E37),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black54,
          ),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }
}
