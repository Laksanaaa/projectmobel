
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/app_user.dart';

class AttendancePage extends StatefulWidget {
  final AppUser user;

  const AttendancePage({
    super.key,
    required this.user,
  });

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  List<Map<String, dynamic>> _records = [];
  List<Map<String, dynamic>> _shifts = [];

  bool _loading = true;
  bool _processing = false;
  String? _error;

  Uri get _attendanceUri =>
      Uri.parse('${ApiConfig.baseUrl}/attendance.php');

  Uri get _shiftsUri =>
      Uri.parse('${ApiConfig.baseUrl}/shifts.php');

  Map<String, String> get _headers => {
        'Accept': 'application/json',
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer ${widget.user.token}',
      };

  bool get _isManager => widget.user.role == UserRole.manager;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<Map<String, dynamic>> _getJson(
    http.Response response,
  ) async {
    final dynamic decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception('Format respons server tidak valid.');
    }

    if (response.statusCode == 401) {
      throw Exception(
        'Sesi login tidak valid atau kedaluwarsa. Silakan login kembali.',
      );
    }

    if (decoded['success'] != true) {
      throw Exception(
        decoded['message']?.toString() ?? 'Permintaan gagal.',
      );
    }

    return decoded;
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final responses = await Future.wait([
        http.get(_attendanceUri, headers: _headers)
            .timeout(const Duration(seconds: 15)),
        if (!_isManager)
          http.get(_shiftsUri, headers: _headers)
              .timeout(const Duration(seconds: 15)),
      ]);

      final attendanceJson = await _getJson(responses[0]);
      final attendanceData = attendanceJson['data'];

      if (attendanceData is! List) {
        throw Exception('Data riwayat absensi tidak valid.');
      }

      List<Map<String, dynamic>> shifts = [];

      if (!_isManager) {
        final shiftsJson = await _getJson(responses[1]);
        final shiftsData = shiftsJson['data'];

        if (shiftsData is List) {
          shifts = shiftsData
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
        }
      }

      if (!mounted) return;

