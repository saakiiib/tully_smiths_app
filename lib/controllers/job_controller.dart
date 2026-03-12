import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import '../utils/app_feedback.dart';

class JobController extends GetxController {
  final isLoading = false.obs;
  final isSubmitting = false.obs;
  final jobs = <Map<String, dynamic>>[].obs;
  final clients = <Map<String, dynamic>>[].obs;

  int _currentPage = 1;
  int _lastPage = 1;
  final isLoadingMore = false.obs;
  final searchQuery = ''.obs;
  final statusFilter = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchJobs();
  }

  Future<void> fetchJobs({bool reset = true}) async {
    try {
      if (reset) {
        _currentPage = 1;
        isLoading.value = true;
      } else {
        if (_currentPage > _lastPage) return;
        isLoadingMore.value = true;
      }

      final uri = Uri.parse('${ApiService.baseUrl}/jobs').replace(queryParameters: {
        'page': '$_currentPage',
        if (searchQuery.value.isNotEmpty) 'search': searchQuery.value,
        if (statusFilter.value.isNotEmpty) 'status': statusFilter.value,
      });

      final res = await http.get(uri, headers: ApiService.headers)
          .timeout(const Duration(seconds: 10));

      final body = jsonDecode(res.body);
      if (res.statusCode != 200) throw Exception(body['message'] ?? 'Failed to load');

      _lastPage = body['last_page'] ?? 1;
      final list = (body['data'] as List).cast<Map<String, dynamic>>();

      if (reset && body['clients'] != null) {
        clients.value = (body['clients'] as List).cast<Map<String, dynamic>>();
      }

      if (reset) {
        jobs.value = list;
      } else {
        jobs.addAll(list);
      }
      _currentPage++;
    } catch (e) {
      AppFeedback.showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }

  Future<void> loadMore() async {
    if (isLoadingMore.value || _currentPage > _lastPage) return;
    await fetchJobs(reset: false);
  }

  Future<void> search(String query) async {
    searchQuery.value = query;
    await fetchJobs();
  }

  Future<void> filterByStatus(String status) async {
    statusFilter.value = status;
    await fetchJobs();
  }

  Future<Map<String, dynamic>?> fetchSingle(int id) async {
    try {
      final res = await http.get(
        Uri.parse('${ApiService.baseUrl}/jobs/$id'),
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

  Future<void> storeJob(Map<String, dynamic> data) async {
    try {
      isSubmitting.value = true;
      final res = await http.post(
        Uri.parse('${ApiService.baseUrl}/jobs'),
        headers: ApiService.headers,
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 10));

      final body = jsonDecode(res.body);
      if (res.statusCode != 201) throw Exception(body['message'] ?? 'Failed to create');

      AppFeedback.showSuccess(body['message']);
      await fetchJobs();
    } catch (e) {
      AppFeedback.showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> updateJob(int id, Map<String, dynamic> data) async {
    try {
      isSubmitting.value = true;
      final res = await http.put(
        Uri.parse('${ApiService.baseUrl}/jobs/$id'),
        headers: ApiService.headers,
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 10));

      final body = jsonDecode(res.body);
      if (res.statusCode != 200) throw Exception(body['message'] ?? 'Failed to update');

      AppFeedback.showSuccess(body['message']);
      await fetchJobs();
    } catch (e) {
      AppFeedback.showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> deleteJob(int id) async {
    final confirmed = await AppFeedback.showConfirm(
      title: 'Delete Job',
      message: 'Are you sure you want to delete this job?',
      confirmText: 'Delete',
      confirmColor: Colors.red,
    );
    if (!confirmed) return;

    try {
      final res = await http.delete(
        Uri.parse('${ApiService.baseUrl}/jobs/$id'),
        headers: ApiService.headers,
      ).timeout(const Duration(seconds: 10));

      final body = jsonDecode(res.body);
      if (res.statusCode != 200) throw Exception(body['message'] ?? 'Failed to delete');

      AppFeedback.showSuccess(body['message']);
      await fetchJobs();
    } catch (e) {
      AppFeedback.showError(e.toString().replaceAll('Exception: ', ''));
    }
  }
}