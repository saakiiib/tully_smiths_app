import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../services/api_service.dart';
import '../utils/app_feedback.dart';

class JobDetailController extends GetxController {
  final int jobId;
  JobDetailController(this.jobId);

  final isLoading = true.obs;
  final isSubmitting = false.obs;

  final job = <String, dynamic>{}.obs;
  final notes = <Map<String, dynamic>>[].obs;
  final documents = <Map<String, dynamic>>[].obs;
  final checklists = <Map<String, dynamic>>[].obs;
  final availableChecklists = <Map<String, dynamic>>[].obs;
  final assignments = <Map<String, dynamic>>[].obs;
  final timeLogs = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchDetail();
  }

  Future<void> fetchDetail() async {
    try {
      isLoading.value = true;
      final res = await http.get(
        Uri.parse('${ApiService.baseUrl}/jobs/$jobId/detail'),
        headers: ApiService.headers,
      ).timeout(const Duration(seconds: 15));

      final body = jsonDecode(res.body);
      if (res.statusCode != 200) throw Exception(body['message'] ?? 'Failed');

      job.value                 = Map<String, dynamic>.from(body['job']);
      notes.value               = (body['notes'] as List).cast<Map<String, dynamic>>();
      documents.value           = (body['documents'] as List).cast<Map<String, dynamic>>();
      checklists.value          = (body['checklists'] as List).cast<Map<String, dynamic>>();
      availableChecklists.value = (body['available_checklists'] as List).cast<Map<String, dynamic>>();
      assignments.value         = (body['assignments'] as List).cast<Map<String, dynamic>>();
      timeLogs.value            = (body['time_logs'] as List).cast<Map<String, dynamic>>();
    } catch (e) {
      AppFeedback.showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addNote(String note) async {
    try {
      isSubmitting.value = true;
      final res = await http.post(
        Uri.parse('${ApiService.baseUrl}/jobs/$jobId/notes'),
        headers: ApiService.headers,
        body: jsonEncode({'note': note}),
      ).timeout(const Duration(seconds: 10));

      final body = jsonDecode(res.body);
      if (res.statusCode != 201) throw Exception(body['message'] ?? 'Failed');

      notes.insert(0, Map<String, dynamic>.from(body['note']));
      AppFeedback.showSuccess(body['message']);
    } catch (e) {
      AppFeedback.showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> deleteNote(int noteId) async {
    final confirmed = await AppFeedback.showConfirm(
      title: 'Delete Note',
      message: 'Are you sure?',
      confirmText: 'Delete',
      confirmColor: Colors.red,
    );
    if (!confirmed) return;
    try {
      final res = await http.delete(
        Uri.parse('${ApiService.baseUrl}/jobs/$jobId/notes/$noteId'),
        headers: ApiService.headers,
      ).timeout(const Duration(seconds: 10));
      final body = jsonDecode(res.body);
      if (res.statusCode != 200) throw Exception(body['message'] ?? 'Failed');
      notes.removeWhere((n) => n['id'] == noteId);
      AppFeedback.showSuccess(body['message']);
    } catch (e) {
      AppFeedback.showError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> uploadDocument({
    required File file,
    required String type,
    String? title,
    String? amount,
  }) async {
    try {
      isSubmitting.value = true;
      final uri = Uri.parse('${ApiService.baseUrl}/jobs/$jobId/documents');
      final req = http.MultipartRequest('POST', uri);
      req.headers.addAll({
        'Accept': 'application/json',
        if (ApiService.token != null) 'Authorization': 'Bearer ${ApiService.token}',
      });
      req.fields['type'] = type;
      if (title != null && title.isNotEmpty) req.fields['title'] = title;
      if (amount != null && amount.isNotEmpty) req.fields['amount'] = amount;

      final ext = file.path.split('.').last.toLowerCase();
      final mime = ext == 'pdf' ? MediaType('application', 'pdf') : MediaType('image', ext);
      req.files.add(await http.MultipartFile.fromPath('file', file.path, contentType: mime));

      final streamed = await req.send().timeout(const Duration(seconds: 30));
      final res = await http.Response.fromStream(streamed);
      final body = jsonDecode(res.body);
      if (res.statusCode != 201) throw Exception(body['message'] ?? 'Failed');

      documents.insert(0, Map<String, dynamic>.from(body['document']));
      AppFeedback.showSuccess(body['message']);
    } catch (e) {
      AppFeedback.showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> deleteDocument(int docId) async {
    final confirmed = await AppFeedback.showConfirm(
      title: 'Delete Document',
      message: 'Are you sure?',
      confirmText: 'Delete',
      confirmColor: Colors.red,
    );
    if (!confirmed) return;
    try {
      final res = await http.delete(
        Uri.parse('${ApiService.baseUrl}/jobs/$jobId/documents/$docId'),
        headers: ApiService.headers,
      ).timeout(const Duration(seconds: 10));
      final body = jsonDecode(res.body);
      if (res.statusCode != 200) throw Exception(body['message'] ?? 'Failed');
      documents.removeWhere((d) => d['id'] == docId);
      AppFeedback.showSuccess(body['message']);
    } catch (e) {
      AppFeedback.showError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> assignChecklist(int checklistId, String showAt) async {
    try {
      isSubmitting.value = true;
      final res = await http.post(
        Uri.parse('${ApiService.baseUrl}/jobs/$jobId/checklists'),
        headers: ApiService.headers,
        body: jsonEncode({'checklist_id': checklistId, 'show_at': showAt}),
      ).timeout(const Duration(seconds: 10));
      final body = jsonDecode(res.body);
      if (res.statusCode != 200 && res.statusCode != 201) throw Exception(body['message'] ?? 'Failed');
      AppFeedback.showSuccess(body['message']);
      await fetchDetail();
    } catch (e) {
      AppFeedback.showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> removeChecklist(int assignmentId) async {
    final confirmed = await AppFeedback.showConfirm(
      title: 'Remove Checklist',
      message: 'Remove this checklist from the job?',
      confirmText: 'Remove',
      confirmColor: Colors.red,
    );
    if (!confirmed) return;
    try {
      final res = await http.delete(
        Uri.parse('${ApiService.baseUrl}/jobs/$jobId/checklists/$assignmentId'),
        headers: ApiService.headers,
      ).timeout(const Duration(seconds: 10));
      final body = jsonDecode(res.body);
      if (res.statusCode != 200) throw Exception(body['message'] ?? 'Failed');
      checklists.removeWhere((c) => c['id'] == assignmentId);
      AppFeedback.showSuccess(body['message']);
    } catch (e) {
      AppFeedback.showError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> saveAnswers(int assignmentId, Map<String, String> answers, Map<String, File> photos) async {
    try {
      isSubmitting.value = true;

      if (photos.isEmpty) {
        final res = await http.post(
          Uri.parse('${ApiService.baseUrl}/jobs/checklists/$assignmentId/answers'),
          headers: ApiService.headers,
          body: jsonEncode({'answers': answers}),
        ).timeout(const Duration(seconds: 15));
        final body = jsonDecode(res.body);
        if (res.statusCode != 200) throw Exception(body['message'] ?? 'Failed');
        AppFeedback.showSuccess(body['message']);
      } else {
        final uri = Uri.parse('${ApiService.baseUrl}/jobs/checklists/$assignmentId/answers');
        final req = http.MultipartRequest('POST', uri);
        req.headers.addAll({
          'Accept': 'application/json',
          if (ApiService.token != null) 'Authorization': 'Bearer ${ApiService.token}',
        });

        answers.forEach((k, v) => req.fields['answers[$k]'] = v);

        for (final entry in photos.entries) {
          final ext = entry.value.path.split('.').last.toLowerCase();
          req.files.add(await http.MultipartFile.fromPath(
            'photos[${entry.key}]',
            entry.value.path,
            contentType: MediaType('image', ext),
          ));
        }

        final streamed = await req.send().timeout(const Duration(seconds: 30));
        final res = await http.Response.fromStream(streamed);
        final body = jsonDecode(res.body);
        if (res.statusCode != 200) throw Exception(body['message'] ?? 'Failed');
        AppFeedback.showSuccess(body['message']);
      }

      await fetchDetail();
    } catch (e) {
      AppFeedback.showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      isSubmitting.value = false;
    }
  }
}