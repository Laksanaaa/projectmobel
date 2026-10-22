
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/app_user.dart';

class PayrollPage extends StatefulWidget {
  final AppUser user;

  const PayrollPage({
    super.key,
    required this.user,
  });

  @override
  State<PayrollPage> createState() => _PayrollPageState();
}

class _PayrollPageState extends State<PayrollPage> {
  // Untuk Flutter Web di komputer dengan XAMPP lokal.
  // Jika menjalankan aplikasi di HP Android, ganti localhost
  // dengan alamat IP komputer yang menjalankan XAMPP.
  static const String apiUrl =
      'http://localhost/cafe_api/payroll.php';

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
      final uri = Uri.parse(apiUrl).replace(
        queryParameters: {
          'week_start': _dateParam(weekStart),
        },
      );

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
          decoded['message']?.toString() ??
              'Gagal mengambil data penggajian.',
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
    final weekEnd = weekStart.add(const Duration(days: 6));

    final rows = responseData['data'] is List
        ? List<dynamic>.from(responseData['data'] as List)
        : <dynamic>[];

    final summary = responseData['summary'] is Map
        ? Map<String, dynamic>.from(responseData['summary'] as Map)
        : <String, dynamic>{};

    return Scaffold(
      appBar: AppBar(
        title: const Text('Penggajian'),
        actions: [
          IconButton(
            onPressed: isLoading ? null : fetchPayroll,
            icon: const Icon(Icons.refresh),
            tooltip: 'Muat ulang',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: fetchPayroll,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildWeekSelector(weekEnd),
            const SizedBox(height: 16),
            if (isLoading)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (errorMessage != null)
              _buildError()
            else ...[
              _buildSummary(summary),
              const SizedBox(height: 20),
              const Text(
                'Rincian Penggajian',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              if (rows.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'Belum ada data penggajian untuk periode ini.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else
                ...rows.map((item) {
                  if (item is! Map) {
                    return const SizedBox.shrink();
                  }

                  final employee =
                      Map<String, dynamic>.from(item);

                  return _buildEmployeeCard(employee);
                }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWeekSelector(DateTime weekEnd) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Periode Penggajian',
              style: TextStyle(
                color: Colors.black54,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${_formatDate(weekStart)} – ${_formatDate(weekEnd)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isLoading ? null : () => changeWeek(-1),
                    icon: const Icon(Icons.chevron_left),
                    label: const Text('Minggu lalu'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isLoading ? null : () => changeWeek(1),
                    icon: const Icon(Icons.chevron_right),
                    label: const Text('Minggu depan'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary(Map<String, dynamic> summary) {
    final employeeCount = summary['total_karyawan'] ??
        summary['total_employees'] ??
        summary['total_employee'] ??
        0;

    final totalShifts = summary['total_shift'] ??
        summary['total_shifts'] ??
        0;

    final totalSalary = summary['total_gaji'] ??
        summary['total_salary'] ??
        0;

    return Card(
      color: const Color(0xFFF5EEE8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ringkasan Mingguan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _summaryRow('Jumlah karyawan', '$employeeCount'),
            _summaryRow('Total shift valid', '$totalShifts'),
            const Divider(height: 24),
            const Text(
              'Total estimasi gaji',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 4),
            Text(
              _formatRupiah(totalSalary),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6F4E37),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeCard(Map<String, dynamic> employee) {
    final name = employee['full_name'] ??
        employee['nama_karyawan'] ??
        'Nama tidak tersedia';

    final code = employee['employee_code'] ??
        employee['kode_karyawan'] ??
        '-';

    final rate = employee['shift_rate'] ??
        employee['tarif_per_shift'] ??
        0;

    final shifts = employee['total_shift'] ??
        employee['total_shifts'] ??
        0;

    final salary = employee['total_salary'] ??
        employee['total_gaji'] ??
        employee['salary'] ??
        0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFFE9DDD3),
                  child: Icon(
                    Icons.person_outline,
                    color: Color(0xFF6F4E37),
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
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Kode: ${code.toString()}',
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _summaryRow('Tarif per shift', _formatRupiah(rate)),
            _summaryRow('Shift yang dihitung', '$shifts'),
            const SizedBox(height: 8),
            const Text(
              'Estimasi gaji',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 4),
            Text(
              _formatRupiah(salary),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6F4E37),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Shift dihitung jika absensi berstatus hadir atau terlambat.',
              style: TextStyle(
                fontSize: 11,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(
              Icons.error_outline,
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
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: fetchPayroll,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba lagi'),
            ),
          ],
        ),
      ),
    );
  }
}
