
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class AttendanceService {
  Future<Map<String, dynamic>> checkIn({
    required int shiftId,
    required int actualEmployeeId,
    double? latitude,
    double? longitude,
    String? notes,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/attendance.php',
    );

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'shift_id': shiftId,
        'actual_employee_id': actualEmployeeId,
        'latitude': latitude,
        'longitude': longitude,
        'notes': notes,
      }),
    );

    Map<String, dynamic> result;

    try {
      result = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw Exception(
        'Respons server tidak valid. Periksa attendance.php.',
      );
    }

    if (response.statusCode != 201 ||
        result['success'] != true) {
      throw Exception(
        result['message']?.toString() ??
            'Absensi gagal disimpan.',
      );
    }

    return result;
  }
}