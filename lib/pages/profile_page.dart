import 'package:flutter/material.dart';
import 'package:project/services/session_manager.dart';

import 'login_page.dart';
import '../models/app_user.dart';

class ProfilePage extends StatelessWidget {
  final AppUser user;

  const ProfilePage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil Saya')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Avatar Profil
            CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(
                'https://ui-avatars.com/api/?name=${user.username}&background=6F4E37&color=fff&size=256',
              ),
            ),
            const SizedBox(height: 12),
            Text(
              user.fullName,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(
              user.roleName,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const Divider(height: 40, thickness: 1),

            // Tampilan Pesan & Kesan Statis
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Saran & Kesan Mata Kuliah',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Kesan:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    '[Isi pesan dan kesan dari kamu dan temanmu di sini nanti]',
                  ),
                  SizedBox(height: 12),
                  Text('Saran:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('[Isi saran untuk mata kuliah di sini nanti]'),
                ],
              ),
            ),
            const Divider(height: 40, thickness: 1),

            // Tombol Logout
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await SessionManager.clearSession();
                  if (context.mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginPage(),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
