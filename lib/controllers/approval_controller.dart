import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import '../utils/app_feedback.dart';

class ApprovalController extends GetxController {
  final isLoading      = false.obs;
  final isLoadingMore  = false.obs;
  final isSubmitting   = false.obs;
  final items          = <Map<String, dynamic>>[].obs;
  final currentStatus  = 'pending'.obs;

  final pendingCount  = 0.obs;
  final approvedCount = 0.obs;
  final rejectedCount = 0.obs;
  final allCount      = 0.obs;

  int _currentPage = 1;
  int _lastPage    = 1;

  @override
  void onInit() {
    super.onInit();
    fetchApprovals();
  }

  Future<void> fetchApprovals({String status = 'pending', bool reset = true}) async {
    try {
      if (reset) {
        _currentPage = 1;
        currentStatus.value = status;
        isLoading.value = true;
      } else {
        if (_currentPage > _lastPage) return;
        isLoadingMore.value = true;
      }

      final res = await http.get(
        Uri.parse('${ApiService.baseUrl}/approvals?status=$status&page=$_currentPage'),
        headers: ApiService.headers,
      ).timeout(const Duration(seconds: 10));

      final body = jsonDecode(res.body);
      if (res.statusCode != 200) throw Exception(body['message'] ?? 'Failed');

      _lastPage = body['last_page'] ?? 1;
      final list = (body['items'] as List).cast<Map<String, dynamic>>();

      if (reset) {
        items.value = list;
      } else {
        items.addAll(list);
      }

      pendingCount.value  = body['pending_count'] ?? 0;
      approvedCount.value = body['approved_count'] ?? 0;
      rejectedCount.value = body['rejected_count'] ?? 0;
      allCount.value      = body['all_count'] ?? 0;

      _currentPage++;
    } catch (e) {
      AppFeedback.showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      isLoading.value     = false;
      isLoadingMore.value = false;
    }
  }

  Future<void> loadMore() async {
    if (isLoadingMore.value || _currentPage > _lastPage) return;
    await fetchApprovals(status: currentStatus.value, reset: false);
  }

  Future<Map<String, dynamic>?> fetchDetail(String type, int id) async {
    try {
      final res = await http.get(
        Uri.parse('${ApiService.baseUrl}/approvals/$type/$id'),
        headers: ApiService.headers,
      ).timeout(const Duration(seconds: 10));

      final body = jsonDecode(res.body);
      if (res.statusCode != 200) throw Exception(body['message'] ?? 'Failed');

      return Map<String, dynamic>.from(body);
    } catch (e) {
      AppFeedback.showError(e.toString().replaceAll('Exception: ', ''));
      return null;
    }
  }

  Future<void> performAction(String type, int id, String action, {String? rejectionReason}) async {
    try {
      isSubmitting.value = true;

      final res = await http.post(
        Uri.parse('${ApiService.baseUrl}/approvals/$type/$id/action'),
        headers: ApiService.headers,
        body: jsonEncode({
          'action': action,
          if (rejectionReason != null && rejectionReason.isNotEmpty)
            'rejection_reason': rejectionReason,
        }),
      ).timeout(const Duration(seconds: 10));

      final body = jsonDecode(res.body);
      if (res.statusCode != 200) throw Exception(body['message'] ?? 'Failed');

      AppFeedback.showSuccess('Action successful');
      await fetchApprovals(status: currentStatus.value);
    } catch (e) {
      AppFeedback.showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      isSubmitting.value = false;
    }
  }
}