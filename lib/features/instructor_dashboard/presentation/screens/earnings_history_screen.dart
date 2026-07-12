import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:lms_platform/core/shared_widgets/loading_state.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/features/instructor_dashboard/presentation/cubit/instructor_earnings_cubit.dart';
import 'package:lms_platform/features/instructor_dashboard/data/models/instructor_earning_model.dart';

/// Earnings History Screen — NEW SCHEMA
class EarningsHistoryScreen extends StatefulWidget {
  const EarningsHistoryScreen({super.key});

  @override
  State<EarningsHistoryScreen> createState() => _EarningsHistoryScreenState();
}

class _GroupedHistoryTransaction {
  final String courseId;
  final String courseName;
  final int count;
  final double netAmount;
  final double commission;
  final DateTime latestDate;
  final EarningStatus status;

  _GroupedHistoryTransaction({
    required this.courseId,
    required this.courseName,
    required this.count,
    required this.netAmount,
    required this.commission,
    required this.latestDate,
    required this.status,
  });
}

class _EarningsHistoryScreenState extends State<EarningsHistoryScreen> {
  String _selectedFilter = 'all';
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final cubit = context.read<InstructorEarningsCubit>();
      cubit.loadEarnings(refresh: true);
      cubit.loadWithdrawHistory(refresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(isArabic ? 'سجل الأرباح' : 'Earnings History'),
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildSummaryCard(context, isArabic, isDark),
          _buildFilters(context, isArabic, isDark),
          Expanded(child: _buildEarningsList(context, isArabic, isDark)),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, bool isArabic, bool isDark) {
    return BlocBuilder<InstructorEarningsCubit, InstructorEarningsState>(
      builder: (context, state) {
        final totalEarnings = state.walletSummary.totalEarnings;
        final availableAmount = state.walletSummary.availableBalance;
        final pendingAmount = state.walletSummary.pendingBalance;
        final filteredEarnings = _filterEarnings(state.earnings);

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary,
                AppColors.primary.withValues(alpha: 0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isArabic ? 'إجمالي الأرباح' : 'Total Earnings',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${totalEarnings.toStringAsFixed(0)} ${isArabic ? 'ج.م' : 'EGP'}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${filteredEarnings.length} ${isArabic ? 'معاملة' : 'transactions'}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryItem(
                      isArabic ? 'متاح' : 'Available',
                      availableAmount,
                      AppColors.success,
                      isArabic,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryItem(
                      isArabic ? 'معلق' : 'Pending',
                      pendingAmount,
                      AppColors.warning,
                      isArabic,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryItem(
      String label, double amount, Color color, bool isArabic) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${amount.toStringAsFixed(0)} ${isArabic ? 'ج.م' : 'EGP'}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(BuildContext context, bool isArabic, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Filter
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('all', isArabic ? 'الكل' : 'All', isDark),
                const SizedBox(width: 8),
                _buildFilterChip(
                    'available', isArabic ? 'متاح' : 'Available', isDark,
                    color: AppColors.success),
                const SizedBox(width: 8),
                _buildFilterChip(
                    'pending', isArabic ? 'معلق' : 'Pending', isDark,
                    color: AppColors.warning),
                const SizedBox(width: 8),
                _buildFilterChip('paid', isArabic ? 'مدفوع' : 'Paid', isDark,
                    color: AppColors.info),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Date Range
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _selectDateRange(context),
                  icon: const Icon(Icons.date_range_rounded, size: 18),
                  label: Text(
                    _startDate != null && _endDate != null
                        ? '${DateFormat('d/M').format(_startDate!)} - ${DateFormat('d/M').format(_endDate!)}'
                        : isArabic
                            ? 'اختر الفترة'
                            : 'Select Period',
                    style: const TextStyle(fontSize: 13),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              if (_startDate != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => setState(() {
                    _startDate = null;
                    _endDate = null;
                  }),
                  icon: const Icon(Icons.clear_rounded, size: 20),
                  tooltip: isArabic ? 'مسح' : 'Clear',
                  style: IconButton.styleFrom(
                    backgroundColor:
                        isDark ? AppColors.surfaceDark : AppColors.grey50,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, bool isDark,
      {Color? color}) {
    final isSelected = _selectedFilter == value;
    final chipColor = color ?? AppColors.primary;

    return FilterChip(
      selected: isSelected,
      label: Text(label),
      onSelected: (selected) {
        setState(() => _selectedFilter = value);
      },
      selectedColor: chipColor.withValues(alpha: 0.2),
      checkmarkColor: chipColor,
      labelStyle: TextStyle(
        color: isSelected
            ? chipColor
            : (isDark ? AppColors.textMainDark : AppColors.textMainLight),
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        fontSize: 13,
      ),
      side: BorderSide(
        color: isSelected
            ? chipColor
            : (isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
    );
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      helpText: isArabic ? 'اختر الفترة' : 'Select Period',
      cancelText: isArabic ? 'إلغاء' : 'Cancel',
      confirmText: isArabic ? 'تأكيد' : 'Confirm',
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  Widget _buildEarningsList(BuildContext context, bool isArabic, bool isDark) {
    return BlocBuilder<InstructorEarningsCubit, InstructorEarningsState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const AppLoadingState.section();
        }

        final filteredEarnings = _filterEarnings(state.earnings);

        if (filteredEarnings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long_outlined,
                    size: 80, color: Colors.grey[400]),
                const SizedBox(height: 20),
                Text(
                  isArabic ? 'لا توجد معاملات' : 'No transactions found',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isArabic ? 'جرب تغيير الفلاتر' : 'Try changing the filters',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        final Map<String, _GroupedHistoryTransaction> grouped = {};
        for (final e in filteredEarnings) {
          final key = '${e.courseId ?? e.courseName}_${e.status.name}';
          if (grouped.containsKey(key)) {
            final existing = grouped[key]!;
            grouped[key] = _GroupedHistoryTransaction(
              courseId: existing.courseId,
              courseName: existing.courseName,
              count: existing.count + 1,
              netAmount: existing.netAmount + e.netAmount,
              commission: existing.commission + e.commission,
              latestDate: e.createdAt.isAfter(existing.latestDate)
                  ? e.createdAt
                  : existing.latestDate,
              status: existing.status,
            );
          } else {
            grouped[key] = _GroupedHistoryTransaction(
              courseId: e.courseId ?? e.courseName,
              courseName: e.courseName,
              count: 1,
              netAmount: e.netAmount,
              commission: e.commission,
              latestDate: e.createdAt,
              status: e.status,
            );
          }
        }

        final groupedList = grouped.values.toList()
          ..sort((a, b) => b.latestDate.compareTo(a.latestDate));

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: groupedList.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final earning = groupedList[index];
            return _buildEarningItem(earning, isArabic, isDark);
          },
        );
      },
    );
  }

  List<EarningsTransactionModel> _filterEarnings(
      List<EarningsTransactionModel> earnings) {
    return earnings.where((e) {
      // Status filter
      if (_selectedFilter != 'all' &&
          e.status.toJsonValue() != _selectedFilter) {
        return false;
      }
      // Date filter
      if (_startDate != null && e.createdAt.isBefore(_startDate!)) {
        return false;
      }
      if (_endDate != null &&
          e.createdAt.isAfter(_endDate!.add(const Duration(days: 1)))) {
        return false;
      }
      return true;
    }).toList();
  }

  Widget _buildEarningItem(
      _GroupedHistoryTransaction earning, bool isArabic, bool isDark) {
    final statusColor = _getStatusColor(earning.status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Status indicator
          Container(
            width: 4,
            height: 60,
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 16),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  earning.courseName.isNotEmpty
                      ? earning.courseName
                      : (isArabic ? 'كورس' : 'Course'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textMainDark
                        : AppColors.textMainLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.calendar_today_rounded,
                        size: 14,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      DateFormat('d MMM yyyy', isArabic ? 'ar' : 'en')
                          .format(earning.latestDate),
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                      ),
                    ),
                    if (earning.count > 1) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isArabic
                              ? '${earning.count} مرات'
                              : '${earning.count}x',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    earning.status.getLabel(isArabic),
                    style: TextStyle(
                      fontSize: 11,
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Amount
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                earning.netAmount.toStringAsFixed(0),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
              ),
              Text(
                isArabic ? 'ج.م' : 'EGP',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondary,
                ),
              ),
              if (earning.commission > 0) ...[
                const SizedBox(height: 4),
                Text(
                  '${isArabic ? 'عمولة:' : 'Fee:'} ${earning.commission.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ],
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
