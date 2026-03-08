import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';

class ApiService {
  ApiService._();

  //live
//   static const String baseUrl = 'https://www.tullysmith.hschub.co.uk/api';

  // local
  static const String baseUrl = 'http://192.168.0.102:8000/api';
  static final _box            = GetStorage();
  static const _timeout        = Duration(seconds: 10);

  static String? get token          => _box.read<String>('token');
  static void saveToken(String t)   => _box.write('token', t);
  static void clearToken()          => _box.remove('token');

  static Map<String, String> get headers => {
        'Content-Type': 'application/json',
        'Accept':       'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  // ── Auth ───────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final res = await http
        .post(
          Uri.parse('$baseUrl/login'),
          headers: {
            'Content-Type': 'application/json',
            'Accept':       'application/json',
          },
          body: jsonEncode({'email': email, 'password': password}),
        )
        .timeout(_timeout);

    // DEBUG — remove after fixing
    print('LOGIN STATUS: ${res.statusCode}');
    print('LOGIN BODY: ${res.body.substring(0, res.body.length.clamp(0, 300))}');

    try {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200) return body;
      throw Exception(body['message'] ?? 'Login failed');
    } catch (_) {
      throw Exception('Server returned (${res.statusCode}): ${res.body.substring(0, res.body.length.clamp(0, 200))}');
    }
  }

  static Future<void> logout() async {
    await http
        .post(Uri.parse('$baseUrl/logout'), headers: headers)
        .timeout(_timeout);
    clearToken();
  }

  // ── Dashboard ──────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getDashboard() async {
    final res = await http
        .get(Uri.parse('$baseUrl/dashboard'), headers: headers)
        .timeout(_timeout);

    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Failed to load dashboard');
  }

  // ── Time ───────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getTimeIndex() async {
    final res = await http
        .get(Uri.parse('$baseUrl/time'), headers: headers)
        .timeout(_timeout);

    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Failed to load time data');
  }

  static Future<Map<String, dynamic>> clockIn(Map<String, dynamic> body) async {
    final res = await http
        .post(
          Uri.parse('$baseUrl/time/clock-in'),
          headers: headers,
          body:    jsonEncode(body),
        )
        .timeout(_timeout);

    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> clockOut(String base64Photo) async {
    final res = await http
        .post(
          Uri.parse('$baseUrl/time/clock-out'),
          headers: headers,
          body:    jsonEncode({'photo': base64Photo}),
        )
        .timeout(_timeout);

    return jsonDecode(res.body);
  }

  // ── Checklists ─────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getClockChecklists({
    required int    serviceJobId,
    required String type,
  }) async {
    final res = await http
        .get(
          Uri.parse('$baseUrl/time/checklist-questions?service_job_id=$serviceJobId&type=$type'),
          headers: headers,
        )
        .timeout(_timeout);

    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Failed to load checklists');
  }

  static Future<http.StreamedResponse> saveClockChecklistAnswers(
    http.MultipartRequest request,
  ) async {
    request.headers['Accept']        = 'application/json';
    request.headers['Authorization'] = token != null ? 'Bearer $token' : '';
    return request.send().timeout(_timeout);
  }

  // ── Timesheet ──────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getTimesheet({
    required String mode,
    required int    offset,
  }) async {
    final res = await http
        .get(
          Uri.parse('$baseUrl/time/timesheet?mode=$mode&offset=$offset'),
          headers: headers,
        )
        .timeout(_timeout);

    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Failed to load timesheet');
  }
}