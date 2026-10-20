
import 'package:local_auth/local_auth.dart';

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> isBiometricAvailable() async {
    final isSupported = await _auth.isDeviceSupported();
    final canCheck = await _auth.canCheckBiometrics;

    return isSupported && canCheck;
  }

  Future<bool> authenticate() async {
    final available = await isBiometricAvailable();

    if (!available) {
      throw Exception(
        'Perangkat tidak mendukung biometrik atau '
        'belum memiliki sidik jari yang terdaftar.',
      );
    }

    try {
      return await _auth.authenticate(
        localizedReason:
            'Verifikasi sidik jari untuk melakukan absensi.',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } on LocalAuthException catch (e) {
      throw Exception(
        'Verifikasi biometrik gagal: ${e.description}',
      );
    }
  }
}
