import 'dart:convert';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../../services/api_service.dart';
import '../utils/app_feedback.dart';
import 'package:flutter/material.dart';

class ChecklistItem {
  final int id;
  final String question;
  final String type;
  final bool isRequired;
  String? existingAnswer;
  String? existingPhotoPath;

  ChecklistItem({
    required this.id,
    required this.question,
    required this.type,
    required this.isRequired,
    this.existingAnswer,
    this.existingPhotoPath,
  });

  factory ChecklistItem.fromJson(Map<String, dynamic> j) => ChecklistItem(
        id: j['id'],
        question: j['question'],
        type: j['type'],
        isRequired: j['is_required'] == true || j['is_required'] == 1,
        existingAnswer: j['existing_answer'],
        existingPhotoPath: j['existing_photo_path'],
      );
}

class ChecklistGroup {
  final int id;
  final String title;
  final List<ChecklistItem> items;

  ChecklistGroup({required this.id, required this.title, required this.items});

  factory ChecklistGroup.fromJson(Map<String, dynamic> j) => ChecklistGroup(
        id: j['id'],
        title: j['title'],
        items: (j['items'] as List).map((i) => ChecklistItem.fromJson(i)).toList(),
      );
}

class JobAssignment {
  final int id;
  final int serviceJobId;
  final String jobTitle;
  final String jobId;
  final String? startTime;
  final String? endTime;
  final String? postcode;
  final String? address;

  JobAssignment({
    required this.id,
    required this.serviceJobId,
    required this.jobTitle,
    required this.jobId,
    this.startTime,
    this.endTime,
    this.postcode,
    this.address,
  });

  factory JobAssignment.fromJson(Map<String, dynamic> j) {
    final job = j['job'] ?? {};
    return JobAssignment(
      id: j['id'],
      serviceJobId: j['service_job_id'],
      jobTitle: job['job_title'] ?? '',
      jobId: job['job_id'] ?? '',
      startTime: j['start_time'],
      endTime: j['end_time'],
      postcode: job['postcode'],
      address: [job['address_line1'], job['city']]
          .where((e) => e != null && e.toString().isNotEmpty)
          .join(', '),
    );
  }
}

class TimeLog {
  final int id;
  final String? jobTitle;
  final String clockInTime;
  final String? clockOutTime;
  final String? totalHours;
  final String? clockInPhoto;
  final String? clockOutPhoto;
  final String? locationNote;
  final bool isActive;

  TimeLog({
    required this.id,
    this.jobTitle,
    required this.clockInTime,
    this.clockOutTime,
    this.totalHours,
    this.clockInPhoto,
    this.clockOutPhoto,
    this.locationNote,
    required this.isActive,
  });

  factory TimeLog.fromJson(Map<String, dynamic> j) {
    final job = j['job'];
    return TimeLog(
      id: j['id'],
      jobTitle: job != null ? job['job_title'] : null,
      clockInTime: j['clock_in_time'] ?? '',
      clockOutTime: j['clock_out_time'],
      totalHours: j['total_hours_formatted'],
      clockInPhoto: j['clock_in_photo'],
      clockOutPhoto: j['clock_out_photo'],
      locationNote: j['location_note'],
      isActive: j['clock_out_at'] == null,
    );
  }
}

class TimeController extends GetxController {
  final isLoading        = false.obs;
  final todayAssignments = <JobAssignment>[].obs;
  final activeLog        = Rxn<TimeLog>();
  final recentLogs       = <TimeLog>[].obs;
  final todayHours       = '0.00'.obs;
  final weekHours        = '0.00'.obs;
  final monthHours       = '0.00'.obs;

  final cameraController  = Rxn<CameraController>();
  final capturedImagePath = RxnString();
  final isCameraReady     = false.obs;
  final isCapturing       = false.obs;

  final locationStatus = 'Getting location…'.obs;
  double? userLat, userLng;

  final selectedAssignment = Rxn<JobAssignment>();

  final checklistGroups    = <ChecklistGroup>[].obs;
  final checklistAnswers   = <String, String>{};
  final checklistPhotos    = <String, File>{};
  final isChecklistLoading = false.obs;

  final isClockOutFlow   = false.obs;
  final isSubmitting     = false.obs;
  final forceClockIn     = false.obs;
  final showCameraScreen = false.obs;
  final showChecklist    = false.obs;

