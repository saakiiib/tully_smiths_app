import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';

class ApiService {
  ApiService._();

  static const String baseUrl = 'http://127.0.0.1:8000/api';
  static final _box = GetStorage();
  static const _timeout = Duration(seconds: 10);

  static String? get token => _box.read<String>('token');

  static void saveToken(String t) => _box.write('token', t);

  static void clearToken() => _box.remove('token');

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final res = await http
        .post(
          Uri.parse('$baseUrl/login'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({'email': email, 'password': password}),
        )
        .timeout(_timeout);

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode == 200) return body;
    throw Exception(body['message'] ?? 'Login failed');
  }

  static Future<void> logout() async {
    await http
        .post(Uri.parse('$baseUrl/logout'), headers: _headers)
        .timeout(_timeout);
    clearToken();
  }
}