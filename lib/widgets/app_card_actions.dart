import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

class AppCardActions extends StatelessWidget {
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleStatus;
  final bool isActive;

  const AppCardActions({
    super.key,
    this.onEdit,
    this.onDelete,
    this.onToggleStatus,
    this.isActive = true,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
      icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
      color: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (_) => [
        if (onEdit != null)
          PopupMenuItem(
            onTap: onEdit,
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.edit_outlined, size: 16, color: AppColors.primary),
                ),
                const SizedBox(width: 10),
                Text('Edit', style: AppTextStyles.small),
              ],
            ),
          ),
        if (onToggleStatus != null)
          PopupMenuItem(
            onTap: onToggleStatus,
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: (isActive ? AppColors.warning : AppColors.success).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isActive ? Icons.block : Icons.check_circle_outline,
                    size: 16,
                    color: isActive ? AppColors.warning : AppColors.success,
                  ),
                ),
                const SizedBox(width: 10),
                Text(isActive ? 'Deactivate' : 'Activate', style: AppTextStyles.small),
              ],
            ),
          ),
        if (onDelete != null)
          PopupMenuItem(
            onTap: onDelete,
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.delete_outline, size: 16, color: AppColors.error),
                ),
                const SizedBox(width: 10),
                Text('Delete', style: AppTextStyles.small),
              ],
            ),
          ),
      ],
    );
  }
}