  String _currentChecklistType = 'clock_in';
  int? _currentServiceJobId;

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  Future<void> loadData() async {
    isLoading.value = true;
    try {
      final res = await http.get(Uri.parse('${ApiService.baseUrl}/time'), headers: ApiService.headers);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        todayAssignments.value = (data['todayAssignments'] as List)
            .map((j) => JobAssignment.fromJson(j))
            .toList();
        activeLog.value  = data['activeLog'] != null ? TimeLog.fromJson(data['activeLog']) : null;
        recentLogs.value = (data['recentLogs'] as List).map((j) => TimeLog.fromJson(j)).toList();
        todayHours.value  = (data['todayHours'] as num).toStringAsFixed(2);
        weekHours.value   = (data['weekHours'] as num).toStringAsFixed(2);
        monthHours.value  = (data['monthHours'] as num).toStringAsFixed(2);
      }
    } catch (e, st) {
      debugPrint('loadData error: $e\n$st');
    }
    isLoading.value = false;
  }

  void selectAssignment(JobAssignment a) => selectedAssignment.value = a;

  Future<void> onClockInTapped() async {
    if (selectedAssignment.value == null) {
      AppFeedback.showError('Please select a job first.');
      return;
    }
    final a = selectedAssignment.value!;

    if (a.startTime != null) {
      final nowMins = _londonMinutes(), startMins = _hhmm24toMins(a.startTime!);
      if (nowMins < startMins - 30) {
        final confirmed = await AppFeedback.showConfirm(
          title: 'Clock In Early?',
          message: 'Your shift starts at ${_format12(a.startTime!)} but it\'s ${_londonFormatted()}. Clock in early?',
          confirmText: 'Yes, Clock In',
          cancelText: 'Cancel',
        );
        if (!confirmed) return;
      }
    }
    _startClockInFlow();
  }

  Future<void> onClockOutTapped() async {
    if (activeLog.value == null) return;

    final end = selectedAssignment.value?.endTime;
    if (end != null) {
      final nowMins = _londonMinutes(), endMins = _hhmm24toMins(end);
      if (nowMins < endMins - 15) {
        final confirmed = await AppFeedback.showConfirm(
          title: 'Clock Out Early?',
          message: 'Your shift ends at ${_format12(end)} but it\'s ${_londonFormatted()}. Clock out early?',
          confirmText: 'Yes, Clock Out',
          cancelText: 'Cancel',
          confirmColor: Colors.red.shade600,
        );
        if (!confirmed) return;
      }
    }
    _startClockOutFlow();
  }

  Future<void> _startClockInFlow() async {
    isClockOutFlow.value = false;
    _currentChecklistType = 'clock_in';
    final jobId = selectedAssignment.value?.serviceJobId;
    if (jobId != null) {
      _currentServiceJobId = jobId;
      final has = await _fetchChecklists(jobId, 'clock_in');
      if (has) { showChecklist.value = true; return; }
    }
    await _openCamera();
  }

  Future<void> _startClockOutFlow() async {
    isClockOutFlow.value = true;
    _currentChecklistType = 'clock_out';
    final jobId = selectedAssignment.value?.serviceJobId ?? activeLog.value?.id;
    if (jobId != null) {
      _currentServiceJobId = jobId;
      final has = await _fetchChecklists(jobId, 'clock_out');
      if (has) { showChecklist.value = true; return; }
    }
    await _openCamera();
  }

  Future<bool> _fetchChecklists(int serviceJobId, String type) async {
    isChecklistLoading.value = true;
    checklistGroups.clear();
    checklistAnswers.clear();
    checklistPhotos.clear();
    try {
      final res = await http.get(
        Uri.parse('${ApiService.baseUrl}/time/checklist-questions?service_job_id=$serviceJobId&type=$type'),
        headers: ApiService.headers,
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['has_checklists'] == true && data['groups'] != null) {
          checklistGroups.value = (data['groups'] as List)
              .map((g) => ChecklistGroup.fromJson(g))
              .toList();

          for (final group in checklistGroups) {
            for (final item in group.items) {
              final key = '${group.id}__${item.id}';
              if (item.existingAnswer != null && item.existingAnswer!.isNotEmpty) {
                checklistAnswers[key] = item.existingAnswer!;
              }
            }
          }

          isChecklistLoading.value = false;
          return true;
        }
      }
    } catch (e, st) {
      debugPrint('_fetchChecklists error: $e\n$st');
    }
    isChecklistLoading.value = false;
    return false;
  }

  void setChecklistAnswer(String key, String value) => checklistAnswers[key] = value;
  void setChecklistPhoto(String key, File file)     => checklistPhotos[key] = file;

  Future<void> submitChecklist() async {
    for (final group in checklistGroups) {
      for (final item in group.items) {
        final key = '${group.id}__${item.id}';
        if (item.isRequired) {
          if (item.type == 'photo_upload') {
            if (checklistPhotos[key] == null && item.existingPhotoPath == null) {
              AppFeedback.showError('Please complete: ${item.question}');
              return;
            }
          } else {
            if ((checklistAnswers[key] ?? '').isEmpty) {
              AppFeedback.showError('Please answer: ${item.question}');
              return;
            }
          }
        }
      }
    }

    isSubmitting.value = true;
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiService.baseUrl}/time/save-checklist-answers'),
      );
      request.headers['Accept']        = 'application/json';
      request.headers['Authorization'] = ApiService.token != null ? 'Bearer ${ApiService.token}' : '';

      if (_currentServiceJobId != null) {
        request.fields['service_job_id'] = _currentServiceJobId.toString();
      }
      request.fields['type'] = _currentChecklistType;

      checklistAnswers.forEach((key, value) {
        final idx      = key.indexOf('__');
        final groupId  = key.substring(0, idx);
        final itemId   = key.substring(idx + 2);
        request.fields['answers[$groupId][$itemId]'] = value;
      });

      for (final entry in checklistPhotos.entries) {
        final idx     = entry.key.indexOf('__');
        final groupId = entry.key.substring(0, idx);
        final itemId  = entry.key.substring(idx + 2);
        request.files.add(
          await http.MultipartFile.fromPath(
            'photos[$groupId][$itemId]',
            entry.value.path,
          ),
        );
      }

      final streamedRes = await request.send();
      final body        = await streamedRes.stream.bytesToString();

      debugPrint('submitChecklist response [${streamedRes.statusCode}]: $body');

      if (streamedRes.statusCode == 200) {
        showChecklist.value = false;
        await _openCamera();
      } else {
        try {
          final data = jsonDecode(body);
          if (data['errors'] != null) {
            final errors = data['errors'] as Map<String, dynamic>;
            final firstMsg = (errors.values.first as List).first.toString();
            AppFeedback.showError(firstMsg);
          } else {
            AppFeedback.showError(data['message'] ?? 'Failed to save checklist.');
          }
        } catch (_) {
          AppFeedback.showError('Failed to save checklist. (${streamedRes.statusCode})');
        }
      }
    } catch (e, st) {
      debugPrint('submitChecklist exception: $e\n$st');
      AppFeedback.showError('Failed to save checklist: $e');
    }
    isSubmitting.value = false;
  }

  Future<void> _openCamera() async {
    final ready = await _ensureLocationPermission();
    if (!ready) return;

    capturedImagePath.value = null;
    isCameraReady.value     = false;
    showCameraScreen.value  = true;
    locationStatus.value    = 'Getting location…';
    userLat = userLng       = null;
    await _initCamera();
    await _fetchLocation();
  }
  Future<bool> _ensureLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      final confirmed = await AppFeedback.showConfirm(
        title: 'Location Required',
        message: 'GPS is turned off. Please enable it to clock in.',
        confirmText: 'Open Settings',
        cancelText: 'Cancel',
      );
      if (!confirmed) return false;

      await Geolocator.openLocationSettings();

      for (int i = 0; i < 30; i++) {
        await Future.delayed(const Duration(seconds: 1));
        if (await Geolocator.isLocationServiceEnabled()) break;
      }

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        AppFeedback.showError('GPS is still off. Please enable it and try again.');
        return false;
      }
    }

    LocationPermission perm = await Geolocator.checkPermission();

    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied) {
        AppFeedback.showError('Location permission is required to clock in.');
        return false;
      }
    }

    if (perm == LocationPermission.deniedForever) {
      final confirmed = await AppFeedback.showConfirm(
        title: 'Location Permission Blocked',
        message:
            'You previously denied location access permanently.\n\n'
            'Tap "Open Settings", then go to Permissions → Location and set it to "Allow while using app".',
        confirmText: 'Open Settings',
        cancelText: 'Cancel',
      );
      if (!confirmed) return false;

      await Geolocator.openAppSettings();

      for (int i = 0; i < 30; i++) {
        await Future.delayed(const Duration(seconds: 1));
        final updated = await Geolocator.checkPermission();
        if (updated != LocationPermission.denied &&
            updated != LocationPermission.deniedForever) {
          return true;
        }
      }

      final stillDenied = await Geolocator.checkPermission();
      if (stillDenied == LocationPermission.denied ||
          stillDenied == LocationPermission.deniedForever) {
        AppFeedback.showError(
          'Location permission is still blocked. '
          'Please allow it in Settings → Apps → [App Name] → Permissions.',
        );
        return false;
      }
    }

    return true;
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;
      final cam = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final ctrl = CameraController(cam, ResolutionPreset.high, enableAudio: false);
      await ctrl.initialize();
      cameraController.value = ctrl;
      isCameraReady.value = true;
    } catch (e, st) {
      debugPrint('_initCamera error: $e\n$st');
    }
  }

  Future<void> _fetchLocation() async {
    try {
      locationStatus.value = 'Getting location…';
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );
      userLat = pos.latitude;
      userLng = pos.longitude;
      locationStatus.value = 'Location found ✓';
    } catch (e) {
      debugPrint('_fetchLocation error: $e');
      locationStatus.value = 'Location unavailable';
    }
  }

  Future<void> capturePhoto() async {
    final ctrl = cameraController.value;
    if (ctrl == null || !ctrl.value.isInitialized) return;
    isCapturing.value = true;
    try {
      final file = await ctrl.takePicture();
      capturedImagePath.value = file.path;
    } catch (e, st) {
      debugPrint('capturePhoto error: $e\n$st');
    }
    isCapturing.value = false;
  }

  void retakePhoto() => capturedImagePath.value = null;

  Future<void> confirmAndSubmit() async {
    if (capturedImagePath.value == null) { AppFeedback.showError('Please take a photo first.'); return; }
    isClockOutFlow.value ? await _doClockOut() : await _doClockIn();
  }

  void closeCamera() { showCameraScreen.value = false; _disposeCamera(); }

  void _disposeCamera() {
    cameraController.value?.dispose();
    cameraController.value = null;
    isCameraReady.value = false;
  }

  Future<void> _doClockIn() async {
    isSubmitting.value = true;
    try {
      final bytes = await File(capturedImagePath.value!).readAsBytes();
      final b64 = 'data:image/jpeg;base64,${base64Encode(bytes)}';

      final res = await http.post(
        Uri.parse('${ApiService.baseUrl}/time/clock-in'),
        headers: ApiService.headers,
        body: jsonEncode({
          'job_assignment_id': selectedAssignment.value!.id,
          'photo': b64,
          'lat': userLat,
          'lng': userLng,
          'force': forceClockIn.value,
        }),
      );

      final data = jsonDecode(res.body);

      if (res.statusCode == 200 && data['warning'] == true) {
        closeCamera();
        final confirmed = await AppFeedback.showConfirm(
          title: 'Already Worked Today',
          message: data['message'],
          confirmText: 'Clock In Again',
          cancelText: 'Cancel',
        );
        if (confirmed) {
          forceClockIn.value = true;
          _startClockInFlow();
        }
        isSubmitting.value = false;
        return;
      }

      if (res.statusCode == 200 || res.statusCode == 201) {
        AppFeedback.showSuccess(data['message'] ?? 'Clocked in successfully.');
        closeCamera();
        forceClockIn.value = false;
        await loadData();
      } else {
        AppFeedback.showError(data['message'] ?? 'Error clocking in.');
      }
    } catch (e, st) {
      debugPrint('_doClockIn error: $e\n$st');
      AppFeedback.showError('Error clocking in.');
    }
    isSubmitting.value = false;
  }

  Future<void> _doClockOut() async {
    isSubmitting.value = true;
    try {
      final bytes = await File(capturedImagePath.value!).readAsBytes();
      final b64 = 'data:image/jpeg;base64,${base64Encode(bytes)}';

      final res = await http.post(
        Uri.parse('${ApiService.baseUrl}/time/clock-out'),
        headers: ApiService.headers,
        body: jsonEncode({
            'photo': b64,
            'lat': userLat,
            'lng': userLng,
        }),
      );

      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        AppFeedback.showSuccess(data['message'] ?? 'Clocked out successfully.');
        closeCamera();
        await loadData();
      } else {
        AppFeedback.showError(data['message'] ?? 'Error clocking out.');
      }
    } catch (e, st) {
      debugPrint('_doClockOut error: $e\n$st');
      AppFeedback.showError('Error clocking out.');
    }
    isSubmitting.value = false;
  }

  int _londonMinutes() {
    final now = DateTime.now().toUtc().add(const Duration(hours: 1));
    return now.hour * 60 + now.minute;
  }

  String _londonFormatted() {
    final now = DateTime.now().toUtc().add(const Duration(hours: 1));
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  int _hhmm24toMins(String hhmm) {
    final p = hhmm.split(':');
    return int.parse(p[0]) * 60 + int.parse(p[1]);
  }

  String _format12(String hhmm) {
    final p   = hhmm.split(':');
    final h   = int.parse(p[0]);
    final h12 = h % 12 == 0 ? 12 : h % 12;
    return '$h12:${p[1]} ${h >= 12 ? 'PM' : 'AM'}';
  }

  @override
  void onClose() { _disposeCamera(); super.onClose(); }
}