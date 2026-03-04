import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class DashboardController extends GetxController {
  final _box = GetStorage();

  final totalEmployees = 128.obs;
  final activeEmployees = 104.obs;
  final totalDepartments = 8.obs;
  final newThisMonth = 6.obs;

  final userName = ''.obs;

  @override
  void onInit() {
    super.onInit();
    userName.value = _box.read('user_email') ?? '';
  }
}