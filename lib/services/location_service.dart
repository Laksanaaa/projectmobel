
import 'package:geolocator/geolocator.dart';

class LocationService {
  // Koordinat Cabang A sebagai titik wajib absensi.
  static const double branchALatitude = -7.789914;
  static const double branchALongitude = 110.378817;

  // Batas jarak absensi: 100 meter.
  static const double radiusMeters = 100;

  /// Mengambil lokasi GPS perangkat.
  Future<Position> getCurrentPosition() async {
    final serviceEnabled =
        await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw Exception(
        'GPS belum aktif. Aktifkan lokasi perangkat terlebih dahulu.',
      );
    }

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw Exception(
        'Izin lokasi ditolak. Izinkan aplikasi mengakses lokasi.',
      );
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Izin lokasi ditolak permanen. Aktifkan izin lokasi melalui pengaturan perangkat.',
      );
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }

  /// Menghitung jarak lokasi perangkat dari Cabang A.
  double calculateDistance(Position position) {
    return Geolocator.distanceBetween(
      branchALatitude,
      branchALongitude,
      position.latitude,
      position.longitude,
    );
  }

  /// Mengambil lokasi dan menolak jika berada di luar radius.
  Future<Position> getPositionWithinBranchA() async {
    final position = await getCurrentPosition();
    final distance = calculateDistance(position);

    if (distance > radiusMeters) {
      throw Exception(
        'Absensi ditolak. Kamu berada sekitar '
        '${distance.round()} meter dari Cabang A. '
        'Absensi hanya dapat dilakukan dalam radius '
        '${radiusMeters.round()} meter.',
      );
    }

    return position;
  }
}
