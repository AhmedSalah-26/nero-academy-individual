import 'package:flutter/material.dart';
import 'package:lms_platform/core/animations/foundation/foundation.dart';

/// Base class for all entry animations
/// Provides common functionality for animation lifecycle and accessibility
abstract class EntryAnimation extends StatefulWidget {
  /// The child widget to animate
  final Widget child;

  /// Animation duration (uses config default if null)
  final Duration? duration;

  /// Delay before animation starts
  final Duration delay;

  /// Animation curve (uses config default if null)
  final Curve? curve;

  /// Whether to animate (if false, shows final state immediately)
  final bool animate;

  const EntryAnimation({
    super.key,
    required this.child,
    this.duration,
    this.delay = Duration.zero,
    this.curve,
    this.animate = true,
  });
}

/// Base state for entry animations with common lifecycle management
abstract class EntryAnimationState<T extends EntryAnimation> extends State<T>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  bool _shouldAnimate = true;
  bool _initialized = false;

  /// Get the effective duration considering accessibility settings
  Duration get effectiveDuration {
    final configDuration =
        widget.duration ?? AnimationConfig.instance.mediumDuration;

    if (!_shouldAnimate) {
      return Duration.zero;
    }

    // Use a safe default if context is not available yet
    try {
      return AccessibilityManager.instance.adjustDuration(
        context,
        configDuration,
      );
    } catch (e) {
      return configDuration;
    }
  }

  /// Get the effective curve
  Curve get effectiveCurve {
    return widget.curve ?? AnimationConfig.instance.standardCurve;
  }

  /// Check if animation should play
  bool get shouldAnimate {
    if (!widget.animate) return false;
    try {
      return AccessibilityManager.instance.shouldAnimate(context);
    } catch (e) {
      return true; // Default to animating if context not available
    }
  }

  @override
  void initState() {
    super.initState();

    // Initialize with default values
    _shouldAnimate = widget.animate;

    controller = AnimationController(
      vsync: this,
      duration: widget.duration ?? AnimationConfig.instance.mediumDuration,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_initialized) {
      _initialized = true;

      // Update with accessibility-aware values
      _shouldAnimate = shouldAnimate;
      controller.duration = effectiveDuration;

      // Start animation after delay
      if (_shouldAnimate) {
        if (widget.delay == Duration.zero) {
          controller.forward();
        } else {
          Future.delayed(widget.delay, () {
            if (mounted) controller.forward();
          });
        }
      } else {
        // Skip to end if animations disabled
        controller.value = 1.0;
      }
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
