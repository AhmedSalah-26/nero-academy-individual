import 'dart:ui' as ui;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/features/student/instructor/domain/entities/instructor_course_entity.dart';

/// Instructor Course Grid - 2 columns grid layout
class InstructorCourseGrid extends StatelessWidget {
  final List<InstructorCourseEntity> courses;
  final String locale;
  final Function(String courseId) onCourseTap;

  const InstructorCourseGrid({
    super.key,
    required this.courses,
    required this.locale,
    required this.onCourseTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final course = courses[index];
            return _InstructorCourseCard(
              course: course,
              locale: locale,
              isDark: isDark,
              onTap: () => onCourseTap(course.id),
            );
          },
          childCount: courses.length,
        ),
      ),
    );
  }
}

class _InstructorCourseCard extends StatelessWidget {
  final InstructorCourseEntity course;
  final String locale;
  final bool isDark;
  final VoidCallback onTap;

  const _InstructorCourseCard({
    required this.course,
    required this.locale,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.grey200,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.15),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: AppColors.primary.withValues(alpha: isDark ? 0.1 : 0.08),
              blurRadius: 24,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildThumbnail(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      course.getTitle(locale),
                      style: TextStyle(
                        color: isDark
                            ? AppColors.textMainDark
                            : AppColors.textMainLight,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    // Stats Row
                    _buildStatsRow(),
                    const SizedBox(height: 4),
                    // Price Row
                    _buildPrice(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    final discountPercentage = course.discountPercentage ?? 0;

    return Stack(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: (course.thumbnailUrl ?? '').isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: course.thumbnailUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      color: isDark ? AppColors.surfaceDark : AppColors.grey200,
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: isDark ? AppColors.surfaceDark : AppColors.grey200,
                      child: const Icon(Icons.play_circle_outline,
                          color: AppColors.grey400),
                    ),
                  )
                : Container(
                    color: isDark ? AppColors.surfaceDark : AppColors.grey200,
                    child: const Icon(Icons.play_circle_outline,
                        color: AppColors.grey400),
                  ),
          ),
        ),
        // Discount Badge
        if (discountPercentage > 0)
          Positioned(
            top: 6,
            left: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '$discountPercentage%',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                ),
              ),
            ),
          ),
        // Free Badge
        if (course.isFree)
          Positioned(
            top: 6,
            left: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.success,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'course.free'.tr(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                ),
              ),
            ),
          ),
        // Premium Badge
        if (course.isBestseller)
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.rating.withValues(alpha: 0.9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.workspace_premium_rounded,
                size: 12,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        // Students
        Icon(Icons.people_alt_outlined,
            size: 12, color: isDark ? AppColors.grey400 : AppColors.grey500),
        const SizedBox(width: 2),
        Text(
          _formatCount(course.enrolledCount),
          style: TextStyle(
            color: isDark ? AppColors.grey400 : AppColors.grey500,
            fontSize: 10,
          ),
        ),
        const Spacer(),
        // Rating
        Text(
          '(${_formatCount(course.ratingCount)})',
          style: TextStyle(
            color: isDark ? AppColors.grey400 : AppColors.grey500,
            fontSize: 10,
          ),
        ),
        const SizedBox(width: 3),
        const Icon(Icons.star_rounded, size: 12, color: AppColors.rating),
        const SizedBox(width: 2),
        Text(
          course.rating.toStringAsFixed(1),
          style: const TextStyle(
            color: AppColors.rating,
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildPrice() {
    if (course.isFree) {
      return Text(
        'course.free'.tr(),
        style: const TextStyle(
          color: AppColors.success,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      );
    }

    final hasDiscount = (course.discountPercentage ?? 0) > 0;
    final currentPrice = course.currentPrice;
    final originalPrice = course.price;
    final currency = course.currency;

    return Directionality(
      textDirection: ui.TextDirection.ltr,
      child: Row(
        children: [
          Text(
            '$currency ${currentPrice.toStringAsFixed(0)}',
            style: TextStyle(
              color: isDark ? AppColors.white : AppColors.primary,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          if (hasDiscount && originalPrice > currentPrice) ...[
            const SizedBox(width: 4),
            Text(
              originalPrice.toStringAsFixed(0),
              style: TextStyle(
                color: isDark ? AppColors.grey500 : AppColors.grey400,
                decoration: TextDecoration.lineThrough,
                fontSize: 10,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
    return count.toString();
  }
}
