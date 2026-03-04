import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

class AppFeedback {
  AppFeedback._();

  static void showSuccess(String message) {
    _showToast(message, AppColors.success, Icons.check_circle);
  }

  static void showError(String message) {
    _showToast(message, AppColors.error, Icons.error_outline);
  }

  static void _showToast(String message, Color bgColor, IconData icon) {
    Get.showSnackbar(GetSnackBar(
      messageText: Row(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.small.copyWith(color: Colors.white),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      snackPosition: SnackPosition.TOP,
      backgroundColor: bgColor,
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
      duration: const Duration(seconds: 3),
      isDismissible: true,
      animationDuration: const Duration(milliseconds: 300),
    ));
  }
}