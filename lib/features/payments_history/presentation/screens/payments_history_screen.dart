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
import '../../domain/entities/payment_entity.dart';
import '../cubit/payments_history_cubit.dart';
import '../widgets/payment_card.dart';

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

class _PaymentsHistoryView extends StatefulWidget {
  const _PaymentsHistoryView();

  @override
  State<_PaymentsHistoryView> createState() => _PaymentsHistoryViewState();
}

class _PaymentsHistoryViewState extends State<_PaymentsHistoryView>
    with SingleTickerProviderStateMixin {
  static const _tabs = <_OrdersTab>[
    _OrdersTab(status: 'all', enLabel: 'All', arLabel: 'الكل'),
    _OrdersTab(status: 'paid', enLabel: 'Paid', arLabel: 'مدفوع'),
    _OrdersTab(
      status: 'pending_manual_payment',
      enLabel: 'Pending',
      arLabel: 'قيد المراجعة',
    ),
    _OrdersTab(status: 'refunded', enLabel: 'Refunded', arLabel: 'مسترد'),
    _OrdersTab(status: 'cancelled', enLabel: 'Cancelled', arLabel: 'ملغي'),
  ];

  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_syncSelectedStatus);
  }

  @override
  void dispose() {
    _tabController.removeListener(_syncSelectedStatus);
    _tabController.dispose();
    super.dispose();
  }

  void _syncSelectedStatus() {
    if (_tabController.indexIsChanging) return;

    final status = _tabs[_tabController.index].status;
    context.read<PaymentsHistoryCubit>().filterByStatus(status);
  }

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
            if (state.payments.isEmpty) {
              return const _OrdersEmptyState();
            }

            return Column(
              children: [
                _OrdersStatusTabBar(
                  controller: _tabController,
                  tabs: _tabs,
                  payments: state.payments,
                  isRtl: isRtl,
                  isDark: isDark,
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      for (final tab in _tabs)
                        _OrdersTabPage(
                          payments: _paymentsFor(state.payments, tab.status),
                        ),
                    ],
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

  List<PaymentEntity> _paymentsFor(
      List<PaymentEntity> payments, String status) {
    if (status == 'all') return payments;
    if (status == 'pending_manual_payment') {
      return payments.where((payment) => payment.isPending).toList();
    }
    return payments
        .where((payment) => payment.paymentStatus == status)
        .toList();
  }
}

class _OrdersStatusTabBar extends StatelessWidget {
  const _OrdersStatusTabBar({
    required this.controller,
    required this.tabs,
    required this.payments,
    required this.isRtl,
    required this.isDark,
  });

  final TabController controller;
  final List<_OrdersTab> tabs;
  final List<PaymentEntity> payments;
  final bool isRtl;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
      ),
      child: TabBar(
        controller: controller,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelColor: isDark ? AppColors.primaryOnDark : AppColors.primary,
        unselectedLabelColor:
            isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
        indicatorColor: isDark ? AppColors.primaryOnDark : AppColors.primary,
        indicatorWeight: 2.6,
        dividerColor: Colors.transparent,
        labelPadding: const EdgeInsets.symmetric(horizontal: 18),
        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        unselectedLabelStyle:
            const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        onTap: (index) {
          HapticFeedback.selectionClick();
          context
              .read<PaymentsHistoryCubit>()
              .filterByStatus(tabs[index].status);
        },
        tabs: [
          for (final tab in tabs)
            Tab(text: '${tab.label(isRtl)} (${_count(tab.status)})'),
        ],
      ),
    );
  }

  int _count(String status) {
    if (status == 'all') return payments.length;
    if (status == 'pending_manual_payment') {
      return payments.where((payment) => payment.isPending).length;
    }
    return payments.where((payment) => payment.paymentStatus == status).length;
  }
}

class _OrdersTabPage extends StatelessWidget {
  const _OrdersTabPage({required this.payments});

  final List<PaymentEntity> payments;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: () async {
        HapticFeedback.mediumImpact();
        await context.read<PaymentsHistoryCubit>().loadPayments(_userId);
      },
      color: AppColors.primary,
      backgroundColor: isDark ? AppColors.cardDark : AppColors.white,
      child: payments.isEmpty
          ? const _OrdersEmptyTabState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: payments.length,
              itemBuilder: (context, index) {
                return PaymentCard(payment: payments[index]);
              },
            ),
    );
  }
}

class _OrdersEmptyTabState extends StatelessWidget {
  const _OrdersEmptyTabState();

  @override
  Widget build(BuildContext context) {
    final isRtl = context.locale.languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 96),
      children: [
        Icon(
          Icons.receipt_long_outlined,
          size: 46,
          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
        ),
        const SizedBox(height: 14),
        Text(
          isRtl ? 'لا توجد طلبات في هذه الحالة' : 'No orders in this status',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
          ),
        ),
      ],
    );
  }
}

class _OrdersTab {
  const _OrdersTab({
    required this.status,
    required this.enLabel,
    required this.arLabel,
  });

  final String status;
  final String enLabel;
  final String arLabel;

  String label(bool isRtl) => isRtl ? arLabel : enLabel;
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
