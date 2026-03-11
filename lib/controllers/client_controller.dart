import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import '../utils/app_feedback.dart';

class ClientController extends GetxController {
  final isLoading = false.obs;
  final isSubmitting = false.obs;
  final clients = <Map<String, dynamic>>[].obs;

  int _currentPage = 1;
  int _lastPage = 1;
  final isLoadingMore = false.obs;
  final searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchClients();
  }

  Future<void> fetchClients({bool reset = true}) async {
    try {
      if (reset) {
        _currentPage = 1;
        isLoading.value = true;
      } else {
        if (_currentPage > _lastPage) return;
        isLoadingMore.value = true;
      }

      final uri = Uri.parse('${ApiService.baseUrl}/client').replace(queryParameters: {
        'page': '$_currentPage',
        if (searchQuery.value.isNotEmpty) 'search': searchQuery.value,
      });

      final res = await http.get(uri, headers: ApiService.headers)
          .timeout(const Duration(seconds: 10));

      final body = jsonDecode(res.body);

      if (res.statusCode != 200) throw Exception(body['message'] ?? 'Failed to load');

      _lastPage = body['last_page'] ?? 1;
      final list = (body['data'] as List).cast<Map<String, dynamic>>();

      if (reset) {
        clients.value = list;
      } else {
        clients.addAll(list);
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
    await fetchClients(reset: false);
  }

  Future<void> search(String query) async {
    searchQuery.value = query;
    await fetchClients();
  }

  Future<void> storeClient(Map<String, dynamic> data) async {
    try {
      isSubmitting.value = true;
      final res = await http.post(
        Uri.parse('${ApiService.baseUrl}/client'),
        headers: ApiService.headers,
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 10));

      final body = jsonDecode(res.body);
      if (res.statusCode != 201) throw Exception(body['message'] ?? 'Failed to create');

      AppFeedback.showSuccess(body['message']);
      await fetchClients();
    } catch (e) {
      AppFeedback.showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> updateClient(int id, Map<String, dynamic> data) async {
    try {
      isSubmitting.value = true;
      final res = await http.put(
        Uri.parse('${ApiService.baseUrl}/client/$id'),
        headers: ApiService.headers,
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 10));

      final body = jsonDecode(res.body);
      if (res.statusCode != 200) throw Exception(body['message'] ?? 'Failed to update');

      AppFeedback.showSuccess(body['message']);
      await fetchClients();
    } catch (e) {
      AppFeedback.showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> deleteClient(int id) async {
    final confirmed = await AppFeedback.showConfirm(
      title: 'Delete Client',
      message: 'Are you sure you want to delete this client?',
      confirmText: 'Delete',
      confirmColor: Colors.red,
    );
    if (!confirmed) return;

    try {
      final res = await http.delete(
        Uri.parse('${ApiService.baseUrl}/client/$id'),
        headers: ApiService.headers,
      ).timeout(const Duration(seconds: 10));

      final body = jsonDecode(res.body);
      if (res.statusCode != 200) throw Exception(body['message'] ?? 'Failed to delete');

      AppFeedback.showSuccess(body['message']);
      await fetchClients();
    } catch (e) {
      AppFeedback.showError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> toggleStatus(int id, int currentStatus) async {
    try {
      final newStatus = currentStatus == 1 ? 0 : 1;
      final res = await http.post(
        Uri.parse('${ApiService.baseUrl}/client/status'),
        headers: ApiService.headers,
        body: jsonEncode({'id': id, 'status': newStatus}),
      ).timeout(const Duration(seconds: 10));

      final body = jsonDecode(res.body);
      if (res.statusCode != 200) throw Exception(body['message'] ?? 'Failed');

      AppFeedback.showSuccess(body['message']);
      await fetchClients();
    } catch (e) {
      AppFeedback.showError(e.toString().replaceAll('Exception: ', ''));
    }
  }
}