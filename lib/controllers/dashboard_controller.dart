import 'dart:convert';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import '../utils/app_feedback.dart';

class DashboardController extends GetxController {
  final _box = GetStorage();

  final userName     = ''.obs;
  final isLoading    = false.obs;
  final todayJobs    = 0.obs;
  final activeJobs   = 0.obs;
  final pendingJobs  = 0.obs;
  final selectedDay  = DateTime.now().obs;
  final focusedDay   = DateTime.now().obs;

  final selectedDayJobs = <Map<String, dynamic>>[].obs;
  final allAssignments  = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    userName.value = _box.read('user_email') ?? '';
    fetchDashboard();
  }

  Future<void> fetchDashboard() async {
    try {
      isLoading.value = true;

      final res = await http
          .get(
            Uri.parse('${ApiService.baseUrl}/dashboard'),
            headers: ApiService.headers,
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode != 200) throw Exception('Failed to load dashboard');

      final body = jsonDecode(res.body) as Map<String, dynamic>;

      todayJobs.value   = body['today_jobs']   ?? 0;
      activeJobs.value  = body['active_jobs']  ?? 0;
      pendingJobs.value = body['pending_jobs'] ?? 0;

      final list = (body['assignments'] as List? ?? []);
      allAssignments.value = list.cast<Map<String, dynamic>>();

      _loadJobsForDay(selectedDay.value);
    } catch (e) {
      AppFeedback.showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      isLoading.value = false;
    }
  }

  void onDaySelected(DateTime selected, DateTime focused) {
    selectedDay.value = selected;
    focusedDay.value  = focused;
    _loadJobsForDay(selected);
  }

  void _loadJobsForDay(DateTime day) {
    final dateStr = _fmt(day);
    selectedDayJobs.value =
        allAssignments.where((a) => a['assigned_date'] == dateStr).toList();
  }

  bool hasJob(DateTime day) {
    return allAssignments.any((a) => a['assigned_date'] == _fmt(day));
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}