import 'package:flutter/material.dart';
import 'package:lms_platform/core/animations/foundation/foundation.dart';

/// Bounce icon animation widget
/// Triggers a bounce animation when the trigger value changes
class BounceIcon extends StatefulWidget {
  /// The icon to display
  final IconData icon;

  /// Icon size
  final double size;

  /// Icon color
  final Color? color;

  /// Trigger to start animation (change this value to trigger)
  final bool trigger;

  /// Animation duration
  final Duration duration;

  /// Bounce intensity (how much to scale up)
  final double intensity;

  const BounceIcon({
    super.key,
    required this.icon,
    this.size = 24.0,
    this.color,
    this.trigger = false,
    this.duration = const Duration(milliseconds: 300),
    this.intensity = 1.3,
  });

  @override
  State<BounceIcon> createState() => _BounceIconState();
}

class _BounceIconState extends State<BounceIcon>
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

    // Bounce sequence: scale up, overshoot, settle back
    _animation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: widget.intensity),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(begin: widget.intensity, end: 0.9),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.9, end: 1.0),
        weight: 40,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void didUpdateWidget(BounceIcon oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Trigger animation when trigger value changes from false to true
    if (widget.trigger && !oldWidget.trigger) {
      final shouldAnimate =
          AccessibilityManager.instance.shouldAnimate(context);
      if (shouldAnimate) {
        _controller.forward(from: 0);
      }
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
      child: Icon(
        widget.icon,
        size: widget.size,
        color: widget.color,
      ),
    );
  }
}
