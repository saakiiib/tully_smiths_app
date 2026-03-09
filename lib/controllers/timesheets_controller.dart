import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import '../utils/app_feedback.dart';

class TimesheetsController extends GetxController {
  final isLoading   = false.obs;
  final mode        = 'weekly'.obs;
  final offset      = 0.obs;

  final label       = ''.obs;
  final periodStart = ''.obs;
  final periodEnd   = ''.obs;
  final totalHours  = 0.0.obs;

  final logs        = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchTimesheet();
  }

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
    if (offset.value >= 0) return;
    offset.value++;
    fetchTimesheet();
  }

  bool get canGoNext => offset.value < 0;

  Map<String, List<Map<String, dynamic>>> get breakdown {
    final map = <String, List<Map<String, dynamic>>>{};
    for (final log in logs) {
      final raw = log['clock_in_at'] as String?;
      if (raw == null) continue;
      final dateKey = raw.substring(0, 10);
      map.putIfAbsent(dateKey, () => []).add(log);
    }
    return map;
  }

  Future<void> fetchTimesheet() async {
    try {
      isLoading.value = true;

      final res = await http
          .get(
            Uri.parse('${ApiService.baseUrl}/time/timesheet?mode=${mode.value}&offset=${offset.value}'),
            headers: ApiService.headers,
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode != 200) throw Exception('Failed to load timesheet');

      final body = jsonDecode(res.body) as Map<String, dynamic>;

      label.value       = body['label'] ?? '';
      periodStart.value = body['start'] ?? '';
      periodEnd.value   = body['end']   ?? '';
      final rawHours    = body['totalHours'];
      totalHours.value  = rawHours == null ? 0.0 : double.tryParse(rawHours.toString()) ?? 0.0;
      logs.value        = (body['logs'] as List? ?? []).cast<Map<String, dynamic>>();
    } catch (e) {
      AppFeedback.showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      isLoading.value = false;
    }
  }
}