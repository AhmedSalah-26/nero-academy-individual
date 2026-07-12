import 'package:flutter/material.dart';
import 'package:lms_platform/core/animations/foundation/foundation.dart';

/// Shimmer effect widget
/// Adds an animated gradient shimmer to skeleton loaders
class ShimmerEffect extends StatefulWidget {
  /// The child widget to apply shimmer to
  final Widget child;

  /// Base color (background)
  final Color baseColor;

  /// Highlight color (shimmer)
  final Color highlightColor;

  /// Animation duration
  final Duration duration;

  /// Whether shimmer is enabled
  final bool enabled;

  const ShimmerEffect({
    super.key,
    required this.child,
    this.baseColor = const Color(0xFFE0E0E0),
    this.highlightColor = const Color(0xFFF5F5F5),
    this.duration = const Duration(milliseconds: 1500),
    this.enabled = true,
  });

  @override
  State<ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<ShimmerEffect>
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

    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.linear,
      ),
    );

    if (widget.enabled) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(ShimmerEffect oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.enabled != oldWidget.enabled) {
      if (widget.enabled) {
        _controller.repeat();
      } else {
        _controller.stop();
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
    if (!widget.enabled) {
      return widget.child;
    }

    final shouldAnimate = AccessibilityManager.instance.shouldAnimate(context);
    if (!shouldAnimate) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: [
                (_animation.value - 0.5).clamp(0.0, 1.0),
                _animation.value.clamp(0.0, 1.0),
                (_animation.value + 0.5).clamp(0.0, 1.0),
              ],
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Shimmer container widget
/// Combines skeleton and shimmer in one widget
class ShimmerContainer extends StatelessWidget {
  /// Width of the container
  final double width;

  /// Height of the container
  final double height;

  /// Border radius
  final BorderRadius? borderRadius;

  /// Base color
  final Color? baseColor;

  /// Highlight color
  final Color? highlightColor;

  /// Whether shimmer is enabled
  final bool enabled;

  const ShimmerContainer({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
    this.baseColor,
    this.highlightColor,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final effectiveBaseColor =
        baseColor ?? (isDark ? Colors.grey[800]! : const Color(0xFFE0E0E0));
    final effectiveHighlightColor = highlightColor ??
        (isDark ? Colors.grey[700]! : const Color(0xFFF5F5F5));

    return ShimmerEffect(
      baseColor: effectiveBaseColor,
      highlightColor: effectiveHighlightColor,
      enabled: enabled,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: effectiveBaseColor,
          borderRadius: borderRadius,
        ),
      ),
    );
  }
}
