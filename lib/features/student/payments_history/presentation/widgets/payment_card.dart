import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lms_platform/features/student/payments_history/domain/entities/payment_entity.dart';

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

              _buildOrderNumberRow(theme, isRtl),
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
                    _formatAmount(payment.total, isRtl),
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

  Widget _buildOrderNumberRow(ThemeData theme, bool isRtl) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.confirmation_number_rounded,
            size: 18,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            isRtl ? 'رقم الطلب' : 'Order number',
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          SelectableText(
            _shortOrderId,
            textDirection: ui.TextDirection.ltr,
            style: TextStyle(
              fontSize: 13,
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
        ],
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
    if (payment.isFree) return Icons.card_giftcard_rounded;

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

              // Order number
              _buildDetailRow(
                isRtl ? 'رقم الطلب' : 'Order Number',
                _shortOrderId,
                Icons.confirmation_number_rounded,
                theme,
                ltrValue: true,
              ),

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
                                _formatAmount(course.price, isRtl),
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

              if (payment.isPending) ...[
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _contactTeacherWhatsapp(context, payment.id),
                    icon: const Icon(Icons.chat_rounded, color: Colors.white),
                    label: Text(
                      isRtl ? 'تأكيد الطلب عبر واتساب' : 'Confirm Order via WhatsApp',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Almarai',
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    IconData icon,
    ThemeData theme, {
    bool ltrValue = false,
  }) {
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
                  textDirection: ltrValue ? ui.TextDirection.ltr : null,
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
            _formatAmount(amount, isRtl),
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

  String _formatAmount(double amount, bool isRtl) {
    if (amount == 0) return 'Free';
    return '${amount.toStringAsFixed(2)} ${isRtl ? 'ج.م' : 'EGP'}';
  }

  String get _shortOrderId => payment.id.length <= 8
      ? payment.id.toUpperCase()
      : payment.id.substring(0, 8).toUpperCase();

  Future<void> _contactTeacherWhatsapp(BuildContext context, String orderId) async {
    final isRtl = Localizations.localeOf(context).languageCode == 'ar';

    // Show a loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    String? phone;
    try {
      final supabase = Supabase.instance.client;

      // 1. Try manual_purchase_request_items
      final requestItem = await supabase
          .from('manual_purchase_request_items')
          .select('teacher_id')
          .eq('parent_enrollment_id', orderId)
          .limit(1)
          .maybeSingle();

      if (requestItem != null && requestItem['teacher_id'] != null) {
        final teacher = await supabase
            .from('teachers')
            .select('profile_id')
            .eq('id', requestItem['teacher_id'] as String)
            .maybeSingle();

        if (teacher != null && teacher['profile_id'] != null) {
          final profile = await supabase
              .from('profiles')
              .select('phone')
              .eq('id', teacher['profile_id'] as String)
              .maybeSingle();
          phone = profile?['phone'] as String?;
        }
      }

      // 2. Fallback: if not found, get any admin or instructor phone
      if (phone == null || phone.isEmpty) {
        final fallback = await supabase
            .from('profiles')
            .select('phone')
            .inFilter('role', ['admin', 'instructor'])
            .not('phone', 'is', null)
            .limit(1)
            .maybeSingle();
        phone = fallback?['phone'] as String?;
      }
    } catch (e) {
      debugPrint('Error loading instructor phone for WhatsApp: $e');
    }

    // Dismiss loading dialog
    if (context.mounted) {
      Navigator.of(context).pop();
    }

    if (phone == null || phone.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isRtl 
                ? 'عذراً، لم نتمكن من العثور على رقم تواصل المدرس'
                : 'Sorry, could not find contact number for the teacher.'),
          ),
        );
      }
      return;
    }

    // Normalize phone
    String normalized = phone.replaceAll(RegExp(r'\D'), '');
    if (normalized.startsWith('00')) {
      normalized = normalized.substring(2);
    } else if (normalized.startsWith('0') && normalized.length == 11) {
      normalized = '2$normalized';
    }

    // Open WhatsApp
    final text = Uri.encodeComponent(
      isRtl
          ? 'مرحباً، أود تأكيد الطلب الخاص بي برقم: $orderId'
          : 'Hello, I would like to confirm my order with ID: $orderId',
    );
    final uri = Uri.parse('whatsapp://send?phone=$normalized&text=$text');
    final fallbackUri = Uri.parse(
        'https://api.whatsapp.com/send?phone=$normalized&text=$text');

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return;
      }
    } catch (_) {}

    try {
      await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isRtl
                ? 'فشل فتح واتساب. رقم الهاتف: +$normalized'
                : 'Failed to open WhatsApp. Phone: +$normalized'),
          ),
        );
      }
    }
  }
}