      setState(() {
        _records = attendanceData
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
        _shifts = shifts;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = _cleanError(e);
      });
    }
  }

  String _cleanError(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }

  Future<Position> _getPosition() async {
    final enabled = await Geolocator.isLocationServiceEnabled();

    if (!enabled) {
      throw Exception(
        'Aktifkan layanan lokasi/GPS pada perangkat terlebih dahulu.',
      );
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw Exception('Izin lokasi belum diberikan.');
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Izin lokasi ditolak permanen. Aktifkan melalui pengaturan aplikasi.',
      );
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 20),
      ),
    );
  }

  Future<void> _submitAttendance({
    required String action,
    required int id,
  }) async {
    if (_processing) return;

    setState(() {
      _processing = true;
    });

    try {
      final position = await _getPosition();

      final body = <String, dynamic>{
        'action': action,
        'latitude': position.latitude,
        'longitude': position.longitude,
      };

      if (action == 'check_in') {
        body['shift_id'] = id;
      } else {
        body['attendance_id'] = id;
      }

      final response = await http
          .post(
            _attendanceUri,
            headers: _headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));

      final result = await _getJson(response);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['message']?.toString() ?? 'Absensi berhasil.',
          ),
        ),
      );

      await _loadData();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_cleanError(e)),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _processing = false;
        });
      }
    }
  }

  String _formatDate(dynamic value) {
    if (value == null || value.toString().isEmpty) return '-';

    final text = value.toString();
    final parts = text.split('-');

    if (parts.length != 3) return text;

    return '${parts[2].split(' ').first}/${parts[1]}/${parts[0]}';
  }

  String _formatTime(dynamic value) {
    if (value == null || value.toString().isEmpty) return '-';

    final text = value.toString();
    if (text.length >= 16) return text.substring(11, 16);
    if (text.length >= 5) return text.substring(0, 5);

    return text;
  }

  String _statusLabel(dynamic value) {
    switch (value?.toString()) {
      case 'hadir':
        return 'Hadir';
      case 'terlambat':
        return 'Terlambat';
      case 'izin':
        return 'Izin';
      case 'sakit':
        return 'Sakit';
      case 'alpa':
        return 'Alpa';
      case 'belum_absen':
        return 'Belum absen';
      default:
        return value?.toString() ?? '-';
    }
  }

  bool _isOpenAttendance(Map<String, dynamic> record) {
    return record['check_in'] != null &&
        record['check_in'].toString().isNotEmpty &&
        (record['check_out'] == null ||
            record['check_out'].toString().isEmpty);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Absensi'),
        actions: [
          IconButton(
            onPressed: _loading || _processing ? null : _loadData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Muat ulang',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildInfoCard(),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    _buildErrorCard(),
                  ],
                  if (!_isManager) ...[
                    const SizedBox(height: 20),
                    const Text(
                      'Jadwal untuk Check-in',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildShiftList(),
                  ],
                  const SizedBox(height: 24),
                  Text(
                    _isManager
                        ? 'Riwayat Absensi Karyawan'
                        : 'Riwayat Absensi Saya',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_records.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text('Belum ada data absensi.'),
                      ),
                    )
                  else
                    ..._records.map(_buildAttendanceCard),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      color: const Color(0xFFF0E5DA),
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.location_on_outlined,
              size: 30,
              color: Color(0xFF6F4E37),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Absensi Cabang A',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Check-in dan check-out hanya dapat dilakukan '
                    'dalam radius 100 meter dari lokasi Cabang A. '
                    'Pastikan GPS perangkat aktif.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          _error!,
          style: TextStyle(color: Colors.red.shade900),
        ),
      ),
    );
  }

  Widget _buildShiftList() {

    final availableShifts = _shifts.where((shift) {
      final date = shift['shift_date']?.toString();
      final id = int.tryParse(shift['id']?.toString() ?? '');

      if (date == null || id == null) return false;

      // Jangan tampilkan shift yang sudah memiliki check-in.
      return !_records.any((record) =>
          record['shift_id'].toString() == id.toString() &&
          record['check_in'] != null &&
          record['check_in'].toString().isNotEmpty);
    }).toList();

    if (availableShifts.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Tidak ada jadwal yang tersedia untuk check-in. '
            'Pastikan jadwal shift sudah dibuat.',
          ),
        ),
      );
    }

    return Column(
      children: availableShifts.map((shift) {
        final shiftId = int.tryParse(shift['id'].toString());

        return Card(
          child: ListTile(
            leading: const Icon(
              Icons.calendar_month,
              color: Color(0xFF6F4E37),
            ),
            title: Text(
              '${shift['branch'] ?? 'Cabang'} • '
              '${_formatDate(shift['shift_date'])}',
            ),
            subtitle: Text(
              '${_formatTime(shift['start_time'])}–'
              '${_formatTime(shift['end_time'])}',
            ),
            trailing: ElevatedButton(
              onPressed: _processing || shiftId == null
                  ? null
                  : () => _submitAttendance(
                        action: 'check_in',
                        id: shiftId,
                      ),
              child: const Text('Check-in'),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAttendanceCard(Map<String, dynamic> record) {
    final open = _isOpenAttendance(record);
    final employeeName =
        record['actual_employee_name'] ??
        record['scheduled_employee_name'] ??
        'Karyawan';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.fingerprint,
                  color: Color(0xFF6F4E37),
                  size: 28,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isManager
                            ? employeeName.toString()
                            : '${record['branch'] ?? 'Cabang'}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_formatDate(record['shift_date'])} • '
                        '${_formatTime(record['start_time'])}–'
                        '${_formatTime(record['end_time'])}',
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: Text(_statusLabel(record['status'])),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const Divider(height: 22),
            Text('Check-in: ${_formatTime(record['check_in'])}'),
            const SizedBox(height: 4),
            Text('Check-out: ${_formatTime(record['check_out'])}'),
            if (open && !_isManager) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _processing
                      ? null
                      : () => _submitAttendance(
                            action: 'check_out',
                            id: int.parse(record['id'].toString()),
                          ),
                  icon: const Icon(Icons.logout),
                  label: const Text('Check-out'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
