import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../controllers/calendar_controller.dart';
import '../../widgets/app_app_bar.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/app_card_actions.dart';
import '../../widgets/app_search_dropdown.dart';
import '../../utils/app_feedback.dart';

class CalendarPage extends StatelessWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(CalendarController());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppTopBar(),
      drawer: const AppDrawer(),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => _showForm(context, ctrl),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Obx(() {
        if (ctrl.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 1.5),
          );
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text('Job Calendar', style: AppTextStyles.heading),
              const SizedBox(height: 20),
              _CalendarWidget(ctrl: ctrl),
              const SizedBox(height: 24),
              Obx(() {
                final day = ctrl.selectedDay.value;
                const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
                const days   = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
                return Text(
                  '${days[day.weekday - 1]}, ${months[day.month - 1]} ${day.day}',
                  style: AppTextStyles.label,
                );
              }),
              const SizedBox(height: 12),
              Obx(() {
                if (ctrl.selectedDayAssignments.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text('No assignments', style: AppTextStyles.small, textAlign: TextAlign.center),
                  );
                }
                return Column(
                  children: ctrl.selectedDayAssignments.map((a) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _AssignmentCard(
                      assignment: a,
                      ctrl: ctrl,
                      onEdit: () => _showForm(context, ctrl, assignment: a),
                    ),
                  )).toList(),
                );
              }),
              const SizedBox(height: 80),
            ],
          ),
        );
      }),
    );
  }

  void _showForm(BuildContext context, CalendarController ctrl, {Map<String, dynamic>? assignment}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AssignmentForm(ctrl: ctrl, assignment: assignment),
    );
  }
}

class _AssignmentForm extends StatefulWidget {
  final CalendarController ctrl;
  final Map<String, dynamic>? assignment;

  const _AssignmentForm({required this.ctrl, this.assignment});

  @override
  State<_AssignmentForm> createState() => _AssignmentFormState();
}

class _AssignmentFormState extends State<_AssignmentForm> {
  late final TextEditingController dateCtrl;
  late final TextEditingController startCtrl;
  late final TextEditingController endCtrl;
  late final TextEditingController noteCtrl;

  Map<String, dynamic>? selectedJob;
  Map<String, dynamic>? selectedWorker;

  @override
  void initState() {
    super.initState();
    final a   = widget.assignment;
    dateCtrl  = TextEditingController(text: a?['assigned_date'] ?? widget.ctrl.fmt(widget.ctrl.selectedDay.value));
    startCtrl = TextEditingController(text: a?['start_time'] ?? '');
    endCtrl   = TextEditingController(text: a?['end_time'] ?? '');
    noteCtrl  = TextEditingController(text: a?['note'] ?? '');

    if (a != null) {
      selectedJob    = widget.ctrl.jobs.firstWhereOrNull((j) => j['id'].toString() == a['service_job_id'].toString());
      selectedWorker = widget.ctrl.workers.firstWhereOrNull((w) => w['id'].toString() == a['worker_id'].toString());
    }
  }

