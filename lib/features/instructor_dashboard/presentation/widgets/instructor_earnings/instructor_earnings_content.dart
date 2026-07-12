// ignore_for_file: deprecated_member_use
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/features/instructor_dashboard/data/models/instructor_earning_model.dart';
import 'package:lms_platform/features/instructor_dashboard/presentation/cubit/instructor_earnings_cubit.dart';

/// Instructor Earnings Content — Simple Stats View
class InstructorEarningsContent extends StatefulWidget {
  const InstructorEarningsContent({super.key});

  @override
  State<InstructorEarningsContent> createState() =>
      _InstructorEarningsContentState();
}

class _InstructorEarningsContentState extends State<InstructorEarningsContent> {
  _Period _selectedPeriod = _Period.month;

  @override
  void initState() {
    super.initState();
    _loadForPeriod(_selectedPeriod);
  }

  void _loadForPeriod(_Period period) {
    final now = DateTime.now();
    DateTime start;
    switch (period) {
      case _Period.week:
        start = now.subtract(const Duration(days: 7));
        break;
      case _Period.month:
        start = DateTime(now.year, now.month, 1);
        break;
      case _Period.year:
        start = DateTime(now.year, 1, 1);
        break;
      case _Period.all:
        start = DateTime(2000);
        break;
    }
    context.read<InstructorEarningsCubit>().loadEarnings(
          refresh: true,
          startDate: start,
          endDate: now,
        );
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<InstructorEarningsCubit, InstructorEarningsState>(
      builder: (context, state) {
        // Calculate stats from loaded earnings
        final totalEarnings =
            state.earnings.fold<double>(0, (sum, e) => sum + e.netAmount);
        final totalEnrollments = state.earnings.length;

        return RefreshIndicator(
          onRefresh: () async => _loadForPeriod(_selectedPeriod),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Period Filter
                _PeriodFilter(
                  selected: _selectedPeriod,
                  isArabic: isArabic,
                  isDark: isDark,
                  onChanged: (p) {
                    setState(() => _selectedPeriod = p);
                    _loadForPeriod(p);
                  },
                ),
                const SizedBox(height: 20),

                // Main Stats Cards
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.attach_money_rounded,
                        label: isArabic ? 'إجمالي الأرباح' : 'Total Earnings',
                        value:
                            '${totalEarnings.toStringAsFixed(0)} ${isArabic ? 'ج.م' : 'EGP'}',
                        color: AppColors.success,
                        isDark: isDark,
                        isLoading: state.isLoading,
                        isArabic: isArabic,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.people_alt_rounded,
                        label:
                            isArabic ? 'عدد الاشتراكات' : 'Total Enrollments',
                        value: '$totalEnrollments',
                        color: AppColors.primary,
                        isDark: isDark,
                        isLoading: state.isLoading,
                        isArabic: isArabic,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Transactions List
                _TransactionsList(
                  earnings: state.earnings,
                  isLoading: state.isLoading,
                  isArabic: isArabic,
                  isDark: isDark,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ──────────────────────────────────────────────
// Period Enum
// ──────────────────────────────────────────────
enum _Period { week, month, year, all }

extension _PeriodLabel on _Period {
  String label(bool isArabic) {
    switch (this) {
      case _Period.week:
        return isArabic ? 'أسبوع' : 'Week';
      case _Period.month:
        return isArabic ? 'شهر' : 'Month';
      case _Period.year:
        return isArabic ? 'سنة' : 'Year';
      case _Period.all:
        return isArabic ? 'الكل' : 'All';
    }
  }
}

// ──────────────────────────────────────────────
// Period Filter Widget
// ──────────────────────────────────────────────
class _PeriodFilter extends StatelessWidget {
  final _Period selected;
  final bool isArabic;
  final bool isDark;
  final ValueChanged<_Period> onChanged;

  const _PeriodFilter({
    required this.selected,
    required this.isArabic,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.grey100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Row(
        children: _Period.values.map((period) {
          final isSelected = period == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(period),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                child: Text(
                  period.label(isArabic),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : isDark
                            ? AppColors.textMutedDark
                            : AppColors.textMutedLight,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Stat Card
// ──────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;
  final bool isLoading;
  final bool isArabic;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
    required this.isLoading,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 14),
          if (isLoading)
            Container(
              height: 28,
              width: 80,
              decoration: BoxDecoration(
                color: isDark ? AppColors.borderDark : AppColors.grey100,
                borderRadius: BorderRadius.circular(6),
              ),
            )
          else
            Directionality(
              textDirection: ui.TextDirection.ltr,
              child: Text(
                isArabic && value.contains('ج.م')
                    ? '${value.replaceAll('ج.م', '').trim()} ج.م'
                    : value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color:
                      isDark ? AppColors.textMainDark : AppColors.textMainLight,
                ),
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

// ──────────────────────────────────────────────
// Transactions List
// ──────────────────────────────────────────────
class _TransactionsList extends StatelessWidget {
  final List<EarningsTransactionModel> earnings;
  final bool isLoading;
  final bool isArabic;
  final bool isDark;

  const _TransactionsList({
    required this.earnings,
    required this.isLoading,
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
              Icons.receipt_long_rounded,
              size: 20,
              color:
                  isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            ),
            const SizedBox(width: 8),
            Text(
              isArabic ? 'المعاملات' : 'Transactions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color:
                    isDark ? AppColors.textMainDark : AppColors.textMainLight,
              ),
            ),
            if (earnings.isNotEmpty) ...[
              const Spacer(),
              Text(
                '${earnings.length} ${isArabic ? 'معاملة' : 'records'}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.textMutedDark
                      : AppColors.textMutedLight,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        if (isLoading)
          ...List.generate(
            4,
            (_) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              height: 72,
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : AppColors.grey100,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          )
        else if (earnings.isEmpty)
          Container(
            padding: const EdgeInsets.all(40),
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
                    Icons.receipt_outlined,
                    size: 48,
                    color: isDark ? AppColors.textMutedDark : AppColors.grey300,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isArabic
                        ? 'لا توجد معاملات في هذه الفترة'
                        : 'No transactions in this period',
                    style: TextStyle(
                      color: isDark
                          ? AppColors.textMutedDark
                          : AppColors.textMutedLight,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...() {
            final Map<String, _GroupedTransaction> grouped = {};
            for (final e in earnings) {
              final key = e.courseId ?? e.courseName;
              if (grouped.containsKey(key)) {
                final existing = grouped[key]!;
                grouped[key] = _GroupedTransaction(
                  courseId: key,
                  courseName: e.courseName,
                  count: existing.count + 1,
                  totalAmount: existing.totalAmount + e.netAmount,
                  latestDate: e.createdAt.isAfter(existing.latestDate)
                      ? e.createdAt
                      : existing.latestDate,
                  sourceType: e.sourceType,
                );
              } else {
                grouped[key] = _GroupedTransaction(
                  courseId: key,
                  courseName: e.courseName,
                  count: 1,
                  totalAmount: e.netAmount,
                  latestDate: e.createdAt,
                  sourceType: e.sourceType,
                );
              }
            }
            final groupedList = grouped.values.toList()
              ..sort((a, b) => b.latestDate.compareTo(a.latestDate));

            return groupedList.map((g) => _TransactionItem(
                  earning: g,
                  isArabic: isArabic,
                  isDark: isDark,
                ));
          }(),
      ],
    );
  }
}

// ──────────────────────────────────────────────
// Transaction Item
// ──────────────────────────────────────────────
class _GroupedTransaction {
  final String courseId;
  final String courseName;
  final int count;
  final double totalAmount;
  final DateTime latestDate;
  final EarningSourceType sourceType;

  _GroupedTransaction({
    required this.courseId,
    required this.courseName,
    required this.count,
    required this.totalAmount,
    required this.latestDate,
    required this.sourceType,
  });
}

class _TransactionItem extends StatelessWidget {
  final _GroupedTransaction earning;
  final bool isArabic;
  final bool isDark;

  const _TransactionItem({
    required this.earning,
    required this.isArabic,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final isRefund = earning.sourceType == EarningSourceType.refund;
    final color = isRefund ? AppColors.error : AppColors.success;
    final prefix = isRefund ? '-' : '+';

    return Container(
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
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isRefund ? Icons.money_off_rounded : Icons.school_rounded,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  earning.courseName.isNotEmpty
                      ? earning.courseName
                      : (isArabic ? 'كورس' : 'Course'),
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
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      DateFormat('dd/MM/yyyy').format(earning.latestDate),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.textMutedDark
                            : AppColors.textMutedLight,
                      ),
                    ),
                    if (earning.count > 1) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isArabic
                              ? '${earning.count} مرات'
                              : '${earning.count}x',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Text(
            '$prefix${earning.totalAmount.abs().toStringAsFixed(0)} ${isArabic ? 'ج.م' : 'EGP'}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Outlined Action Button (kept for potential reuse elsewhere)
class OutlinedActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  const OutlinedActionButton({
    super.key,
    required this.icon,
    required this.label,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        side: BorderSide(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
    );
  }
}
