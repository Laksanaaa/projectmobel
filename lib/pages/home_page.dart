
import 'package:flutter/material.dart';

import '../models/app_user.dart';
import 'profile_page.dart';
import 'employees_page.dart';
import 'shifts_page.dart';

class HomePage extends StatelessWidget {
  final AppUser user;

  const HomePage({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    final menus = _getMenus(context, user.role);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Café Management'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => ProfilePage(user: user),
                ),
              );
            },
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: 'Profil',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeCard(),

              const SizedBox(height: 24),

              const Text(
                'Dashboard',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                'Anda masuk sebagai ${user.roleName}.',
                style: const TextStyle(
                  color: Colors.black54,
                ),
              ),

              const SizedBox(height: 20),

              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: menus.length,
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.95,
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

              const SizedBox(height: 24),

              const Text(
                'Café Management System',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.black45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF6F4E37),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.coffee_rounded,
            color: Colors.white,
            size: 36,
          ),

          const SizedBox(height: 16),

          Text(
            'Halo, ${user.fullName}!',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Selamat datang di sistem manajemen café.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),

          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              user.roleName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
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
    return Card(
      elevation: 1,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(
          color: Color(0xFFE9E1D8),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap ??
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
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 36,
                color: const Color(0xFF6F4E37),
              ),

              const SizedBox(height: 12),

              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<_DashboardMenu> _getMenus(
    BuildContext context,
    UserRole role,
  ) {
    switch (role) {
      case UserRole.manager:
        return [
          _DashboardMenu(
            title: 'Karyawan',
            icon: Icons.groups_outlined,
            description: 'Kelola data karyawan',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const EmployeesPage(),
                ),
              );
            },
          ),

          _DashboardMenu(
            title: 'Jadwal Shift',
            icon: Icons.calendar_month_outlined,
            description: 'Atur jadwal kerja',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const ShiftsPage(),
                ),
              );
            },
          ),

          const _DashboardMenu(
            title: 'Absensi',
            icon: Icons.fingerprint,
            description: 'Pantau kehadiran',
          ),

          const _DashboardMenu(
            title: 'Penggajian',
            icon: Icons.payments_outlined,
            description: 'Kelola gaji karyawan',
          ),

          const _DashboardMenu(
            title: 'Keuangan',
            icon: Icons.account_balance_wallet_outlined,
            description: 'Pantau keuangan café',
          ),

          const _DashboardMenu(
            title: 'Inventaris',
            icon: Icons.inventory_2_outlined,
            description: 'Kelola persediaan',
          ),

          const _DashboardMenu(
            title: 'Menu Café',
            icon: Icons.local_cafe_outlined,
            description: 'Kelola menu dan harga',
          ),

          const _DashboardMenu(
            title: 'Laporan',
            icon: Icons.bar_chart_outlined,
            description: 'Lihat laporan operasional',
          ),
        ];

      case UserRole.akuntan:
        return const [
          _DashboardMenu(
            title: 'Keuangan',
            icon: Icons.account_balance_wallet_outlined,
            description: 'Catat transaksi keuangan',
          ),

          _DashboardMenu(
            title: 'Penggajian',
            icon: Icons.payments_outlined,
            description: 'Periksa perhitungan gaji',
          ),

          _DashboardMenu(
            title: 'Laporan',
            icon: Icons.bar_chart_outlined,
            description: 'Lihat laporan keuangan',
          ),

          _DashboardMenu(
            title: 'Inventaris',
            icon: Icons.inventory_2_outlined,
            description: 'Pantau nilai persediaan',
          ),
        ];

      case UserRole.karyawan:
        return const [
          _DashboardMenu(
            title: 'Absensi',
            icon: Icons.fingerprint,
            description: 'Catat kehadiran',
          ),

          _DashboardMenu(
            title: 'Jadwal Shift',
            icon: Icons.calendar_month_outlined,
            description: 'Lihat jadwal pribadi',
          ),

          _DashboardMenu(
            title: 'Penggajian',
            icon: Icons.payments_outlined,
            description: 'Lihat informasi gaji',
          ),
        ];
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
