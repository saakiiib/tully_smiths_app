import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';

class ApiService {
  ApiService._();

  //live
  // static const String baseUrl = 'https://www.tullysmith.hschub.co.uk/api';

  // local
  static const String baseUrl = 'http://192.168.0.106:8000/api';
  
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

  static Future<void> logout() async {
    await http
        .post(Uri.parse('$baseUrl/logout'), headers: headers)
        .timeout(_timeout);
    clearToken();
  }
}