import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lms_platform/core/theme/app_colors.dart';

/// What You'll Learn Section
class WhatYouLearnSection extends StatelessWidget {
  final List<String> objectives;

  const WhatYouLearnSection({
    super.key,
    required this.objectives,
  });

  @override
  Widget build(BuildContext context) {
    if (objectives.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.grey200,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: isDark ? 0.15 : 0.12),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: AppColors.primary.withValues(alpha: isDark ? 0.08 : 0.06),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'course_details.what_you_learn'.tr(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color:
                    isDark ? AppColors.textMainDark : AppColors.textMainLight,
              ),
            ),
            const SizedBox(height: 16),
            ...objectives.take(6).map((objective) => _buildObjectiveItem(
                  objective,
                  isDark,
                )),
            if (objectives.length > 6) ...[
              const SizedBox(height: 8),
              Text(
                '+${objectives.length - 6} ${'course_details.more'.tr()}',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildObjectiveItem(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            child: const Icon(
              Icons.check_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color:
                    isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
