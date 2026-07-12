import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lms_platform/core/theme/app_colors.dart';

/// Help Contact Section Widget
class HelpContactSection extends StatelessWidget {
  final VoidCallback? onLiveChat;
  final VoidCallback? onEmail;
  final bool isDark;

  const HelpContactSection({
    super.key,
    this.onLiveChat,
    this.onEmail,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primaryDark,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'help_support.still_need_help'.tr(),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'help_support.support_available'.tr(),
            style: TextStyle(
              fontSize: 14,
              color: AppColors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildContactButton(
                  icon: Icons.mail_outline,
                  label: 'help_support.email_us'.tr(),
                  onTap: onEmail,
                  isPrimary: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildContactButton(
                  icon: Icons.chat_bubble_outline,
                  label: 'help_support.live_chat'.tr(),
                  onTap: onLiveChat,
                  isPrimary: false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactButton({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
    required bool isPrimary,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isPrimary
                ? AppColors.white
                : AppColors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
            border: isPrimary
                ? null
                : Border.all(
                    color: AppColors.white.withValues(alpha: 0.3),
                  ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isPrimary ? AppColors.primary : AppColors.white,
                size: 24,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isPrimary ? AppColors.primary : AppColors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
