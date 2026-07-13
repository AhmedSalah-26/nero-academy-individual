import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lms_platform/core/theme/app_colors.dart';

/// App Button Variants
enum AppButtonVariant { primary, secondary, outline, text, success, error }

/// App Button Sizes
enum AppButtonSize { small, medium, large }

/// Unified App Button Widget
class AppButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;
  final bool enableHaptic;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.enableHaptic = true,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _onTapCancel() {
    _controller.reverse();
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
        onTapDown: widget.onPressed != null ? _onTapDown : null,
        onTapUp: widget.onPressed != null ? _onTapUp : null,
        onTapCancel: widget.onPressed != null ? _onTapCancel : null,
        child: SizedBox(
          width: widget.isFullWidth ? double.infinity : null,
          height: _getHeight(),
          child: _buildButton(isDark),
        ),
      ),
    );
  }

  Widget _buildButton(bool isDark) {
    final actionColor = Theme.of(context).colorScheme.tertiary;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final glowColor = _getBackgroundColor(actionColor);

    switch (widget.variant) {
      case AppButtonVariant.primary:
      case AppButtonVariant.success:
      case AppButtonVariant.error:
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: glowColor.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: glowColor.withValues(alpha: 0.2),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: widget.isLoading ? null : _handlePress,
            style: _getElevatedStyle(isDark, actionColor),
            child: _buildChild(Colors.white),
          ),
        );
      case AppButtonVariant.secondary:
        return ElevatedButton(
          onPressed: widget.isLoading ? null : _handlePress,
          style: _getSecondaryStyle(isDark, actionColor),
          child: _buildChild(actionColor),
        );
      case AppButtonVariant.outline:
        return OutlinedButton(
          onPressed: widget.isLoading ? null : _handlePress,
          style: _getOutlineStyle(isDark, actionColor),
          child: _buildChild(actionColor),
        );
      case AppButtonVariant.text:
        return TextButton(
          onPressed: widget.isLoading ? null : _handlePress,
          style: _getTextStyle(actionColor),
          child: _buildChild(primaryColor),
        );
    }
  }

  void _handlePress() {
    if (widget.enableHaptic) {
      HapticFeedback.lightImpact();
    }
    widget.onPressed?.call();
  }

  Widget _buildChild(Color color) {
    if (widget.isLoading) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      );
    }

    if (widget.icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(widget.icon, size: _getIconSize()),
          const SizedBox(width: 8),
          Text(widget.text, style: TextStyle(fontSize: _getFontSize())),
        ],
      );
    }

    return Text(widget.text, style: TextStyle(fontSize: _getFontSize()));
  }

  double _getHeight() {
    switch (widget.size) {
      case AppButtonSize.small:
        return 36;
      case AppButtonSize.medium:
        return 48;
      case AppButtonSize.large:
        return 56;
    }
  }

  double _getFontSize() {
    switch (widget.size) {
      case AppButtonSize.small:
        return 13;
      case AppButtonSize.medium:
        return 15;
      case AppButtonSize.large:
        return 16;
    }
  }

  double _getIconSize() {
    switch (widget.size) {
      case AppButtonSize.small:
        return 16;
      case AppButtonSize.medium:
        return 20;
      case AppButtonSize.large:
        return 22;
    }
  }

  Color _getBackgroundColor(Color actionColor) {
    switch (widget.variant) {
      case AppButtonVariant.primary:
        return actionColor;
      case AppButtonVariant.success:
        return AppColors.success;
      case AppButtonVariant.error:
        return AppColors.error;
      default:
        return actionColor;
    }
  }

  ButtonStyle _getElevatedStyle(bool isDark, Color actionColor) {
    final backgroundColor = _getBackgroundColor(actionColor);
    return ElevatedButton.styleFrom(
      backgroundColor: backgroundColor,
      foregroundColor: Colors.white,
      elevation: 0,
      padding: _getPadding(),
      shadowColor: backgroundColor.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: TextStyle(
        fontFamily: 'Almarai',
        fontSize: _getFontSize(),
        fontWeight: FontWeight.w600,
      ),
    );
  }

  ButtonStyle _getSecondaryStyle(bool isDark, Color actionColor) {
    return ElevatedButton.styleFrom(
      backgroundColor: isDark
          ? actionColor.withValues(alpha: 0.15)
          : actionColor.withValues(alpha: 0.12),
      foregroundColor: actionColor,
      elevation: 0,
      padding: _getPadding(),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: TextStyle(
        fontFamily: 'Almarai',
        fontSize: _getFontSize(),
        fontWeight: FontWeight.w600,
      ),
    );
  }

  ButtonStyle _getOutlineStyle(bool isDark, Color actionColor) {
    return OutlinedButton.styleFrom(
      foregroundColor: actionColor,
      padding: _getPadding(),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      side: BorderSide(
        color: actionColor,
        width: 1.5,
      ),
      textStyle: TextStyle(
        fontFamily: 'Almarai',
        fontSize: _getFontSize(),
        fontWeight: FontWeight.w600,
      ),
    );
  }

  ButtonStyle _getTextStyle(Color actionColor) {
    return TextButton.styleFrom(
      foregroundColor: actionColor,
      padding: _getPadding(),
      textStyle: TextStyle(
        fontFamily: 'Almarai',
        fontSize: _getFontSize(),
        fontWeight: FontWeight.w600,
      ),
    );
  }

  EdgeInsets _getPadding() {
    switch (widget.size) {
      case AppButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
      case AppButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 12);
      case AppButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 32, vertical: 16);
    }
  }
}
