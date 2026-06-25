import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../../core/routing/app_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../domain/entities/cart_item_entity.dart';

/// Cart Item Card - Professional Design
class CartItemCard extends StatelessWidget {
  final CartItemEntity item;
  final VoidCallback onRemove;
  final bool isRemoving;
  final String locale;

  const CartItemCard({
    super.key,
    required this.item,
    required this.onRemove,
    this.isRemoving = false,
    required this.locale,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => _navigateToCourseDetails(context),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: isDark ? 0.1 : 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Thumbnail
              _buildThumbnail(isDark),
              const SizedBox(width: 10),
              // Content
              Expanded(child: _buildContent(isDark)),
              // Price & Remove
              _buildPriceAndRemove(isDark),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToCourseDetails(BuildContext context) {
    AppRouter.goToCourseDetails(context, item.courseId);
  }

  Widget _buildPriceAndRemove(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Price
        Text(
          item.isFree
              ? 'cart.free'.tr()
              : '${item.currency} ${item.currentPrice.toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.white : AppColors.primary,
          ),
        ),
        if (item.discountPercentage != null && !item.isFree) ...[
          const SizedBox(height: 2),
          Text(
            '${item.currency} ${item.price.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 11,
              color: isDark ? AppColors.grey500 : AppColors.grey400,
              decoration: TextDecoration.lineThrough,
            ),
          ),
        ],
        const SizedBox(height: 6),
        // Remove button
        _buildRemoveButton(isDark),
      ],
    );
  }

  Widget _buildThumbnail(bool isDark) {
    return Hero(
      tag: 'cart_item_${item.id}',
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: isDark ? AppColors.surfaceDark : AppColors.grey100,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: item.thumbnailUrl != null
              ? Image.network(
                  item.thumbnailUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildPlaceholder(isDark),
                )
              : _buildPlaceholder(isDark),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(bool isDark) {
    return Container(
      color: isDark ? AppColors.surfaceDark : AppColors.grey100,
      child: Center(
        child: Icon(
          Icons.play_circle_outline_rounded,
          size: 24,
          color: isDark ? AppColors.grey500 : AppColors.grey400,
        ),
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Title
        Text(
          item.getTitle(locale),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
            height: 1.2,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (item.pricingOption != null) ...[
          const SizedBox(height: 4),
          Text(
            item.pricingOption!.durationDays == null
                ? item.pricingOption!.label
                : '${item.pricingOption!.label} - ${item.pricingOption!.durationDays} ${locale == 'ar' ? 'يوم' : 'days'}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        const SizedBox(height: 4),
        // Instructor & Rating in one row
        Row(
          children: [
            if (item.instructorName != null) ...[
              Flexible(
                child: Text(
                  item.instructorName!,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.textMutedDark
                        : AppColors.textMutedLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
            ],
            const Icon(Icons.star_rounded, size: 12, color: AppColors.rating),
            const SizedBox(width: 2),
            Text(
              item.rating.toStringAsFixed(1),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.rating,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRemoveButton(bool isDark) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isRemoving ? null : onRemove,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: isRemoving
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.error,
                  ),
                )
              : const Icon(
                  Icons.delete_outline_rounded,
                  size: 16,
                  color: AppColors.error,
                ),
        ),
      ),
    );
  }
}
