import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
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
      final res = await ApiService.login(email: email, password: password);
      final token = res['access_token'] ?? res['token'];
      if (token == null) throw Exception('Token not found in response');
      ApiService.saveToken(token);
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