import 'package:flutter/material.dart';

import 'pages/login_page.dart';
import 'pages/home_page.dart';
import 'services/session_manager.dart';
import 'models/app_user.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Cek apakah ada sesi aktif yang belum kedaluwarsa
  AppUser? activeUser = await SessionManager.getValidSession();

  runApp(MyApp(initialUser: activeUser));
}

class MyApp extends StatelessWidget {
  final AppUser? initialUser;

  const MyApp({super.key, this.initialUser});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Café Management System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6F4E37),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFFAF7F2),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF6F4E37),
          foregroundColor: Colors.white,
          centerTitle: false,
        ),
      ),
      home: initialUser != null
          ? HomePage(user: initialUser!)
          : const LoginPage(),
    );
  }
}
