import 'package:flutter/material.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/features/instructor_dashboard/presentation/cubit/instructor_earnings_cubit.dart';

/// Stats Cards for Earnings — NEW SCHEMA
class EarningsStatsCards extends StatelessWidget {
  final InstructorEarningsState state;
  final bool isArabic;
  final bool isDark;

  const EarningsStatsCards({
    super.key,
    required this.state,
    required this.isArabic,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    // Read directly from wallet summary (DB-stored, auto-updated by triggers)
    final availableBalance = state.walletSummary.availableBalance;
    final pendingBalance = state.walletSummary.pendingBalance;
    final totalEarnings = state.walletSummary.totalEarnings;
    final totalWithdrawn = state.walletSummary.totalWithdrawn;

    final now = DateTime.now();
    final thisMonthEarnings = state.earnings
        .where((e) =>
            e.createdAt.month == now.month && e.createdAt.year == now.year)
        .fold<double>(0, (sum, e) => sum + e.netAmount);

    final lastMonth = DateTime(now.year, now.month - 1);
    final lastMonthEarnings = state.earnings
        .where((e) =>
            e.createdAt.month == lastMonth.month &&
            e.createdAt.year == lastMonth.year)
        .fold<double>(0, (sum, e) => sum + e.netAmount);

    final growthPercent = lastMonthEarnings > 0
        ? ((thisMonthEarnings - lastMonthEarnings) / lastMonthEarnings * 100)
        : (thisMonthEarnings > 0 ? 100.0 : 0.0);

    return Column(
      children: [
        MainBalanceCard(
          available: availableBalance,
          pending: pendingBalance,
          isArabic: isArabic,
          isDark: isDark,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: StatCard(
                icon: Icons.trending_up_rounded,
                label: isArabic ? 'هذا الشهر' : 'This Month',
                value:
                    '${thisMonthEarnings.toStringAsFixed(0)} ${isArabic ? 'ج.م' : 'EGP'}',
                trend: growthPercent,
                color: AppColors.success,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                icon: Icons.account_balance_wallet_rounded,
                label: isArabic ? 'إجمالي الأرباح' : 'Total Earnings',
                value:
                    '${totalEarnings.toStringAsFixed(0)} ${isArabic ? 'ج.م' : 'EGP'}',
                color: AppColors.primary,
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: StatCard(
                icon: Icons.payments_rounded,
                label: isArabic ? 'تم السحب' : 'Withdrawn',
                value:
                    '${totalWithdrawn.toStringAsFixed(0)} ${isArabic ? 'ج.م' : 'EGP'}',
                color: AppColors.info,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                icon: Icons.receipt_long_rounded,
                label: isArabic ? 'عدد المعاملات' : 'Transactions',
                value: '${state.earnings.length}',
                color: AppColors.warning,
                isDark: isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Main Balance Card
class MainBalanceCard extends StatelessWidget {
  final double available;
  final double pending;
  final bool isArabic;
  final bool isDark;

  const MainBalanceCard({
    super.key,
    required this.available,
    required this.pending,
    required this.isArabic,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  AppColors.primaryDark,
                  AppColors.primary,
                ]
              : [
                  AppColors.primary,
                  AppColors.primaryDark,
                ],
        ),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: isDark ? 0.25 : 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: isDark ? 0.22 : 0.16),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                isArabic ? 'الرصيد المتاح للسحب' : 'Available Balance',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '${available.toStringAsFixed(0)} ${isArabic ? 'ج.م' : 'EGP'}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          // Pending
          Row(
            children: [
              Icon(
                Icons.hourglass_bottom_rounded,
                color: Colors.white.withValues(alpha: 0.7),
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                '${isArabic ? 'رصيد معلق:' : 'Pending Balance:'} ${pending.toStringAsFixed(0)} ${isArabic ? 'ج.م' : 'EGP'}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Stat Card Widget
class StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final double? trend;
  final Color color;
  final bool isDark;

  const StatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.trend,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              if (trend != null) ...[
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: trend! >= 0
                        ? AppColors.success.withValues(alpha: 0.1)
                        : AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        trend! >= 0
                            ? Icons.arrow_upward_rounded
                            : Icons.arrow_downward_rounded,
                        size: 12,
                        color:
                            trend! >= 0 ? AppColors.success : AppColors.error,
                      ),
                      Text(
                        '${trend!.abs().toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color:
                              trend! >= 0 ? AppColors.success : AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color:
                  isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            ),
          ),
        ],
      ),
    );
  }
}