  @override
  void dispose() {
    dateCtrl.dispose();
    startCtrl.dispose();
    endCtrl.dispose();
    noteCtrl.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration() => InputDecoration(
    filled: true,
    fillColor: AppColors.surface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border:        OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
  );

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.assignment != null;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(isEdit ? 'Edit Assignment' : 'New Assignment', style: AppTextStyles.heading),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ],
            ),
            const SizedBox(height: 16),

            Obx(() => AppSearchDropdown<Map<String, dynamic>>(
              label: 'Job',
              hint: 'Select job',
              searchHint: 'Search job...',
              items: widget.ctrl.jobs.toList(),
              selectedItem: selectedJob,
              itemAsString: (j) => '${j['job_id']} — ${j['job_title']}',
              onChanged: (v) => setState(() => selectedJob = v),
              validator: (v) => v == null ? 'Required' : null,
              compareFn: (a, b) => a['id'].toString() == b['id'].toString(),
            )),
            const SizedBox(height: 12),

            Obx(() => AppSearchDropdown<Map<String, dynamic>>(
              label: 'Worker',
              hint: 'Select worker',
              searchHint: 'Search worker...',
              items: widget.ctrl.workers.toList(),
              selectedItem: selectedWorker,
              itemAsString: (w) => w['name'],
              onChanged: (v) => setState(() => selectedWorker = v),
              validator: (v) => v == null ? 'Required' : null,
              compareFn: (a, b) => a['id'].toString() == b['id'].toString(),
            )),
            const SizedBox(height: 12),

            Text('Assign Date', style: AppTextStyles.label),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.tryParse(dateCtrl.text) ?? DateTime.now(),
                  firstDate: DateTime(2024),
                  lastDate: DateTime(2027),
                );
                if (picked != null) dateCtrl.text = widget.ctrl.fmt(picked);
              },
              child: AbsorbPointer(
                child: TextFormField(
                  controller: dateCtrl,
                  style: AppTextStyles.small,
                  decoration: _inputDecoration().copyWith(
                    suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.textSecondary),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Start Time', style: AppTextStyles.label),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () async {
                          final picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                          if (picked != null) {
                            startCtrl.text = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                          }
                        },
                        child: AbsorbPointer(
                          child: TextFormField(
                            controller: startCtrl,
                            style: AppTextStyles.small,
                            decoration: _inputDecoration().copyWith(
                              suffixIcon: const Icon(Icons.access_time, size: 18, color: AppColors.textSecondary),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('End Time', style: AppTextStyles.label),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () async {
                          final picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                          if (picked != null) {
                            endCtrl.text = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                          }
                        },
                        child: AbsorbPointer(
                          child: TextFormField(
                            controller: endCtrl,
                            style: AppTextStyles.small,
                            decoration: _inputDecoration().copyWith(
                              suffixIcon: const Icon(Icons.access_time, size: 18, color: AppColors.textSecondary),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Text('Note', style: AppTextStyles.label),
            const SizedBox(height: 6),
            TextFormField(
              controller: noteCtrl,
              maxLines: 2,
              style: AppTextStyles.small,
              decoration: _inputDecoration().copyWith(hintText: 'Optional note...'),
            ),
            const SizedBox(height: 24),

            Obx(() => SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: widget.ctrl.isSubmitting.value
                    ? null
                    : () {
                        if (selectedJob == null || selectedWorker == null || dateCtrl.text.isEmpty) {
                          AppFeedback.showError('Job, worker and date are required.');
                          return;
                        }
                        final data = {
                          'service_job_id': selectedJob!['id'],
                          'worker_id':      selectedWorker!['id'],
                          'assigned_date':  dateCtrl.text,
                          if (startCtrl.text.isNotEmpty) 'start_time': startCtrl.text,
                          if (endCtrl.text.isNotEmpty)   'end_time':   endCtrl.text,
                          if (noteCtrl.text.isNotEmpty)  'note':       noteCtrl.text,
                        };
                        Navigator.pop(context);
                        if (isEdit) {
                          widget.ctrl.updateAssignment(widget.assignment!['id'], data);
                        } else {
                          widget.ctrl.storeAssignment(data);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: widget.ctrl.isSubmitting.value
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 1.5))
                    : Text(isEdit ? 'Update' : 'Save', style: AppTextStyles.button.copyWith(color: Colors.white)),
              ),
            )),
          ],
        ),
      ),
    );
  }
}

class _CalendarWidget extends StatefulWidget {
  final CalendarController ctrl;
  const _CalendarWidget({required this.ctrl});

  @override
  State<_CalendarWidget> createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends State<_CalendarWidget> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    _focusedDay  = widget.ctrl.focusedDay.value;
    _selectedDay = widget.ctrl.selectedDay.value;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: TableCalendar(
        firstDay: DateTime.utc(2024, 1, 1),
        lastDay: DateTime.utc(2027, 12, 31),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (selected, focused) {
          setState(() { _selectedDay = selected; _focusedDay = focused; });
          widget.ctrl.onDaySelected(selected, focused);
        },
        onPageChanged: (focused) {
          setState(() => _focusedDay = focused);
          widget.ctrl.focusedDay.value = focused;
        },
        calendarStyle: CalendarStyle(
          todayDecoration:    const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
          selectedDecoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), shape: BoxShape.circle),
          selectedTextStyle:  const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
          todayTextStyle:     const TextStyle(color: AppColors.white),
          markersMaxCount:    1,
          markerDecoration:   const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
          outsideDaysVisible: false,
          weekendTextStyle:   AppTextStyles.small,
          defaultTextStyle:   AppTextStyles.small,
        ),
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered:       true,
          titleTextStyle:      AppTextStyles.button,
          leftChevronIcon:     const Icon(Icons.chevron_left_rounded, color: AppColors.primary),
          rightChevronIcon:    const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
        ),
        eventLoader: (day) => widget.ctrl.hasAssignment(day) ? ['•'] : [],
      ),
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  final Map<String, dynamic> assignment;
  final CalendarController ctrl;
  final VoidCallback onEdit;

  const _AssignmentCard({
    required this.assignment,
    required this.ctrl,
    required this.onEdit,
  });

  String _fmtTime(String t) {
    final parts  = t.split(':');
    final h      = int.parse(parts[0]);
    final m      = parts[1];
    final period = h >= 12 ? 'PM' : 'AM';
    final hour   = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return '$hour:$m $period';
  }

  @override
  Widget build(BuildContext context) {
    final a         = assignment;
    final startTime = a['start_time'];
    final endTime   = a['end_time'];
    final timeLabel = startTime != null
        ? '${_fmtTime(startTime)}${endTime != null ? ' — ${_fmtTime(endTime)}' : ''}'
        : 'All day';

    return GestureDetector(
      onTap: () => Get.toNamed('/jobs/detail', arguments: a['service_job_id']),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Row(
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.work_outline_rounded, color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a['job_title'] ?? '', style: AppTextStyles.body),
                  const SizedBox(height: 2),
                  Text(a['worker_name'] ?? '', style: AppTextStyles.small),
                  const SizedBox(height: 2),
                  Text(timeLabel, style: AppTextStyles.label.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
            AppCardActions(
              onEdit:   onEdit,
              onDelete: () => ctrl.delete(a['id']),
            ),
          ],
        ),
      ),
    );
  }
}