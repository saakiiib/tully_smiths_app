import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../controllers/auth_controller.dart';
import '../services/api_service.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final role = ApiService.role?.toLowerCase() ?? '';
    final isAdminOrSuperAdmin = role == 'admin' || role == 'super admin';

    return Drawer(
      backgroundColor: AppColors.white,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              color: AppColors.primary,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      'assets/icon/app_icon.png',
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Tully Smiths',
                    style: AppTextStyles.button.copyWith(color: AppColors.white),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    ApiService.role ?? '',
                    style: AppTextStyles.small.copyWith(
                      color: AppColors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  const _DrawerItem(
                    icon: Icons.dashboard_outlined,
                    label: 'Dashboard',
                    route: '/dashboard',
                  ),
                  const _DrawerItem(
                    icon: Icons.access_time_rounded,
                    label: 'Time',
                    route: '/time',
                  ),
                  const _DrawerItem(
                    icon: Icons.calendar_today_outlined,
                    label: 'Timesheets',
                    route: '/timesheets',
                  ),
                  if (isAdminOrSuperAdmin) ...[
                    const _DrawerItem(
                      icon: Icons.calendar_month_outlined,
                      label: 'Calendar',
                      route: '/calendar',
                    ),
                    const _DrawerItem(
                      icon: Icons.work_outline_rounded,
                      label: 'Jobs',
                      route: '/jobs',
                    ),
                    const _DrawerItem(
                      icon: Icons.file_copy_outlined,
                      label: 'Approvals',
                      route: '/approvals',
                    ),
                    const _DrawerItem(
                      icon: Icons.person_outline_rounded,
                      label: 'Clients',
                      route: '/clients',
                    ),
                    const _DrawerItem(
                      icon: Icons.checklist_rounded,
                      label: 'Checklist',
                      route: '/checklist',
                    ),
                    const _DrawerItem(
                      icon: Icons.people_outline_rounded,
                      label: 'Employees',
                      route: '/employees',
                    ),
                  ],
                ],
              ),
            ),
            Divider(color: AppColors.border),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: AppColors.textSecondary),
              title: Text('Logout', style: AppTextStyles.body),
              onTap: auth.logout,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    final isCurrent = Get.currentRoute == route;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: ListTile(
        leading: Icon(
          icon,
          color: isCurrent ? AppColors.primary : AppColors.textSecondary,
          size: 20,
        ),
        title: Text(
          label,
          style: AppTextStyles.body.copyWith(
            color: isCurrent ? AppColors.primary : null,
            fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        tileColor: isCurrent
            ? AppColors.primary.withValues(alpha: 0.08)
            : Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        onTap: () {
          Get.back();
          if (!isCurrent) Get.offAllNamed(route);
        },
      ),
    );
  }
}