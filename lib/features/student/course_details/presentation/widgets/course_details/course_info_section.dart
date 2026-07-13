import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/features/student/course_details/domain/entities/course_details_entity.dart';

/// Course Info Section - Title, subtitle, badges, stats
class CourseInfoSection extends StatelessWidget {
  final CourseDetailsEntity course;
  final String locale;

  const CourseInfoSection({
    super.key,
    required this.course,
    required this.locale,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badges row
          _buildBadges(context, isDark),
          const SizedBox(height: 12),
          // Title
          Text(
            course.getTitle(locale),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          // Subtitle
          if (course.getSubtitle(locale).isNotEmpty)
            Text(
              course.getSubtitle(locale),
              style: TextStyle(
                fontSize: 14,
                color:
                    isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                height: 1.5,
              ),
            ),
          const SizedBox(height: 16),
          // Stats row
          _buildStatsRow(isDark),
        ],
      ),
    );
  }

  Widget _buildBadges(BuildContext context, bool isDark) {
    final customBadge = (course.badge ?? '').trim();
    final fallbackAccent = Theme.of(context).colorScheme.tertiary;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (customBadge.isNotEmpty)
          _buildBadge(
            customBadge,
            fallbackAccent,
            Colors.white,
          ),
        if (customBadge.isEmpty && course.isFlashSaleActive)
          _buildBadge(
            locale == 'ar' ? 'فلاش سيل' : 'Flash Sale',
            Colors.orange,
            Colors.white,
          ),
        // Premium badge
        if (course.isFeatured)
          _buildBadge(
            locale == 'ar' ? 'مميز' : 'Premium',
            AppColors.rating,
            Colors.white,
          ),
        // Level badge
        _buildBadge(
          course.level.getDisplayName(locale),
          fallbackAccent.withValues(alpha: isDark ? 0.22 : 0.12),
          fallbackAccent,
        ),
      ],
    );
  }

  Widget _buildBadge(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildStatsRow(bool isDark) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Rating
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              course.rating.toStringAsFixed(1),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.rating,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.star_rounded, color: AppColors.rating, size: 18),
            const SizedBox(width: 4),
            Text(
              '(${_formatCount(course.ratingCount)} ${'course_details.ratings'.tr()})',
              style: TextStyle(
                fontSize: 13,
                color:
                    isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              ),
            ),
          ],
        ),
        _buildDot(isDark),
        // Students
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.people_outline_rounded,
              size: 18,
              color:
                  isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            ),
            const SizedBox(width: 4),
            Text(
              '${_formatCount(course.enrolledCount)} ${'course_details.students'.tr()}',
              style: TextStyle(
                fontSize: 13,
                color:
                    isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              ),
            ),
          ],
        ),
        _buildDot(isDark),
        // Language
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.language_rounded,
              size: 18,
              color:
                  isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            ),
            const SizedBox(width: 4),
            Text(
              course.language == 'ar' ? 'العربية' : 'English',
              style: TextStyle(
                fontSize: 13,
                color:
                    isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDot(bool isDark) {
    return Text(
      '•',
      style: TextStyle(
        color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
    return count.toString();
  }
}
