import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/core/shared_widgets/loading_skeleton.dart';
import 'package:lms_platform/features/instructor_dashboard/data/models/instructor_earning_model.dart';
import 'package:lms_platform/features/instructor_dashboard/data/models/instructor_payout_model.dart';
import 'package:lms_platform/features/instructor_dashboard/presentation/cubit/instructor_earnings_cubit.dart';
import 'package:lms_platform/features/instructor_dashboard/presentation/pages/earning_details_wrapper.dart';
import 'package:lms_platform/features/instructor_dashboard/presentation/pages/withdraw_details_screen.dart';

/// Recent Earnings List — NEW SCHEMA
class RecentEarningsList extends StatelessWidget {
  final InstructorEarningsState state;
  final bool isArabic;
  final bool isDark;

  const RecentEarningsList({
    super.key,
    required this.state,
    required this.isArabic,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.monetization_on_rounded,
              color:
                  isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              isArabic ? 'الأرباح الأخيرة' : 'Recent Earnings',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color:
                    isDark ? AppColors.textMainDark : AppColors.textMainLight,
              ),
            ),
            const Spacer(),
            if (state.earnings.isNotEmpty)
              Text(
                '${state.earnings.length} ${isArabic ? 'معاملة' : 'transactions'}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.textMutedDark
                      : AppColors.textMutedLight,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (state.isLoading)
          ...List.generate(
            5,
            (_) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: const LoadingSkeleton(width: double.infinity, height: 70),
            ),
          )
        else if (state.earnings.isEmpty)
          EarningsEmptyState(
            icon: Icons.monetization_on_outlined,
            message: isArabic ? 'لا توجد أرباح بعد' : 'No earnings yet',
            isDark: isDark,
          )
        else
          ...state.earnings.take(10).map(
                (earning) => EarningItem(
                    earning: earning, isArabic: isArabic, isDark: isDark),
              ),
      ],
    );
  }
}

/// Earning Item Widget — NEW SCHEMA
class EarningItem extends StatelessWidget {
  final EarningsTransactionModel earning;
  final bool isArabic;
  final bool isDark;

  const EarningItem({
    super.key,
    required this.earning,
    required this.isArabic,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(earning.status);
    final statusLabel = earning.status.getLabel(isArabic);
    final isRefund = earning.sourceType == EarningSourceType.refund;
    final displayAmount = earning.netAmount;
    final amountColor = isRefund ? AppColors.error : AppColors.success;
    final amountPrefix = isRefund ? '-' : '+';

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EarningDetailsWrapper(earning: earning),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (isRefund ? AppColors.error : AppColors.success)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isRefund ? Icons.money_off_rounded : Icons.school_rounded,
                color: isRefund ? AppColors.error : AppColors.success,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          earning.courseName,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: isDark
                                ? AppColors.textMainDark
                                : AppColors.textMainLight,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isRefund)
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isArabic ? 'استرداد' : 'Refund',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.error,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        DateFormat('dd/MM/yyyy').format(earning.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.textMutedDark
                              : AppColors.textMutedLight,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$amountPrefix${displayAmount.abs().toStringAsFixed(0)} ${isArabic ? 'ج.م' : 'EGP'}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: amountColor,
                  ),
                ),
                if (earning.commission.abs() > 0)
                  Text(
                    '${isArabic ? 'عمولة:' : 'Fee:'} ${earning.commission.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? AppColors.textMutedDark
                          : AppColors.textMutedLight,
                    ),
                  ),
                if (earning.couponDiscount.abs() > 0)
                  Text(
                    '${isArabic ? 'خصم كوبون:' : 'Coupon:'} -${earning.couponDiscount.abs().toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.warning,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(EarningStatus status) {
    switch (status) {
      case EarningStatus.available:
        return AppColors.success;
      case EarningStatus.pending:
        return AppColors.warning;
      case EarningStatus.paid:
        return AppColors.info;
    }
  }
}

