import 'package:flutter/material.dart';

import 'profile_page.dart';
import '../models/app_user.dart';
import 'employees_page.dart';
import 'shifts_page.dart';
import 'attendance_page.dart';
import 'payroll_page.dart';

class HomePage extends StatefulWidget {
  final AppUser user; // Tambahkan variabel user

  // Tambahkan required this.user pada constructor
  const HomePage({super.key, required this.user});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Pindahkan list _pages ke dalam build agar bisa mengakses widget.user
    final List<Widget> pages = [
      DashboardTab(user: widget.user), // Teruskan data user ke DashboardTab
      ProfilePage(user: widget.user), // Teruskan data user ke ProfilePage
    ];

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: const Color(0xFF6F4E37),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}

// Tambahkan parameter user pada class DashboardTab
class DashboardTab extends StatelessWidget {
  final AppUser user;

  const DashboardTab({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Café Dashboard')),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          _buildMenuCard(context, Icons.people, 'Karyawan awokaowk', () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const EmployeesPage(),
              ), // Ini tetap const
            );
          }),
          _buildMenuCard(context, Icons.calendar_month, 'Jadwal Shift', () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ShiftsPage(user: user),
              ), // Hapus const, kirim user
            );
          }),
          _buildMenuCard(context, Icons.fingerprint, 'Absensi', () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AttendancePage(user: user),
              ), // Hapus const, kirim user
            );
          }),
          _buildMenuCard(context, Icons.monetization_on, 'Penggajian', () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PayrollPage(user: user),
              ), // Hapus const, kirim user
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.white,
      elevation: 4,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias, // Memotong efek ripple agar melengkung rapi
      child: InkWell(
        onTap: () {
          print("Navigasi ke $title ditekan!");
          onTap();
        },
        // Widget Center ini penting untuk memaksa area klik memenuhi seluruh kotak Grid
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min, // Sesuaikan ukuran kolom ke tengah
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: const Color(0xFF6F4E37)),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
