import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/features/instructor_dashboard/data/models/instructor_payout_model.dart';

/// صفحة تفاصيل السحب
/// Withdraw Details Screen - Shows detailed information about a withdrawal request
class WithdrawDetailsScreen extends StatelessWidget {
  final WithdrawRequestModel request;

  const WithdrawDetailsScreen({
    super.key,
    required this.request,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(isArabic ? 'تفاصيل السحب' : 'Withdrawal Details'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAmountCard(isDark, isArabic),
            const SizedBox(height: 20),
            _buildDetailsCard(isDark, isArabic),
            const SizedBox(height: 20),
            _buildStatusCard(isDark, isArabic),
            if (request.notes != null && request.notes!.isNotEmpty) ...[
              const SizedBox(height: 20),
              _buildNotesCard(isDark, isArabic),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAmountCard(bool isDark, bool isArabic) {
    final statusColor = _getStatusColor(request.status);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [statusColor, statusColor.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            isArabic ? 'مبلغ السحب' : 'Withdrawal Amount',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${request.amount.toStringAsFixed(2)} ${isArabic ? 'ج.م' : 'EGP'}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              request.status.getLabel(isArabic),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(bool isDark, bool isArabic) {
    final methodLabel = _getMethodLabel(request.method, isArabic);

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
            isArabic ? 'معلومات الطلب' : 'Request Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
            icon: Icons.fingerprint_rounded,
            label: isArabic ? 'رقم الطلب' : 'Request ID',
            value: request.id.substring(0, 8).toUpperCase(),
            isDark: isDark,
          ),
          const Divider(height: 24),
          _buildDetailRow(
            icon: Icons.account_balance_rounded,
            label: isArabic ? 'طريقة السحب' : 'Withdrawal Method',
            value: methodLabel,
            isDark: isDark,
          ),
          const Divider(height: 24),
          _buildDetailRow(
            icon: Icons.calendar_today_rounded,
            label: isArabic ? 'تاريخ الطلب' : 'Request Date',
            value: DateFormat('dd MMMM yyyy', isArabic ? 'ar' : 'en')
                .format(request.requestedAt),
            isDark: isDark,
          ),
          const Divider(height: 24),
          _buildDetailRow(
            icon: Icons.access_time_rounded,
            label: isArabic ? 'الوقت' : 'Time',
            value: DateFormat('hh:mm a', isArabic ? 'ar' : 'en')
                .format(request.requestedAt),
            isDark: isDark,
          ),
          if (request.approvedAt != null || request.paidAt != null) ...[
            const Divider(height: 24),
            _buildDetailRow(
              icon: Icons.check_circle_outline_rounded,
              label: isArabic ? 'تاريخ المعالجة' : 'Processed Date',
              value: DateFormat('dd MMMM yyyy', isArabic ? 'ar' : 'en')
                  .format(request.paidAt ?? request.approvedAt!),
              isDark: isDark,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusCard(bool isDark, bool isArabic) {
    final statusColor = _getStatusColor(request.status);
    final statusLabel = request.status.getLabel(isArabic);
    final statusDescription = _getStatusDescription(request.status, isArabic);

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
            isArabic ? 'حالة الطلب' : 'Request Status',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
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
                  _getStatusIcon(request.status),
                  color: statusColor,
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  statusDescription,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? AppColors.textMutedDark
                        : AppColors.textMutedLight,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesCard(bool isDark, bool isArabic) {
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
          Row(
            children: [
              const Icon(
                Icons.note_rounded,
                color: AppColors.info,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isArabic ? 'ملاحظات' : 'Notes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color:
                      isDark ? AppColors.textMainDark : AppColors.textMainLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.info.withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              request.notes!,
              style: TextStyle(
                fontSize: 14,
                color:
                    isDark ? AppColors.textMainDark : AppColors.textMainLight,
                height: 1.5,
              ),
            ),
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

  String _getStatusDescription(WithdrawStatus status, bool isArabic) {
    switch (status) {
      case WithdrawStatus.pending:
        return isArabic
            ? 'طلبك قيد المراجعة وسيتم معالجته قريباً'
            : 'Your request is under review and will be processed soon';
      case WithdrawStatus.approved:
        return isArabic
            ? 'تمت الموافقة على طلبك وجاري التحويل'
            : 'Your request has been approved and is being transferred';
      case WithdrawStatus.paid:
        return isArabic
            ? 'تم تحويل المبلغ بنجاح إلى حسابك'
            : 'Amount has been successfully transferred to your account';
      case WithdrawStatus.rejected:
        return isArabic
            ? 'تم رفض الطلب، يرجى التواصل مع الدعم'
            : 'Request was rejected, please contact support';
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
