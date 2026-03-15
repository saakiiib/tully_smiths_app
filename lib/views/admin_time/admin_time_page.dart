import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/admin_time_controller.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/app_app_bar.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/app_search_dropdown.dart';

class AdminTimePage extends StatelessWidget {
  const AdminTimePage({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(AdminTimeController());
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppTopBar(),
      drawer: const AppDrawer(),
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: ctrl.fetchWorkerData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Time Management', style: AppTextStyles.heading),
              const SizedBox(height: 2),
              Text('Manage worker attendance', style: AppTextStyles.small),
              const SizedBox(height: 20),

              Obx(() => ctrl.isLoadingWorkers.value
                  ? const Center(child: CircularProgressIndicator(strokeWidth: 1.5))
                  : AppSearchDropdown<AdminWorker>(
                      label: 'Worker',
                      hint: 'Select a worker',
                      searchHint: 'Search worker...',
                      items: ctrl.workers.toList(),
                      selectedItem: ctrl.selectedWorker.value,
                      itemAsString: (w) => w.name,
                      onChanged: ctrl.selectWorker,
                      compareFn: (a, b) => a.id == b.id,
                    )),
              const SizedBox(height: 20),

              Obx(() {
                if (ctrl.selectedWorker.value == null) {
                  return _InfoBox(message: 'Select a worker to manage their time.');
                }
                if (ctrl.isLoadingData.value) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: CircularProgressIndicator(strokeWidth: 1.5),
                    ),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StatsRow(ctrl: ctrl),
                    const SizedBox(height: 20),
                    if (ctrl.activeLog.value != null) ...[
                      _ActiveLogCard(ctrl: ctrl),
                      const SizedBox(height: 20),
                    ],
                    _TodayJobsCard(ctrl: ctrl),
                    const SizedBox(height: 20),
                    _RecentEntries(ctrl: ctrl),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final String message;
  const _InfoBox({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: AppTextStyles.small.copyWith(color: AppColors.primary))),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final AdminTimeController ctrl;
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
  final AdminTimeController ctrl;
  const _ActiveLogCard({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final log = ctrl.activeLog.value!;
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
                  Text('Currently Working — ${ctrl.selectedWorker.value?.name ?? ''}',
                      style: AppTextStyles.small.copyWith(color: Colors.white, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(log.jobTitle ?? '—', style: AppTextStyles.button.copyWith(color: Colors.white, fontSize: 18)),
            const SizedBox(height: 6),
            Text('Clocked in at ${log.clockInTime}',
                style: AppTextStyles.small.copyWith(color: Colors.white.withValues(alpha: 0.75))),
            const SizedBox(height: 18),
            Obx(() => SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: ctrl.isSubmitting.value ? null : ctrl.submitClockOut,
                icon: ctrl.isSubmitting.value
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.stop_circle_outlined, size: 18),
                label: const Text('Clock Out Worker'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            )),
          ],
        ),
      );
    });
  }
}

class _TodayJobsCard extends StatelessWidget {
  final AdminTimeController ctrl;
  const _TodayJobsCard({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final assignments = ctrl.todayAssignments;
      final hasActiveLog = ctrl.activeLog.value != null;
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
                return _AssignmentRow(
                  assignment: a,
                  hasActiveLog: hasActiveLog,
                  onClockIn: () => _showManualClockInSheet(context, ctrl, a),
                );
              }),
          ],
        ),
      );
    });
  }

  void _showManualClockInSheet(BuildContext context, AdminTimeController ctrl, AdminTimeAssignment assignment) {
    ctrl.selectedAssignment.value = assignment;
    ctrl.clockInDate.value        = DateTime.now();
    ctrl.clockOutDate.value       = null;
    ctrl.clockInPhotoPath.value   = null;
    ctrl.clockOutPhotoPath.value  = null;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ManualClockInSheet(ctrl: ctrl, assignment: assignment),
    );
  }
}

