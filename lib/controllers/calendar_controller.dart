import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import '../utils/app_feedback.dart';

class CalendarController extends GetxController {
  final isLoading    = false.obs;
  final isSubmitting = false.obs;

  final assignments            = <Map<String, dynamic>>[].obs;
  final jobs                   = <Map<String, dynamic>>[].obs;
  final workers                = <Map<String, dynamic>>[].obs;
  final selectedDay            = DateTime.now().obs;
  final focusedDay             = DateTime.now().obs;
  final selectedDayAssignments = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchIndex();
  }

  Future<void> fetchIndex() async {
    try {
      isLoading.value = true;

      final res = await http.get(
        Uri.parse('${ApiService.baseUrl}/calendar'),
        headers: ApiService.headers,
      ).timeout(const Duration(seconds: 10));

      final body = jsonDecode(res.body);
      if (res.statusCode != 200) throw Exception(body['message'] ?? 'Failed to load');

      jobs.value        = (body['jobs']        as List).cast<Map<String, dynamic>>();
      workers.value     = (body['workers']     as List).cast<Map<String, dynamic>>();
      assignments.value = (body['assignments'] as List).cast<Map<String, dynamic>>();

      _loadForDay(selectedDay.value);
    } catch (e) {
      AppFeedback.showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      isLoading.value = false;
    }
  }

  void onDaySelected(DateTime selected, DateTime focused) {
    selectedDay.value = selected;
    focusedDay.value  = focused;
    _loadForDay(selected);
  }

  void _loadForDay(DateTime day) {
    final dateStr = fmt(day);
    selectedDayAssignments.value =
        assignments.where((a) => a['assigned_date'] == dateStr).toList();
  }

  bool hasAssignment(DateTime day) =>
      assignments.any((a) => a['assigned_date'] == fmt(day));

  String fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> storeAssignment(Map<String, dynamic> data) async {
    try {
      isSubmitting.value = true;
      final res = await http.post(
        Uri.parse('${ApiService.baseUrl}/calendar'),
        headers: ApiService.headers,
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 10));

      final body = jsonDecode(res.body);
      if (res.statusCode != 201) throw Exception(body['message'] ?? 'Failed to create');

      AppFeedback.showSuccess(body['message']);
      Get.back();
      await fetchIndex();
    } catch (e) {
      AppFeedback.showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> updateAssignment(int id, Map<String, dynamic> data) async {
    try {
      isSubmitting.value = true;
      final res = await http.put(
        Uri.parse('${ApiService.baseUrl}/calendar/$id'),
        headers: ApiService.headers,
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 10));

      final body = jsonDecode(res.body);
      if (res.statusCode != 200) throw Exception(body['message'] ?? 'Failed to update');

      AppFeedback.showSuccess(body['message']);
      Get.back();
      await fetchIndex();
    } catch (e) {
      AppFeedback.showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> delete(int id) async {
    final confirmed = await AppFeedback.showConfirm(
      title: 'Delete Assignment',
      message: 'Are you sure you want to delete this assignment?',
      confirmText: 'Delete',
      confirmColor: Colors.red,
    );
    if (!confirmed) return;

    try {
      final res = await http.delete(
        Uri.parse('${ApiService.baseUrl}/calendar/$id'),
        headers: ApiService.headers,
      ).timeout(const Duration(seconds: 10));

      final body = jsonDecode(res.body);
      if (res.statusCode != 200) throw Exception(body['message'] ?? 'Failed to delete');

      AppFeedback.showSuccess(body['message']);
      await fetchIndex();
    } catch (e) {
      AppFeedback.showError(e.toString().replaceAll('Exception: ', ''));
    }
  }
}