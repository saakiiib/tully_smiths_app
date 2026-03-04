import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'controllers/auth_controller.dart';
import 'services/api_service.dart';
import 'views/auth/login_page.dart';
import 'views/dashboard/dashboard_page.dart';
import 'views/time/time_page.dart'; 
import 'views/timesheets/timesheets_page.dart';
import 'views/more/more_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    Get.lazyPut(() => AuthController(), fenix: true);
    return GetMaterialApp(
      title: 'Tully Smith',
      debugShowCheckedModeBanner: false,
      defaultTransition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 150),
      initialRoute: ApiService.token != null ? '/dashboard' : '/login',
      getPages: [
        GetPage(name: '/login', page: () => const LoginPage()),
        GetPage(name: '/dashboard', page: () => DashboardPage()),
        GetPage(name: '/time', page: () => TimePage()),
        GetPage(name: '/timesheets', page: () => TimesheetsPage()),
        GetPage(name: '/more', page: () => MorePage()),
      ],
    );
  }
}