import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/features/student/home/domain/entities/course_entity.dart';
import 'course_card.dart';

/// Home Recommended Section - Personalized course recommendations
class HomeRecommendedSection extends StatelessWidget {
  final List<CourseEntity> courses;
  final String locale;
  final Function(CourseEntity) onCourseTap;
  final VoidCallback? onSeeAll;

  const HomeRecommendedSection({
    super.key,
    required this.courses,
    required this.locale,
    required this.onCourseTap,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    if (courses.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header with AI badge
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withValues(alpha: 0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'home.recommended_for_you'.tr(),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColors.textMainDark
                            : AppColors.textMainLight,
                      ),
                    ),
                    Text(
                      'home.based_on_interests'.tr(),
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
              if (onSeeAll != null)
                GestureDetector(
                  onTap: onSeeAll,
                  child: Text(
                    'home.see_all'.tr(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Courses List
        SizedBox(
          height: 260,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: courses.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: CourseCard(
                  course: courses[index],
                  locale: locale,
                  onTap: () => onCourseTap(courses[index]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
