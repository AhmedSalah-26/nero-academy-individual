import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../data/models/admin_payout_model.dart';

/// Payout Detail Screen — full page for withdrawal request details
class PayoutDetailScreen extends StatelessWidget {
  final AdminPayoutModel payout;
  final VoidCallback? onApprove;
  final VoidCallback? onComplete;
  final VoidCallback? onReject;

  const PayoutDetailScreen({
    super.key,
    required this.payout,
    this.onApprove,
    this.onComplete,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(isArabic ? 'تفاصيل طلب السحب' : 'Withdrawal Details'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Status & Amount Card
            _buildAmountCard(isDark, isArabic),
            const SizedBox(height: 16),

            // Instructor Info
            _buildSection(
              isDark,
              isArabic,
              icon: Icons.person_rounded,
              title: isArabic ? 'معلومات المدرب' : 'Instructor Info',
              children: [
                _buildInfoRow(
                  context,
                  isDark,
                  isArabic,
                  label: isArabic ? 'الاسم' : 'Name',
                  value: payout.instructorName ?? 'Unknown',
                ),
                _buildInfoRow(
                  context,
                  isDark,
                  isArabic,
                  label: isArabic ? 'البريد' : 'Email',
                  value: payout.instructorEmail ?? '-',
                  canCopy: payout.instructorEmail != null,
                ),
                _buildInfoRow(
                  context,
                  isDark,
                  isArabic,
                  label: isArabic ? 'معرف المدرب' : 'Instructor ID',
                  value: payout.instructorId,
                  canCopy: true,
                  isMonospace: true,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Payment Info
            _buildSection(
              isDark,
              isArabic,
              icon: Icons.payment_rounded,
              title: isArabic ? 'معلومات الدفع' : 'Payment Info',
              children: [
                _buildInfoRow(
                  context,
                  isDark,
                  isArabic,
                  label: isArabic ? 'طريقة الدفع' : 'Method',
                  value: _getPayoutMethodLabel(isArabic),
                  valueWidget: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_getMethodIcon(),
                          size: 16, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        _getPayoutMethodLabel(isArabic),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.textMainDark
                              : AppColors.textMainLight,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_getPaymentDetailsText().isNotEmpty)
                  _buildInfoRow(
                    context,
                    isDark,
                    isArabic,
                    label: isArabic ? 'رقم الحساب' : 'Account Number',
                    value: _getPaymentDetailsText(),
                    canCopy: true,
                    isMonospace: true,
                    highlight: true,
                  ),
                if (_getAllPaymentDetails().isNotEmpty)
                  ..._getAllPaymentDetails().map(
                    (entry) => _buildInfoRow(
                      context,
                      isDark,
                      isArabic,
                      label: entry.key,
                      value: entry.value,
                      canCopy: true,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Request Info
            _buildSection(
              isDark,
              isArabic,
              icon: Icons.info_outline_rounded,
              title: isArabic ? 'معلومات الطلب' : 'Request Info',
              children: [
                _buildInfoRow(
                  context,
                  isDark,
                  isArabic,
                  label: isArabic ? 'رقم الطلب' : 'Request ID',
                  value: payout.id,
                  canCopy: true,
                  isMonospace: true,
                ),
                _buildInfoRow(
                  context,
                  isDark,
                  isArabic,
                  label: isArabic ? 'تاريخ الطلب' : 'Requested At',
                  value: dateFormat.format(payout.requestedAt),
                ),
                if (payout.processedAt != null)
                  _buildInfoRow(
                    context,
                    isDark,
                    isArabic,
                    label: isArabic ? 'تاريخ المعالجة' : 'Processed At',
                    value: dateFormat.format(payout.processedAt!),
                  ),
                if (payout.processedBy != null)
                  _buildInfoRow(
                    context,
                    isDark,
                    isArabic,
                    label: isArabic ? 'معالج بواسطة' : 'Processed By',
                    value: payout.processedBy!,
                    canCopy: true,
                    isMonospace: true,
                  ),
                if (payout.notes != null && payout.notes!.isNotEmpty)
                  _buildInfoRow(
                    context,
                    isDark,
                    isArabic,
                    label: isArabic ? 'ملاحظات' : 'Notes',
                    value: payout.notes!,
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // Action Buttons
            if (!payout.isTerminal)
              _buildActionButtons(context, isDark, isArabic),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountCard(bool isDark, bool isArabic) {
    final statusColor = _getStatusColor();
    final statusLabel = _getStatusLabel(isArabic);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
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
          Text(
            isArabic ? 'المبلغ المطلوب' : 'Requested Amount',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            payout.formattedAmount,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: statusColor.withValues(alpha: 0.5)),
            ),
            child: Text(
              statusLabel,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    bool isDark,
    bool isArabic, {
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(icon, size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textMainDark
                        : AppColors.textMainLight,
                  ),
                ),
              ],
            ),
          ),
          Divider(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            height: 1,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    bool isDark,
    bool isArabic, {
    required String label,
    required String value,
    bool canCopy = false,
    bool isMonospace = false,
    bool highlight = false,
    Widget? valueWidget,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color:
                    isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: valueWidget ??
                Container(
                  padding: highlight
                      ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
                      : EdgeInsets.zero,
                  decoration: highlight
                      ? BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.2),
                          ),
                        )
                      : null,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: highlight ? 15 : 13,
                      fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
                      fontFamily: isMonospace ? 'monospace' : null,
                      color: highlight
                          ? AppColors.primary
                          : (isDark
                              ? AppColors.textMainDark
                              : AppColors.textMainLight),
                    ),
                  ),
                ),
          ),
          if (canCopy)
            InkWell(
              onTap: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isArabic ? 'تم النسخ ✓' : 'Copied ✓'),
                    duration: const Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              borderRadius: BorderRadius.circular(6),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(
                  Icons.copy_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, bool isDark, bool isArabic) {
    return Column(
      children: [
        if (payout.isPending) ...[
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                onApprove?.call();
                Navigator.pop(context);
              },
              icon: const Icon(Icons.check_circle_rounded),
              label: Text(
                isArabic ? 'موافقة على الطلب' : 'Approve Request',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () {
                onReject?.call();
              },
              icon: const Icon(Icons.close_rounded),
              label: Text(
                isArabic ? 'رفض الطلب' : 'Reject Request',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
        if (payout.isUnderReview) ...[
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                onComplete?.call();
                Navigator.pop(context);
              },
              icon: const Icon(Icons.done_all_rounded),
              label: Text(
                isArabic ? 'تأكيد الدفع' : 'Confirm Payment',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () {
                onReject?.call();
              },
              icon: const Icon(Icons.close_rounded),
              label: Text(
                isArabic ? 'رفض الطلب' : 'Reject Request',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ─── Helpers ───

  Color _getStatusColor() {
    switch (payout.status) {
      case PayoutStatusType.pending:
        return AppColors.warning;
      case PayoutStatusType.underReview:
        return AppColors.info;
      case PayoutStatusType.completed:
        return AppColors.success;
      case PayoutStatusType.rejected:
        return AppColors.error;
    }
  }

  String _getStatusLabel(bool isArabic) {
    switch (payout.status) {
      case PayoutStatusType.pending:
        return isArabic ? 'قيد الانتظار' : 'Pending';
      case PayoutStatusType.underReview:
        return isArabic ? 'تمت الموافقة' : 'Approved';
      case PayoutStatusType.completed:
        return isArabic ? 'تم الدفع' : 'Paid';
      case PayoutStatusType.rejected:
        return isArabic ? 'مرفوض' : 'Rejected';
    }
  }

  IconData _getMethodIcon() {
    switch (payout.payoutMethod) {
      case PayoutMethod.instapay:
        return Icons.phone_android_rounded;
      case PayoutMethod.wallet:
        return Icons.account_balance_wallet_rounded;
      case PayoutMethod.other:
        return Icons.payment_rounded;
    }
  }

  String _getPayoutMethodLabel(bool isArabic) {
    switch (payout.payoutMethod) {
      case PayoutMethod.instapay:
        return isArabic ? 'انستاباي' : 'InstaPay';
      case PayoutMethod.wallet:
        return isArabic ? 'محفظة إلكترونية' : 'E-Wallet';
      case PayoutMethod.other:
        return isArabic ? 'أخرى' : 'Other';
    }
  }

  String _getPaymentDetailsText() {
    if (payout.payoutDetails == null) return '';
    final details = payout.payoutDetails!;
    if (details.containsKey('instapay_id')) return '${details['instapay_id']}';
    if (details.containsKey('phone_number')) {
      return '${details['phone_number']}';
    }
    if (details.containsKey('account_number')) {
      return '${details['account_number']}';
    }
    for (final v in details.values) {
      if (v != null && v.toString().isNotEmpty) return v.toString();
    }
    return '';
  }

  List<MapEntry<String, String>> _getAllPaymentDetails() {
    if (payout.payoutDetails == null) return [];
    final result = <MapEntry<String, String>>[];
    payout.payoutDetails!.forEach((key, value) {
      if (value != null && value.toString().isNotEmpty) {
        // Skip if already shown as main detail
        if (key == 'instapay_id' ||
            key == 'phone_number' ||
            key == 'account_number') {
          return;
        }
        result.add(MapEntry(key, value.toString()));
      }
    });
    return result;
  }
}
