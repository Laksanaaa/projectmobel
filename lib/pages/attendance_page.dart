
import 'package:flutter/material.dart';

import '../models/shift.dart';
import '../services/attendance_check_in_service.dart';
import '../services/shift_service.dart';

class AttendancePage extends StatefulWidget {
  final int actualEmployeeId;

  const AttendancePage({
    super.key,
    required this.actualEmployeeId,
  });

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  final ShiftService _shiftService = ShiftService();
  final AttendanceCheckInService _checkInService =
      AttendanceCheckInService();

  List<Shift> _shifts = [];
  bool _isLoading = true;
  int? _processingShiftId;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadShifts();
  }

  Future<void> _loadShifts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final shifts = await _shiftService.getShifts();

      if (!mounted) return;

      setState(() {
        _shifts = shifts;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _checkIn(Shift shift) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Absensi'),
        content: Text(
          'Kamu akan melakukan absensi untuk shift '
          '${shift.branchName} pada ${shift.shiftDate} '
          '(${shift.startTime}–${shift.endTime}).\n\n'
          'Pastikan kamu berada di Cabang A.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Lanjutkan'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _processingShiftId = shift.id;
    });

    try {
      await _checkInService.checkIn(
        shiftId: shift.id,
        actualEmployeeId: widget.actualEmployeeId,
      );

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 48,
          ),
          title: const Text('Absensi Berhasil'),
          content: const Text(
            'Data absensi berhasil dikirim ke server.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Selesai'),
            ),
          ],
        ),
      );

      await _loadShifts();
    } catch (e) {
      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 48,
          ),
          title: const Text('Absensi Gagal'),
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Mengerti'),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _processingShiftId = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Absensi Karyawan'),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadShifts,
            icon: const Icon(Icons.refresh),
            tooltip: 'Muat ulang jadwal',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildError()
              : _shifts.isEmpty
                  ? _buildEmpty()
                  : RefreshIndicator(
                      onRefresh: _loadShifts,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'Ketentuan Absensi',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    '• Absensi wajib dilakukan di Cabang A.\n'
                                    '• Lokasi harus berada dalam radius 100 meter.\n'
                                    '• Verifikasi biometrik diperlukan.\n'
                                    '• Pilih shift yang benar sebelum melanjutkan.',
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Jadwal Shift',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ..._shifts.map(_buildShiftCard),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildShiftCard(Shift shift) {
    final isProcessing = _processingShiftId == shift.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cabang ${shift.branch}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text('Tanggal: ${shift.shiftDate}'),
            Text('Karyawan terjadwal: ${shift.employeeName}'),
            Text('Waktu: ${shift.startTime}–${shift.endTime}'),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _processingShiftId != null
                    ? null
                    : () => _checkIn(shift),
                icon: isProcessing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.fingerprint),
                label: Text(
                  isProcessing ? 'Memproses...' : 'Absen Sekarang',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _loadShifts,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.event_busy, size: 48),
            const SizedBox(height: 12),
            const Text(
              'Belum ada jadwal shift.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _loadShifts,
              child: const Text('Muat Ulang'),
            ),
          ],
        ),
      ),
    );
  }
}