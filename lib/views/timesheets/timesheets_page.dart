import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/timesheets_controller.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/app_app_bar.dart';
import '../../constants/app_text_styles.dart';
import '../../constants/app_colors.dart';

class TimesheetsPage extends StatelessWidget {
  const TimesheetsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(TimesheetsController());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppTopBar(),
      bottomNavigationBar: const AppBottomNav(currentIndex: 2),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text('Timesheets', style: AppTextStyles.heading),
            const SizedBox(height: 4),
            Text('Your work history', style: AppTextStyles.small),
            const SizedBox(height: 24),
            Obx(() => Column(
                  children: ctrl.timesheets
                      .map((item) => _TimesheetCard(label: item))
                      .toList(),
                )),
          ],
        ),
      ),
    );
  }
}

class _TimesheetCard extends StatelessWidget {
  final String label;

  const _TimesheetCard({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.calendar_today_outlined,
              color: AppColors.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.body),
                const SizedBox(height: 4),
                Text('8h 00m', style: AppTextStyles.small),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Approved',
              style: AppTextStyles.label.copyWith(color: AppColors.success),
            ),
          ),
        ],
      ),
    );
  }
}