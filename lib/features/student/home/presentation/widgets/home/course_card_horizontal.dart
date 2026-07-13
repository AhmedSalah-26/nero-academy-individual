import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lms_platform/core/shared_widgets/glass_icon_button.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/core/theme/app_text_styles.dart';
import 'package:lms_platform/features/student/home/domain/entities/course_entity.dart';

/// Course Card Horizontal Widget - Responsive for vertical list
class CourseCardHorizontal extends StatelessWidget {
  final CourseEntity course;
  final String locale;
  final VoidCallback? onTap;
  final VoidCallback? onWishlistTap;
  final bool isInWishlist;

  const CourseCardHorizontal({
    super.key,
    required this.course,
    required this.locale,
    this.onTap,
    this.onWishlistTap,
    this.isInWishlist = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final cardHeight = (screenWidth * 0.26).clamp(95.0, 120.0);
    final borderWidth = isDark ? 1.5 : 1.0;
    final imageSize = cardHeight - (borderWidth * 2);
    final accent = theme.colorScheme.tertiary;
    final borderColor = Color.alphaBlend(
      accent.withValues(alpha: isDark ? 0.34 : 0.16),
      theme.cardColor,
    );
    const radius = 14.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: cardHeight,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: borderColor, width: borderWidth),
        ),
        child: Padding(
          padding: EdgeInsets.all(borderWidth),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius - borderWidth),
            child: Row(
              children: [
                _buildThumbnail(context, isDark, imageSize),
                Expanded(child: _buildContent(context, isDark, screenWidth)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(BuildContext context, bool isDark, double size) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.tertiary;
    final placeholderColor = Color.alphaBlend(
      accent.withValues(alpha: isDark ? 0.08 : 0.025),
      theme.cardColor,
    );

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: size,
            height: size,
            child: (course.thumbnailUrl ?? '').isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: course.thumbnailUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: placeholderColor),
                    errorWidget: (_, __, ___) => Container(
                      color: placeholderColor,
                      child: Icon(Icons.play_circle_outline,
                          size: 28, color: accent),
                    ),
                  )
                : Container(
                    color: placeholderColor,
                    child: Icon(Icons.play_circle_outline,
                        size: 28, color: accent),
                  ),
          ),
        ),
        if (course.isFlashSaleActive && course.discountPercentage != null)
          Positioned(
            top: 6,
            left: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(4)),
              child: Text('${course.discountPercentage}%',
                  style: AppTextStyles.badge
                      .copyWith(color: AppColors.white, fontSize: 8)),
            ),
          ),
        // Wishlist Button
        Positioned(
          top: 6,
          right: 6,
          child: GlassIconButton(
            icon: isInWishlist
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            onTap: onWishlistTap,
            size: 32,
            iconSize: 16,
            borderRadius: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context, bool isDark, double screenWidth) {
    return Padding(
      padding: EdgeInsets.all(screenWidth * 0.028),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title with New badge
          Flexible(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    course.getTitle(locale),
                    style: AppTextStyles.titleSmall.copyWith(
                      color: isDark
                          ? AppColors.textMainDark
                          : AppColors.textMainLight,
                      fontSize: 12,
                      height: 1.25,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_isNew())
                  Container(
                    margin: const EdgeInsets.only(left: 6),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.success
                          .withValues(alpha: isDark ? 0.2 : 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('course.new'.tr(),
                        style: AppTextStyles.badge
                            .copyWith(color: AppColors.success, fontSize: 8)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 3),
          // Instructor
          Row(
            children: [
              Icon(Icons.person_outline_rounded,
                  size: 10,
                  color: isDark
                      ? AppColors.textMutedDark
                      : AppColors.textMutedLight),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                  course.instructorName ?? '',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.textMutedDark
                        : AppColors.textMutedLight,
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Rating & Price
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildRating(),
              Flexible(child: _buildPrice(context, isDark)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRating() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.rating.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 10, color: AppColors.rating),
          const SizedBox(width: 2),
          Text(course.rating.toStringAsFixed(1),
              style: AppTextStyles.rating.copyWith(fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildPrice(BuildContext context, bool isDark) {
    final accent = Theme.of(context).colorScheme.tertiary;

    if (course.isFree) {
      return Text('course.free'.tr(),
          style: AppTextStyles.price
              .copyWith(fontSize: 13, color: AppColors.success));
    }

    final hasDiscount =
        course.discountPrice != null || course.isFlashSaleActive;
    final currentPrice = course.currentPrice;
    final originalPrice = course.price;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasDiscount && originalPrice > currentPrice) ...[
          Text(originalPrice.toStringAsFixed(0),
              style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.grey400,
                  decoration: TextDecoration.lineThrough,
                  fontSize: 10)),
          const SizedBox(width: 4),
        ],
        Flexible(
          child: Text('EGP ${currentPrice.toStringAsFixed(0)}',
              style: AppTextStyles.price.copyWith(
                fontSize: 13,
                color: isDark ? AppColors.white : accent,
              ),
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  bool _isNew() {
    if (course.publishedAt == null) return false;
    return DateTime.now().difference(course.publishedAt!).inDays < 7;
  }
}
