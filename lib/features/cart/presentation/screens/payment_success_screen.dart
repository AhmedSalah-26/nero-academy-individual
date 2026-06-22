import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/shared_widgets/app_button.dart';
import '../../../../core/theme/app_colors.dart';

/// Manual order confirmation screen.
class PaymentSuccessScreen extends StatelessWidget {
  static const String adminWhatsappNumber = '201000000000';

  final String orderId;

  const PaymentSuccessScreen({
    super.key,
    required this.orderId,
  });

  String get shortOrderId => orderId.length <= 8
      ? orderId.toUpperCase()
      : orderId.substring(0, 8).toUpperCase();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = context.locale.languageCode == 'ar';

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.success.withValues(alpha: 0.12),
                  border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.24),
                  ),
                ),
                child: const Icon(
                  Icons.assignment_turned_in_rounded,
                  size: 58,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                isArabic ? 'تم تقديم الطلب' : 'Request submitted',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: isDark ? AppColors.white : AppColors.textMainLight,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                isArabic
                    ? 'تواصل مع الإدارة على واتساب وأرسل رقم العملية لإتمام الدفع وتفعيل الكورس.'
                    : 'Contact admin on WhatsApp and send the operation ID to complete payment and activate your course.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  color: isDark
                      ? AppColors.textMutedDark
                      : AppColors.textMutedLight,
                ),
              ),
              const SizedBox(height: 24),
              _InfoTile(
                icon: Icons.confirmation_number_rounded,
                label: isArabic ? 'رقم العملية' : 'Operation ID',
                value: shortOrderId,
                isDark: isDark,
                onCopy: () => _copy(context, orderId),
              ),
              const SizedBox(height: 12),
              _InfoTile(
                icon: Icons.chat_rounded,
                label: isArabic ? 'واتساب الإدارة' : 'Admin WhatsApp',
                value: '+$adminWhatsappNumber',
                isDark: isDark,
                onCopy: () => _copy(context, '+$adminWhatsappNumber'),
              ),
              const Spacer(),
              AppButton(
                text: isArabic ? 'تواصل على واتساب' : 'Contact on WhatsApp',
                onPressed: () => _openWhatsapp(context, isArabic),
                variant: AppButtonVariant.primary,
                size: AppButtonSize.large,
                icon: Icons.chat_rounded,
                isFullWidth: true,
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => AppRouter.goToHome(context),
                child: Text(
                  isArabic ? 'العودة للرئيسية' : 'Back to home',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openWhatsapp(BuildContext context, bool isArabic) async {
    final text = Uri.encodeComponent(
      isArabic
          ? 'مرحباً، أريد إتمام دفع طلب شهاب اكاديمى. رقم العملية: $orderId'
          : 'Hello, I want to complete my Shehab Academy payment. Operation ID: $orderId',
    );
    final uri = Uri.parse('https://wa.me/$adminWhatsappNumber?text=$text');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
        context.mounted) {
      _copy(context, '+$adminWhatsappNumber');
    }
  }

  void _copy(BuildContext context, String value) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.locale.languageCode == 'ar' ? 'تم النسخ' : 'Copied',
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
    required this.onCopy,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isDark;
  final VoidCallback onCopy;

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
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
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
                const SizedBox(height: 3),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.white : AppColors.textMainLight,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onCopy,
            icon: const Icon(Icons.copy_rounded),
            tooltip: context.locale.languageCode == 'ar' ? 'نسخ' : 'Copy',
          ),
        ],
      ),
    );
  }
}
