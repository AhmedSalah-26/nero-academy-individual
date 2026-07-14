import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:lms_platform/core/animations/animations.dart';
import 'package:lms_platform/core/routing/app_router.dart';
import 'package:lms_platform/core/shared_widgets/back_button.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/features/student/cart/domain/entities/cart_entity.dart';
import 'package:lms_platform/features/student/cart/presentation/cubit/cart_cubit.dart';
import 'package:lms_platform/features/student/cart/presentation/cubit/checkout_cubit.dart';
import 'package:lms_platform/features/student/cart/presentation/cubit/checkout_state.dart';

/// Checkout Screen - manual order request flow.
class CheckoutScreen extends StatefulWidget {
  final CartEntity cart;

  const CheckoutScreen({
    super.key,
    required this.cart,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  @override
  void initState() {
    super.initState();
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      context.read<CheckoutCubit>().initCheckout(userId, widget.cart);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = theme.colorScheme.tertiary;
    final onAccent = theme.colorScheme.onTertiary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: BlocConsumer<CheckoutCubit, CheckoutState>(
        listener: (context, state) {
          if (!mounted) return;

          if (state.hasOrder) {
            context.read<CartCubit>().clearCart();
            if (state.isOrderSuccessful) {
              AppRouter.goToMyLearning(context);
            } else {
              AppRouter.goToPaymentSuccess(context, state.order!.id);
            }
          } else if (state.failure != null) {
            String errorMsg = state.errorMessage ?? 'errors.unknown'.tr();
            if (errorMsg.contains('pending purchase request') ||
                errorMsg.contains('pending manual request')) {
              errorMsg = 'errors.pending_purchase_request'.tr();
            }
            AnimatedSnackbar.showError(
              context: context,
              message: errorMsg,
            );
          }
        },
        builder: (context, state) {
          final cart = state.cart ?? widget.cart;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: theme.scaffoldBackgroundColor,
                surfaceTintColor: Colors.transparent,
                foregroundColor: theme.appBarTheme.foregroundColor,
                elevation: 0,
                leading: const AppBackButton(),
                title: Text(
                  context.locale.languageCode == 'ar'
                      ? 'تأكيد الطلب'
                      : 'Confirm Order',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.textMainDark
                        : AppColors.textMainLight,
                  ),
                ),
                centerTitle: true,
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList.list(
                  children: [
                    _OrderSummaryCard(cart: cart, isDark: isDark),
                    const SizedBox(height: 16),
                    _ManualPaymentInfo(isDark: isDark),
                    const SizedBox(height: 96),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: BlocBuilder<CheckoutCubit, CheckoutState>(
        builder: (context, state) {
          final cart = state.cart ?? widget.cart;
          return Container(
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              12 + MediaQuery.of(context).padding.bottom,
            ),
            decoration: BoxDecoration(
              color: theme.cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: state.isProcessing
                    ? null
                    : () {
                        HapticFeedback.mediumImpact();
                        context.read<CheckoutCubit>().processCheckout();
                      },
                icon: state.isProcessing
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: onAccent,
                        ),
                      )
                    : Icon(Icons.send_rounded, color: onAccent),
                label: Text(
                  context.locale.languageCode == 'ar'
                      ? 'تقديم الطلب - ${cart.currency} ${cart.total.toStringAsFixed(0)}'
                      : 'Submit request - ${cart.currency} ${cart.total.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: onAccent,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: onAccent,
                  disabledBackgroundColor: accent.withValues(alpha: 0.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _OrderSummaryCard extends StatelessWidget {
  const _OrderSummaryCard({required this.cart, required this.isDark});

  final CartEntity cart;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final locale = context.locale.languageCode;
    final theme = Theme.of(context);
    final accent = theme.colorScheme.tertiary;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  Icons.shopping_bag_rounded,
                  color: accent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'cart.order_summary'.tr(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? AppColors.textMainDark
                        : AppColors.textMainLight,
                  ),
                ),
              ),
              Text(
                '${cart.currency} ${cart.total.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...cart.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 16,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.getTitle(locale),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? AppColors.textMainDark
                            : AppColors.textMainLight,
                      ),
                    ),
                  ),
                  Text(
                    '${item.currency} ${item.currentPrice.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color:
                          isDark ? AppColors.grey300 : AppColors.textMutedLight,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ManualPaymentInfo extends StatelessWidget {
  const _ManualPaymentInfo({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final isArabic = context.locale.languageCode == 'ar';
    final theme = Theme.of(context);
    final accent = theme.colorScheme.tertiary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: isDark ? 0.12 : 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_rounded, color: accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArabic ? 'الدفع يدوي بعد تقديم الطلب' : 'Manual payment',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? AppColors.textMainDark
                        : AppColors.textMainLight,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isArabic
                      ? 'بعد تقديم الطلب سيظهر لك رقم العملية ورقم واتساب للتواصل مع الإدارة وإتمام الدفع. سيتم تفعيل الكورس بعد مراجعة الأدمن.'
                      : 'After submitting, you will get an operation ID and WhatsApp contact. Admin will activate the course after payment review.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: isDark
                        ? AppColors.textMutedDark
                        : AppColors.textMutedLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
