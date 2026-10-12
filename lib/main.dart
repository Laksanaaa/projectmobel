
import 'package:flutter/material.dart';
import 'pages/login_page.dart';

void main() {
  runApp(const CafeManagementApp());
}

class CafeManagementApp extends StatelessWidget {
  const CafeManagementApp({super.key});

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
      home: const LoginPage(),
    );
  }
}
