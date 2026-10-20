
import 'package:geolocator/geolocator.dart';

import 'attendance_service.dart';
import 'biometric_service.dart';
import 'location_service.dart';

class AttendanceCheckInService {
  final LocationService _locationService = LocationService();
  final BiometricService _biometricService = BiometricService();
  final AttendanceService _attendanceService = AttendanceService();

  /// Memvalidasi lokasi, meminta biometrik, lalu mengirim absensi.
  Future<void> checkIn({
    required int shiftId,
    required int actualEmployeeId,
    String? notes,
  }) async {
    // 1. Pastikan perangkat berada dalam radius Cabang A.
    final Position position =
        await _locationService.getPositionWithinBranchA();

    // 2. Minta verifikasi sidik jari.
    final authenticated = await _biometricService.authenticate();

    if (!authenticated) {
      throw Exception(
        'Absensi dibatalkan karena verifikasi sidik jari gagal.',
      );
    }

    // 3. Kirim absensi beserta koordinat ke backend PHP.
    await _attendanceService.checkIn(
      shiftId: shiftId,
      actualEmployeeId: actualEmployeeId,
      latitude: position.latitude,
      longitude: position.longitude,
      notes: notes,
    );
  }
}
