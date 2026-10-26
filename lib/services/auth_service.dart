import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/app_user.dart';

class AuthService {
  Future<AppUser?> login({
    required String username,
    required String password,
  }) async {
    final normalizedUsername = username.trim();

    // Validasi input sebelum mengirim permintaan ke server.
    if (normalizedUsername.isEmpty || password.isEmpty) {
      throw const AuthException('Username dan password wajib diisi.');
    }

    try {
      final response = await http
          .post(
            Uri.parse(ApiConfig.loginUrl),
            headers: {
              'Content-Type': 'application/json; charset=UTF-8',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'username': normalizedUsername,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 15));

      // Pastikan respons server berupa JSON yang valid.
      final dynamic decoded = jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        throw const AuthException('Format respons dari server tidak valid.');
      }

      // Username/password salah atau akun tidak aktif.
      if (response.statusCode == 401) {
        return null;
      }

      // Tangani respons HTTP selain 200.
      if (response.statusCode != 200) {
        final message = decoded['message'];

        throw AuthException(
          message is String ? message : 'Server gagal memproses login.',
        );
      }

      // Validasi struktur respons login.
      if (decoded['success'] != true ||
          decoded['data'] is! Map<String, dynamic>) {
        final message = decoded['message'];

        throw AuthException(
          message is String ? message : 'Respons login tidak sesuai format.',
        );
      }

      // Ubah data JSON menjadi objek AppUser.
      final userData = decoded['data'] as Map<String, dynamic>;
      final user = AppUser.fromJson(userData);

      // Jangan lanjutkan login jika akun tidak aktif.
      if (!user.isActive) {
        return null;
      }

      // Token wajib tersedia untuk mengakses API yang dilindungi.
      if (user.token.trim().isEmpty) {
        throw const AuthException(
          'Token login tidak ditemukan dari server. '
          'Periksa login.php.',
        );
      }

      return user;
    } on TimeoutException {
      throw const AuthException('Server terlalu lama merespons. Coba lagi.');
    } on http.ClientException {
      throw const AuthException(
        'Tidak dapat terhubung ke server. '
        'Periksa koneksi dan URL API.',
      );
    } on FormatException {
      throw const AuthException('Respons server bukan JSON yang valid.');
    }
  }
}

class AuthException implements Exception {
  final String message;

  const AuthException(this.message);

  @override
  String toString() => message;
}
