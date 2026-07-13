import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lms_platform/core/routing/app_router.dart';
import 'package:lms_platform/core/shared_widgets/responsive_dialog.dart';
import 'package:lms_platform/core/services/app_logger.dart';
import 'package:lms_platform/core/utils/toast_utils.dart';
import 'package:lms_platform/features/student/cart/presentation/cubit/cart_cubit.dart';
import 'package:lms_platform/features/student/cart/presentation/cubit/cart_state.dart';
import 'package:lms_platform/features/student/wishlist/presentation/cubit/wishlist_cubit.dart';
import 'package:lms_platform/features/student/wishlist/presentation/cubit/wishlist_state.dart';
import 'package:lms_platform/features/student/wishlist/presentation/widgets/wishlist/wishlist_app_bar.dart';
import 'package:lms_platform/features/student/wishlist/presentation/widgets/wishlist/wishlist_content.dart';
import 'package:lms_platform/features/student/wishlist/presentation/widgets/wishlist/wishlist_empty_state.dart';
import 'package:lms_platform/features/student/wishlist/presentation/widgets/wishlist/wishlist_error_state.dart';
import 'package:lms_platform/features/student/wishlist/presentation/widgets/wishlist/wishlist_loading_state.dart';

/// Wishlist Screen - Main wishlist page
class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  String? _addingToCartCourseId;
  bool _showErrorShake = false;
  String? _errorCourseId;

  @override
  void initState() {
    super.initState();
    _loadWishlist();
  }

  Future<void> _loadWishlist({bool force = false}) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    AppLogger.i('❤️ [WishlistScreen] Loading wishlist for user: $userId');

    if (userId != null) {
      await context.read<WishlistCubit>().loadWishlist(userId, force: force);
    }
  }

  Future<void> _onRefresh() async {
    HapticFeedback.mediumImpact();
    await _loadWishlist(force: true);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: BlocBuilder<WishlistCubit, WishlistState>(
        builder: (context, state) {
          return Column(
            children: [
              WishlistAppBar(
                isDark: isDark,
                hasItems: state.items.isNotEmpty,
                onClear: state.items.isNotEmpty ? _showClearConfirmation : null,
              ),
              Expanded(child: _buildRefreshableContent(state, isDark)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildContent(WishlistState state, bool isDark) {
    if (state.isLoading) {
      return WishlistLoadingState(isDark: isDark);
    }

    if (state.isError) {
      return WishlistErrorState(
        message: state.errorMessage ?? 'common.error'.tr(),
        onRetry: _loadWishlist,
        isDark: isDark,
      );
    }

    if (state.items.isEmpty) {
      return WishlistEmptyState(
        onBrowseCourses: _browseCourses,
        isDark: isDark,
      );
    }

    return BlocBuilder<CartCubit, CartState>(
      builder: (context, cartState) {
        // Get cart course IDs
        final cartCourseIds =
            cartState.cart?.items.map((item) => item.courseId).toSet() ??
                <String>{};

        return WishlistContent(
          items: state.items,
          onRemoveItem: _removeItem,
          onAddToCart: _addToCart,
          onTap: _goToCourseDetails,
          removingItemId: state.removingItemId,
          addingToCartCourseId: _addingToCartCourseId,
          cartCourseIds: cartCourseIds,
          showErrorShake: _showErrorShake,
          errorCourseId: _errorCourseId,
          locale: context.locale.languageCode,
          isDark: isDark,
        );
      },
    );
  }

  Widget _buildRefreshableContent(WishlistState state, bool isDark) {
    final content = _buildContent(state, isDark);
    final isScrollableContent =
        !state.isLoading && !state.isError && !state.isEmpty;

    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: Theme.of(context).colorScheme.tertiary,
      backgroundColor: Theme.of(context).cardColor,
      child: isScrollableContent
          ? content
          : SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.75,
                child: content,
              ),
            ),
    );
  }

  void _removeItem(String itemId) {
    HapticFeedback.lightImpact();
    context.read<WishlistCubit>().removeFromWishlist(itemId);
  }

  void _addToCart(String courseId) async {
    HapticFeedback.mediumImpact();

    // Check if already in cart
    final cartCubit = context.read<CartCubit>();
    if (cartCubit.isInCart(courseId)) {
      ToastUtils.showInfo('wishlist.already_in_cart'.tr());
      return;
    }

    setState(() => _addingToCartCourseId = courseId);

    final success = await cartCubit.addToCart(courseId);

    if (mounted) {
      setState(() => _addingToCartCourseId = null);

      if (success) {
        ToastUtils.showSuccess('wishlist.added_to_cart'.tr());
      } else {
        // Show error shake animation
        setState(() {
          _showErrorShake = true;
          _errorCourseId = courseId;
        });

        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            setState(() {
              _showErrorShake = false;
              _errorCourseId = null;
            });
          }
        });

        // Show error message
        final error = cartCubit.state.addToCartError;
        if (error != null && error.contains('enrolled')) {
          ToastUtils.showError('wishlist.already_enrolled'.tr());
        } else {
          ToastUtils.showError('common.error'.tr());
        }
      }
    }
  }

  void _goToCourseDetails(String courseId) {
    AppRouter.goToCourseDetails(context, courseId);
  }

  void _browseCourses() {
    AppRouter.goToHome(context);
  }

  void _showClearConfirmation() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (dialogContext) => ResponsiveAlertDialog(
        title: 'common.confirm'.tr(),
        content: 'wishlist.clear_confirm'.tr(),
        confirmText: 'common.clear'.tr(),
        cancelText: 'common.cancel'.tr(),
        isDestructive: true,
        onConfirm: () {
          Navigator.pop(dialogContext);
          _clearWishlist();
        },
      ),
    );
  }

  void _clearWishlist() {
    HapticFeedback.mediumImpact();
    context.read<WishlistCubit>().clearWishlist();
  }
}
