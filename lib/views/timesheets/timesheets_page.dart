import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../controllers/timesheets_controller.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/app_app_bar.dart';

class TimesheetsPage extends StatelessWidget {
  const TimesheetsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(TimesheetsController());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppTopBar(),
      bottomNavigationBar: const AppBottomNav(currentIndex: 2),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: ctrl.fetchTimesheet,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text('Timesheets', style: AppTextStyles.heading),
              const SizedBox(height: 4),
              Text('Your work history', style: AppTextStyles.small),
              const SizedBox(height: 24),

              // ── Mode toggle ─────────────────────────────────────────────
              _ModeToggle(ctrl: ctrl),
              const SizedBox(height: 16),

              // ── Period navigator + total hours ──────────────────────────
              _PeriodCard(ctrl: ctrl),
              const SizedBox(height: 24),

              // ── Daily breakdown ─────────────────────────────────────────
              Obx(() {
                if (ctrl.isLoading.value) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                        strokeWidth: 1.5,
                      ),
                    ),
                  );
                }

                if (ctrl.logs.isEmpty) {
                  return _EmptyState();
                }

                final breakdown = ctrl.breakdown;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: breakdown.entries.map((entry) {
                    final dateStr = entry.key;
                    final dayLogs = entry.value;
                    final dayTotal = dayLogs.fold<double>(
                      0,
                      (sum, l) => sum + (double.tryParse(l['total_hours']?.toString() ?? '') ?? 0.0),
                    );

                    return _DaySection(
                      dateStr:  dateStr,
                      dayLogs:  dayLogs,
                      dayTotal: dayTotal,
                    );
                  }).toList(),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Mode Toggle ──────────────────────────────────────────────────────────────

class _ModeToggle extends StatelessWidget {
  final TimesheetsController ctrl;
  const _ModeToggle({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    const modes = {'daily': 'Daily', 'weekly': 'Weekly', 'monthly': 'Monthly'};

    return Obx(() => Container(
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
            children: modes.entries.map((e) {
              final isSelected = ctrl.mode.value == e.key;
              return Expanded(
                child: GestureDetector(
                  onTap: () => ctrl.setMode(e.key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.all(4),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      e.value,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.label.copyWith(
                        color: isSelected ? AppColors.white : AppColors.textSecondary,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ));
  }
}

// ── Period Card ──────────────────────────────────────────────────────────────

class _PeriodCard extends StatelessWidget {
  final TimesheetsController ctrl;
  const _PeriodCard({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() => Container(
          padding: const EdgeInsets.all(16),
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
          child: Column(
            children: [
              // Period nav row
              Row(
                children: [
                  _NavButton(
                    icon: Icons.chevron_left_rounded,
                    onTap: ctrl.prev,
                    enabled: true,
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          ctrl.label.value,
                          style: AppTextStyles.button,
                          textAlign: TextAlign.center,
                        ),
                        if (ctrl.periodStart.value.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            _formatPeriodSub(
                              ctrl.periodStart.value,
                              ctrl.periodEnd.value,
                              ctrl.mode.value,
                            ),
                            style: AppTextStyles.small,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  ),
                  _NavButton(
                    icon: Icons.chevron_right_rounded,
                    onTap: ctrl.canGoNext ? ctrl.next : null,
                    enabled: ctrl.canGoNext,
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Total hours
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text('Total Hours', style: AppTextStyles.small),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          ctrl.totalHours.value.toStringAsFixed(2),
                          style: AppTextStyles.heading.copyWith(fontSize: 28),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          'h',
                          style: AppTextStyles.small.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ));
  }

  String _formatPeriodSub(String start, String end, String mode) {
    if (mode == 'monthly') return _prettyDate(start, 'month');
    if (start == end)      return _prettyDate(start, 'short');
    return '${_prettyDate(start, 'short')} — ${_prettyDate(end, 'short')}';
  }

  String _prettyDate(String iso, String format) {
    try {
      final d = DateTime.parse(iso);
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      if (format == 'month') return '${months[d.month - 1]} ${d.year}';
      return '${months[d.month - 1]} ${d.day}, ${d.year}';
    } catch (_) {
      return iso;
    }
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool enabled;

  const _NavButton({
    required this.icon,
    required this.onTap,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: enabled
              ? AppColors.primary.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: enabled ? AppColors.primary : AppColors.textSecondary.withValues(alpha: 0.3),
          size: 22,
        ),
      ),
    );
  }
}

// ── Day Section ──────────────────────────────────────────────────────────────

class _DaySection extends StatelessWidget {
  final String dateStr;
  final List<Map<String, dynamic>> dayLogs;
  final double dayTotal;

  const _DaySection({
    required this.dateStr,
    required this.dayLogs,
    required this.dayTotal,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Day header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_formatDayHeader(dateStr), style: AppTextStyles.label),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${dayTotal.toStringAsFixed(2)}h',
                style: AppTextStyles.label.copyWith(color: AppColors.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Log cards for this day
        ...dayLogs.map((log) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _LogCard(log: log),
            )),

        const SizedBox(height: 14),
      ],
    );
  }

  String _formatDayHeader(String iso) {
    try {
      final d = DateTime.parse(iso);
      const days   = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${days[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}';
    } catch (_) {
      return iso;
    }
  }
}

// ── Log Card ─────────────────────────────────────────────────────────────────

class _LogCard extends StatelessWidget {
  final Map<String, dynamic> log;
  const _LogCard({required this.log});

  @override
  Widget build(BuildContext context) {
    final job         = log['job'] as Map<String, dynamic>?;
    final jobTitle    = job?['job_title'] as String? ?? '—';
    final clockIn     = log['clock_in_time']  as String? ?? '—';
    final clockOut    = log['clock_out_time'] as String?;
    final rawHours   = double.tryParse(log['total_hours']?.toString() ?? '') ?? 0.0;
    final hoursLabel  = log['clock_out_at'] != null ? '${rawHours.toStringAsFixed(2)}h' : null;
    final locationNote = log['location_note'] as String?;
    final isActive    = clockOut == null;
    final status      = log['status'] as String? ?? '';

    final locationVerified = locationNote == 'location_verified';
    final locationWarning  = locationNote != null &&
        locationNote != 'location_verified' &&
        locationNote != 'location_check_failed';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.work_outline_rounded,
              color: AppColors.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),

          // Main content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(jobTitle, style: AppTextStyles.body),
                const SizedBox(height: 4),

                // Clock-in → clock-out
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded,
                        size: 13, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      isActive ? '$clockIn — Active' : '$clockIn — ${clockOut ?? '—'}',
                      style: AppTextStyles.small,
                    ),
                  ],
                ),

                // Location badge
                if (locationVerified || locationWarning) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: locationVerified
                          ? AppColors.success.withValues(alpha: 0.1)
                          : AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 11,
                          color: locationVerified
                              ? AppColors.success
                              : AppColors.warning,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          locationVerified ? 'Location verified' : locationNote!,
                          style: AppTextStyles.label.copyWith(
                            color: locationVerified
                                ? AppColors.success
                                : AppColors.warning,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Right column: hours + status
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                hoursLabel ?? (isActive ? '—' : '—'),
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              if (isActive)
                _StatusBadge(label: 'Active', color: AppColors.success)
              else if (status == 'approved')
                _StatusBadge(label: 'Approved', color: AppColors.success)
              else
                _StatusBadge(label: 'Pending', color: AppColors.warning),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: AppTextStyles.label.copyWith(color: color, fontSize: 11),
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 40,
            color: AppColors.textSecondary.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          Text(
            'No entries for this period',
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}