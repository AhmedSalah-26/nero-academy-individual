import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/features/instructor_dashboard/data/models/instructor_earning_model.dart';
import 'package:lms_platform/features/instructor_dashboard/data/models/instructor_course_model.dart';

/// صفحة تفاصيل الدفع
/// Earning Details Screen - Shows detailed information about a payment transaction
class EarningDetailsScreen extends StatelessWidget {
  final EarningsTransactionModel earning;
  final InstructorCourseModel? course;

  const EarningDetailsScreen({
    super.key,
    required this.earning,
    this.course,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(isArabic ? 'تفاصيل الدفع' : 'Payment Details'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAmountCard(isDark, isArabic),
            const SizedBox(height: 20),
            if (course != null) ...[
              _buildCourseStatsCard(isDark, isArabic),
              const SizedBox(height: 20),
            ],
            _buildDetailsCard(isDark, isArabic),
            const SizedBox(height: 20),
            _buildBreakdownCard(isDark, isArabic),
            const SizedBox(height: 20),
            _buildStatusCard(isDark, isArabic),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountCard(bool isDark, bool isArabic) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.success, AppColors.success.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.success.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            isArabic ? 'صافي الربح' : 'Net Earnings',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${earning.netAmount.toStringAsFixed(2)} ${isArabic ? 'ج.م' : 'EGP'}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            earning.courseName,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCourseStatsCard(bool isDark, bool isArabic) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isArabic ? 'تحليلات الطلاب' : 'Student Analytics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.people_rounded,
                  label: isArabic ? 'التسجيلات الكلية' : 'Total Enrollments',
                  value: course!.enrollmentCount.toString(),
                  color: AppColors.primary,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.star_rounded,
                  label: isArabic ? 'متوسط التقييم' : 'Average Rating',
                  value: course!.averageRating.toStringAsFixed(1),
                  color: AppColors.warning,
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.info.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.trending_up_rounded,
                  color: AppColors.info,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isArabic
                        ? 'إجمالي الإيرادات: ${course!.totalRevenue.toStringAsFixed(0)} ج.م'
                        : 'Total Revenue: ${course!.totalRevenue.toStringAsFixed(0)} EGP',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.info,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 28,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color:
                  isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(bool isDark, bool isArabic) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isArabic ? 'معلومات المعاملة' : 'Transaction Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
            icon: Icons.fingerprint_rounded,
            label: isArabic ? 'رقم المعاملة' : 'Transaction ID',
            value: earning.id.substring(0, 8).toUpperCase(),
            isDark: isDark,
          ),
          const Divider(height: 24),
          _buildDetailRow(
            icon: Icons.person_rounded,
            label: isArabic ? 'معرف المشتري' : 'Buyer ID',
            value: earning.userId.substring(0, 8).toUpperCase(),
            isDark: isDark,
          ),
          const Divider(height: 24),
          _buildDetailRow(
            icon: Icons.calendar_today_rounded,
            label: isArabic ? 'تاريخ الشراء' : 'Purchase Date',
            value: DateFormat('dd MMMM yyyy', isArabic ? 'ar' : 'en')
                .format(earning.createdAt),
            isDark: isDark,
          ),
          const Divider(height: 24),
          _buildDetailRow(
            icon: Icons.access_time_rounded,
            label: isArabic ? 'الوقت' : 'Time',
            value: DateFormat('hh:mm a', isArabic ? 'ar' : 'en')
                .format(earning.createdAt),
            isDark: isDark,
          ),
          if (earning.courseId != null) ...[
            const Divider(height: 24),
            _buildDetailRow(
              icon: Icons.school_rounded,
              label: isArabic ? 'معرف الكورس' : 'Course ID',
              value: earning.courseId!.substring(0, 8).toUpperCase(),
              isDark: isDark,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBreakdownCard(bool isDark, bool isArabic) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isArabic ? 'تفاصيل المبلغ' : 'Amount Breakdown',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
            ),
          ),
          const SizedBox(height: 16),
          _buildAmountRow(
            label: isArabic ? 'السعر الأصلي' : 'Original Price',
            amount: earning.originalPrice > 0
                ? earning.originalPrice
                : earning.amount,
            isDark: isDark,
            isArabic: isArabic,
          ),
          if (earning.couponDiscount > 0) ...[
            const SizedBox(height: 12),
            _buildAmountRow(
              label: isArabic ? 'خصم الكوبون' : 'Coupon Discount',
              amount: -earning.couponDiscount,
              isDark: isDark,
              isArabic: isArabic,
              color: AppColors.warning,
            ),
          ],
          const SizedBox(height: 12),
          _buildAmountRow(
            label: isArabic ? 'المبلغ الإجمالي' : 'Total Amount',
            amount: earning.amount,
            isDark: isDark,
            isArabic: isArabic,
            isBold: true,
          ),
          const SizedBox(height: 12),
          _buildAmountRow(
            label: isArabic ? 'عمولة المنصة' : 'Platform Commission',
            amount: -earning.commission,
            isDark: isDark,
            isArabic: isArabic,
            color: AppColors.error,
          ),
          const Divider(height: 24),
          _buildAmountRow(
            label: isArabic ? 'صافي الربح' : 'Net Earnings',
            amount: earning.netAmount,
            isDark: isDark,
            isArabic: isArabic,
            isBold: true,
            color: AppColors.success,
            isLarge: true,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(bool isDark, bool isArabic) {
    final statusColor = _getStatusColor(earning.status);
    final statusLabel = earning.status.getLabel(isArabic);
    final sourceLabel = earning.sourceType.getLabel(isArabic);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isArabic ? 'الحالة والنوع' : 'Status & Type',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _getStatusIcon(earning.status),
                        color: statusColor,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isArabic ? 'الحالة' : 'Status',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.textMutedDark
                              : AppColors.textMutedLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.info.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _getSourceIcon(earning.sourceType),
                        color: AppColors.info,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isArabic ? 'النوع' : 'Type',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.textMutedDark
                              : AppColors.textMutedLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        sourceLabel,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.info,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.textMutedDark
                      : AppColors.textMutedLight,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color:
                      isDark ? AppColors.textMainDark : AppColors.textMainLight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAmountRow({
    required String label,
    required double amount,
    required bool isDark,
    required bool isArabic,
    bool isBold = false,
    Color? color,
    bool isLarge = false,
  }) {
    final textColor =
        color ?? (isDark ? AppColors.textMainDark : AppColors.textMainLight);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isLarge ? 16 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: textColor,
          ),
        ),
        Text(
          '${amount >= 0 ? '' : ''}${amount.toStringAsFixed(2)} ${isArabic ? 'ج.م' : 'EGP'}',
          style: TextStyle(
            fontSize: isLarge ? 18 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: textColor,
          ),
        ),
      ],
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

  IconData _getStatusIcon(EarningStatus status) {
    switch (status) {
      case EarningStatus.available:
        return Icons.check_circle_rounded;
      case EarningStatus.pending:
        return Icons.hourglass_empty_rounded;
      case EarningStatus.paid:
        return Icons.account_balance_wallet_rounded;
    }
  }

  IconData _getSourceIcon(EarningSourceType sourceType) {
    switch (sourceType) {
      case EarningSourceType.courseSale:
        return Icons.shopping_cart_rounded;
      case EarningSourceType.refund:
        return Icons.replay_rounded;
      case EarningSourceType.adjustment:
        return Icons.tune_rounded;
    }
  }
}
