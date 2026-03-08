import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;

  const AppBottomNav({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textSecondary,
      backgroundColor: AppColors.white,
      elevation: 8,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: AppTextStyles.label,
      unselectedLabelStyle: AppTextStyles.label,
      onTap: (i) {
        if (i == currentIndex) return;

        switch (i) {
          case 0:
            Get.offAllNamed('/dashboard');
            break;
          case 1:
            Get.offAllNamed('/time');
            break;
          case 2:
            Get.offAllNamed('/timesheets');
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_outlined),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.access_time_rounded),
          label: 'Time',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today_outlined),
          label: 'Timesheets',
        ),
      ],
    );
  }
}