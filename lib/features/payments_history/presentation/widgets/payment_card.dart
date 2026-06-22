import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../domain/entities/payment_entity.dart';

class PaymentCard extends StatelessWidget {
  final PaymentEntity payment;

  const PaymentCard({super.key, required this.payment});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRtl = context.locale.languageCode == 'ar';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showPaymentDetails(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Status and Date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatusChip(theme, isRtl),
                  Text(
                    DateFormat('dd MMM yyyy', isRtl ? 'ar' : 'en')
                        .format(payment.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Courses
              if (payment.courses.isNotEmpty) ...[
                ...payment.courses.map((course) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.play_circle_outline,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              course.title,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 12),
              ],

              // Payment details
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Payment method
                  Row(
                    children: [
                      Icon(
                        _getPaymentIcon(),
                        size: 18,
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isRtl ? payment.methodAr : payment.methodEn,
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),

                  // Total amount
                  Text(
                    '${payment.total.toStringAsFixed(2)} ${isRtl ? 'ج.م' : 'EGP'}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),

              // Transaction ID (if available)
              if (payment.transactionId != null) ...[
                const SizedBox(height: 8),
                Text(
                  '${isRtl ? 'رقم المعاملة' : 'Transaction ID'}: ${payment.transactionId}',
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(ThemeData theme, bool isRtl) {
    Color backgroundColor;
    Color textColor;

    if (payment.isPaid) {
      backgroundColor = Colors.green.shade50;
      textColor = Colors.green.shade700;
    } else if (payment.isPending) {
      backgroundColor = Colors.orange.shade50;
      textColor = Colors.orange.shade700;
    } else if (payment.isCancelled || payment.isFailed) {
      backgroundColor = Colors.red.shade50;
      textColor = Colors.red.shade700;
    } else {
      backgroundColor = Colors.grey.shade200;
      textColor = Colors.grey.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isRtl ? payment.statusAr : payment.statusEn,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  IconData _getPaymentIcon() {
    switch (payment.paymentMethod) {
      case 'card':
        return Icons.credit_card;
      case 'wallet':
        return Icons.account_balance_wallet;
      case 'manual':
        return Icons.receipt_long_rounded;
      case 'free':
        return Icons.card_giftcard_rounded;
      case 'cash':
        return Icons.money;
      default:
        return Icons.payment;
    }
  }

  void _showPaymentDetails(BuildContext context) {
    final theme = Theme.of(context);
    final isRtl = context.locale.languageCode == 'ar';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isRtl ? 'تفاصيل الدفع' : 'Payment Details',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  _buildStatusChip(theme, isRtl),
                ],
              ),
              const SizedBox(height: 24),

              // Date
              _buildDetailRow(
                isRtl ? 'التاريخ' : 'Date',
                DateFormat('dd MMMM yyyy - hh:mm a', isRtl ? 'ar' : 'en')
                    .format(payment.createdAt),
                Icons.calendar_today,
                theme,
              ),

              // Payment method
              _buildDetailRow(
                isRtl ? 'طريقة الدفع' : 'Payment Method',
                isRtl ? payment.methodAr : payment.methodEn,
                _getPaymentIcon(),
                theme,
              ),

              // Transaction ID
              if (payment.transactionId != null)
                _buildDetailRow(
                  isRtl ? 'رقم المعاملة' : 'Transaction ID',
                  payment.transactionId!,
                  Icons.tag,
                  theme,
                ),

              // Paid at
              if (payment.paidAt != null)
                _buildDetailRow(
                  isRtl ? 'تاريخ الدفع' : 'Paid At',
                  DateFormat('dd MMMM yyyy - hh:mm a', isRtl ? 'ar' : 'en')
                      .format(payment.paidAt!),
                  Icons.check_circle,
                  theme,
                ),

              const Divider(height: 32),

              // Courses
              Text(
                isRtl ? 'الكورسات' : 'Courses',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              ...payment.courses.map((course) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Icon(
                          Icons.play_circle_outline,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                course.title,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '${course.price.toStringAsFixed(2)} ${isRtl ? 'ج.م' : 'EGP'}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )),

              const Divider(height: 32),

              // Price breakdown
              Text(
                isRtl ? 'تفاصيل السعر' : 'Price Breakdown',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),

              _buildPriceRow(
                isRtl ? 'المجموع الفرعي' : 'Subtotal',
                payment.subtotal,
                isRtl,
                theme,
              ),

              if (payment.discount > 0)
                _buildPriceRow(
                  isRtl ? 'الخصم' : 'Discount',
                  -payment.discount,
                  isRtl,
                  theme,
                  isDiscount: true,
                ),

              if (payment.couponDiscount > 0)
                _buildPriceRow(
                  '${isRtl ? 'كوبون' : 'Coupon'} (${payment.couponCode})',
                  -payment.couponDiscount,
                  isRtl,
                  theme,
                  isDiscount: true,
                ),

              const Divider(height: 24),

              _buildPriceRow(
                isRtl ? 'الإجمالي' : 'Total',
                payment.total,
                isRtl,
                theme,
                isTotal: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
      String label, String value, IconData icon, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(
    String label,
    double amount,
    bool isRtl,
    ThemeData theme, {
    bool isDiscount = false,
    bool isTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface,
            ),
          ),
          Text(
            '${amount.toStringAsFixed(2)} ${isRtl ? 'ج.م' : 'EGP'}',
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: isDiscount
                  ? Colors.green
                  : (isTotal
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}
