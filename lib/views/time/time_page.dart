import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/time_controller.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/app_app_bar.dart';
import '../../constants/app_text_styles.dart';
import '../../constants/app_colors.dart';

class TimePage extends StatelessWidget {
  const TimePage({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(TimeController());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppTopBar(),
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text('Time', style: AppTextStyles.heading),
            const SizedBox(height: 4),
            Text("Today's attendance", style: AppTextStyles.small),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, Color(0xFF16213E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Hours',
                    style: AppTextStyles.small.copyWith(
                      color: AppColors.white.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Obx(() => Text(
                        ctrl.totalHours.value,
                        style: AppTextStyles.heading.copyWith(
                          color: AppColors.white,
                          fontSize: 36,
                        ),
                      )),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Today',
                        style: AppTextStyles.small.copyWith(
                          color: AppColors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _TimeCard(
                    label: 'Check In',
                    icon: Icons.login_rounded,
                    iconColor: AppColors.success,
                    valueObs: ctrl.todayCheckIn,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _TimeCard(
                    label: 'Check Out',
                    icon: Icons.logout_rounded,
                    iconColor: AppColors.error,
                    valueObs: ctrl.todayCheckOut,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color iconColor;
  final RxString valueObs;

  const _TimeCard({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.valueObs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(height: 16),
          Text(label, style: AppTextStyles.small),
          const SizedBox(height: 4),
          Obx(() => Text(valueObs.value, style: AppTextStyles.button)),
        ],
      ),
    );
  }
}