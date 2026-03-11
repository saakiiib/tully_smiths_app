import 'dart:convert';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import '../utils/app_feedback.dart';

class AuthController extends GetxController {
  final _box = GetStorage();

  final isLoading = false.obs;
  final userEmail = ''.obs;

  @override
  void onInit() {
    super.onInit();
    userEmail.value = _box.read('user_email') ?? '';
  }

  Future<void> login({required String email, required String password}) async {
    try {
      isLoading.value = true;

      final res = await http
          .post(
            Uri.parse('${ApiService.baseUrl}/login'),
            headers: {
              'Content-Type': 'application/json',
              'Accept':       'application/json',
            },
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 10));

      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode != 200) {
        throw Exception(body['message'] ?? 'Login failed');
      }

      final token = body['access_token'] ?? body['token'];
      if (token == null) throw Exception('Token not found in response');

      ApiService.saveToken(token);
      ApiService.saveRole(body['role'] ?? '');
      userEmail.value = email;
      _box.write('user_email', email);

      Get.offNamed('/dashboard');
    } catch (e) {
      AppFeedback.showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    try {
      await ApiService.logout();
    } catch (_) {
      ApiService.clearToken();
    }
    _box.remove('user_email');
    userEmail.value = '';
    Get.offAllNamed('/login');
  }
}