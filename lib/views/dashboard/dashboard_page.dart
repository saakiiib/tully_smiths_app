import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
            Obx(() => GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.3,
                  children: [
                    _StatCard(
                      label: 'Total Employees',
                      value: '${dash.totalEmployees.value}',
                      icon: Icons.people_outline_rounded,
                    ),
                    _StatCard(
                      label: 'Active',
                      value: '${dash.activeEmployees.value}',
                      icon: Icons.check_circle_outline_rounded,
                    ),
                    _StatCard(
                      label: 'Departments',
                      value: '${dash.totalDepartments.value}',
                      icon: Icons.business_outlined,
                    ),
                    _StatCard(
                      label: 'New This Month',
                      value: '${dash.newThisMonth.value}',
                      icon: Icons.person_add_outlined,
                    ),
                  ],
                )),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(height: 12),
          Text(value, style: AppTextStyles.heading),
          const SizedBox(height: 4),
          Text(label, style: AppTextStyles.small),
        ],
      ),
    );
  }
}