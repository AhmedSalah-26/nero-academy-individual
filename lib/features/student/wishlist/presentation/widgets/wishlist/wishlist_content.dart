import 'package:flutter/material.dart';
import 'package:lms_platform/core/animations/widgets/feedback/error_shake.dart';
import 'package:lms_platform/features/student/wishlist/domain/entities/wishlist_item_entity.dart';
import 'wishlist_item_card.dart';

/// Wishlist Content - Main content area with list
class WishlistContent extends StatelessWidget {
  final List<WishlistItemEntity> items;
  final void Function(String) onRemoveItem;
  final void Function(String) onAddToCart;
  final void Function(String)? onTap;
  final String? removingItemId;
  final String? addingToCartCourseId;
  final Set<String> cartCourseIds;
  final bool showErrorShake;
  final String? errorCourseId;
  final String locale;
  final bool isDark;

  const WishlistContent({
    super.key,
    required this.items,
    required this.onRemoveItem,
    required this.onAddToCart,
    this.onTap,
    this.removingItemId,
    this.addingToCartCourseId,
    this.cartCourseIds = const {},
    this.showErrorShake = false,
    this.errorCourseId,
    required this.locale,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final shouldShake = showErrorShake && errorCourseId == item.courseId;

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: ErrorShake(
            trigger: shouldShake,
            child: WishlistItemCard(
              item: item,
              onRemove: () => onRemoveItem(item.id),
              onAddToCart: () => onAddToCart(item.courseId),
              onTap: onTap != null ? () => onTap!(item.courseId) : null,
              isRemoving: removingItemId == item.id,
              isAddingToCart: addingToCartCourseId == item.courseId,
              isInCart: cartCourseIds.contains(item.courseId),
              locale: locale,
            ),
          ),
        );
      },
    );
  }
}
