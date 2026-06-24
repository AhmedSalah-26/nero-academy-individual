import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../../../../../core/theme/app_colors.dart';
import '../../../domain/entities/lesson_entity.dart';

/// Lesson Item Widget
class LessonItem extends StatelessWidget {
  final LessonEntity lesson;
  final int lessonNumber;
  final bool isCurrentLesson;
  final bool isCompleted;
  final bool isLocked;
  final bool hasQuiz;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback? onDownloadTap;

  const LessonItem({
    super.key,
    required this.lesson,
    this.lessonNumber = 0,
    required this.isCurrentLesson,
    required this.isCompleted,
    required this.isLocked,
    this.hasQuiz = false,
    required this.isDark,
    required this.onTap,
    this.onDownloadTap,
  });

  @override
  Widget build(BuildContext context) {
    final locale = context.locale.languageCode;

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLocked ? null : onTap,
          child: Opacity(
            opacity: isLocked ? 0.62 : 1,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _backgroundColor(),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isCurrentLesson
                      ? AppColors.primary.withValues(alpha: 0.28)
                      : Colors.transparent,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildLeadingIcon(),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _buildLessonNumber(),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                lesson.getTitle(locale),
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  color: isCurrentLesson
                                      ? AppColors.primary
                                      : (isDark
                                          ? AppColors.textMainDark
                                          : AppColors.textMainLight),
                                  fontSize: 14,
                                  fontWeight: isCurrentLesson
                                      ? FontWeight.w800
                                      : FontWeight.w700,
                                  height: 1.35,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (isCurrentLesson) _buildPlayingBadge(),
                            if (hasQuiz) _buildQuizBadge(),
                            Text(
                              isCurrentLesson
                                  ? 'تمت المشاهدة 35%'
                                  : _subtitleText(),
                              style: TextStyle(
                                color: isCurrentLesson
                                    ? AppColors.primary.withValues(alpha: 0.82)
                                    : (isDark
                                        ? AppColors.textMutedDark
                                        : AppColors.textMutedLight),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (onDownloadTap != null && !isLocked) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: onDownloadTap,
                      icon: Icon(
                        isCompleted ? Icons.download_done : Icons.download,
                        color: isCompleted
                            ? AppColors.primary
                            : (isDark
                                ? AppColors.textMutedDark
                                : AppColors.textMutedLight),
                        size: 18,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _backgroundColor() {
    if (isCurrentLesson) {
      return AppColors.primary.withValues(alpha: isDark ? 0.16 : 0.08);
    }
    return isDark ? AppColors.surfaceDark : AppColors.white;
  }

  Widget _buildLeadingIcon() {
    final icon = isLocked
        ? Icons.lock_outline_rounded
        : isCompleted
            ? Icons.check_rounded
            : isCurrentLesson
                ? Icons.play_arrow_rounded
                : _getLessonTypeIcon();

    final color = isLocked
        ? (isDark ? AppColors.textMutedDark : AppColors.textMutedLight)
        : AppColors.white;

    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: isLocked
            ? (isDark ? AppColors.cardDark : const Color(0xFFF3EEF9))
            : AppColors.primary,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 18),
    );
  }

  Widget _buildLessonNumber() {
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isCurrentLesson
            ? AppColors.primary.withValues(alpha: 0.12)
            : (isDark ? AppColors.cardDark : const Color(0xFFF5F0FB)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        lessonNumber > 0 ? '$lessonNumber' : '1',
        style: TextStyle(
          color: isCurrentLesson
              ? AppColors.primary
              : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildPlayingBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        'قيد التشغيل',
        style: TextStyle(
          color: Colors.white,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          height: 1.1,
        ),
      ),
    );
  }

  Widget _buildQuizBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.28),
        ),
      ),
      child: const Text(
        'اختبار',
        style: TextStyle(
          color: AppColors.warning,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          height: 1.1,
        ),
      ),
    );
  }

  String _subtitleText() {
    if (isLocked) return 'غير متاح الآن';
    if (lesson.durationInMinutes > 0) {
      return '${lesson.durationInMinutes} ${'course_player.min'.tr()}';
    }
    return isCompleted ? 'تمت المشاهدة' : 'جاهز للمشاهدة';
  }

  IconData _getLessonTypeIcon() {
    switch (lesson.type) {
      case LessonType.video:
        return Icons.play_circle_outline;
      case LessonType.article:
        return Icons.description_outlined;
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
