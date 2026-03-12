import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../controllers/auth_controller.dart';
import '../services/api_service.dart';

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;

  const AppTopBar({super.key, this.title});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();

    if (!ApiService.isWorker) {
      return AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
      );
    }

    return AppBar(
      backgroundColor: AppColors.primary,
      elevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.asset(
                'assets/icon/app_icon.png',
                width: 45,
                height: 45,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Tully Smiths',
              style: AppTextStyles.button.copyWith(color: AppColors.white),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          onPressed: auth.logout,
          icon: const Icon(Icons.logout_rounded, color: AppColors.white, size: 20),
        ),
      ],
    );
  }
}