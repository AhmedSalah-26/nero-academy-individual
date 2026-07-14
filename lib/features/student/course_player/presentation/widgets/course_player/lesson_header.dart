import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/features/student/course_player/domain/entities/lesson_entity.dart';
import 'package:lms_platform/features/student/course_player/domain/entities/section_entity.dart';

/// Lesson Header Widget
class LessonHeader extends StatelessWidget {
  final LessonEntity lesson;
  final SectionEntity? section;
  final int sectionIndex;
  final int lessonIndex;
  final bool isDark;
  final bool isBookmarked;
  final VoidCallback? onBookmarkTap;
  final String? instructorName;
  final String? instructorAvatar;
  final VoidCallback? onInstructorTap;
  final VoidCallback? onHeaderTap;

  const LessonHeader({
    super.key,
    required this.lesson,
    this.section,
    required this.sectionIndex,
    required this.lessonIndex,
    required this.isDark,
    this.isBookmarked = false,
    this.onBookmarkTap,
    this.instructorName,
    this.instructorAvatar,
    this.onInstructorTap,
    this.onHeaderTap,
  });

  @override
  Widget build(BuildContext context) {
    final locale = context.locale.languageCode;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: GestureDetector(
        onTap: onHeaderTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.borderDark : const Color(0xFFE8DDF7),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${'course_player.section'.tr()} ${sectionIndex + 1} • ${'course_player.lesson'.tr()} ${lessonIndex + 1}',
                      textAlign: TextAlign.start,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      lesson.getTitle(locale),
                      textAlign: TextAlign.start,
                      style: TextStyle(
                        color: isDark
                            ? AppColors.textMainDark
                            : AppColors.textMainLight,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (lesson.getDescription(locale) != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        lesson.getDescription(locale)!,
                        textAlign: TextAlign.start,
                        style: TextStyle(
                          color: isDark
                              ? AppColors.textMutedDark
                              : AppColors.textMutedLight,
                          fontSize: 13,
                          height: 1.5,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (onBookmarkTap != null) ...[
                const SizedBox(width: 12),
                IconButton(
                  onPressed: onBookmarkTap,
                  icon: Icon(
                    isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    color: isBookmarked
                        ? Theme.of(context).colorScheme.primary
                        : (isDark
                            ? AppColors.textMutedDark
                            : AppColors.textMutedLight),
                  ),
                  iconSize: 24,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