/// Withdraw History List — NEW SCHEMA (replaces PayoutHistoryList)
class WithdrawHistoryList extends StatelessWidget {
  final InstructorEarningsState state;
  final bool isArabic;
  final bool isDark;

  const WithdrawHistoryList({
    super.key,
    required this.state,
    required this.isArabic,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.history_rounded,
              color:
                  isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              isArabic ? 'سجل السحوبات' : 'Withdraw History',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color:
                    isDark ? AppColors.textMainDark : AppColors.textMainLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (state.withdrawStatus == InstructorEarningsStatus.loading)
          ...List.generate(
            3,
            (_) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: const LoadingSkeleton(width: double.infinity, height: 70),
            ),
          )
        else if (state.withdrawRequests.isEmpty)
          EarningsEmptyState(
            icon: Icons.payments_outlined,
            message: isArabic ? 'لا توجد سحوبات بعد' : 'No withdrawals yet',
            isDark: isDark,
          )
        else
          ...state.withdrawRequests.map(
            (request) => WithdrawItem(
                request: request, isArabic: isArabic, isDark: isDark),
          ),
      ],
    );
  }
}

/// Withdraw Item Widget — NEW SCHEMA (replaces PayoutItem)
class WithdrawItem extends StatelessWidget {
  final WithdrawRequestModel request;
  final bool isArabic;
  final bool isDark;

  const WithdrawItem({
    super.key,
    required this.request,
    required this.isArabic,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(request.status);
    final statusLabel = request.status.getLabel(isArabic);
    final methodLabel = _getMethodLabel(request.method, isArabic);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WithdrawDetailsScreen(request: request),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _getStatusIcon(request.status),
                color: statusColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${request.amount.toStringAsFixed(0)} ${isArabic ? 'ج.م' : 'EGP'}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: isDark
                          ? AppColors.textMainDark
                          : AppColors.textMainLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 12,
                        color: isDark
                            ? AppColors.textMutedDark
                            : AppColors.textMutedLight,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('dd/MM/yyyy').format(request.requestedAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.textMutedDark
                              : AppColors.textMutedLight,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.account_balance_rounded,
                        size: 12,
                        color: isDark
                            ? AppColors.textMutedDark
                            : AppColors.textMutedLight,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        methodLabel,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.textMutedDark
                              : AppColors.textMutedLight,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(WithdrawStatus status) {
    switch (status) {
      case WithdrawStatus.pending:
        return AppColors.warning;
      case WithdrawStatus.approved:
        return AppColors.info;
      case WithdrawStatus.paid:
        return AppColors.success;
      case WithdrawStatus.rejected:
        return AppColors.error;
    }
  }

  IconData _getStatusIcon(WithdrawStatus status) {
    switch (status) {
      case WithdrawStatus.pending:
        return Icons.hourglass_empty_rounded;
      case WithdrawStatus.approved:
        return Icons.check_circle_outline_rounded;
      case WithdrawStatus.paid:
        return Icons.check_circle_rounded;
      case WithdrawStatus.rejected:
        return Icons.cancel_rounded;
    }
  }

  String _getMethodLabel(String method, bool isArabic) {
    switch (method) {
      case 'instapay':
        return isArabic ? 'انستاباي' : 'InstaPay';
      case 'wallet':
        return isArabic ? 'محفظة إلكترونية' : 'E-Wallet';
      case 'bank_transfer':
        return isArabic ? 'تحويل بنكي' : 'Bank Transfer';
      case 'vodafone_cash':
        return isArabic ? 'فودافون كاش' : 'Vodafone Cash';
      default:
        return method;
    }
  }
}

/// Empty State Widget
class EarningsEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final bool isDark;

  const EarningsEmptyState({
    super.key,
    required this.icon,
    required this.message,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              icon,
              size: 48,
              color: isDark ? AppColors.textMutedDark : AppColors.grey300,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                color:
                    isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
