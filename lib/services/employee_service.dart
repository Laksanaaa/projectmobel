
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/employee.dart';

class EmployeeService {
  // Mengambil daftar karyawan dari PHP API.
  Future<List<Employee>> getEmployees() async {
    final response = await http
        .get(
          Uri.parse('${ApiConfig.baseUrl}/employees.php'),
          headers: {'Accept': 'application/json'},
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception(
        'Server gagal mengambil data (${response.statusCode}).',
      );
    }

    final dynamic result = jsonDecode(response.body);

    if (result is! Map<String, dynamic> ||
        result['success'] != true ||
        result['data'] is! List) {
      throw Exception('Format respons data karyawan tidak valid.');
    }

    final List<dynamic> data = result['data'];

    return data
        .map(
          (item) => Employee.fromMap(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  // Menambahkan karyawan baru melalui PHP API.
  Future<void> addEmployee({
    required String fullName,
    required String phone,
    required String position,
    required double shiftRate,
    required String hireDate,
  }) async {
    final response = await http
        .post(
          Uri.parse('${ApiConfig.baseUrl}/employees.php'),
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'full_name': fullName.trim(),
            'phone': phone.trim(),
            'position': position,
            'shift_rate': shiftRate,
            'hire_date': hireDate,
          }),
        )
        .timeout(const Duration(seconds: 15));

    final dynamic result = jsonDecode(response.body);

    if (result is! Map<String, dynamic>) {
      throw Exception('Respons server tidak valid.');
    }

    if (response.statusCode != 201 || result['success'] != true) {
      throw Exception(
        result['message']?.toString() ??
            'Gagal menambahkan karyawan.',
      );
    }
  }
}
