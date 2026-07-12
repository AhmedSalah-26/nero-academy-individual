import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/features/student/course_search/domain/entities/course_entity.dart';
import 'dart:ui' as ui;

/// Course Card Widget - Horizontal card for search results
class CourseCardWidget extends StatelessWidget {
  final CourseEntity course;
  final VoidCallback onTap;

  const CourseCardWidget({
    super.key,
    required this.course,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            _buildThumbnail(isDark),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: _buildContent(context, theme, isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail(bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 112,
        height: 84,
        child: course.thumbnailUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: course.thumbnailUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: isDark
                      ? AppColors.shimmerBaseDark
                      : AppColors.shimmerBase,
                ),
                errorWidget: (context, url, error) => Container(
                  color: isDark
                      ? AppColors.shimmerBaseDark
                      : AppColors.shimmerBase,
                  child: const Icon(Icons.image_not_supported_outlined),
                ),
              )
            : Container(
                color:
                    isDark ? AppColors.shimmerBaseDark : AppColors.shimmerBase,
                child: const Icon(Icons.image_not_supported_outlined),
              ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Title
        Text(
          course.title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            height: 1.3,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),

        // Instructor
        Text(
          course.instructorName,
          style: theme.textTheme.bodySmall?.copyWith(
            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            fontWeight: FontWeight.w300,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),

        // Rating
        _buildRating(theme),
        const SizedBox(height: 8),

        // Price and Badge
        _buildPriceRow(theme, isDark),
      ],
    );
  }

  Widget _buildRating(ThemeData theme) {
    return Row(
      children: [
        Text(
          course.rating.toStringAsFixed(1),
          style: theme.textTheme.labelSmall?.copyWith(
            color: AppColors.rating,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 4),
        ...List.generate(5, (index) {
          final starValue = index + 1;
          IconData icon;
          if (course.rating >= starValue) {
            icon = Icons.star_rounded;
          } else if (course.rating >= starValue - 0.5) {
            icon = Icons.star_half_rounded;
          } else {
            icon = Icons.star_outline_rounded;
          }
          return Icon(icon, size: 14, color: AppColors.rating);
        }),
        const SizedBox(width: 4),
        Text(
          '(${_formatReviewCount(course.reviewCount)})',
          style: theme.textTheme.labelSmall?.copyWith(
            color: AppColors.grey400,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRow(ThemeData theme, bool isDark) {
    final hasDiscount =
        course.originalPrice != null && course.originalPrice! > course.price;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Directionality(
              textDirection: ui.TextDirection.ltr,
              child: Text(
                'EGP ${course.price.toStringAsFixed(0)}',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: isDark ? AppColors.white : AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (hasDiscount)
              Directionality(
                textDirection: ui.TextDirection.ltr,
                child: Text(
                  'EGP ${course.originalPrice!.toStringAsFixed(0)}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isDark
                        ? AppColors.textMutedDark
                        : AppColors.textMutedLight,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ),
          ],
        ),
        if (course.badge != null) _buildBadge(theme, isDark),
      ],
    );
  }

  Widget _buildBadge(ThemeData theme, bool isDark) {
    final badgeType = course.badge?.toLowerCase();

    if (badgeType == 'premium') {
      return Builder(
        builder: (context) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.rating,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.workspace_premium_rounded,
                size: 10,
                color: Colors.white,
              ),
              const SizedBox(width: 2),
              Text(
                context.locale.languageCode == 'ar' ? 'مميز' : 'Premium',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  String _formatReviewCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(0)}k';
    }
    return count.toString();
  }
}
