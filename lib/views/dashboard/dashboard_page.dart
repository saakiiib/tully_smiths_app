import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../controllers/dashboard_controller.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/app_app_bar.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final dash = Get.put(DashboardController());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppTopBar(),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text('Dashboard', style: AppTextStyles.heading),
            const SizedBox(height: 4),
            Obx(() => Text(dash.userName.value, style: AppTextStyles.small)),
            const SizedBox(height: 24),

            Obx(() => Row(
                  children: [
                    _StatCard(
                      label: "Today's Jobs",
                      value: '${dash.todayJobs.value}',
                      icon: Icons.today_outlined,
                      iconColor: AppColors.accent,
                    ),
                    const SizedBox(width: 12),
                    _StatCard(
                      label: 'Active',
                      value: '${dash.activeJobs.value}',
                      icon: Icons.check_circle_outline_rounded,
                      iconColor: AppColors.success,
                    ),
                    const SizedBox(width: 12),
                    _StatCard(
                      label: 'Pending',
                      value: '${dash.pendingJobs.value}',
                      icon: Icons.access_time_rounded,
                      iconColor: AppColors.warning,
                    ),
                  ],
                )),
            const SizedBox(height: 24),

            _CalendarWidget(dash: dash),
            const SizedBox(height: 24),

            Obx(() {
              if (dash.isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 1.5,
                  ),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatDate(dash.selectedDay.value),
                    style: AppTextStyles.label,
                  ),
                  const SizedBox(height: 12),
                  dash.selectedDayJobs.isEmpty
                      ? Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(
                            'No jobs scheduled',
                            style: AppTextStyles.small,
                            textAlign: TextAlign.center,
                          ),
                        )
                      : Column(
                          children: dash.selectedDayJobs
                              .map((job) => Padding(
                                    padding:
                                        const EdgeInsets.only(bottom: 12),
                                    child: _JobCard(
                                      title: job['job_title'] ?? '',
                                      client: job['client_name'] ?? '',
                                      time: _formatTime(
                                          job['start_time'], job['end_time']),
                                      status: job['status'] ?? '',
                                    ),
                                  ))
                              .toList(),
                        ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = [
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'
    ];
    const days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    return '${days[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}';
  }

  String _formatTime(String? start, String? end) {
    if (start == null) return '-';
    String fmt(String t) {
      final parts = t.split(':');
      final h = int.parse(parts[0]);
      final m = parts[1];
      final period = h >= 12 ? 'PM' : 'AM';
      final hour = h > 12 ? h - 12 : (h == 0 ? 12 : h);
      return '$hour:$m $period';
    }
    return end != null ? '${fmt(start)} — ${fmt(end)}' : fmt(start);
  }
}

class _CalendarWidget extends StatefulWidget {
  final DashboardController dash;

  const _CalendarWidget({required this.dash});

  @override
  State<_CalendarWidget> createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends State<_CalendarWidget> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    _focusedDay = widget.dash.focusedDay.value;
    _selectedDay = widget.dash.selectedDay.value;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TableCalendar(
        firstDay: DateTime.utc(2024, 1, 1),
        lastDay: DateTime.utc(2027, 12, 31),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (selected, focused) {
          setState(() {
            _selectedDay = selected;
            _focusedDay = focused;
          });
          widget.dash.onDaySelected(selected, focused);
        },
        onPageChanged: (focused) {
          setState(() => _focusedDay = focused);
          widget.dash.focusedDay.value = focused;
        },
        calendarStyle: CalendarStyle(
          todayDecoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          selectedDecoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          selectedTextStyle: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
          todayTextStyle: const TextStyle(color: AppColors.white),
          markersMaxCount: 1,
          markerDecoration: const BoxDecoration(
            color: AppColors.accent,
            shape: BoxShape.circle,
          ),
          outsideDaysVisible: false,
          weekendTextStyle: AppTextStyles.small,
          defaultTextStyle: AppTextStyles.small,
        ),
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: AppTextStyles.button,
          leftChevronIcon: const Icon(
            Icons.chevron_left_rounded,
            color: AppColors.primary,
          ),
          rightChevronIcon: const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.primary,
          ),
        ),
        eventLoader: (day) => widget.dash.hasJob(day) ? ['job'] : [],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: iconColor),
            ),
            const SizedBox(height: 10),
            Text(value, style: AppTextStyles.heading),
            const SizedBox(height: 2),
            Text(label, style: AppTextStyles.small),
          ],
        ),
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  final String title;
  final String client;
  final String time;
  final String status;

  const _JobCard({
    required this.title,
    required this.client,
    required this.time,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.work_outline_rounded,
                color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.body),
                const SizedBox(height: 2),
                Text(client, style: AppTextStyles.small),
                const SizedBox(height: 2),
                Text(time,
                    style: AppTextStyles.label
                        .copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              status,
              style:
                  AppTextStyles.label.copyWith(color: AppColors.success),
            ),
          ),
        ],
      ),
    );
  }
}