import 'package:flutter/material.dart';

import '../models/app_user.dart';
import 'profile_page.dart';
import 'employees_page.dart';
import 'shifts_page.dart';
import 'attendance_page.dart';
import 'payroll_page.dart';

class HomePage extends StatelessWidget {
  final AppUser user;

  const HomePage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final menus = _getMenus(context, user);
    const lightBg = Color(0xFFFAFAFA);
    const primaryBrown = Color(0xFF8C5E3C);
    const darkBrown = Color(0xFF5A3921);

    return Scaffold(
      backgroundColor: lightBg,
      appBar: AppBar(
        backgroundColor: lightBg,
        elevation: 0,
        title: const Text(
          'Hi!',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => ProfilePage(user: user),
                  ),
                );
              },
              icon: const CircleAvatar(
                backgroundColor: Color(0xFFEFE8E1),
                child: Icon(Icons.person, color: darkBrown),
              ),
              tooltip: 'Profil',
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back, ${user.fullName}',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              _buildWelcomeCard(primaryBrown, darkBrown),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Most Popular Menu',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    user.roleName,
                    style: const TextStyle(
                      fontSize: 14,
                      color: primaryBrown,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: menus.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.15,
                ),
                itemBuilder: (context, index) {
                  final menu = menus[index];
                  return _buildMenuCard(
                    context,
                    title: menu.title,
                    icon: menu.icon,
                    description: menu.description,
                    onTap: menu.onTap,
                  );
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(Color primaryColor, Color darkColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, darkColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Dashboard System',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Manage Your\nCafé Seamlessly',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Select a menu below to get started',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required String description,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap:
              onTap ??
              () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Menu $title akan dibuat pada tahap berikutnya.',
                    ),
                  ),
                );
              },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF9F5F2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 26, color: const Color(0xFF8C5E3C)),
                ),
                const Spacer(),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.black45,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<_DashboardMenu> _getMenus(BuildContext context, AppUser user) {
    final role = user.role;

    final attendanceMenu = _DashboardMenu(
      title: 'Absensi',
      icon: Icons.fingerprint_rounded,
      description: role == UserRole.manager
          ? 'Pantau kehadiran'
          : 'Check-in, check-out, dan riwayat',
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (_) => AttendancePage(user: user)),
        );
      },
    );

    final shiftMenu = _DashboardMenu(
      title: 'Jadwal Shift',
      icon: Icons.calendar_month_rounded,
      description: role == UserRole.manager
          ? 'Atur jadwal kerja'
          : role == UserRole.akuntan
          ? 'Lihat jadwal kerja'
          : 'Lihat jadwal pribadi',
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (_) => ShiftsPage(user: user)),
        );
      },
    );

    final payrollMenu = _DashboardMenu(
      title: 'Penggajian',
      icon: Icons.payments_rounded,
      description: role == UserRole.manager
          ? 'Kelola gaji karyawan'
          : role == UserRole.akuntan
          ? 'Periksa perhitungan gaji'
          : 'Lihat informasi gaji',
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (_) => PayrollPage(user: user)),
        );
      },
    );

    final miniGame = _DashboardMenu(
      title: 'Mini Game',
      icon: Icons.sports_esports_rounded,
      description: 'Permainan santai',
    );

    switch (role) {
      case UserRole.manager:
        return [
          _DashboardMenu(
            title: 'Karyawan',
            icon: Icons.groups_rounded,
            description: 'Kelola data karyawan',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(builder: (_) => const EmployeesPage()),
              );
            },
          ),
          shiftMenu,
          attendanceMenu,
          payrollMenu,
          const _DashboardMenu(
            title: 'Keuangan',
            icon: Icons.account_balance_wallet_rounded,
            description: 'Pantau keuangan café',
          ),
          const _DashboardMenu(
            title: 'Menu Café',
            icon: Icons.local_cafe_rounded,
            description: 'Kelola menu dan harga',
          ),
          const _DashboardMenu(
            title: 'Laporan',
            icon: Icons.bar_chart_rounded,
            description: 'Lihat laporan operasional',
          ),
          miniGame,
        ];

      case UserRole.akuntan:
        return [
          attendanceMenu,
          shiftMenu,
          const _DashboardMenu(
            title: 'Keuangan',
            icon: Icons.account_balance_wallet_rounded,
            description: 'Catat transaksi keuangan',
          ),
          payrollMenu,
          const _DashboardMenu(
            title: 'Laporan',
            icon: Icons.bar_chart_rounded,
            description: 'Lihat laporan operasional',
          ),
          miniGame,
        ];

      case UserRole.karyawan:
        return [attendanceMenu, shiftMenu, payrollMenu, miniGame];
    }
  }
}

class _DashboardMenu {
  final String title;
  final IconData icon;
  final String description;
  final VoidCallback? onTap;

  const _DashboardMenu({
    required this.title,
    required this.icon,
    required this.description,
    this.onTap,
  });
}
