import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/features/student/auth/domain/entities/user_entity.dart';
import 'package:lms_platform/features/student/auth/presentation/widgets/login/role_card.dart';

class StageRoleSelection extends StatelessWidget {
  final UserRole selectedRole;
  final ValueChanged<UserRole> onRoleChanged;
  final bool isDark;

  const StageRoleSelection({
    super.key,
    required this.selectedRole,
    required this.onRoleChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.person_outline_rounded,
            size: 64,
            color: AppColors.primary,
          ),
          const SizedBox(height: 24),
          Text(
            'auth.i_am_a'.tr(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.white : AppColors.textMainLight,
            ),
          ),
          const SizedBox(height: 32),
          _buildRoleSelector(),
        ],
      ),
    );
  }

  Widget _buildRoleSelector() {
    return LayoutBuilder(
      builder: (_, c) {
        final s = (c.maxWidth - 12) / 2;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RoleCard(
              role: UserRole.student,
              selectedRole: selectedRole,
              icon: Icons.school_rounded,
              label: 'auth.role_student'.tr(),
              isDark: isDark,
              size: s,
              onTap: () => onRoleChanged(UserRole.student),
            ),
          ],
        );
      },
    );
  }
}
