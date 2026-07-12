import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../domain/entities/section_entity.dart';

/// Section Header Widget
class SectionHeader extends StatelessWidget {
  final SectionEntity section;
  final int sectionIndex;
  final int completedCount;
  final bool isDark;
  final bool showDivider;
  final String? lessonProgressLabel;

  const SectionHeader({
    super.key,
    required this.section,
    required this.sectionIndex,
    required this.completedCount,
    required this.isDark,
    this.showDivider = true,
    this.lessonProgressLabel,
  });

  @override
  Widget build(BuildContext context) {
    final locale = context.locale.languageCode;

    return Column(
      children: [
        if (showDivider && sectionIndex > 0)
          Divider(
            height: 1,
            thickness: 1,
            color: isDark ? AppColors.grey700 : const Color(0xFFE8DDF7),
          ),
        Container(
          padding: const EdgeInsets.fromLTRB(14, 13, 14, 10),
          color: isDark
              ? Colors.white.withValues(alpha: 0.04)
              : AppColors.backgroundLight.withValues(alpha: 0.45),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  section.getTitle(locale),
                  textAlign: TextAlign.start,
                  style: TextStyle(
                    color: isDark
                        ? AppColors.textMainDark
                        : AppColors.textMainLight,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                lessonProgressLabel ?? 'course_player.lesson_list'.tr(),
                style: TextStyle(
                  color: isDark
                      ? AppColors.textMutedDark.withValues(alpha: 0.75)
                      : AppColors.textMutedLight.withValues(alpha: 0.75),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
