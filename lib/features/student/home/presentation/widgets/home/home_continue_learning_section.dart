import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lms_platform/core/theme/app_colors.dart';

/// Continue Learning Course Model
class ContinueLearningCourse {
  final String id;
  final String title;
  final String? thumbnailUrl;
  final String? instructorName;
  final double progress; // 0.0 to 1.0
  final String? nextLessonTitle;
  final int remainingLessons;

  const ContinueLearningCourse({
    required this.id,
    required this.title,
    this.thumbnailUrl,
    this.instructorName,
    required this.progress,
    this.nextLessonTitle,
    this.remainingLessons = 0,
  });
}

/// Home Continue Learning Section
class HomeContinueLearningSection extends StatelessWidget {
  final List<ContinueLearningCourse> courses;
  final Function(String courseId) onCourseTap;
  final Function(String courseId) onContinueTap;

  const HomeContinueLearningSection({
    super.key,
    required this.courses,
    required this.onCourseTap,
    required this.onContinueTap,
  });

  @override
  Widget build(BuildContext context) {
    if (courses.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Icon(
                Icons.play_circle_filled_rounded,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'home.continue_learning'.tr(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color:
                      isDark ? AppColors.textMainDark : AppColors.textMainLight,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Courses List
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: courses.length,
            itemBuilder: (context, index) {
              return _ContinueLearningCard(
                course: courses[index],
                isDark: isDark,
                onTap: () => onCourseTap(courses[index].id),
                onContinue: () => onContinueTap(courses[index].id),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ContinueLearningCard extends StatelessWidget {
  final ContinueLearningCourse course;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onContinue;

  const _ContinueLearningCard({
    required this.course,
    required this.isDark,
    required this.onTap,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 280,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: const BorderRadiusDirectional.only(
                topStart: Radius.circular(12),
                bottomStart: Radius.circular(12),
              ),
              child: SizedBox(
                width: 100,
                height: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    (course.thumbnailUrl ?? '').isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: course.thumbnailUrl!,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              color: isDark
                                  ? AppColors.surfaceDark
                                  : AppColors.grey200,
                            ),
                            errorWidget: (_, __, ___) => Container(
                              color: isDark
                                  ? AppColors.surfaceDark
                                  : AppColors.grey200,
                              child: const Icon(Icons.play_circle_outline,
                                  color: AppColors.grey400),
                            ),
                          )
                        : Container(
                            color: isDark
                                ? AppColors.surfaceDark
                                : AppColors.grey200,
                            child: const Icon(Icons.play_circle_outline,
                                color: AppColors.grey400),
                          ),
                    // Progress Overlay
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 4,
                        color: isDark ? AppColors.grey700 : AppColors.grey300,
                        child: FractionallySizedBox(
                          alignment: AlignmentDirectional.centerStart,
                          widthFactor: course.progress,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      course.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textMainDark
                            : AppColors.textMainLight,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Progress Text
                    Text(
                      '${(course.progress * 100).toInt()}% ${'home.completed'.tr()}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    // Continue Button
                    SizedBox(
                      width: double.infinity,
                      height: 32,
                      child: ElevatedButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          onContinue();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.play_arrow_rounded, size: 18),
                            const SizedBox(width: 4),
                            Text(
                              'home.continue'.tr(),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
