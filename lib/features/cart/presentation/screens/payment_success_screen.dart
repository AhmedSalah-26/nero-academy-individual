import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/shared_widgets/app_button.dart';
import '../../../../core/theme/app_colors.dart';

/// Manual order confirmation screen.
class PaymentSuccessScreen extends StatefulWidget {
  // No fallback — show instructor number only

  final String orderId;

  const PaymentSuccessScreen({
    super.key,
    required this.orderId,
  });

  @override
  State<PaymentSuccessScreen> createState() => _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends State<PaymentSuccessScreen> {
  late final Future<String?> _instructorWhatsappFuture = _loadInstructorWhatsappNumber();

  String get shortOrderId => widget.orderId.length <= 8
      ? widget.orderId.toUpperCase()
      : widget.orderId.substring(0, 8).toUpperCase();

  Future<String?> _loadInstructorWhatsappNumber() async {
    try {
      // 1. Get the instructor_id from the first enrollment of this order
      final enrollment = await Supabase.instance.client
          .from('enrollments')
          .select('instructor_id')
          .eq('parent_enrollment_id', widget.orderId)
          .limit(1)
          .maybeSingle();

      if (enrollment != null && enrollment['instructor_id'] != null) {
        // 2. Get the phone number from profiles for this instructor
        final instructor = await Supabase.instance.client
            .from('profiles')
            .select('phone')
            .eq('id', enrollment['instructor_id'])
            .maybeSingle();

        final phone = instructor?['phone'] as String?;
        if (phone != null && phone.isNotEmpty) {
          return _normalizeWhatsappNumber(phone);
        }
      }

      // No instructor number found — return null (hide the tile)
      return null;
    } catch (_) {
      return null;
    }
  }

  String? _normalizeWhatsappNumber(String? value) {
    final digits = value?.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits == null || digits.isEmpty) return null;
    if (digits.startsWith('00')) return digits.substring(2);
    if (digits.startsWith('0')) return '20${digits.substring(1)}';
    return digits;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                'payment.request_submitted'.tr(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: isDark ? AppColors.white : AppColors.textMainLight,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'payment.manual_request_subtitle'.tr(),
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
                label: 'payment.operation_id'.tr(),
                value: shortOrderId,
                isDark: isDark,
                onCopy: () => _copy(context, widget.orderId),
              ),
              const SizedBox(height: 12),
              FutureBuilder<String?>(
                future: _instructorWhatsappFuture,
                builder: (context, snapshot) {
                  final instructorNumber = snapshot.data;
                  // Hide tile if no instructor number found
                  if (instructorNumber == null) return const SizedBox.shrink();
                  return Column(
                    children: [
                      const SizedBox(height: 12),
                      _InfoTile(
                        icon: Icons.chat_rounded,
                        label: 'payment.instructor_whatsapp'.tr(),
                        value: '+$instructorNumber',
                        isDark: isDark,
                        onCopy: () => _copy(context, '+$instructorNumber'),
                      ),
                    ],
                  );
                },
              ),
              const Spacer(),
              AppButton(
                text: 'payment.contact_whatsapp'.tr(),
                onPressed: () => _openWhatsapp(context),
                variant: AppButtonVariant.primary,
                size: AppButtonSize.large,
                icon: Icons.chat_rounded,
                isFullWidth: true,
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => AppRouter.goToHome(context),
                child: Text(
                  'payment.back_to_home'.tr(),
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

  Future<void> _openWhatsapp(BuildContext context) async {
    final instructorNumber = await _instructorWhatsappFuture;
    if (instructorNumber == null) return;
    final text = Uri.encodeComponent(
      'payment.whatsapp_message'.tr(namedArgs: {'orderId': widget.orderId}),
    );
    final uri = Uri.parse('whatsapp://send?phone=$instructorNumber&text=$text');
    final fallbackUri = Uri.parse('https://api.whatsapp.com/send?phone=$instructorNumber&text=$text');

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return;
      }
    } catch (_) {}

    if (!await launchUrl(fallbackUri, mode: LaunchMode.externalApplication) &&
        context.mounted) {
      _copy(context, '+$instructorNumber');
    }
  }

  void _copy(BuildContext context, String value) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'payment.copied'.tr(),
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
                  textDirection: TextDirection.ltr,
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
            tooltip: 'common.copy'.tr(),
          ),
        ],
      ),
    );
  }
}
