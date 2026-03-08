import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../services/api_service.dart';
import '../utils/app_feedback.dart';

class DashboardController extends GetxController {
  final _box = GetStorage();

  final userName = ''.obs;
  final isLoading = false.obs;
  final todayJobs = 0.obs;
  final activeJobs = 0.obs;
  final pendingJobs = 0.obs;
  final jobEvents = <DateTime>[].obs;
  final selectedDay = DateTime.now().obs;
  final focusedDay = DateTime.now().obs;

  // jobs for selected day
  final selectedDayJobs = <Map<String, dynamic>>[].obs;

  // all assignments raw
  final allAssignments = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    userName.value = _box.read('user_email') ?? '';
    fetchDashboard();
  }

  Future<void> fetchDashboard() async {
    try {
      isLoading.value = true;
      final res = await ApiService.getDashboard();

      todayJobs.value = res['today_jobs'] ?? 0;
      activeJobs.value = res['active_jobs'] ?? 0;
      pendingJobs.value = res['pending_jobs'] ?? 0;

      // parse assignments
      final list = (res['assignments'] as List? ?? []);
      allAssignments.value = list.cast<Map<String, dynamic>>();

      // extract job dates for calendar dots
      jobEvents.value = list.map((a) {
        final dateStr = a['assigned_date'] as String?;
        if (dateStr == null) return null;
        return DateTime.tryParse(dateStr);
      }).whereType<DateTime>().toList();

      // load today's jobs
      _loadJobsForDay(selectedDay.value);
    } catch (e) {
      AppFeedback.showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      isLoading.value = false;
    }
  }

  void onDaySelected(DateTime selected, DateTime focused) {
    selectedDay.value = selected;
    focusedDay.value = focused;
    _loadJobsForDay(selected);
  }

  void _loadJobsForDay(DateTime day) {
    final dateStr =
        '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
    selectedDayJobs.value = allAssignments
        .where((a) => a['assigned_date'] == dateStr)
        .toList();
  }

  bool hasJob(DateTime day) {
    final dateStr =
        '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
    return allAssignments.any((a) => a['assigned_date'] == dateStr);
  }
}