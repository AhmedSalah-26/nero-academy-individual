import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lms_platform/core/theme/app_colors.dart';

/// Instructor Contact/Message Button
class InstructorContactButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isDark;
  final bool isCompact;

  const InstructorContactButton({
    super.key,
    required this.onTap,
    required this.isDark,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return _buildCompactButton();
    }
    return _buildFullButton();
  }

  Widget _buildCompactButton() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.grey100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.mail_outline_rounded,
              size: 16,
              color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
            ),
            const SizedBox(width: 6),
            Text(
              'instructor.message'.tr(),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color:
                    isDark ? AppColors.textMainDark : AppColors.textMainLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullButton() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.grey100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.mail_outline_rounded,
              size: 20,
              color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
            ),
            const SizedBox(width: 8),
            Text(
              'instructor.contact'.tr(),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color:
                    isDark ? AppColors.textMainDark : AppColors.textMainLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Contact Options Bottom Sheet
class ContactOptionsSheet extends StatelessWidget {
  final String? email;
  final VoidCallback? onEmailTap;
  final VoidCallback? onMessageTap;
  final bool isDark;

  const ContactOptionsSheet({
    super.key,
    this.email,
    this.onEmailTap,
    this.onMessageTap,
    required this.isDark,
  });

  static void show(
    BuildContext context, {
    String? email,
    VoidCallback? onEmailTap,
    VoidCallback? onMessageTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.cardDark : AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ContactOptionsSheet(
        email: email,
        onEmailTap: onEmailTap,
        onMessageTap: onMessageTap,
        isDark: isDark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? AppColors.grey600 : AppColors.grey300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          // Title
          Text(
            'instructor.contact_instructor'.tr(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
            ),
          ),
          const SizedBox(height: 20),
          // Options
          if (onMessageTap != null)
            _ContactOption(
              icon: Icons.chat_bubble_outline_rounded,
              title: 'instructor.send_message'.tr(),
              subtitle: 'instructor.send_message_desc'.tr(),
              onTap: () {
                onMessageTap!();
              },
              isDark: isDark,
            ),
          if (email != null && onEmailTap != null) ...[
            const SizedBox(height: 12),
            _ContactOption(
              icon: Icons.email_outlined,
              title: 'instructor.send_email'.tr(),
              subtitle: email!,
              onTap: () {
                onEmailTap!();
              },
              isDark: isDark,
            ),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _ContactOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDark;

  const _ContactOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.grey50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.textMutedDark
                          : AppColors.textMutedLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: isDark ? AppColors.grey500 : AppColors.grey400,
            ),
          ],
        ),
      ),
    );
  }
}
