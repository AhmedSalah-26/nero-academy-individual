import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lms_platform/core/theme/app_colors.dart';

/// App Card Variants
enum AppCardVariant { elevated, outlined, filled }

/// Unified App Card Widget
class AppCard extends StatefulWidget {
  final Widget child;
  final AppCardVariant variant;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool enableHaptic;
  final Color? backgroundColor;
  final Color? borderColor;
  final bool enableGlow;
  final Color? glowColor;

  const AppCard({
    super.key,
    required this.child,
    this.variant = AppCardVariant.elevated,
    this.padding,
    this.margin,
    this.borderRadius = 12,
    this.onTap,
    this.onLongPress,
    this.enableHaptic = true,
    this.backgroundColor,
    this.borderColor,
    this.enableGlow = true,
    this.glowColor,
  });

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onTap != null) {
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  void _handleTap() {
    if (widget.enableHaptic) {
      HapticFeedback.lightImpact();
    }
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnimation.value,
        child: child,
      ),
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onTap: widget.onTap != null ? _handleTap : null,
        onLongPress: widget.onLongPress,
        child: Container(
          margin: widget.margin,
          decoration: _getDecoration(isDark),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: Material(
              color: Colors.transparent,
              child: Padding(
                padding: widget.padding ?? const EdgeInsets.all(16),
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _getDecoration(bool isDark) {
    final glow = widget.enableGlow
        ? [
            BoxShadow(
              color: (widget.glowColor ?? AppColors.primary)
                  .withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: (widget.glowColor ?? AppColors.primary)
                  .withValues(alpha: 0.15),
              blurRadius: 24,
              spreadRadius: 2,
            ),
          ]
        : <BoxShadow>[];

    switch (widget.variant) {
      case AppCardVariant.elevated:
        return BoxDecoration(
          color: widget.backgroundColor ??
              (isDark ? AppColors.cardDark : AppColors.white),
          borderRadius: BorderRadius.circular(widget.borderRadius),
          boxShadow: widget.enableGlow
              ? glow
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        );
      case AppCardVariant.outlined:
        return BoxDecoration(
          color: widget.backgroundColor ??
              (isDark ? AppColors.cardDark : AppColors.white),
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(
            color: widget.borderColor ??
                (isDark ? AppColors.borderDark : AppColors.borderLight),
          ),
          boxShadow: widget.enableGlow ? glow : null,
        );
      case AppCardVariant.filled:
        return BoxDecoration(
          color: widget.backgroundColor ??
              (isDark ? AppColors.surfaceDark : AppColors.grey50),
          borderRadius: BorderRadius.circular(widget.borderRadius),
          boxShadow: widget.enableGlow ? glow : null,
        );
    }
  }
}
