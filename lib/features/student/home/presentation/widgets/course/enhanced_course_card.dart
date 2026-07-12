import 'dart:ui' as ui;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lms_platform/core/shared_widgets/glass_icon_button.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/features/student/home/domain/entities/course_entity.dart';

/// Enhanced Course Card with all new features
class EnhancedCourseCard extends StatelessWidget {
  final CourseEntity course;
  final String locale;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;
  final VoidCallback? onWishlistTap;
  final double? width;
  final bool showAddToCart;
  final bool isInWishlist;
  final bool isBestSeller;
  final bool hasCertificate;
  final double? userProgress; // 0.0 to 1.0, null if not enrolled

  const EnhancedCourseCard({
    super.key,
    required this.course,
    required this.locale,
    this.onTap,
    this.onAddToCart,
    this.onWishlistTap,
    this.width,
    this.showAddToCart = false,
    this.isInWishlist = false,
    this.isBestSeller = false,
    this.hasCertificate = false,
    this.userProgress,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = width ?? screenWidth * 0.44;
    const radius = 12.0;
    const borderWidth = 1.0;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap?.call();
      },
      child: Container(
        width: cardWidth,
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.white,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.grey200,
            width: borderWidth,
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
        child: Padding(
          padding: const EdgeInsets.all(borderWidth),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius - borderWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildThumbnail(isDark),
                Padding(
                  padding: const EdgeInsets.all(10),
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
                          fontSize: 13,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // Instructor
                      Text(
                        course.instructorName ?? '',
                        style: TextStyle(
                          color: isDark
                              ? AppColors.textMutedDark
                              : AppColors.textMutedLight,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      // Course Info Row (Duration, Lessons, Level)
                      _buildCourseInfoRow(isDark),
                      const SizedBox(height: 8),
                      // Stats Row
                      _buildStatsRow(isDark),
                      const SizedBox(height: 8),
                      // Progress Bar (if enrolled)
                      if (userProgress != null) ...[
                        _buildProgressBar(isDark),
                        const SizedBox(height: 8),
                      ],
                      // Price Row
                      _buildPrice(isDark),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(bool isDark) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
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
        // Top Left Badges
        Positioned(
          top: 8,
          left: 8,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Custom Badge
              if (course.effectiveBadge != null &&
                  course.effectiveBadge!.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  margin: const EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF512F), Color(0xFFDD2476)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    course.effectiveBadge!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              // Premium Badge
              if (isBestSeller)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  margin: const EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(
                    color: AppColors.rating,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.workspace_premium_rounded,
                          size: 12, color: Colors.white),
                      const SizedBox(width: 2),
                      Text(
                        locale == 'ar' ? 'مميز' : 'Premium',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              // Discount Badge
              if (course.discountPercentage != null &&
                  course.discountPercentage! > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '-${course.discountPercentage!.toInt()}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
              // Free Badge
              if (course.isFree)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'course.free'.tr(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ),
        ),
        // Top Right - Wishlist & Certificate
        Positioned(
          top: 8,
          right: 8,
          child: Column(
            children: [
              // Wishlist Button
              GlassIconButton(
                icon: isInWishlist
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                onTap: () {
                  HapticFeedback.lightImpact();
                  onWishlistTap?.call();
                },
                size: 36,
                iconSize: 18,
                borderRadius: 18,
              ),
              // Certificate Badge
              if (hasCertificate) ...[
                const SizedBox(height: 4),
                GlassIconButton(
                  icon: Icons.workspace_premium_rounded,
                  onTap: () {},
                  size: 36,
                  iconSize: 18,
                  borderRadius: 18,
                ),
              ],
            ],
          ),
        ),
        // Add to Cart Button
        if (showAddToCart && !course.isFree)
          Positioned(
            bottom: 8,
            right: 8,
            child: GlassIconButton(
              icon: Icons.add_shopping_cart_rounded,
              onTap: () {
                HapticFeedback.mediumImpact();
                onAddToCart?.call();
              },
              size: 40,
              iconSize: 18,
              borderRadius: 20,
            ),
          ),
      ],
    );
  }

  Widget _buildCourseInfoRow(bool isDark) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        // Duration
        _buildInfoChip(
          Icons.access_time_rounded,
          course.formattedDuration,
          isDark,
        ),
        // Lessons
        _buildInfoChip(
          Icons.play_lesson_rounded,
          '${course.totalLessons} ${'course.lessons'.tr()}',
          isDark,
        ),
        // Level
        _buildLevelBadge(isDark),
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String text, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 12,
          color: isDark ? AppColors.grey400 : AppColors.grey500,
        ),
        const SizedBox(width: 3),
        Text(
          text,
          style: TextStyle(
            fontSize: 10,
            color: isDark ? AppColors.grey400 : AppColors.grey500,
          ),
        ),
      ],
    );
  }

  Widget _buildLevelBadge(bool isDark) {
    Color badgeColor;
    switch (course.level) {
      case CourseLevel.beginner:
        badgeColor = AppColors.success;
        break;
      case CourseLevel.intermediate:
        badgeColor = AppColors.warning;
        break;
      case CourseLevel.advanced:
        badgeColor = AppColors.error;
        break;
      case CourseLevel.allLevels:
        badgeColor = AppColors.info;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        course.level.getDisplayName(locale),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: badgeColor,
        ),
      ),
    );
  }

  Widget _buildStatsRow(bool isDark) {
    return Row(
      children: [
        // Students
        Icon(Icons.people_alt_outlined,
            size: 14, color: isDark ? AppColors.grey400 : AppColors.grey500),
        const SizedBox(width: 3),
        Text(
          _formatCount(course.enrolledCount),
          style: TextStyle(
            color: isDark ? AppColors.grey400 : AppColors.grey500,
            fontSize: 11,
          ),
        ),
        const Spacer(),
        // Rating
        Text(
          '(${_formatCount(course.ratingCount)})',
          style: TextStyle(
            color: isDark ? AppColors.grey400 : AppColors.grey500,
            fontSize: 11,
          ),
        ),
        const SizedBox(width: 4),
        const Icon(Icons.star_rounded, size: 14, color: AppColors.rating),
        const SizedBox(width: 2),
        Text(
          course.rating.toStringAsFixed(1),
          style: const TextStyle(
            color: AppColors.rating,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'course.your_progress'.tr(),
              style: TextStyle(
                fontSize: 10,
                color:
                    isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              ),
            ),
            Text(
              '${(userProgress! * 100).toInt()}%',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: userProgress!,
            backgroundColor: isDark ? AppColors.grey700 : AppColors.grey200,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildPrice(bool isDark) {
    if (course.isFree) {
      return Text(
        'course.free'.tr(),
        style: const TextStyle(
          color: AppColors.success,
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
      );
    }

    final hasDiscount = course.discountPrice != null ||
        (course.discountPercentage != null && course.discountPercentage! > 0);
    final currentPrice = course.currentPrice;
    final originalPrice = course.price;
    final currency = course.currency;

    return Directionality(
      textDirection: ui.TextDirection.ltr,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              '$currency ${currentPrice.toStringAsFixed(0)}',
              style: TextStyle(
                color: isDark ? AppColors.white : AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (hasDiscount && originalPrice > currentPrice) ...[
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                originalPrice.toStringAsFixed(0),
                style: TextStyle(
                  color: isDark ? AppColors.grey500 : AppColors.grey400,
                  decoration: TextDecoration.lineThrough,
                  fontSize: 11,
                ),
                overflow: TextOverflow.ellipsis,
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
