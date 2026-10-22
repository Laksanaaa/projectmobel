
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/cafe_menu.dart';

class CafeMenuService {
  final http.Client _client;
  final Future<String?> Function() getToken;

  CafeMenuService({
    required this.getToken,
    http.Client? client,
  }) : _client = client ?? http.Client();

  Future<Map<String, String>> _headers({
    bool jsonContent = false,
  }) async {
    final token = await getToken();

    if (token == null || token.trim().isEmpty) {
      throw Exception(
        'Token login tidak ditemukan. Silakan login kembali.',
      );
    }

    return {
      'Accept': 'application/json',
      'Authorization': 'Bearer ${token.trim()}',
      if (jsonContent) 'Content-Type': 'application/json; charset=UTF-8',
    };
  }

  Uri get _uri => Uri.parse(
        '${ApiConfig.baseUrl}/cafe_menu.php',
      );

  dynamic _decode(http.Response response) {
    try {
      return jsonDecode(response.body);
    } catch (_) {
      throw Exception(
        'Respons server tidak valid. Periksa file PHP dan log server.',
      );
    }
  }

  void _checkResponse(http.Response response, dynamic result) {
    if (result is! Map<String, dynamic>) {
      throw Exception('Format respons server tidak valid.');
    }

    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        result['success'] != true) {
      throw Exception(
        result['message']?.toString() ??
            'Permintaan menu gagal.',
      );
    }
  }

  Future<List<CafeMenu>> getMenus() async {
    final response = await _client
        .get(_uri, headers: await _headers())
        .timeout(const Duration(seconds: 15));

    final result = _decode(response);
    _checkResponse(response, result);

    if (result['data'] is! List) {
      throw Exception('Data menu tidak valid.');
    }

    return (result['data'] as List)
        .map(
          (item) => CafeMenu.fromMap(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  Future<void> addMenu({
    required String name,
    required String category,
    required double price,
  }) async {
    final response = await _client
        .post(
          _uri,
          headers: await _headers(jsonContent: true),
          body: jsonEncode({
            'name': name.trim(),
            'category': category.trim(),
            'price': price,
          }),
        )
        .timeout(const Duration(seconds: 15));

    final result = _decode(response);
    _checkResponse(response, result);
  }

  Future<void> updateMenu({
    required int id,
    required String name,
    required String category,
    required double price,
  }) async {
    final response = await _client
        .put(
          _uri,
          headers: await _headers(jsonContent: true),
          body: jsonEncode({
            'id': id,
            'name': name.trim(),
            'category': category.trim(),
            'price': price,
          }),
        )
        .timeout(const Duration(seconds: 15));

    final result = _decode(response);
    _checkResponse(response, result);
  }

  Future<void> deleteMenu(int id) async {
    final response = await _client
        .delete(
          _uri,
          headers: await _headers(jsonContent: true),
          body: jsonEncode({'id': id}),
        )
        .timeout(const Duration(seconds: 15));

    final result = _decode(response);
    _checkResponse(response, result);
  }

  void dispose() {
    _client.close();
  }
}
