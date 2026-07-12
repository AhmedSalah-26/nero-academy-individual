import 'package:flutter/material.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/features/student/auth/domain/entities/user_entity.dart';

/// Role Selector - student registration only.
class RoleSelector extends StatelessWidget {
  final UserRole selectedRole;
  final ValueChanged<UserRole> onRoleChanged;

  const RoleSelector({
    super.key,
    required this.selectedRole,
    required this.onRoleChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'أنا',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.grey300
                : AppColors.grey700,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _RoleCard(
                icon: Icons.school,
                label: 'طالب',
                isSelected: selectedRole == UserRole.student,
                onTap: () => onRoleChanged(UserRole.student),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.05)
              : (isDark ? AppColors.grey800 : AppColors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.grey700 : AppColors.grey200),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          children: [
            // Checkmark
            if (isSelected)
              Align(
                alignment: AlignmentDirectional.topEnd,
                child: Container(
                  margin: const EdgeInsetsDirectional.only(end: 8),
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 14,
                    color: AppColors.white,
                  ),
                ),
              )
            else
              const SizedBox(height: 20),
            // Icon
            Icon(
              icon,
              size: 28,
              color: isSelected
                  ? AppColors.primary
                  : (isDark ? AppColors.grey400 : AppColors.grey500),
            ),
            const SizedBox(height: 8),
            // Label
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
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