class _AssignmentRow extends StatelessWidget {
  final AdminTimeAssignment assignment;
  final bool hasActiveLog;
  final VoidCallback onClockIn;
  const _AssignmentRow({required this.assignment, required this.hasActiveLog, required this.onClockIn});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(assignment.jobTitle, style: AppTextStyles.button.copyWith(fontSize: 14), overflow: TextOverflow.ellipsis),
                Text(assignment.jobId, style: AppTextStyles.small.copyWith(fontSize: 12, color: Colors.grey)),
                if (assignment.startTime != null)
                  Text(
                    _fmtTime(assignment.startTime!) + (assignment.endTime != null ? ' – ${_fmtTime(assignment.endTime!)}' : ''),
                    style: AppTextStyles.small.copyWith(fontSize: 12),
                  ),
              ],
            ),
          ),
          if (!hasActiveLog) ...[
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: onClockIn,
              icon: const Icon(Icons.shield_outlined, size: 15),
              label: const Text('Clock In', style: TextStyle(fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _fmtTime(String hhmm) {
    final p = hhmm.split(':');
    final h = int.parse(p[0]);
    return '${h % 12 == 0 ? 12 : h % 12}:${p[1]} ${h >= 12 ? 'PM' : 'AM'}';
  }
}

class _ManualClockInSheet extends StatefulWidget {
  final AdminTimeController ctrl;
  final AdminTimeAssignment assignment;
  const _ManualClockInSheet({required this.ctrl, required this.assignment});

  @override
  State<_ManualClockInSheet> createState() => _ManualClockInSheetState();
}

class _ManualClockInSheetState extends State<_ManualClockInSheet> {
  @override
  Widget build(BuildContext context) {
    final ctrl = widget.ctrl;
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Manual Clock In', style: AppTextStyles.button),
                        Text(widget.assignment.jobTitle, style: AppTextStyles.small),
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Get.back()),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollCtrl,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Clock In *', style: AppTextStyles.label),
                    const SizedBox(height: 8),
                    Obx(() => _DateTimePickerTile(
                      value: ctrl.clockInDate.value,
                      hint: 'Select clock-in date & time',
                      onTap: () async {
                        final picked = await _pickDateTime(context, ctrl.clockInDate.value ?? DateTime.now());
                        if (picked != null) ctrl.clockInDate.value = picked;
                      },
                    )),
                    const SizedBox(height: 16),

                    Text('Clock Out (optional)', style: AppTextStyles.label),
                    const SizedBox(height: 8),
                    Obx(() => _DateTimePickerTile(
                      value: ctrl.clockOutDate.value,
                      hint: 'Leave blank if still active',
                      onTap: () async {
                        final picked = await _pickDateTime(context, ctrl.clockOutDate.value ?? DateTime.now());
                        if (picked != null) ctrl.clockOutDate.value = picked;
                      },
                      onClear: ctrl.clockOutDate.value != null ? () => ctrl.clockOutDate.value = null : null,
                    )),
                    const SizedBox(height: 20),

                    Text('Clock-In Photo (optional)', style: AppTextStyles.label),
                    const SizedBox(height: 8),
                    Obx(() => _PhotoPickerTile(
                      path: ctrl.clockInPhotoPath.value,
                      onTap: () => ctrl.pickPhoto(true),
                      onClear: ctrl.clockInPhotoPath.value != null ? () => ctrl.clockInPhotoPath.value = null : null,
                    )),
                    const SizedBox(height: 16),

                    Obx(() => ctrl.clockOutDate.value != null
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Clock-Out Photo (optional)', style: AppTextStyles.label),
                              const SizedBox(height: 8),
                              _PhotoPickerTile(
                                path: ctrl.clockOutPhotoPath.value,
                                onTap: () => ctrl.pickPhoto(false),
                                onClear: ctrl.clockOutPhotoPath.value != null ? () => ctrl.clockOutPhotoPath.value = null : null,
                              ),
                              const SizedBox(height: 16),
                            ],
                          )
                        : const SizedBox()),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 24),
              child: Obx(() => SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: ctrl.isSubmitting.value ? null : ctrl.submitManualClockIn,
                  icon: ctrl.isSubmitting.value
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.shield_outlined, size: 18),
                  label: Text(ctrl.isSubmitting.value ? 'Saving…' : 'Confirm Clock In'),
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
      ),
    );
  }

  Future<DateTime?> _pickDateTime(BuildContext context, DateTime initial) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (date == null) return null;
    if (!context.mounted) return null;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(initial));
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }
}

