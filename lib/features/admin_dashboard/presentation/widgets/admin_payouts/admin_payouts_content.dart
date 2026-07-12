import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/shared_widgets/dashboard/dashboard_widgets.dart';
import '../../../../../core/shared_widgets/loading_skeleton.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../data/models/admin_payout_model.dart';
import '../../cubit/admin_payouts_cubit.dart';
import 'payout_list_item.dart';
import 'payout_detail_screen.dart';

/// Admin Payouts Content
class AdminPayoutsContent extends StatefulWidget {
  const AdminPayoutsContent({super.key});

  @override
  State<AdminPayoutsContent> createState() => _AdminPayoutsContentState();
}

class _AdminPayoutsContentState extends State<AdminPayoutsContent> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<AdminPayoutsCubit>().loadPayouts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<AdminPayoutsCubit>().loadMorePayouts();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return BlocBuilder<AdminPayoutsCubit, AdminPayoutsState>(
      builder: (context, state) {
        return Column(
          children: [
            _buildHeader(context, state, isArabic),
            Expanded(child: _buildPayoutsList(context, state, isArabic)),
          ],
        );
      },
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AdminPayoutsState state,
    bool isArabic,
  ) {
    final tabs = [
      const DashboardTabItem(label: 'All', labelAr: 'الكل'),
      const DashboardTabItem(label: 'Pending', labelAr: 'قيد الانتظار'),
      const DashboardTabItem(label: 'Under Review', labelAr: 'تحت المراجعة'),
      const DashboardTabItem(label: 'Completed', labelAr: 'مكتمل'),
      const DashboardTabItem(label: 'Rejected', labelAr: 'مرفوض'),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      child: DashboardTabs(
        tabs: tabs,
        selectedIndex: _getTabIndex(state.currentStatus),
        onTabSelected: (index) {
          context
              .read<AdminPayoutsCubit>()
              .changeStatusFilter(_getStatusFromIndex(index));
        },
      ),
    );
  }

  int _getTabIndex(PayoutStatusType? status) {
    if (status == null) return 0;
    switch (status) {
      case PayoutStatusType.pending:
        return 1;
      case PayoutStatusType.underReview:
        return 2;
      case PayoutStatusType.completed:
        return 3;
      case PayoutStatusType.rejected:
        return 4;
    }
  }

  PayoutStatusType? _getStatusFromIndex(int index) {
    switch (index) {
      case 0:
        return null; // All
      case 1:
        return PayoutStatusType.pending;
      case 2:
        return PayoutStatusType.underReview;
      case 3:
        return PayoutStatusType.completed;
      case 4:
        return PayoutStatusType.rejected;
      default:
        return null;
    }
  }

  Widget _buildPayoutsList(
    BuildContext context,
    AdminPayoutsState state,
    bool isArabic,
  ) {
    final isLoading = state.status == AdminPayoutsStatus.loading;
    final isLoadingMore = state.status == AdminPayoutsStatus.loadingMore;

    if (isLoading && state.payouts.isEmpty) {
      return _buildLoadingSkeleton();
    }

    if (state.payouts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.payments_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              isArabic ? 'لا توجد مدفوعات' : 'No payouts found',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<AdminPayoutsCubit>().loadPayouts(
            status: state.currentStatus,
            refresh: true,
          ),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: state.payouts.length + (isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == state.payouts.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final payout = state.payouts[index];
          return PayoutListItem(
            payout: payout,
            onReview: payout.isPending
                ? () => context.read<AdminPayoutsCubit>().reviewPayout(payout)
                : null,
            onComplete: payout.isUnderReview
                ? () => _showCompleteDialog(context, payout, isArabic)
                : null,
            onReject: (payout.isPending || payout.isUnderReview)
                ? () => _showRejectDialog(context, payout, isArabic)
                : null,
            onViewDetails: () {
              final cubit = context.read<AdminPayoutsCubit>();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PayoutDetailScreen(
                    payout: payout,
                    onApprove: payout.isPending
                        ? () => cubit.reviewPayout(payout)
                        : null,
                    onComplete: payout.isUnderReview
                        ? () => cubit.completePayout(payout)
                        : null,
                    onReject: (payout.isPending || payout.isUnderReview)
                        ? () => _showRejectDialog(context, payout, isArabic)
                        : null,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 10,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.cardDark
                : AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.borderDark
                  : AppColors.borderLight,
            ),
          ),
          child: const Row(
            children: [
              LoadingSkeleton(width: 48, height: 48),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LoadingSkeleton(height: 16, width: 150),
                    SizedBox(height: 8),
                    LoadingSkeleton(height: 14, width: 100),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCompleteDialog(
      BuildContext context, AdminPayoutModel payout, bool isArabic) {
    final cubit = context.read<AdminPayoutsCubit>();
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (dialogContext) => DashboardInputDialog(
        title: isArabic ? 'إتمام الدفعة' : 'Complete Payout',
        message: isArabic ? 'أدخل ملاحظة (اختياري)' : 'Enter a note (optional)',
        hintText: isArabic ? 'ملاحظة...' : 'Note...',
        confirmText: isArabic ? 'إتمام' : 'Complete',
        cancelText: isArabic ? 'إلغاء' : 'Cancel',
      ),
    ).then((notes) {
      cubit.completePayout(payout, notes: notes);
    });
  }

  void _showRejectDialog(
      BuildContext context, AdminPayoutModel payout, bool isArabic) {
    final cubit = context.read<AdminPayoutsCubit>();
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (dialogContext) => DashboardInputDialog(
        title: isArabic ? 'رفض الدفعة' : 'Reject Payout',
        message: isArabic ? 'أدخل سبب الرفض' : 'Enter the rejection reason',
        hintText: isArabic ? 'سبب الرفض...' : 'Rejection reason...',
        confirmText: isArabic ? 'رفض' : 'Reject',
        cancelText: isArabic ? 'إلغاء' : 'Cancel',
        maxLines: 3,
      ),
    ).then((reason) {
      if (reason != null && reason.isNotEmpty) {
        cubit.rejectPayout(payout, reason: reason);
      }
    });
  }
}
