import 'package:flutter/material.dart';
import 'package:lms_platform/core/theme/app_colors.dart';

/// Unified Section Header Widget
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? actionText;
  final VoidCallback? onActionTap;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionText,
    this.onActionTap,
    this.trailing,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Almarai',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.white : AppColors.textMainLight,
                    letterSpacing: -0.3,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontFamily: 'Almarai',
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: isDark
                          ? AppColors.textMutedDark
                          : AppColors.textMutedLight,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
          if (actionText != null && onActionTap != null)
            _buildActionButton(isDark),
        ],
      ),
    );
  }

  Widget _buildActionButton(bool isDark) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onActionTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                actionText!,
                style: TextStyle(
                  fontFamily: 'Almarai',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.primaryOnDark : AppColors.primary,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: isDark ? AppColors.primaryOnDark : AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
