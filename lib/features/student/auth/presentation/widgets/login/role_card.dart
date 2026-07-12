import 'package:flutter/material.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/features/student/auth/domain/entities/user_entity.dart';

class RoleCard extends StatelessWidget {
  final UserRole role;
  final UserRole selectedRole;
  final IconData icon;
  final String label;
  final bool isDark;
  final double size;
  final VoidCallback onTap;

  const RoleCard({
    super.key,
    required this.role,
    required this.selectedRole,
    required this.icon,
    required this.label,
    required this.isDark,
    required this.size,
    required this.onTap,
  });

  bool get isSelected => selectedRole == role;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.08)
                  : (isDark ? AppColors.cardDark : Colors.white),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : (isDark ? AppColors.grey700 : const Color(0xFFE2E8F0)),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 32,
                  color: isSelected
                      ? AppColors.primary
                      : (isDark ? AppColors.grey400 : AppColors.grey500),
                ),
                const SizedBox(height: 10),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? AppColors.primary
                        : (isDark ? AppColors.grey400 : AppColors.grey500),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          if (isSelected)
            Positioned(
              top: -6,
              right: -6,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 12,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
