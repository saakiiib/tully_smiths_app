import 'dart:convert';
import 'dart:io';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../../services/api_service.dart';
import '../utils/app_feedback.dart';
import 'package:flutter/material.dart';

class AdminWorker {
  final int id;
  final String name;
  AdminWorker({required this.id, required this.name});
  factory AdminWorker.fromJson(Map<String, dynamic> j) =>
      AdminWorker(id: j['id'], name: j['name']);
}

class AdminTimeAssignment {
  final int id;
  final int serviceJobId;
  final String jobTitle;
  final String jobId;
  final String? startTime;
  final String? endTime;
  final String? address;

  AdminTimeAssignment({
    required this.id,
    required this.serviceJobId,
    required this.jobTitle,
    required this.jobId,
    this.startTime,
    this.endTime,
    this.address,
  });

  factory AdminTimeAssignment.fromJson(Map<String, dynamic> j) {
    final job = j['job'] ?? {};
    return AdminTimeAssignment(
      id: j['id'],
      serviceJobId: j['service_job_id'],
      jobTitle: job['job_title'] ?? '',
      jobId: job['job_id'] ?? '',
      startTime: j['start_time'],
      endTime: j['end_time'],
      address: [job['address_line1'], job['city']]
          .where((e) => e != null && e.toString().isNotEmpty)
          .join(', '),
    );
  }
}

class AdminTimeLog {
  final int id;
  final String? jobTitle;
  final String clockInTime;
  final String? clockOutTime;
  final String? totalHoursFormatted;
  final String? clockInPhoto;
  final String? clockOutPhoto;
  final String? locationNote;
  final bool isActive;

  AdminTimeLog({
    required this.id,
    this.jobTitle,
    required this.clockInTime,
    this.clockOutTime,
    this.totalHoursFormatted,
    this.clockInPhoto,
    this.clockOutPhoto,
    this.locationNote,
    required this.isActive,
  });

  factory AdminTimeLog.fromJson(Map<String, dynamic> j) {
    final job = j['job'];
    return AdminTimeLog(
      id: j['id'],
      jobTitle: job?['job_title'],
      clockInTime: j['clock_in_time'] ?? '',
      clockOutTime: j['clock_out_time'],
      totalHoursFormatted: j['total_hours_formatted'],
      clockInPhoto: j['clock_in_photo'],
      clockOutPhoto: j['clock_out_photo'],
      locationNote: j['location_note'],
      isActive: j['clock_out_at'] == null,
    );
  }
}

class AdminTimeController extends GetxController {
  final isLoadingWorkers  = false.obs;
  final isLoadingData     = false.obs;
  final isSubmitting      = false.obs;

  final workers           = <AdminWorker>[].obs;
  final selectedWorker    = Rxn<AdminWorker>();

  final todayAssignments  = <AdminTimeAssignment>[].obs;
  final activeLog         = Rxn<AdminTimeLog>();
  final recentLogs        = <AdminTimeLog>[].obs;
  final todayHours        = '0.00'.obs;
  final weekHours         = '0.00'.obs;
  final monthHours        = '0.00'.obs;

  // form fields
  final selectedAssignment     = Rxn<AdminTimeAssignment>();
  final clockInDate            = Rxn<DateTime>();
  final clockOutDate           = Rxn<DateTime>();
  final clockInPhotoPath       = RxnString();
  final clockOutPhotoPath      = RxnString();

  @override
  void onInit() {
    super.onInit();
    _fetchWorkers();
  }

  Future<void> _fetchWorkers() async {
    isLoadingWorkers.value = true;
    try {
      final res = await http.get(
        Uri.parse('${ApiService.baseUrl}/admin/time/workers'),
        headers: ApiService.headers,
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        workers.value = (data['workers'] as List)
            .map((w) => AdminWorker.fromJson(w))
            .toList();
      }
    } catch (_) {}
    isLoadingWorkers.value = false;
  }

  Future<void> selectWorker(AdminWorker? w) async {
    selectedWorker.value     = w;
    selectedAssignment.value = null;
    clockInDate.value        = null;
    clockOutDate.value       = null;
    clockInPhotoPath.value   = null;
    clockOutPhotoPath.value  = null;
    if (w == null) return;
    await fetchWorkerData();
  }

