import 'package:get/get.dart';
import '../services/api_service.dart';
import '../utils/app_feedback.dart';

class TimesheetsController extends GetxController {
  // ── State ──────────────────────────────────────────────────────────────────
  final isLoading   = false.obs;
  final mode        = 'weekly'.obs;   // 'daily' | 'weekly' | 'monthly'
  final offset      = 0.obs;

  final label       = ''.obs;
  final periodStart = ''.obs;
  final periodEnd   = ''.obs;
  final totalHours  = 0.0.obs;

  final logs        = <Map<String, dynamic>>[].obs;

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  void onInit() {
    super.onInit();
    fetchTimesheet();
  }

  // ── Public helpers ─────────────────────────────────────────────────────────

  void setMode(String newMode) {
    mode.value   = newMode;
    offset.value = 0;
    fetchTimesheet();
  }

  void prev() {
    offset.value--;
    fetchTimesheet();
  }

  void next() {
    if (offset.value >= 0) return; // can't go into the future
    offset.value++;
    fetchTimesheet();
  }

  bool get canGoNext => offset.value < 0;

  /// Group logs by date string (yyyy-MM-dd) for the daily-breakdown view.
  Map<String, List<Map<String, dynamic>>> get breakdown {
    final map = <String, List<Map<String, dynamic>>>{};
    for (final log in logs) {
      final raw = log['clock_in_at'] as String?;
      if (raw == null) continue;
      final dateKey = raw.substring(0, 10); // 'yyyy-MM-dd'
      map.putIfAbsent(dateKey, () => []).add(log);
    }
    return map;
  }

  // ── API call ───────────────────────────────────────────────────────────────
  Future<void> fetchTimesheet() async {
    try {
      isLoading.value = true;

      final res = await ApiService.getTimesheet(
        mode:   mode.value,
        offset: offset.value,
      );

      label.value       = res['label']      ?? '';
      periodStart.value = res['start']      ?? '';
      periodEnd.value   = res['end']        ?? '';
      final rawHours = res["totalHours"];
      totalHours.value  = rawHours == null ? 0.0 : double.tryParse(rawHours.toString()) ?? 0.0;
      logs.value        = (res['logs'] as List? ?? []).cast<Map<String, dynamic>>();
    } catch (e) {
      AppFeedback.showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      isLoading.value = false;
    }
  }
}