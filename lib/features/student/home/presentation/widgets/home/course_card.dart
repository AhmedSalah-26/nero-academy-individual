import 'dart:ui' as ui;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lms_platform/core/shared_widgets/glass_icon_button.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/features/student/home/domain/entities/course_entity.dart';

class CourseCard extends StatelessWidget {
  final CourseEntity course;
  final String locale;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;
  final VoidCallback? onWishlistTap;
  final double? width;
  final bool showAddToCart;
  final bool isInWishlist;

  const CourseCard({
    super.key,
    required this.course,
    required this.locale,
    this.onTap,
    this.onAddToCart,
    this.onWishlistTap,
    this.width,
    this.showAddToCart = false,
    this.isInWishlist = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = width ?? screenWidth * 0.44;
    final borderWidth = isDark ? 1.5 : 1.0;
    const radius = 8.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: cardWidth,
        height: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.white,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: isDark
                ? AppColors.primary.withValues(alpha: 0.7)
                : AppColors.primary.withValues(alpha: 0.25),
            width: borderWidth,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(borderWidth),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius - borderWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildThumbnail(isDark),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 7, 8, 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Top Section
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Title
                              Flexible(
                                child: Text(
                                  course.getTitle(locale),
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    color: isDark
                                        ? AppColors.textMainDark
                                        : AppColors.textMainLight,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11.5,
                                    height: 1.22,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(height: 4),
                              // Instructor
                              Text(
                                course.instructorName ?? '',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  color: isDark
                                      ? AppColors.textMutedDark
                                      : AppColors.textMutedLight,
                                  fontSize: 9.8,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        // Bottom Section
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Stats Row
                            _buildStatsRow(isDark),
                            const SizedBox(height: 6),
                            // Price Row
                            _buildPrice(isDark),
                          ],
                        ),
                      ],
                    ),
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
                    errorWidget: (_, __, ___) =>
                        _buildThumbnailFallback(isDark),
                  )
                : _buildThumbnailFallback(isDark),
          ),
        ),
        // Custom Badge, Free Badge, or Discount Badge (Priority Order)
        if (course.effectiveBadge != null && course.effectiveBadge!.isNotEmpty)
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFFF512F),
                    Color(0xFFDD2476)
                  ], // Red-Pink Gradient
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
                  fontSize: 9,
                ),
              ),
            ),
          )
        else if (course.isFree)
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.success,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'course.free'.tr(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 9,
                ),
              ),
            ),
          )
        else if (course.discountPercentage != null &&
            course.discountPercentage! > 0)
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${course.discountPercentage!.toInt()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 9,
                ),
              ),
            ),
          ),
        // Wishlist Button - Accessible touch target (44px minimum)
        Positioned(
          top: 4,
          right: 4,
          child: GlassIconButton(
            icon: isInWishlist
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            onTap: onWishlistTap,
            size: 34,
            iconSize: 17,
            borderRadius: 17,
          ),
        ),
        // Add to Cart Button (overlay) - Accessible touch target
        if (showAddToCart && !course.isFree)
          Positioned(
            bottom: 4,
            right: 4,
            child: GlassIconButton(
              icon: Icons.add_shopping_cart_rounded,
              onTap: onAddToCart,
              size: 34,
              iconSize: 17,
              borderRadius: 17,
            ),
          ),
      ],
    );
  }

  Widget _buildThumbnailFallback(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.grey200,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.grey400.withValues(alpha: isDark ? 0.18 : 0.12),
              border: Border.all(
                color:
                    AppColors.grey400.withValues(alpha: isDark ? 0.34 : 0.28),
                width: 1.5,
              ),
            ),
            child: Icon(
              Icons.play_arrow_rounded,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.82)
                  : AppColors.grey600.withValues(alpha: 0.82),
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(bool isDark) {
    return Row(
      children: [
        // Rating
        Text(
          '(${_formatCount(course.ratingCount)})',
          style: TextStyle(
            color: isDark ? AppColors.grey400 : AppColors.grey500,
            fontSize: 10,
          ),
        ),
        const SizedBox(width: 4),
        const Icon(Icons.star_rounded, size: 12, color: AppColors.rating),
        const SizedBox(width: 2),
        Text(
          course.rating.toStringAsFixed(1),
          style: const TextStyle(
            color: AppColors.rating,
            fontWeight: FontWeight.w700,
            fontSize: 10.5,
          ),
        ),
        const Spacer(),
        Text(
          _formatCount(course.enrolledCount),
          style: TextStyle(
            color: isDark ? AppColors.grey400 : AppColors.grey500,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 3),
        Icon(Icons.people_alt_outlined,
            size: 12, color: isDark ? AppColors.grey400 : AppColors.grey500),
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
          fontSize: 14,
        ),
      );
    }

    final hasDiscount = course.discountPrice != null ||
        (course.discountPercentage != null && course.discountPercentage! > 0);
    final currentPrice = course.currentPrice;
    final originalPrice = course.price;
    final currency = course.currency;

    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: Directionality(
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
                  fontSize: 13.5,
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
                    fontSize: 10,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
    return count.toString();
  }
}
