import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../cubit/payments_history_cubit.dart';
import '../widgets/payment_card.dart';
import '../widgets/payment_filter_chips.dart';

class PaymentsHistoryScreen extends StatelessWidget {
  const PaymentsHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final authState = sl<AuthCubit>().state;
        final userId = authState.user?.id ?? '';
        return sl<PaymentsHistoryCubit>()..loadPayments(userId);
      },
      child: const _PaymentsHistoryView(),
    );
  }
}

class _PaymentsHistoryView extends StatelessWidget {
  const _PaymentsHistoryView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRtl = context.locale.languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        title: Text(
          isRtl ? 'حالة الطلبات' : 'Orders Status',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<PaymentsHistoryCubit, PaymentsHistoryState>(
        builder: (context, state) {
          if (state is PaymentsHistoryLoading) {
            return Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            );
          }

          if (state is PaymentsHistoryError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    style: TextStyle(
                      fontSize: 16,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      final authState = sl<AuthCubit>().state;
                      final userId = authState.user?.id ?? '';
                      context.read<PaymentsHistoryCubit>().loadPayments(userId);
                    },
                    icon: const Icon(Icons.refresh),
                    label: Text(isRtl ? 'إعادة المحاولة' : 'Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is PaymentsHistoryLoaded) {
            final payments = state.filteredPayments;

            if (payments.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 80,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isRtl ? 'لا توجد طلبات' : 'No orders yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isRtl
                          ? 'ستظهر طلباتك هنا'
                          : 'Your orders will appear here',
                      style: TextStyle(
                        fontSize: 14,
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                // Filter chips
                const PaymentFilterChips(),
                const SizedBox(height: 8),

                // Payments list
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      final authState = context.read<AuthCubit>().state;
                      final userId = authState.user?.id ?? '';
                      await context
                          .read<PaymentsHistoryCubit>()
                          .loadPayments(userId);
                    },
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

          return const SizedBox();
        },
      ),
    );
  }
}
