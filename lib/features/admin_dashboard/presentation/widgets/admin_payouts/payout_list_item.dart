import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../data/models/admin_payout_model.dart';

/// Payout List Item Widget
class PayoutListItem extends StatelessWidget {
  final AdminPayoutModel payout;
  final VoidCallback? onReview;
  final VoidCallback? onComplete;
  final VoidCallback? onReject;
  final VoidCallback? onViewDetails;

  const PayoutListItem({
    super.key,
    required this.payout,
    this.onReview,
    this.onComplete,
    this.onReject,
    this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onViewDetails,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildInstructorInfo(isDark, isArabic),
                    _buildStatusBadge(isDark, isArabic),
                  ],
                ),
                const SizedBox(height: 12),
                _buildPaymentInfo(context, isDark, isArabic),
                const SizedBox(height: 8),
                _buildPayoutMeta(isDark, isArabic),
                const SizedBox(height: 12),
                _buildActions(context, isDark, isArabic),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInstructorInfo(bool isDark, bool isArabic) {
    return Expanded(
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: payout.instructorAvatar != null
                ? ClipOval(
                    child: Image.network(
                      payout.instructorAvatar!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.person,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                  )
                : const Icon(Icons.person, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payout.instructorName ?? 'Unknown',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textMainDark
                        : AppColors.textMainLight,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (payout.instructorEmail != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    payout.instructorEmail!,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? AppColors.textMutedDark
                          : AppColors.textMutedLight,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentInfo(BuildContext context, bool isDark, bool isArabic) {
    final methodLabel = _getPayoutMethodLabel(isArabic);
    final detailsText = _getPaymentDetailsText();

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.primary.withValues(alpha: 0.08)
            : AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_getMethodIcon(), size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                methodLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color:
                      isDark ? AppColors.textMainDark : AppColors.textMainLight,
                ),
              ),
              const Spacer(),
              Text(
                payout.formattedAmount,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          if (detailsText.isNotEmpty) ...[
            const SizedBox(height: 6),
            InkWell(
              onTap: () {
                Clipboard.setData(ClipboardData(text: detailsText));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isArabic ? 'تم النسخ ✓' : 'Copied ✓'),
                    duration: const Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? Colors.black26 : Colors.white54,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      detailsText,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'monospace',
                        color: isDark
                            ? AppColors.textMainDark
                            : AppColors.textMainLight,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.copy_rounded,
                      size: 14,
                      color: isDark
                          ? AppColors.textMutedDark
                          : AppColors.textMutedLight,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPayoutMeta(bool isDark, bool isArabic) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    return Row(
      children: [
        Icon(Icons.calendar_today_rounded,
            size: 13,
            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
        const SizedBox(width: 4),
        Text(
          dateFormat.format(payout.requestedAt),
          style: TextStyle(
            fontSize: 11,
            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
          ),
        ),
        const SizedBox(width: 12),
        Icon(Icons.tag_rounded,
            size: 13,
            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
        const SizedBox(width: 4),
        Text(
          payout.id.length > 8 ? payout.id.substring(0, 8) : payout.id,
          style: TextStyle(
            fontSize: 11,
            fontFamily: 'monospace',
            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
          ),
        ),
      ],
    );
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

  Widget _buildActions(BuildContext context, bool isDark, bool isArabic) {
    if (payout.isRejected && payout.notes != null) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, size: 16, color: AppColors.error),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                payout.notes!,
                style: const TextStyle(fontSize: 12, color: AppColors.error),
              ),
            ),
          ],
        ),
      );
    }

    if (payout.isTerminal) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (payout.isPending) ...[
          TextButton.icon(
            onPressed: onReview,
            icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
            label: Text(isArabic ? 'موافقة' : 'Approve'),
            style: TextButton.styleFrom(foregroundColor: AppColors.success),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: onReject,
            icon: const Icon(Icons.close_rounded, size: 18),
            label: Text(isArabic ? 'رفض' : 'Reject'),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
          ),
        ],
        if (payout.isUnderReview) ...[
          TextButton.icon(
            onPressed: onComplete,
            icon: const Icon(Icons.done_all_rounded, size: 18),
            label: Text(isArabic ? 'تم الدفع' : 'Mark Paid'),
            style: TextButton.styleFrom(foregroundColor: AppColors.success),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: onReject,
            icon: const Icon(Icons.close_rounded, size: 18),
            label: Text(isArabic ? 'رفض' : 'Reject'),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
          ),
        ],
      ],
    );
  }

  Widget _buildStatusBadge(bool isDark, bool isArabic) {
    Color color;
    String label;

    switch (payout.status) {
      case PayoutStatusType.pending:
        color = AppColors.warning;
        label = isArabic ? 'قيد الانتظار' : 'Pending';
        break;
      case PayoutStatusType.underReview:
        color = AppColors.info;
        label = isArabic ? 'تمت الموافقة' : 'Approved';
        break;
      case PayoutStatusType.completed:
        color = AppColors.success;
        label = isArabic ? 'تم الدفع' : 'Paid';
        break;
      case PayoutStatusType.rejected:
        color = AppColors.error;
        label = isArabic ? 'مرفوض' : 'Rejected';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
