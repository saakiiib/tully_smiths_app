import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/more_controller.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/app_app_bar.dart';
import '../../constants/app_text_styles.dart';
import '../../constants/app_colors.dart';

class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(MoreController());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppTopBar(),
      bottomNavigationBar: const AppBottomNav(currentIndex: 3),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text('More', style: AppTextStyles.heading),
            const SizedBox(height: 4),
            Text('Settings & options', style: AppTextStyles.small),
            const SizedBox(height: 24),
            Obx(() => Column(
                  children: ctrl.menuItems.map((item) => _MenuItem(label: item)).toList(),
                )),
          ],
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final String label;

  const _MenuItem({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Text(label, style: AppTextStyles.body),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textSecondary),
        onTap: () {},
      ),
    );
  }
}