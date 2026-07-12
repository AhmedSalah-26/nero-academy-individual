import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lms_platform/core/theme/app_colors.dart';

/// Instructor Stats Row - Shows courses, students, rating
class InstructorStatsRow extends StatelessWidget {
  final int courses;
  final int students;
  final double rating;
  final bool isDark;

  const InstructorStatsRow({
    super.key,
    required this.courses,
    required this.students,
    required this.rating,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _StatItem(
          value: courses.toString(),
          label: 'instructor.courses'.tr(),
          isDark: isDark,
        ),
        _StatItem(
          value: _formatCount(students),
          label: 'instructor.students'.tr(),
          isDark: isDark,
        ),
        _StatItem(
          value: rating.toStringAsFixed(1),
          label: 'instructor.rating'.tr(),
          isDark: isDark,
          icon: Icons.star_rounded,
          iconColor: AppColors.rating,
        ),
      ],
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    }
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final bool isDark;
  final IconData? icon;
  final Color? iconColor;

  const _StatItem({
    required this.value,
    required this.label,
    required this.isDark,
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 4),
            ],
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.white : AppColors.textMainLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
          ),
        ),
      ],
    );
  }
}
