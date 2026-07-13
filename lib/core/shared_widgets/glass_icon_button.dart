import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:lms_platform/core/theme/app_colors.dart';

class GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final double iconSize;
  final double borderRadius;
  final bool hasNotification;
  final int? badgeCount;
  final bool compactBadge;
  final Color? iconColor;

  const GlassIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.size = 40,
    this.iconSize = 22,
    this.borderRadius = 14,
    this.hasNotification = false,
    this.badgeCount,
    this.compactBadge = false,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final actionColor = theme.colorScheme.tertiary;
    final numberBadgeScale = compactBadge ? 0.78 : 1.0;
    const borderWidth = 1.5;
    final radius = BorderRadius.circular(borderRadius);
    final innerRadius = BorderRadius.circular(borderRadius - borderWidth);
    final borderColor = isDark
        ? actionColor.withValues(alpha: 0.28)
        : actionColor.withValues(alpha: 0.32);
    final fillColor = theme.cardColor.withValues(alpha: isDark ? 0.84 : 0.78);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          padding: const EdgeInsets.all(borderWidth),
          decoration: BoxDecoration(
            color: borderColor,
            borderRadius: radius,
          ),
          child: ClipRRect(
            borderRadius: innerRadius,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Material(
                color: fillColor,
                borderRadius: innerRadius,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: innerRadius,
                  child: Icon(
                    icon,
                    size: iconSize,
                    color: iconColor ?? actionColor,
                  ),
                ),
              ),
            ),
          ),
        ),
        if (hasNotification || (badgeCount != null && badgeCount! > 0))
          Positioned(
            top: size * 0.08,
            right: size * 0.08,
            child: Container(
              padding: badgeCount != null
                  ? EdgeInsets.symmetric(
                      horizontal: size * 0.09 * numberBadgeScale,
                      vertical: size * 0.02 * numberBadgeScale,
                    )
                  : EdgeInsets.zero,
              constraints: BoxConstraints(
                minWidth: size * 0.17 * numberBadgeScale,
                minHeight: size * 0.17 * numberBadgeScale,
              ),
              decoration: BoxDecoration(
                color: actionColor,
                borderRadius:
                    BorderRadius.circular(size * 0.18 * numberBadgeScale),
                border: Border.all(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  width: compactBadge ? 1.2 : 1.5,
                ),
              ),
              child: badgeCount != null
                  ? Text(
                      '$badgeCount',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize:
                            (size * 0.22 * numberBadgeScale).clamp(7.0, 10.0),
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  : null,
            ),
          ),
      ],
    );
  }
}
