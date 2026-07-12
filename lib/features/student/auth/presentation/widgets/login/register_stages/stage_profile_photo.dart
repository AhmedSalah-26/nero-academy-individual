import 'dart:typed_data';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/features/student/auth/presentation/widgets/login/avatar_picker.dart';

class StageProfilePhoto extends StatelessWidget {
  final Uint8List? avatarBytes;
  final VoidCallback? onPickAvatar;
  final bool isDark;

  const StageProfilePhoto({
    super.key,
    this.avatarBytes,
    this.onPickAvatar,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'auth.add_photo'.tr(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.white : AppColors.textMainLight,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'auth.photo_subtitle'.tr(),
          style: TextStyle(
            fontSize: 14,
            color: isDark ? AppColors.grey400 : AppColors.grey500,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        if (onPickAvatar != null)
          AvatarPicker(
            imageBytes: avatarBytes,
            onTap: onPickAvatar!,
            isDark: isDark,
          ),
        const SizedBox(height: 16),
        Text(
          'auth.optional'.tr(),
          style: TextStyle(
            fontSize: 12,
            color: isDark ? AppColors.grey400 : AppColors.grey500,
          ),
        ),
      ],
    );
  }
}
