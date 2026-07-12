import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lms_platform/core/shared_widgets/glass_icon_button.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/features/student/wishlist/domain/entities/wishlist_item_entity.dart';

/// Wishlist Item Card - Course card in wishlist
class WishlistItemCard extends StatelessWidget {
  final WishlistItemEntity item;
  final VoidCallback onRemove;
  final VoidCallback onAddToCart;
  final VoidCallback? onTap;
  final bool isRemoving;
  final bool isAddingToCart;
  final bool isInCart;
  final String locale;

  const WishlistItemCard({
    super.key,
    required this.item,
    required this.onRemove,
    required this.onAddToCart,
    this.onTap,
    this.isRemoving = false,
    this.isAddingToCart = false,
    this.isInCart = false,
    required this.locale,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const radius = 16.0;

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.cardDark.withValues(alpha: 0.78)
                  : Colors.white.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.14)
                    : AppColors.primary.withValues(alpha: 0.18),
                width: 1.4,
              ),
              boxShadow: [
                BoxShadow(
                  color:
                      AppColors.primary.withValues(alpha: isDark ? 0.18 : 0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 5),
                ),
                BoxShadow(
                  color:
                      AppColors.primary.withValues(alpha: isDark ? 0.08 : 0.06),
                  blurRadius: 26,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              children: [
                _buildMainContent(isDark),
                _buildFooter(isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildThumbnail(isDark),
          const SizedBox(width: 14),
          Expanded(child: _buildContent(isDark)),
          _buildFavoriteButton(isDark),
        ],
      ),
    );
  }

  Widget _buildThumbnail(bool isDark) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isDark ? AppColors.surfaceDark : AppColors.grey100,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: item.thumbnailUrl != null
            ? Image.network(
                item.thumbnailUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildPlaceholder(isDark),
              )
            : _buildPlaceholder(isDark),
      ),
    );
  }

  Widget _buildPlaceholder(bool isDark) {
    return Container(
      color: isDark ? AppColors.surfaceDark : AppColors.grey100,
      child: Center(
        child: Icon(
          Icons.play_circle_outline_rounded,
          size: 36,
          color: isDark ? AppColors.grey500 : AppColors.grey400,
        ),
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.getTitle(locale),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
            height: 1.3,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        if (item.instructorName != null)
          Text(
            item.instructorName!,
            style: TextStyle(
              fontSize: 12,
              color:
                  isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        const SizedBox(height: 6),
        _buildRating(isDark),
        const SizedBox(height: 8),
        _buildPrice(isDark),
      ],
    );
  }

  Widget _buildRating(bool isDark) {
    return Row(
      children: [
        const Icon(Icons.star_rounded, size: 16, color: AppColors.rating),
        const SizedBox(width: 4),
        Text(
          item.rating.toStringAsFixed(1),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.rating,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '(${_formatCount(item.ratingCount)})',
          style: TextStyle(
            fontSize: 11,
            color: isDark ? AppColors.grey500 : AppColors.grey400,
          ),
        ),
      ],
    );
  }

  Widget _buildPrice(bool isDark) {
    if (item.isEnrolled) {
      return Text(
        'wishlist.purchased'.tr(),
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.success,
        ),
      );
    }

    final hasDiscount = item.discountPercentage != null && !item.isFree;

    return Row(
      children: [
        Text(
          item.isFree
              ? 'wishlist.free'.tr()
              : '${item.currency} ${item.currentPrice.toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.textMainDark : AppColors.primary,
          ),
        ),
        if (hasDiscount) ...[
          const SizedBox(width: 8),
          Text(
            '${item.currency} ${item.price.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 11,
              color: isDark ? AppColors.grey500 : AppColors.grey400,
              decoration: TextDecoration.lineThrough,
            ),
          ),
        ],
        const Spacer(),
        if (hasDiscount)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${item.discountPercentage!}% ${'wishlist.off'.tr()}',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppColors.success,
              ),
            ),
          )
        else if (item.isBestseller)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.rating.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.workspace_premium_rounded,
                  size: 10,
                  color: AppColors.rating,
                ),
                const SizedBox(width: 2),
                Text(
                  locale == 'ar' ? 'مميز' : 'Premium',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.rating,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildFavoriteButton(bool isDark) {
    if (isRemoving) {
      return const SizedBox(
        width: 36,
        height: 36,
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
        ),
      );
    }

    return GlassIconButton(
      icon: Icons.favorite_rounded,
      onTap: onRemove,
      size: 36,
      iconSize: 20,
      borderRadius: 18,
    );
  }

  Widget _buildFooter(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.white.withValues(alpha: 0.28),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : AppColors.primary.withValues(alpha: 0.12),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.schedule_rounded,
                size: 14,
                color: isDark ? AppColors.grey500 : AppColors.grey400,
              ),
              const SizedBox(width: 4),
              Text(
                _formatAddedTime(),
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.grey500 : AppColors.grey400,
                ),
              ),
            ],
          ),
          _buildActionButton(isDark),
        ],
      ),
    );
  }

  Widget _buildActionButton(bool isDark) {
    // Show "View Content" for enrolled courses
    if (item.isEnrolled) {
      return TextButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.play_circle_outline_rounded, size: 18),
        style: TextButton.styleFrom(
          backgroundColor: AppColors.success.withValues(alpha: 0.15),
          foregroundColor: AppColors.success,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        label: Text(
          'wishlist.go_to_learning'.tr(),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      );
    }

    // Show "In Cart" if already added to cart
    if (isInCart) {
      return TextButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
        style: TextButton.styleFrom(
          backgroundColor: AppColors.grey200.withValues(alpha: 0.5),
          foregroundColor: AppColors.grey600,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        label: Text(
          'wishlist.in_cart'.tr(),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      );
    }

    // Show "Add to Cart" for non-enrolled courses
    return TextButton(
      onPressed: isAddingToCart ? null : onAddToCart,
      style: TextButton.styleFrom(
        backgroundColor: isDark
            ? AppColors.primary
            : AppColors.primary.withValues(alpha: 0.1),
        foregroundColor: isDark ? Colors.white : AppColors.primary,
        disabledBackgroundColor: isDark
            ? AppColors.primary.withValues(alpha: 0.5)
            : AppColors.primary.withValues(alpha: 0.05),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: isAddingToCart
          ? SizedBox(
              width: 100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: isDark ? Colors.white : AppColors.primary,
                    ),
                  ),
                ],
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.shopping_cart_outlined, size: 18),
                const SizedBox(width: 6),
                Text(
                  'wishlist.add_to_cart'.tr(),
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            ),
    );
  }

  String _formatAddedTime() {
    final now = DateTime.now();
    final diff = now.difference(item.addedAt);

    if (diff.inDays > 30) {
      return 'wishlist.added_months_ago'.tr(args: ['${diff.inDays ~/ 30}']);
    } else if (diff.inDays > 7) {
      return 'wishlist.added_weeks_ago'.tr(args: ['${diff.inDays ~/ 7}']);
    } else if (diff.inDays > 0) {
      return 'wishlist.added_days_ago'.tr(args: ['${diff.inDays}']);
    } else if (diff.inHours > 0) {
      return 'wishlist.added_hours_ago'.tr(args: ['${diff.inHours}']);
    } else {
      return 'wishlist.added_just_now'.tr();
    }
  }

  String _formatCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return count.toString();
  }
}
