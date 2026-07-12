import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lms_platform/core/theme/app_colors.dart';

/// Unified Back Button Widget - Used across the app for consistent design
class AppBackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final double size;
  final double iconSize;
  final double borderRadius;
  final String fallbackLocation;

  const AppBackButton({
    super.key,
    this.onPressed,
    this.size = 36,
    this.iconSize = 18,
    this.borderRadius = 12,
    this.fallbackLocation = '/home',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return IconButton(
      icon: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color:
              isDark ? Colors.white.withValues(alpha: 0.1) : AppColors.grey100,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Icon(
          Icons.arrow_back_ios_new_rounded,
          size: iconSize,
          color: isDark ? AppColors.white : AppColors.textMainLight,
        ),
      ),
      onPressed: onPressed ?? () => _handleBack(context),
    );
  }

  void _handleBack(BuildContext context) {
    final router = GoRouter.maybeOf(context);
    if (router != null && router.canPop()) {
      router.pop();
      return;
    }

    final navigator = Navigator.maybeOf(context);
    if (navigator != null && navigator.canPop()) {
      navigator.pop();
      return;
    }

    if (router != null) {
      router.go(fallbackLocation);
    }
  }
}
