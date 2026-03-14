import 'dart:io';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/time_controller.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/app_app_bar.dart';
import '../../constants/app_text_styles.dart';
import '../../constants/app_colors.dart';
import '../../services/api_service.dart';
import '../../widgets/app_drawer.dart';

class _NetImage extends StatelessWidget {
  final String? url;
  final double width;
  final double height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const _NetImage({
    this.url,
    this.width = 46,
    this.height = 46,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final child = url != null
        ? Image.network(
            url!,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (_, _, _) => _defaultIcon(),
            loadingBuilder: (_, child, progress) =>
                progress == null ? child : _defaultIcon(),
          )
        : _defaultIcon();

    return borderRadius != null
        ? ClipRRect(borderRadius: borderRadius!, child: child)
        : child;
  }

  Widget _defaultIcon() => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: borderRadius ?? BorderRadius.circular(10),
        ),
        child: Icon(Icons.work_outline_rounded, color: AppColors.primary, size: width * 0.45),
      );
}

class TimePage extends StatelessWidget {
  const TimePage({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(TimeController());
    return Obx(() {
      if (ctrl.showCameraScreen.value) return _CameraScreen(ctrl: ctrl);
      if (ctrl.showChecklist.value)    return _ChecklistScreen(ctrl: ctrl);
      return _MainScreen(ctrl: ctrl);
    });
  }
}

class _MainScreen extends StatelessWidget {
  final TimeController ctrl;
  const _MainScreen({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppTopBar(),
      drawer: ApiService.isWorker ? null : const AppDrawer(),
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
      body: Obx(() {
        if (ctrl.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return RefreshIndicator(
          onRefresh: ctrl.loadData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Time', style: AppTextStyles.heading),
                const SizedBox(height: 2),
                Text("Today's attendance", style: AppTextStyles.small),
                const SizedBox(height: 20),
                _StatsRow(ctrl: ctrl),
                const SizedBox(height: 20),
                if (ctrl.activeLog.value != null)
                  _ActiveLogCard(ctrl: ctrl)
                else
                  _StartCard(ctrl: ctrl),
                const SizedBox(height: 20),
                _RecentEntries(ctrl: ctrl),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final TimeController ctrl;
  const _StatsRow({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() => Row(
      children: [
        _StatCard(label: 'Today',      value: ctrl.todayHours.value),
        const SizedBox(width: 10),
        _StatCard(label: 'This Week',  value: ctrl.weekHours.value),
        const SizedBox(width: 10),
        _StatCard(label: 'This Month', value: ctrl.monthHours.value),
      ],
    ));
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            Text(value, style: AppTextStyles.button.copyWith(fontSize: 17, color: AppColors.primary)),
            const SizedBox(height: 4),
            Text(label, style: AppTextStyles.small.copyWith(fontSize: 11), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _ActiveLogCard extends StatelessWidget {
  final TimeController ctrl;
  const _ActiveLogCard({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final log        = ctrl.activeLog.value!;
      final isVerified = log.locationNote == 'location_verified';
      final isFailed   = log.locationNote == 'location_check_failed';
      final hasLocNote = log.locationNote != null && !isFailed;

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1B4332), Color(0xFF2D6A4F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: const Color(0xFF2D6A4F).withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 7, height: 7, decoration: const BoxDecoration(color: Color(0xFF74C69D), shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text('Currently Working', style: AppTextStyles.small.copyWith(color: Colors.white, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(log.jobTitle ?? '—', style: AppTextStyles.button.copyWith(color: Colors.white, fontSize: 18)),
            const SizedBox(height: 6),
            Text('Clocked in at ${log.clockInTime}', style: AppTextStyles.small.copyWith(color: Colors.white.withValues(alpha: 0.75))),
            if (hasLocNote) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isVerified ? Colors.green.withValues(alpha: 0.25) : Colors.orange.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(isVerified ? Icons.location_on : Icons.location_off, color: Colors.white, size: 13),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        isVerified ? 'Location verified' : log.locationNote!,
                        style: AppTextStyles.small.copyWith(color: Colors.white, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: Obx(() => ElevatedButton.icon(
                onPressed: ctrl.isSubmitting.value ? null : ctrl.onClockOutTapped,
                icon: ctrl.isSubmitting.value
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.stop_circle_outlined, size: 18),
                label: const Text('Clock Out'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              )),
            ),
          ],
        ),
      );
    });
  }
}

class _StartCard extends StatelessWidget {
  final TimeController ctrl;
  const _StartCard({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final assignments = ctrl.todayAssignments;
      return Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text("Today's Jobs", style: AppTextStyles.button),
                ],
              ),
            ),
            const Divider(height: 1),
            if (assignments.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('No jobs assigned for today.', style: TextStyle(color: Colors.grey))),
              )
            else
              ...assignments.map((a) {
                final isSelected = ctrl.selectedAssignment.value?.id == a.id;
                return GestureDetector(
                  onTap: () => ctrl.selectAssignment(a),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary.withValues(alpha: 0.08) : Colors.grey.shade50,
                      border: Border.all(color: isSelected ? AppColors.primary : Colors.grey.shade200, width: isSelected ? 1.5 : 1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(a.jobTitle, style: AppTextStyles.button.copyWith(fontSize: 14), overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 2),
                              Text(a.jobId, style: AppTextStyles.small.copyWith(fontSize: 12, color: Colors.grey)),
                              if (a.startTime != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  _fmtTime(a.startTime!) + (a.endTime != null ? ' – ${_fmtTime(a.endTime!)}' : ''),
                                  style: AppTextStyles.small.copyWith(fontSize: 12),
                                ),
                              ],
                              if (a.address != null && a.address!.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on_outlined, size: 12, color: Colors.grey),
                                    const SizedBox(width: 3),
                                    Expanded(
                                      child: Text(a.address!, style: AppTextStyles.small.copyWith(fontSize: 11, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (isSelected)
                          Container(
                            width: 28, height: 28,
                            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                            child: const Icon(Icons.check, color: Colors.white, size: 16),
                          ),
                      ],
                    ),
                  ),
                );
              }),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Obx(() => SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: ctrl.isSubmitting.value ? null : ctrl.onClockInTapped,
                  icon: ctrl.isSubmitting.value
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.login_rounded, size: 18),
                  label: const Text('Clock In'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              )),
            ),
          ],
        ),
      );
    });
  }

  String _fmtTime(String hhmm) {
    final p = hhmm.split(':');
    final h = int.parse(p[0]);
    final h12 = h % 12 == 0 ? 12 : h % 12;
    return '$h12:${p[1]} ${h >= 12 ? 'PM' : 'AM'}';
  }
}