  Future<void> fetchWorkerData() async {
    final w = selectedWorker.value;
    if (w == null) return;
    isLoadingData.value = true;
    try {
      final res = await http.get(
        Uri.parse('${ApiService.baseUrl}/admin/time/worker-data?worker_id=${w.id}'),
        headers: ApiService.headers,
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        todayAssignments.value = (data['todayAssignments'] as List)
            .map((a) => AdminTimeAssignment.fromJson(a))
            .toList();
        activeLog.value  = data['activeLog'] != null ? AdminTimeLog.fromJson(data['activeLog']) : null;
        recentLogs.value = (data['recentLogs'] as List).map((l) => AdminTimeLog.fromJson(l)).toList();
        todayHours.value  = (data['todayHours'] as num).toStringAsFixed(2);
        weekHours.value   = (data['weekHours'] as num).toStringAsFixed(2);
        monthHours.value  = (data['monthHours'] as num).toStringAsFixed(2);
      }
    } catch (_) {}
    isLoadingData.value = false;
  }

  Future<void> pickPhoto(bool isClockIn) async {
    final picked = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 82);
    if (picked == null) return;
    if (isClockIn) {
      clockInPhotoPath.value = picked.path;
    } else {
      clockOutPhotoPath.value = picked.path;
    }
  }

  Future<void> submitManualClockIn() async {
    final w = selectedWorker.value;
    final a = selectedAssignment.value;
    if (w == null || a == null) {
      AppFeedback.showError('Please select a worker and assignment.');
      return;
    }
    if (clockInDate.value == null) {
      AppFeedback.showError('Please set clock-in date & time.');
      return;
    }
    if (clockOutDate.value != null && clockOutDate.value!.isBefore(clockInDate.value!)) {
      AppFeedback.showError('Clock-out must be after clock-in.');
      return;
    }

    isSubmitting.value = true;
    try {
      final body = <String, dynamic>{
        'worker_id':         w.id,
        'job_assignment_id': a.id,
        'clock_in_at':       clockInDate.value!.toIso8601String(),
        if (clockOutDate.value != null)
          'clock_out_at': clockOutDate.value!.toIso8601String(),
      };

      if (clockInPhotoPath.value != null) {
        final bytes = await File(clockInPhotoPath.value!).readAsBytes();
        body['clock_in_photo'] = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      }
      if (clockOutPhotoPath.value != null && clockOutDate.value != null) {
        final bytes = await File(clockOutPhotoPath.value!).readAsBytes();
        body['clock_out_photo'] = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      }

      final res = await http.post(
        Uri.parse('${ApiService.baseUrl}/admin/time/manual-clock-in'),
        headers: ApiService.headers,
        body: jsonEncode(body),
      );

      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        AppFeedback.showSuccess(data['message'] ?? 'Clock in recorded.');
        _resetForm();
        await fetchWorkerData();
        Get.back();
      } else {
        AppFeedback.showError(data['message'] ?? 'Failed to clock in.');
      }
    } catch (_) {
      AppFeedback.showError('Something went wrong.');
    }
    isSubmitting.value = false;
  }

  Future<void> submitClockOut() async {
    final w = selectedWorker.value;
    if (w == null || activeLog.value == null) return;

    final confirmed = await AppFeedback.showConfirm(
      title: 'Clock Out Worker?',
      message: 'Clock out ${w.name} now?',
      confirmText: 'Yes, Clock Out',
      cancelText: 'Cancel',
      confirmColor: Colors.red.shade600,
    );
    if (!confirmed) return;

    isSubmitting.value = true;
    try {
      final body = <String, dynamic>{'worker_id': w.id};

      if (clockOutPhotoPath.value != null) {
        final bytes = await File(clockOutPhotoPath.value!).readAsBytes();
        body['clock_out_photo'] = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      }

      final res = await http.post(
        Uri.parse('${ApiService.baseUrl}/admin/time/clock-out'),
        headers: ApiService.headers,
        body: jsonEncode(body),
      );

      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        AppFeedback.showSuccess(data['message'] ?? 'Clocked out.');
        clockOutPhotoPath.value = null;
        await fetchWorkerData();
      } else {
        AppFeedback.showError(data['message'] ?? 'Failed to clock out.');
      }
    } catch (_) {
      AppFeedback.showError('Something went wrong.');
    }
    isSubmitting.value = false;
  }

  void _resetForm() {
    selectedAssignment.value  = null;
    clockInDate.value         = null;
    clockOutDate.value        = null;
    clockInPhotoPath.value    = null;
    clockOutPhotoPath.value   = null;
  }
}