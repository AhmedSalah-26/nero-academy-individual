import 'package:flutter/material.dart';
import 'package:lms_platform/core/animations/foundation/foundation.dart';

/// Error shake animation widget
/// Shakes the child widget horizontally to indicate an error
class ErrorShake extends StatefulWidget {
  /// The child widget to shake
  final Widget child;

  /// Trigger to start the shake animation
  final bool trigger;

  /// Number of shakes
  final int shakeCount;

  /// Shake offset (distance to shake)
  final double offset;

  /// Animation duration
  final Duration duration;

  const ErrorShake({
    super.key,
    required this.child,
    this.trigger = false,
    this.shakeCount = 3,
    this.offset = 10.0,
    this.duration = const Duration(milliseconds: 500),
  });

  @override
  State<ErrorShake> createState() => _ErrorShakeState();
}

class _ErrorShakeState extends State<ErrorShake>
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

    _animation = _createShakeAnimation();
  }

  Animation<double> _createShakeAnimation() {
    // Create a shake pattern: 0 -> 1 -> -1 -> 1 -> -1 -> 0
    final shakeCount = widget.shakeCount;
    final items = <TweenSequenceItem<double>>[];

    // Start at 0
    items.add(TweenSequenceItem(
      tween: Tween(begin: 0.0, end: 1.0),
      weight: 1,
    ));

    // Alternate between positive and negative
    for (int i = 0; i < shakeCount; i++) {
      items.add(TweenSequenceItem(
        tween: Tween(begin: 1.0, end: -1.0),
        weight: 1,
      ));
      items.add(TweenSequenceItem(
        tween: Tween(begin: -1.0, end: 1.0),
        weight: 1,
      ));
    }

    // End at 0
    items.add(TweenSequenceItem(
      tween: Tween(begin: 1.0, end: 0.0),
      weight: 1,
    ));

    return TweenSequence<double>(items).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void didUpdateWidget(ErrorShake oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Trigger animation when trigger changes from false to true
    if (widget.trigger && !oldWidget.trigger) {
      final shouldAnimate =
          AccessibilityManager.instance.shouldAnimate(context);
      if (shouldAnimate) {
        _controller.forward(from: 0.0);
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
        return Transform.translate(
          offset: Offset(_animation.value * widget.offset, 0),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
