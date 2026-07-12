import 'package:flutter/material.dart';
import 'package:lms_platform/core/animations/foundation/foundation.dart';
import 'base_entry_animation.dart';

/// Slide and fade in animation widget with RTL support
/// Combines slide and fade animations for smooth entry effects
class SlideFadeIn extends EntryAnimation {
  /// Starting offset for slide animation
  final Offset begin;

  /// Ending offset for slide animation
  final Offset end;

  /// Starting opacity value
  final double fadeBegin;

  /// Ending opacity value
  final double fadeEnd;

  /// Whether to use RTL-aware positioning
  final bool useRTL;

  const SlideFadeIn({
    super.key,
    required super.child,
    this.begin = const Offset(0, 0.5),
    this.end = Offset.zero,
    this.fadeBegin = 0.0,
    this.fadeEnd = 1.0,
    super.duration,
    super.delay,
    super.curve,
    super.animate,
    this.useRTL = false,
  });

  /// Slide from start (left in LTR, right in RTL)
  factory SlideFadeIn.fromStart({
    Key? key,
    required Widget child,
    Duration? duration,
    Duration delay = Duration.zero,
    Curve? curve,
    bool animate = true,
    double distance = 0.3,
  }) {
    return SlideFadeIn(
      key: key,
      begin: Offset(-distance, 0),
      duration: duration,
      delay: delay,
      curve: curve,
      animate: animate,
      useRTL: true,
      child: child,
    );
  }

  /// Slide from end (right in LTR, left in RTL)
  factory SlideFadeIn.fromEnd({
    Key? key,
    required Widget child,
    Duration? duration,
    Duration delay = Duration.zero,
    Curve? curve,
    bool animate = true,
    double distance = 0.3,
  }) {
    return SlideFadeIn(
      key: key,
      begin: Offset(distance, 0),
      duration: duration,
      delay: delay,
      curve: curve,
      animate: animate,
      useRTL: true,
      child: child,
    );
  }

  /// Slide from top
  factory SlideFadeIn.fromTop({
    Key? key,
    required Widget child,
    Duration? duration,
    Duration delay = Duration.zero,
    Curve? curve,
    bool animate = true,
    double distance = 0.3,
  }) {
    return SlideFadeIn(
      key: key,
      begin: Offset(0, -distance),
      duration: duration,
      delay: delay,
      curve: curve,
      animate: animate,
      child: child,
    );
  }

  /// Slide from bottom
  factory SlideFadeIn.fromBottom({
    Key? key,
    required Widget child,
    Duration? duration,
    Duration delay = Duration.zero,
    Curve? curve,
    bool animate = true,
    double distance = 0.3,
  }) {
    return SlideFadeIn(
      key: key,
      begin: Offset(0, distance),
      duration: duration,
      delay: delay,
      curve: curve,
      animate: animate,
      child: child,
    );
  }

  @override
  State<SlideFadeIn> createState() => _SlideFadeInState();
}

class _SlideFadeInState extends EntryAnimationState<SlideFadeIn> {
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  final RTLHandler _rtlHandler = const RTLHandler();

  @override
  void initState() {
    super.initState();

    _fadeAnimation = Tween<double>(
      begin: widget.fadeBegin,
      end: widget.fadeEnd,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: effectiveCurve,
      ),
    );

    // Slide animation will be created in build to access context for RTL
  }

  @override
  Widget build(BuildContext context) {
    // Adjust offset for RTL if needed
    final beginOffset = widget.useRTL
        ? _rtlHandler.adjustOffset(widget.begin, context)
        : widget.begin;

    _slideAnimation = Tween<Offset>(
      begin: beginOffset,
      end: widget.end,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: effectiveCurve,
      ),
    );

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}
