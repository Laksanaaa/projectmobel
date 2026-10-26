import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user.dart';

class SessionManager {
  static const String _keyUser = 'user_session';
  static const String _keyLoginTime = 'login_timestamp';
  static const int _sessionDurationMinutes = 5; // Durasi batas waktu 5 menit

  // 1. Simpan Sesi Login
  static Future<void> saveSession(AppUser user) async {
    final prefs = await SharedPreferences.getInstance();

    // Mengubah AppUser menjadi JSON string menggunakan toMap()
    String userJson = jsonEncode(user.toMap());
    await prefs.setString(_keyUser, userJson);

    // Simpan waktu saat login (Waktu lokal HP)
    await prefs.setString(_keyLoginTime, DateTime.now().toIso8601String());
  }

  // 2. Ambil Sesi (Sekaligus Cek Apakah Masih Valid)
  static Future<AppUser?> getValidSession() async {
    final prefs = await SharedPreferences.getInstance();

    String? userJson = prefs.getString(_keyUser);
    String? loginTimeStr = prefs.getString(_keyLoginTime);

    // Cek apakah data benar-benar ada di memori
    print("=== DEBUG SESSION ===");
    print("Data User JSON: $userJson");
    print("Waktu Login Disimpan: $loginTimeStr");

    // Jika belum pernah login atau data tidak ada
    if (userJson == null || loginTimeStr == null) {
      print("Hasil: Sesi tidak ditemukan (kosong).");
      return null;
    }

    DateTime loginTime = DateTime.parse(loginTimeStr);
    DateTime currentTime = DateTime.now();

    // Hitung selisih waktu dalam menit
    int differenceInMinutes = currentTime.difference(loginTime).inMinutes;

    print("Waktu Login: $loginTime");
    print("Waktu Sekarang: $currentTime");
    print("Selisih: $differenceInMinutes menit");

    // Jika sudah 5 menit atau lebih, hapus sesi dan anggap expired
    if (differenceInMinutes >= _sessionDurationMinutes) {
      print("Hasil: Sesi kedaluwarsa (dihapus).");
      await clearSession();
      return null;
    }

    print("Hasil: Sesi masih valid!");
    // Jika kurang dari 5 menit, ubah JSON kembali jadi AppUser pakai fromJson()
    Map<String, dynamic> userMap = jsonDecode(userJson);
    return AppUser.fromJson(userMap);
  }

  // 3. Hapus Sesi (Saat Logout)
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUser);
    await prefs.remove(_keyLoginTime);
  }
}