class _RecentEntries extends StatelessWidget {
  final TimeController ctrl;
  const _RecentEntries({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final logs = ctrl.recentLogs;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent Entries', style: AppTextStyles.button),
              TextButton.icon(
                onPressed: () => Get.toNamed('/timesheets'),
                icon: const Icon(Icons.calendar_month_outlined, size: 16),
                label: const Text('Timesheet', style: TextStyle(fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (logs.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('No entries yet', style: AppTextStyles.small),
              ),
            )
          else
            ...logs.map((log) => _EntryItem(log: log)),
        ],
      );
    });
  }
}

class _EntryItem extends StatelessWidget {
  final TimeLog log;
  const _EntryItem({required this.log});

  @override
  Widget build(BuildContext context) {
    final isVerified = log.locationNote == 'location_verified';
    final hasLoc     = log.locationNote != null && log.locationNote != 'location_check_failed';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _NetImage(
            url: log.clockInPhoto,
            width: 46,
            height: 46,
            borderRadius: BorderRadius.circular(10),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.jobTitle ?? '—',
                  style: AppTextStyles.button.copyWith(fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (hasLoc) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_on, size: 11, color: isVerified ? Colors.green : Colors.orange),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          isVerified ? 'Verified' : log.locationNote!,
                          style: TextStyle(fontSize: 11, color: isVerified ? Colors.green : Colors.orange),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (log.isActive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: const Text('Active', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w600)),
                )
              else ...[
                Text(log.totalHours ?? '', style: AppTextStyles.button.copyWith(color: AppColors.primary, fontSize: 14)),
                const SizedBox(height: 2),
                Text(
                  '${log.clockInTime} – ${log.clockOutTime ?? ''}',
                  style: AppTextStyles.small.copyWith(fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (log.clockOutPhoto != null) ...[
                const SizedBox(height: 6),
                _NetImage(
                  url: log.clockOutPhoto,
                  width: 30,
                  height: 30,
                  borderRadius: BorderRadius.circular(6),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _CameraScreen extends StatelessWidget {
  final TimeController ctrl;
  const _CameraScreen({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) ctrl.closeCamera();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: Obx(() => Text(
            ctrl.isClockOutFlow.value ? 'Clock Out — Take Photo' : 'Clock In — Take Photo',
            style: const TextStyle(fontSize: 16),
          )),
          leading: IconButton(icon: const Icon(Icons.close), onPressed: ctrl.closeCamera),
        ),
        body: Obx(() {
          final captured = ctrl.capturedImagePath.value;
          return Column(
            children: [
              Expanded(
                child: captured != null
                    ? Image.file(File(captured), fit: BoxFit.cover, width: double.infinity)
                    : ctrl.isCameraReady.value && ctrl.cameraController.value != null
                        ? CameraPreview(ctrl.cameraController.value!)
                        : const Center(child: CircularProgressIndicator(color: Colors.white)),
              ),
              Container(
                color: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Center(
                  child: Obx(() {
                    final status = ctrl.locationStatus.value;
                    final isGood = status.contains('✓');
                    final color  = isGood ? Colors.green : Colors.orange;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: color, width: 0.8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.location_on, size: 14, color: color),
                          const SizedBox(width: 6),
                          Text(status, style: TextStyle(color: color, fontSize: 13)),
                        ],
                      ),
                    );
                  }),
                ),
              ),
              Container(
                color: Colors.black,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                child: Obx(() {
                  final captured   = ctrl.capturedImagePath.value;
                  final submitting = ctrl.isSubmitting.value;
                  if (captured == null) {
                    return Center(
                      child: GestureDetector(
                        onTap: ctrl.isCapturing.value ? null : ctrl.capturePhoto,
                        child: Container(
                          width: 72, height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            color: Colors.white.withValues(alpha: 0.15),
                          ),
                          child: ctrl.isCapturing.value
                              ? const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 32),
                        ),
                      ),
                    );
                  }
                  return Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: submitting ? null : ctrl.retakePhoto,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Retake'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white54),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: submitting ? null : ctrl.confirmAndSubmit,
                          icon: submitting
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.check_rounded),
                          label: Text(submitting ? 'Submitting…' : 'Confirm & Submit'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _ChecklistScreen extends StatelessWidget {
  final TimeController ctrl;
  const _ChecklistScreen({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) ctrl.showChecklist.value = false;
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Obx(() => Text(ctrl.isClockOutFlow.value ? 'Clock Out Checklist' : 'Clock In Checklist')),
          leading: IconButton(icon: const Icon(Icons.close), onPressed: () => ctrl.showChecklist.value = false),
        ),
        body: Obx(() {
          if (ctrl.isChecklistLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: ctrl.checklistGroups.map((g) => _ChecklistGroupWidget(group: g, ctrl: ctrl)).toList(),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                color: AppColors.white,
                child: Obx(() => SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: ctrl.isSubmitting.value ? null : ctrl.submitChecklist,
                    icon: ctrl.isSubmitting.value
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check_rounded),
                    label: Obx(() => Text(ctrl.isClockOutFlow.value ? 'Save & Clock Out' : 'Save & Clock In')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                )),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _ChecklistGroupWidget extends StatelessWidget {
  final ChecklistGroup group;
  final TimeController ctrl;
  const _ChecklistGroupWidget({required this.group, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Expanded(child: Text(group.title, style: AppTextStyles.button)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('${group.items.length} items', style: const TextStyle(fontSize: 12, color: Colors.blue)),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...group.items.asMap().entries.map((e) {
            final isLast = e.key == group.items.length - 1;
            return Column(
              children: [
                _ChecklistItemWidget(item: e.value, groupId: group.id, ctrl: ctrl),
                if (!isLast) const Divider(height: 1, indent: 16),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _ChecklistItemWidget extends StatefulWidget {
  final ChecklistItem item;
  final int groupId;
  final TimeController ctrl;
  const _ChecklistItemWidget({required this.item, required this.groupId, required this.ctrl});

  @override
  State<_ChecklistItemWidget> createState() => _ChecklistItemWidgetState();
}

class _ChecklistItemWidgetState extends State<_ChecklistItemWidget> {
  String? _selectedRadio;
  late final TextEditingController _textCtrl;
  File? _pickedPhoto;

  @override
  void initState() {
    super.initState();
    _selectedRadio = widget.item.existingAnswer;
    _textCtrl      = TextEditingController(text: widget.item.existingAnswer ?? '');
  }

  String get _key => '${widget.groupId}__${widget.item.id}';

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6)),
                child: Text(_capitalize(item.type.replaceAll('_', ' ')), style: const TextStyle(fontSize: 11, color: Colors.black54)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    text: item.question,
                    style: const TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w500),
                    children: item.isRequired
                        ? [const TextSpan(text: ' *', style: TextStyle(color: Colors.red))]
                        : [],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (item.type == 'yes_no')
            _radioRow(['yes', 'no'], ['Yes', 'No'])
          else if (item.type == 'yes_no_na')
            _radioRow(['yes', 'no', 'na'], ['Yes', 'No', 'N/A'])
          else if (item.type == 'photo_upload') ...[
            if (item.existingPhotoPath != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _NetImage(url: item.existingPhotoPath, width: double.infinity, height: 70, fit: BoxFit.cover),
                ),
              ),
            if (_pickedPhoto != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(_pickedPhoto!, height: 70, fit: BoxFit.cover),
                ),
              ),
            OutlinedButton.icon(
              onPressed: _pickPhoto,
              icon: const Icon(Icons.camera_alt_outlined, size: 16),
              label: const Text('Choose Photo', style: TextStyle(fontSize: 13)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ] else
            TextField(
              controller: _textCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Enter answer…',
                hintStyle: const TextStyle(fontSize: 13),
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              onChanged: (v) => widget.ctrl.setChecklistAnswer(_key, v),
            ),
        ],
      ),
    );
  }

  Widget _radioRow(List<String> values, List<String> labels) {
    return Row(
      children: List.generate(values.length, (i) {
        final selected = _selectedRadio == values[i];
        return Padding(
          padding: EdgeInsets.only(right: i < values.length - 1 ? 20 : 0),
          child: GestureDetector(
            onTap: () {
              setState(() => _selectedRadio = values[i]);
              widget.ctrl.setChecklistAnswer(_key, values[i]);
            },
            child: Row(
              children: [
                Container(
                  width: 20, height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: selected ? AppColors.primary : Colors.grey.shade400, width: 2),
                    color: selected ? AppColors.primary : Colors.transparent,
                  ),
                  child: selected ? const Icon(Icons.check, color: Colors.white, size: 12) : null,
                ),
                const SizedBox(width: 6),
                Text(labels[i], style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
        );
      }),
    );
  }

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.camera);
    if (picked != null) {
      setState(() => _pickedPhoto = File(picked.path));
      widget.ctrl.setChecklistPhoto(_key, _pickedPhoto!);
    }
  }

  String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  @override
  void dispose() { _textCtrl.dispose(); super.dispose(); }
}