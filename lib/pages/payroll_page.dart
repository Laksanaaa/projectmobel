import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/app_user.dart';

class PayrollPage extends StatefulWidget {
  final AppUser user;

  const PayrollPage({super.key, required this.user});

  @override
  State<PayrollPage> createState() => _PayrollPageState();
}

class _PayrollPageState extends State<PayrollPage> {
  static const String apiUrl = 'http://localhost/cafe_api/payroll.php';

  bool isLoading = true;
  String? errorMessage;
  Map<String, dynamic> responseData = {};

  late DateTime weekStart;

  @override
  void initState() {
    super.initState();

    weekStart = _mondayOf(DateTime.now());
    fetchPayroll();
  }

  DateTime _mondayOf(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    return normalizedDate.subtract(
      Duration(days: normalizedDate.weekday - DateTime.monday),
    );
  }

  String _dateParam(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  String _formatDate(DateTime date) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatRupiah(dynamic value) {
    final number = value is num
        ? value.toDouble()
        : double.tryParse(value?.toString() ?? '') ?? 0;

    final rounded = number.round();
    final digits = rounded.toString();
    final result = StringBuffer();

    for (var i = 0; i < digits.length; i++) {
      result.write(digits[i]);

      final remaining = digits.length - i - 1;
      if (remaining > 0 && remaining % 3 == 0) {
        result.write('.');
      }
    }

    return 'Rp$result';
  }

  Future<void> fetchPayroll() async {
    if (mounted) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    }

    try {
      final uri = Uri.parse(apiUrl)
          .replace(queryParameters: {'week_start': _dateParam(weekStart)});

      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer ${widget.user.token}',
        },
      );

      final dynamic decoded = jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        throw Exception('Format respons API tidak valid.');
      }

      if (response.statusCode < 200 ||
          response.statusCode >= 300 ||
          decoded['success'] != true) {
        throw Exception(
          decoded['message']?.toString() ?? 'Gagal mengambil data penggajian.',
        );
      }

      if (!mounted) return;

      setState(() {
        responseData = decoded;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> changeWeek(int amount) async {
    setState(() {
      weekStart = weekStart.add(Duration(days: amount * 7));
    });

    await fetchPayroll();
  }

  @override
  Widget build(BuildContext context) {
    const lightBg = Color(0xFFFAFAFA);
    const primaryBrown = Color(0xFF8C5E3C);

    final weekEnd = weekStart.add(const Duration(days: 6));

    final rows = responseData['data'] is List
        ? List<dynamic>.from(responseData['data'] as List)
        : <dynamic>[];

    final summary = responseData['summary'] is Map
        ? Map<String, dynamic>.from(responseData['summary'] as Map)
        : <String, dynamic>{};

    return Scaffold(
      backgroundColor: lightBg,
      appBar: AppBar(
        backgroundColor: lightBg,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black87,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Penggajian',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            onPressed: isLoading ? null : fetchPayroll,
            icon: const Icon(Icons.refresh_rounded, color: Colors.black87),
            tooltip: 'Muat ulang',
          ),
        ],
      ),
      body: RefreshIndicator(
        color: primaryBrown,
        onRefresh: fetchPayroll,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          children: [
            _buildWeekSelector(weekEnd),
            const SizedBox(height: 16),
            if (isLoading)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(
                  child: CircularProgressIndicator(color: primaryBrown),
                ),
              )
            else if (errorMessage != null)
              _buildError()
            else ...[
              _buildSummary(summary),
              const SizedBox(height: 24),
              const Text(
                'Rincian Penggajian',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              if (rows.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Belum ada data penggajian untuk periode ini.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54),
                  ),
                )
              else
                ...rows.map((item) {
                  if (item is! Map) {
                    return const SizedBox.shrink();
                  }

                  final employee = Map<String, dynamic>.from(item);

                  return _buildEmployeeCard(employee);
                }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWeekSelector(DateTime weekEnd) {
    const primaryBrown = Color(0xFF8C5E3C);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Periode Penggajian',
            style: TextStyle(
              color: Colors.black45,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_formatDate(weekStart)} – ${_formatDate(weekEnd)}',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isLoading ? null : () => changeWeek(-1),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFEFE8E1)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  icon: const Icon(
                    Icons.chevron_left_rounded,
                    color: primaryBrown,
                  ),
                  label: const Text(
                    'Minggu lalu',
                    style: TextStyle(color: primaryBrown),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isLoading ? null : () => changeWeek(1),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFEFE8E1)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  icon: const Icon(
                    Icons.chevron_right_rounded,
                    color: primaryBrown,
                  ),
                  label: const Text(
                    'Minggu depan',
                    style: TextStyle(color: primaryBrown),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(Map<String, dynamic> summary) {
    const primaryBrown = Color(0xFF8C5E3C);
    const darkBrown = Color(0xFF5A3921);

    final employeeCount =
        summary['total_karyawan'] ??
        summary['total_employees'] ??
        summary['total_employee'] ??
        0;

    final totalShifts = summary['total_shift'] ?? summary['total_shifts'] ?? 0;

    final totalSalary = summary['total_gaji'] ?? summary['total_salary'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [primaryBrown, darkBrown],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primaryBrown.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ringkasan Mingguan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 14),
          _summaryRowDark('Jumlah karyawan', '$employeeCount'),
          _summaryRowDark('Total shift valid', '$totalShifts'),
          const Divider(height: 24, color: Colors.white24),
          const Text(
            'Total estimasi gaji',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            _formatRupiah(totalSalary),
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRowDark(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.black54, fontSize: 13),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeCard(Map<String, dynamic> employee) {
    const primaryBrown = Color(0xFF8C5E3C);

    final name =
        employee['full_name'] ??
        employee['nama_karyawan'] ??
        'Nama tidak tersedia';

    final code = employee['employee_code'] ?? employee['kode_karyawan'] ?? '-';

    final rate = employee['shift_rate'] ?? employee['tarif_per_shift'] ?? 0;

    final shifts = employee['total_shift'] ?? employee['total_shifts'] ?? 0;

    final salary =
        employee['total_salary'] ??
        employee['total_gaji'] ??
        employee['salary'] ??
        0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFFF9F5F2),
                  child: Text(
                    name.toString().isNotEmpty
                        ? name.toString()[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: primaryBrown,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.toString(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        'Kode: ${code.toString()}',
                        style: const TextStyle(
                          color: Colors.black45,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            const SizedBox(height: 12),
            _summaryRow('Tarif per shift', _formatRupiah(rate)),
            _summaryRow('Shift yang dihitung', '$shifts'),
            const SizedBox(height: 8),
            const Text(
              'Estimasi gaji',
              style: TextStyle(color: Colors.black45, fontSize: 12),
            ),
            const SizedBox(height: 2),
            Text(
              _formatRupiah(salary),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: primaryBrown,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Shift dihitung jika absensi berstatus hadir atau terlambat.',
              style: TextStyle(fontSize: 11, color: Colors.black38),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 42,
            color: Colors.redAccent,
          ),
          const SizedBox(height: 12),
          const Text(
            'Data penggajian gagal dimuat',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            errorMessage ?? 'Terjadi kesalahan.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54, fontSize: 13),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: fetchPayroll,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8C5E3C),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Coba lagi'),
          ),
        ],
      ),
    );
  }
}