class _DateTimePickerTile extends StatelessWidget {
  final DateTime? value;
  final String hint;
  final VoidCallback onTap;
  final VoidCallback? onClear;
  const _DateTimePickerTile({required this.value, required this.hint, required this.onTap, this.onClear});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: value != null ? AppColors.primary : Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(Icons.access_time_rounded, size: 18, color: value != null ? AppColors.primary : Colors.grey),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                value != null ? _format(value!) : hint,
                style: AppTextStyles.body.copyWith(color: value != null ? Colors.black87 : Colors.grey),
              ),
            ),
            if (onClear != null)
              GestureDetector(
                onTap: onClear,
                child: const Icon(Icons.close, size: 16, color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }

  String _format(DateTime dt) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final h = dt.hour, m = dt.minute.toString().padLeft(2, '0');
    final h12 = h % 12 == 0 ? 12 : h % 12;
    final ampm = h >= 12 ? 'PM' : 'AM';
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}  $h12:$m $ampm';
  }
}

class _PhotoPickerTile extends StatelessWidget {
  final String? path;
  final VoidCallback onTap;
  final VoidCallback? onClear;
  const _PhotoPickerTile({required this.path, required this.onTap, this.onClear});

  @override
  Widget build(BuildContext context) {
    if (path != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(File(path!), height: 120, width: double.infinity, fit: BoxFit.cover),
          ),
          Positioned(
            top: 6, right: 6,
            child: GestureDetector(
              onTap: onClear,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                child: const Icon(Icons.close, color: Colors.white, size: 14),
              ),
            ),
          ),
        ],
      );
    }
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.camera_alt_outlined, color: Colors.grey, size: 20),
            const SizedBox(width: 8),
            Text('Take Photo', style: AppTextStyles.small.copyWith(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class _RecentEntries extends StatelessWidget {
  final AdminTimeController ctrl;
  const _RecentEntries({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final logs = ctrl.recentLogs;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recent Entries', style: AppTextStyles.button),
          const SizedBox(height: 10),
          if (logs.isEmpty)
            Center(child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('No entries yet', style: AppTextStyles.small),
            ))
          else
            ...logs.map((log) => _EntryItem(log: log)),
        ],
      );
    });
  }
}

class _EntryItem extends StatelessWidget {
  final AdminTimeLog log;
  const _EntryItem({required this.log});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: log.clockInPhoto != null
                ? Image.network(log.clockInPhoto!, width: 46, height: 46, fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _photoPlaceholder())
                : _photoPlaceholder(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(log.jobTitle ?? '—', style: AppTextStyles.button.copyWith(fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(
                  log.isActive ? '${log.clockInTime} — Active' : '${log.clockInTime} – ${log.clockOutTime ?? ''}',
                  style: AppTextStyles.small.copyWith(fontSize: 12),
                ),
                if (log.locationNote != null && log.locationNote != 'location_check_failed') ...[
                  const SizedBox(height: 3),
                  Text(
                    log.locationNote == 'location_verified' ? 'Location verified' : log.locationNote!,
                    style: TextStyle(fontSize: 11, color: log.locationNote == 'location_verified' ? Colors.green : Colors.orange),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (log.isActive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: const Text('Active', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w600)),
                )
              else
                Text(log.totalHoursFormatted ?? '—', style: AppTextStyles.button.copyWith(color: AppColors.primary, fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _photoPlaceholder() => Container(
    width: 46, height: 46,
    decoration: BoxDecoration(
      color: AppColors.primary.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(10),
    ),
    child: const Icon(Icons.work_outline_rounded, color: AppColors.primary, size: 20),
  );
}