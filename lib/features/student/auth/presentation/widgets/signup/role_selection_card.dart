import 'package:flutter/material.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/features/student/auth/domain/entities/user_entity.dart';

class RoleSelectionCard extends StatelessWidget {
  final UserRole role;
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const RoleSelectionCard({
    super.key,
    required this.role,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : (isDark ? AppColors.grey800 : AppColors.grey100),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.grey700 : AppColors.grey300),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? AppColors.primary : AppColors.grey400,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? AppColors.primary
                    : (isDark ? AppColors.grey300 : AppColors.grey700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
