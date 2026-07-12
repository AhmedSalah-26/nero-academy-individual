import 'package:flutter/material.dart';
import 'package:lms_platform/core/animations/foundation/foundation.dart';

/// Pulse animation widget
/// Continuously pulses (scales up and down) while animate is true
class PulseAnimation extends StatefulWidget {
  /// The child widget to animate
  final Widget child;

  /// Whether to animate
  final bool animate;

  /// Animation duration (one complete pulse cycle)
  final Duration duration;

  /// Minimum scale value
  final double minScale;

  /// Maximum scale value
  final double maxScale;

  const PulseAnimation({
    super.key,
    required this.child,
    this.animate = true,
    this.duration = const Duration(milliseconds: 1000),
    this.minScale = 1.0,
    this.maxScale = 1.1,
  });

  @override
  State<PulseAnimation> createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<PulseAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _animation = Tween<double>(
      begin: widget.minScale,
      end: widget.maxScale,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _updateAnimation();
  }

  @override
  void didUpdateWidget(PulseAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.animate != oldWidget.animate) {
      _updateAnimation();
    }
  }

  void _updateAnimation() {
    final shouldAnimate =
        widget.animate && AccessibilityManager.instance.shouldAnimate(context);

    if (shouldAnimate && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!shouldAnimate && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 0.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
