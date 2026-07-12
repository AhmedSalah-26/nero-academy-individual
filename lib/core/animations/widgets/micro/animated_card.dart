import 'package:flutter/material.dart';
import 'package:lms_platform/core/animations/foundation/foundation.dart';

/// Animated card widget with tap animation
/// Combines scale and elevation changes for tactile feedback
class AnimatedCard extends StatefulWidget {
  /// The child widget (card content)
  final Widget child;

  /// Callback when card is tapped
  final VoidCallback? onTap;

  /// Scale factor when pressed
  final double scaleDown;

  /// Elevation increase on press
  final double elevationIncrease;

  /// Animation duration
  final Duration duration;

  const AnimatedCard({
    super.key,
    required this.child,
    this.onTap,
    this.scaleDown = 0.98,
    this.elevationIncrease = 4.0,
    this.duration = const Duration(milliseconds: 150),
  });

  @override
  State<AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<AnimatedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;

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

    _elevationAnimation = Tween<double>(
      begin: 0.0,
      end: widget.elevationIncrease,
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

  @override
  Widget build(BuildContext context) {
    final shouldAnimate = AccessibilityManager.instance.shouldAnimate(context);

    // If animations disabled, return card without animation
    if (!shouldAnimate) {
      return GestureDetector(
        onTap: widget.onTap,
        child: widget.child,
      );
    }

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Material(
              elevation: _elevationAnimation.value,
              color: Colors.transparent,
              child: child,
            ),
          );
        },
        child: widget.child,
      ),
    );
  }
}
