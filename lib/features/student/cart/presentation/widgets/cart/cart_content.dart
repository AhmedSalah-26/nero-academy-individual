import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lms_platform/core/animations/widgets/feedback/error_shake.dart';
import 'package:lms_platform/features/student/cart/presentation/cubit/cart_state.dart';
import 'cart_app_bar.dart';
import 'cart_item_card.dart';
import 'cart_summary_card.dart';
import 'coupon_section.dart';

/// Cart Content Widget - Main content when cart has items
class CartContent extends StatefulWidget {
  final CartState state;
  final String locale;
  final bool isDark;
  final VoidCallback onBack;
  final VoidCallback onClear;
  final VoidCallback onCheckout;
  final ValueChanged<String> onRemoveItem;
  final ValueChanged<String> onApplyCoupon;
  final VoidCallback onRemoveCoupon;

  const CartContent({
    super.key,
    required this.state,
    required this.locale,
    required this.isDark,
    required this.onBack,
    required this.onClear,
    required this.onCheckout,
    required this.onRemoveItem,
    required this.onApplyCoupon,
    required this.onRemoveCoupon,
  });

  @override
  State<CartContent> createState() => _CartContentState();
}

class _CartContentState extends State<CartContent> {
  String? _errorItemId;

  @override
  void didUpdateWidget(CartContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Trigger error shake if removal failed
    if (oldWidget.state.isRemovingItem && !widget.state.isRemovingItem) {
      if (widget.state.removeItemError != null) {
        setState(() {
          _errorItemId = oldWidget.state.removingItemId;
        });
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            setState(() {
              _errorItemId = null;
            });
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // App Bar
        CartAppBar(
          itemsCount: widget.state.itemsCount,
          onBack: widget.onBack,
          onClear: widget.onClear,
          isDark: widget.isDark,
        ),
        // Cart Items Header
        _buildItemsHeader(),
        // Cart Items
        _buildCartItems(),
        // Coupon Section
        _buildCouponSection(),
        // Summary Card
        _buildSummaryCard(),
        // Bottom spacing
        SliverToBoxAdapter(
          child: SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
        ),
      ],
    );
  }

  Widget _buildItemsHeader() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${widget.state.itemsCount} ${widget.state.itemsCount == 1 ? 'course.course'.tr() : 'cart.courses'.tr()}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartItems() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final item = widget.state.cart!.items[index];
            final shouldShake = _errorItemId == item.id;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: ErrorShake(
                trigger: shouldShake,
                child: CartItemCard(
                  item: item,
                  onRemove: () => widget.onRemoveItem(item.id),
                  isRemoving: widget.state.isRemovingItem &&
                      widget.state.removingItemId == item.id,
                  locale: widget.locale,
                ),
              ),
            );
          },
          childCount: widget.state.cart!.items.length,
        ),
      ),
    );
  }

  Widget _buildCouponSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: CouponSection(
          appliedCoupon: widget.state.appliedCoupon,
          isLoading: widget.state.isApplyingCoupon,
          error: widget.state.couponError,
          onApply: widget.onApplyCoupon,
          onRemove: widget.onRemoveCoupon,
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: CartSummaryCard(
          subtotal: widget.state.subtotal,
          discountAmount: widget.state.discountAmount,
          total: widget.state.total,
          currency: widget.state.cart?.currency ?? 'EGP',
          itemsCount: widget.state.itemsCount,
          onCheckout: widget.onCheckout,
        ),
      ),
    );
  }
}
