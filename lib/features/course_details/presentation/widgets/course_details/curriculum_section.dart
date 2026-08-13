import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../domain/entities/section_entity.dart';
import '../../../domain/entities/lesson_entity.dart';

/// Curriculum Section - Udemy-style accordion list
class CurriculumSection extends StatelessWidget {
  final List<SectionEntity> sections;
  final String locale;
  final List<int> expandedSections;
  final Function(int) onToggleSection;
  final Function(LessonEntity)? onLessonTap;
  final bool isEnrolled;

  const CurriculumSection({
    super.key,
    required this.sections,
    required this.locale,
    required this.expandedSections,
    required this.onToggleSection,
    this.onLessonTap,
    this.isEnrolled = false,
  });

  @override
  Widget build(BuildContext context) {
    if (sections.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Calculate totals
    final totalSections = sections.length;
    final totalLectures =
        sections.fold<int>(0, (sum, section) => sum + section.lessons.length);
    final totalDuration =
        sections.fold<int>(0, (sum, section) => sum + section.totalDuration);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'course_details.curriculum'.tr(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
            ),
          ),
          const SizedBox(height: 8),
          // Summary row
          _buildSummaryRow(totalSections, totalLectures, totalDuration, isDark),
          const SizedBox(height: 16),
          // Sections list
          ...sections.asMap().entries.map((entry) {
            final index = entry.key;
            final section = entry.value;
            final isExpanded = expandedSections.contains(index);
            return _buildSectionItem(section, index, isExpanded, isDark);
          }),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
      int sections, int lectures, int durationSeconds, bool isDark) {
    final hours = durationSeconds ~/ 3600;
    final minutes = (durationSeconds % 3600) ~/ 60;

    String durationText;
    if (hours > 0 && minutes > 0) {
      durationText = '${hours}h ${minutes}m';
    } else if (hours > 0) {
      durationText = '${hours}h';
    } else {
      durationText = '${minutes}m';
    }

    final isArabic = locale == 'ar';
    final summaryParts = <String>[
      '$sections ${'course_details.sections'.tr()}',
      '$lectures ${'course_details.lectures'.tr()}',
    ];
    if (durationSeconds > 0) {
      summaryParts.add(isArabic
          ? '${'course_details.total_length'.tr()} $durationText'
          : '$durationText ${'course_details.total_length'.tr()}');
    }
    final summaryText = summaryParts.join(' • ');

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        summaryText,
        style: TextStyle(
          fontSize: 13,
          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
        ),
      ),
    );
  }

  Widget _buildSectionItem(
    SectionEntity section,
    int index,
    bool isExpanded,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.grey200,
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          // Section header
          InkWell(
            onTap: () => onToggleSection(index),
            child: Container(
              padding: const EdgeInsets.all(16),
              color: isDark
                  ? AppColors.cardDark.withValues(alpha: 0.5)
                  : AppColors.grey50,
              child: Row(
                children: [
                  // Expand icon
                  AnimatedRotation(
                    turns: isExpanded ? 0.25 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: isDark
                          ? AppColors.textMutedDark
                          : AppColors.textMutedLight,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Section info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          section.getTitle(locale),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.textMainDark
                                : AppColors.textMainLight,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          section.totalDuration > 0
                              ? '${section.totalLessons} ${'course_details.lectures'.tr()} • ${section.formattedDuration}'
                              : '${section.totalLessons} ${'course_details.lectures'.tr()}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.textMutedDark
                                : AppColors.textMutedLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Lessons list (animated)
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              children: section.lessons
                  .map((lesson) => _buildLessonItem(lesson, isDark))
                  .toList(),
            ),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonItem(LessonEntity lesson, bool isDark) {
    final canPlay = isEnrolled || lesson.isPreview;

    return InkWell(
      onTap: canPlay ? () => onLessonTap?.call(lesson) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.white,
          border: Border(
            top: BorderSide(
              color: isDark
                  ? AppColors.borderDark.withValues(alpha: 0.3)
                  : AppColors.grey100,
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            // Checkbox or lock icon
            Container(
              width: 20,
              height: 20,
              margin: const EdgeInsets.only(left: 28),
              child: Icon(
                canPlay ? _getLessonIcon(lesson.type) : Icons.lock_outline,
                size: 18,
                color: canPlay
                    ? (isDark ? AppColors.textMutedDark : AppColors.grey500)
                    : AppColors.grey400,
              ),
            ),
            const SizedBox(width: 12),
            // Lesson title
            Expanded(
              child: Text(
                lesson.getTitle(locale),
                style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? AppColors.textMutedDark
                      : AppColors.textMutedLight,
                ),
              ),
            ),
            // Preview badge
            if (lesson.isPreview && !isEnrolled) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.primary, width: 1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'course_details.preview'.tr(),
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            // Duration (only when metadata is available)
            if (lesson.videoDuration > 0)
              Text(
                lesson.formattedDuration,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.textMutedDark
                      : AppColors.textMutedLight,
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getLessonIcon(LessonType type) {
    switch (type) {
      case LessonType.video:
        return Icons.play_circle_outline;
      case LessonType.article:
        return Icons.article_outlined;
      case LessonType.quiz:
        return Icons.quiz_outlined;
      case LessonType.assignment:
        return Icons.assignment_outlined;
      case LessonType.resource:
        return Icons.folder_outlined;
      case LessonType.live:
        return Icons.live_tv_outlined;
      case LessonType.document:
        return Icons.insert_drive_file_outlined;
    }
  }
}
