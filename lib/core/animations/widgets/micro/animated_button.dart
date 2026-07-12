import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lms_platform/core/animations/foundation/foundation.dart';

/// Animated button widget with scale-down animation on press
/// Provides tactile feedback with haptic vibration
class AnimatedButton extends StatefulWidget {
  /// The child widget (button content)
  final Widget child;

  /// Callback when button is pressed
  final VoidCallback? onPressed;

  /// Scale factor when pressed (1.0 = no scale, 0.95 = 5% smaller)
  final double scaleDown;

  /// Animation duration
  final Duration duration;

  /// Whether to enable haptic feedback
  final bool enableHaptic;

  const AnimatedButton({
    super.key,
    required this.child,
    this.onPressed,
    this.scaleDown = 0.95,
    this.duration = const Duration(milliseconds: 100),
    this.enableHaptic = true,
  });

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleDown,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onPressed != null) {
      _controller.forward();

      // Haptic feedback
      if (widget.enableHaptic) {
        HapticFeedback.lightImpact();
      }
    }
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final shouldAnimate = AccessibilityManager.instance.shouldAnimate(context);

    // If animations disabled, return button without animation
    if (!shouldAnimate) {
      return GestureDetector(
        onTap: widget.onPressed,
        child: widget.child,
      );
    }

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onPressed,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}
