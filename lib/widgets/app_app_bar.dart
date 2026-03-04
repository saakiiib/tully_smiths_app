import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../controllers/auth_controller.dart';

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;

  const AppTopBar({super.key, this.title});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();

    return AppBar(
      backgroundColor: AppColors.primary,
      elevation: 0,
      title: Row(
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
            'Tully Smith',
            style: AppTextStyles.button.copyWith(color: AppColors.white),
          ),
        ],
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