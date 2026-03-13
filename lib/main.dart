import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'views/employee/employee_page.dart';
import 'controllers/auth_controller.dart';
import 'services/api_service.dart';
import 'views/auth/login_page.dart';
import 'views/dashboard/dashboard_page.dart';
import 'views/time/time_page.dart'; 
import 'views/timesheets/timesheets_page.dart';
import 'views/client/client_page.dart';
import 'views/checklist/checklist_page.dart';
import 'views/jobs/job_page.dart';
import 'views/jobs/job_detail_page.dart';
import 'views/approval/approval_page.dart';
import 'views/calendar/calendar_page.dart';
import 'views/admin_time/admin_time_page.dart';

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
      title: 'Tully Smiths',
      debugShowCheckedModeBanner: false,
      defaultTransition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 150),
      initialRoute: ApiService.token != null ? '/dashboard' : '/login',
      getPages: [
        GetPage(name: '/login', page: () => const LoginPage()),
        GetPage(name: '/dashboard', page: () => DashboardPage()),
        GetPage(name: '/time', page: () => TimePage()),
        GetPage(name: '/admin/time', page: () => const AdminTimePage()),
        GetPage(name: '/timesheets', page: () => TimesheetsPage()),
        GetPage(name: '/clients', page: () => const ClientPage()),
        GetPage(name: '/employees', page: () => const EmployeePage()),
        GetPage(name: '/checklist', page: () => const ChecklistPage()),
        GetPage(name: '/jobs', page: () => const JobPage()),
        GetPage(name: '/jobs/detail', page: () => JobDetailPage(jobId: Get.arguments)),
        GetPage(name: '/approvals', page: () => const ApprovalPage()),
        GetPage(name: '/calendar', page: () => const CalendarPage()),
      ],
    );
  }
}