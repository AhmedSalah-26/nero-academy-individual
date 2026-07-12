import 'package:flutter/material.dart';
import 'package:lms_platform/core/animations/foundation/foundation.dart';

/// Animated tab view widget
/// Smoothly transitions between tabs with cross-fade animation
class AnimatedTabView extends StatelessWidget {
  /// Current tab index
  final int currentIndex;

  /// List of tab content widgets
  final List<Widget> children;

  /// Animation duration
  final Duration duration;

  /// Animation curve
  final Curve curve;

  const AnimatedTabView({
    super.key,
    required this.currentIndex,
    required this.children,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
  });

  @override
  Widget build(BuildContext context) {
    final shouldAnimate = AccessibilityManager.instance.shouldAnimate(context);
    final effectiveDuration = shouldAnimate ? duration : Duration.zero;

    return AnimatedSwitcher(
      duration: effectiveDuration,
      switchInCurve: curve,
      switchOutCurve: curve,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      child: KeyedSubtree(
        key: ValueKey<int>(currentIndex),
        child: children[currentIndex],
      ),
    );
  }
}

/// Animated indexed stack
/// Similar to IndexedStack but with animations
class AnimatedIndexedStack extends StatefulWidget {
  /// Current index
  final int index;

  /// List of children
  final List<Widget> children;

  /// Animation duration
  final Duration duration;

  /// Animation curve
  final Curve curve;

  /// Transition type
  final StackTransitionType transitionType;

  const AnimatedIndexedStack({
    super.key,
    required this.index,
    required this.children,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
    this.transitionType = StackTransitionType.fade,
  });

  @override
  State<AnimatedIndexedStack> createState() => _AnimatedIndexedStackState();
}

class _AnimatedIndexedStackState extends State<AnimatedIndexedStack>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int _previousIndex = 0;

  @override
  void initState() {
    super.initState();
    _previousIndex = widget.index;

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );

    _controller.value = 1.0;
  }

  @override
  void didUpdateWidget(AnimatedIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.index != oldWidget.index) {
      _previousIndex = oldWidget.index;
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shouldAnimate = AccessibilityManager.instance.shouldAnimate(context);

    if (!shouldAnimate) {
      return IndexedStack(
        index: widget.index,
        children: widget.children,
      );
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Stack(
          children: [
            // Previous child (fading out)
            if (_animation.value < 1.0)
              _buildTransition(
                widget.children[_previousIndex],
                1.0 - _animation.value,
                false,
              ),
            // Current child (fading in)
            _buildTransition(
              widget.children[widget.index],
              _animation.value,
              true,
            ),
          ],
        );
      },
    );
  }

  Widget _buildTransition(Widget child, double value, bool isEntering) {
    switch (widget.transitionType) {
      case StackTransitionType.fade:
        return Opacity(
          opacity: value,
          child: child,
        );

      case StackTransitionType.scale:
        return Opacity(
          opacity: value,
          child: Transform.scale(
            scale: 0.9 + (value * 0.1),
            child: child,
          ),
        );

      case StackTransitionType.slide:
        final offset = isEntering
            ? Offset(0.3 * (1 - value), 0)
            : Offset(-0.3 * (1 - value), 0);
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: offset,
            child: child,
          ),
        );
    }
  }
}

/// Stack transition types
enum StackTransitionType {
  /// Fade transition
  fade,

  /// Scale transition
  scale,

  /// Slide transition
  slide,
}
