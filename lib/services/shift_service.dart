
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/shift.dart';

class ShiftService {
  final http.Client _client;

  ShiftService({http.Client? client})
      : _client = client ?? http.Client();

  /// Mengambil jadwal shift.
  ///
  /// Parameter date dan branch bersifat opsional.
  /// Contoh: getShifts(date: '2026-10-15', branch: 'A')
  Future<List<Shift>> getShifts({
    String? date,
    String? branch,
  }) async {
    final queryParameters = <String, String>{};

    if (date != null && date.isNotEmpty) {
      queryParameters['date'] = date;
    }

    if (branch != null && branch.isNotEmpty) {
      queryParameters['branch'] = branch;
    }

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/shifts.php',
    ).replace(
      queryParameters:
          queryParameters.isEmpty ? null : queryParameters,
    );

    final response = await _client
        .get(
          uri,
          headers: {'Accept': 'application/json'},
        )
        .timeout(const Duration(seconds: 15));

    final dynamic result = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(
        result is Map<String, dynamic>
            ? result['message']?.toString() ??
                'Gagal mengambil jadwal shift.'
            : 'Gagal mengambil jadwal shift.',
      );
    }

    if (result is! Map<String, dynamic> ||
        result['success'] != true ||
        result['data'] is! List) {
      throw Exception('Format respons jadwal tidak valid.');
    }

    final List<dynamic> data = result['data'];

    return data
        .map(
          (item) => Shift.fromMap(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  /// Menambahkan satu jadwal shift.
  ///
  /// Jam kerja ditentukan otomatis oleh API PHP berdasarkan cabang.
  Future<void> addShift({
    required int employeeId,
    required String branch,
    required String shiftDate,
  }) async {
    if (branch != 'A' && branch != 'B') {
      throw Exception('Cabang hanya boleh A atau B.');
    }

    final response = await _client
        .post(
          Uri.parse('${ApiConfig.baseUrl}/shifts.php'),
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'employee_id': employeeId,
            'branch': branch,
            'shift_date': shiftDate,
          }),
        )
        .timeout(const Duration(seconds: 15));

    final dynamic result = jsonDecode(response.body);

    if (result is! Map<String, dynamic>) {
      throw Exception('Format respons server tidak valid.');
    }

    if (response.statusCode != 201 || result['success'] != true) {
      throw Exception(
        result['message']?.toString() ??
            'Gagal menambahkan jadwal shift.',
      );
    }
  }

  void dispose() {
    _client.close();
  }
}
