import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lms_platform/core/animations/animations.dart';
import 'package:lms_platform/core/routing/app_router.dart';
import 'package:lms_platform/core/shared_widgets/responsive_dialog.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/core/services/app_logger.dart';
import 'package:lms_platform/features/student/cart/presentation/cubit/cart_cubit.dart';
import 'package:lms_platform/features/student/cart/presentation/cubit/cart_state.dart';
import 'package:lms_platform/features/student/cart/presentation/widgets/cart/cart_content.dart';
import 'package:lms_platform/features/student/cart/presentation/widgets/cart/cart_empty_state.dart';
import 'package:lms_platform/features/student/cart/presentation/widgets/cart/cart_error_state.dart';
import 'package:lms_platform/features/student/cart/presentation/widgets/cart/cart_loading_state.dart';

/// Cart Screen - Professional Design
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    AppLogger.i('🛒 [CartScreen] Loading cart for user: $userId');

    if (userId != null) {
      final cartCubit = context.read<CartCubit>();
      await cartCubit.loadCart(userId);
    }
  }

  Future<void> _onRefresh() async {
    HapticFeedback.mediumImpact();
    await _loadCart();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: BlocBuilder<CartCubit, CartState>(
        builder: (context, state) {
          if (state.isLoading) {
            return _wrapStaticRefresh(CartLoadingState(isDark: isDark), isDark);
          }

          if (state.isError) {
            return _wrapStaticRefresh(
              FadeIn(
                duration: const Duration(milliseconds: 400),
                child: CartErrorState(
                  message: state.errorMessage ?? '',
                  onRetry: _loadCart,
                  isDark: isDark,
                ),
              ),
              isDark,
            );
          }

          if (state.isEmpty) {
            return _wrapStaticRefresh(
              FadeIn(
                duration: const Duration(milliseconds: 400),
                child: CartEmptyState(
                  onBack: () => Navigator.of(context).pop(),
                  onBrowseCourses: _browseCourses,
                  isDark: isDark,
                ),
              ),
              isDark,
            );
          }

          return RefreshIndicator(
            onRefresh: _onRefresh,
            color: AppColors.primary,
            backgroundColor: isDark ? AppColors.cardDark : AppColors.white,
            child: SlideFadeIn.fromBottom(
              duration: const Duration(milliseconds: 500),
              child: CartContent(
                state: state,
                locale: context.locale.languageCode,
                isDark: isDark,
                onBack: () => Navigator.of(context).pop(),
                onClear: () => _showClearCartDialog(isDark),
                onCheckout: _goToCheckout,
                onRemoveItem: _removeItem,
                onApplyCoupon: _applyCoupon,
                onRemoveCoupon: _removeCoupon,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _wrapStaticRefresh(Widget child, bool isDark) {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: AppColors.primary,
      backgroundColor: isDark ? AppColors.cardDark : AppColors.white,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height,
          child: child,
        ),
      ),
    );
  }

  void _showClearCartDialog(bool isDark) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (dialogContext) => ResponsiveAlertDialog(
        title: 'common.confirm'.tr(),
        content: 'cart.clear_cart_confirm'.tr(),
        confirmText: 'common.delete'.tr(),
        cancelText: 'common.cancel'.tr(),
        isDestructive: true,
        onConfirm: () {
          Navigator.pop(dialogContext);
          _clearCart();
        },
      ),
    );
  }

  void _clearCart() {
    HapticFeedback.mediumImpact();
    context.read<CartCubit>().clearCart();
  }

  void _removeItem(String itemId) {
    HapticFeedback.lightImpact();
    context.read<CartCubit>().removeFromCart(itemId);
  }

  void _applyCoupon(String code) {
    context.read<CartCubit>().applyCoupon(code);
  }

  void _removeCoupon() {
    context.read<CartCubit>().removeCoupon();
  }

  void _goToCheckout() {
    HapticFeedback.mediumImpact();
    final cart = context.read<CartCubit>().state.cart;
    if (cart != null) {
      // Navigate directly to checkout
      AppRouter.goToCheckout(context, cart);
    }
  }

  void _browseCourses() {
    AppRouter.goToHome(context);
  }
}
