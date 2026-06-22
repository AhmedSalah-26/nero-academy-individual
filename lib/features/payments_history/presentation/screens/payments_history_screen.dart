import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/shared_widgets/error_state.dart';
import '../../../../core/shared_widgets/loading_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../cubit/payments_history_cubit.dart';
import '../widgets/payment_card.dart';
import '../widgets/payment_filter_chips.dart';

class PaymentsHistoryScreen extends StatelessWidget {
  const PaymentsHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<PaymentsHistoryCubit>()..loadPayments(_userId),
      child: const _PaymentsHistoryView(),
    );
  }
}

String? get _userId => Supabase.instance.client.auth.currentUser?.id;

class _PaymentsHistoryView extends StatelessWidget {
  const _PaymentsHistoryView();

  @override
  Widget build(BuildContext context) {
    final isRtl = context.locale.languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.backgroundDark : AppColors.backgroundLight;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        foregroundColor: isDark ? AppColors.white : AppColors.textMainLight,
        leading: IconButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).maybePop();
          },
          icon: Icon(
            isRtl ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded,
          ),
        ),
        title: Text(
          isRtl ? 'حالة الطلبات' : 'Orders Status',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<PaymentsHistoryCubit, PaymentsHistoryState>(
        builder: (context, state) {
          if (state is PaymentsHistoryLoading) {
            return AppLoadingState(
              message:
                  isRtl ? 'جاري تحميل طلباتك...' : 'Loading your orders...',
            );
          }

          if (state is PaymentsHistoryError) {
            return _OrdersErrorState(state: state);
          }

          if (state is PaymentsHistoryLoaded) {
            final payments = state.filteredPayments;

            if (payments.isEmpty) {
              return const _OrdersEmptyState();
            }

            return Column(
              children: [
                const PaymentFilterChips(),
                const SizedBox(height: 8),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      HapticFeedback.mediumImpact();
                      await context.read<PaymentsHistoryCubit>().loadPayments(
                            _userId,
                          );
                    },
                    color: AppColors.primary,
                    backgroundColor:
                        isDark ? AppColors.cardDark : AppColors.white,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: payments.length,
                      itemBuilder: (context, index) {
                        return PaymentCard(payment: payments[index]);
                      },
                    ),
                  ),
                ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _OrdersErrorState extends StatelessWidget {
  const _OrdersErrorState({required this.state});

  final PaymentsHistoryError state;

  @override
  Widget build(BuildContext context) {
    final isRtl = context.locale.languageCode == 'ar';
    final isUnauthorized = state.type == PaymentsHistoryErrorType.unauthorized;

    return ErrorState(
      type: isUnauthorized ? ErrorType.unauthorized : ErrorType.server,
      title: isUnauthorized
          ? (isRtl ? 'سجّل الدخول أولاً' : 'Sign in first')
          : (isRtl ? 'تعذر تحميل الطلبات' : 'Could not load orders'),
      message: isUnauthorized
          ? (isRtl
              ? 'تحتاج إلى تسجيل الدخول لعرض حالة طلباتك.'
              : 'You need to sign in to view your order status.')
          : (isRtl
              ? 'حدثت مشكلة أثناء تحميل حالة طلباتك. حاول مرة أخرى.'
              : 'Something went wrong while loading your orders. Please try again.'),
      retryText: isUnauthorized
          ? (isRtl ? 'تسجيل الدخول' : 'Sign in')
          : (isRtl ? 'إعادة المحاولة' : 'Retry'),
      onRetry: () {
        HapticFeedback.lightImpact();
        if (isUnauthorized) {
          AppRouter.goToLogin(context);
          return;
        }
        context.read<PaymentsHistoryCubit>().loadPayments(_userId);
      },
    );
  }
}

class _OrdersEmptyState extends StatelessWidget {
  const _OrdersEmptyState();

  @override
  Widget build(BuildContext context) {
    final isRtl = context.locale.languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          physics: const ClampingScrollPhysics(),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        (isDark ? AppColors.primaryOnDark : AppColors.primary)
                            .withValues(alpha: isDark ? 0.18 : 0.12),
                    border: Border.all(
                      color:
                          (isDark ? AppColors.primaryOnDark : AppColors.primary)
                              .withValues(alpha: isDark ? 0.32 : 0.18),
                    ),
                  ),
                  child: Icon(
                    Icons.receipt_long_rounded,
                    size: 44,
                    color: isDark ? AppColors.primaryOnDark : AppColors.primary,
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  isRtl ? 'لا توجد طلبات حتى الآن' : 'No orders yet',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? AppColors.textMainDark
                        : AppColors.textMainLight,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  isRtl
                      ? 'عند إتمام عملية شراء أو طلب كورس ستظهر التفاصيل هنا.'
                      : 'When you complete a course purchase or request, the details will appear here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.5,
                    color: isDark
                        ? AppColors.textMutedDark
                        : AppColors.textMutedLight,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
