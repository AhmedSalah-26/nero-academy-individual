import 'package:flutter/material.dart';
import 'package:lms_platform/core/animations/foundation/foundation.dart';
import 'slide_fade_in.dart';

/// Staggered list animation widget
/// Animates list items with sequential delays for a cascading effect
class StaggeredList extends StatelessWidget {
  /// List of child widgets to animate
  final List<Widget> children;

  /// Delay between each item animation
  final Duration staggerDelay;

  /// Duration for each item animation
  final Duration? itemDuration;

  /// Curve for animations
  final Curve? curve;

  /// Custom animation builder for each item
  /// If null, uses default SlideFadeIn.fromBottom
  final Widget Function(Widget child, int index)? animationBuilder;

  const StaggeredList({
    super.key,
    required this.children,
    this.staggerDelay = const Duration(milliseconds: 50),
    this.itemDuration,
    this.curve,
    this.animationBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final accessibilityManager = AccessibilityManager.instance;
    final shouldAnimate = accessibilityManager.shouldAnimate(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children.asMap().entries.map((entry) {
        final index = entry.key;
        final child = entry.value;

        // If animations disabled, return child directly
        if (!shouldAnimate) {
          return child;
        }

        // Use custom builder if provided, otherwise use default
        if (animationBuilder != null) {
          return animationBuilder!(child, index);
        }

        // Default animation: slide fade from bottom
        return SlideFadeIn.fromBottom(
          delay: staggerDelay * index,
          duration: itemDuration,
          curve: curve,
          child: child,
        );
      }).toList(),
    );
  }
}

/// Staggered grid animation widget
/// Similar to StaggeredList but for grid layouts
class StaggeredGrid extends StatelessWidget {
  /// List of child widgets to animate
  final List<Widget> children;

  /// Delay between each item animation
  final Duration staggerDelay;

  /// Duration for each item animation
  final Duration? itemDuration;

  /// Curve for animations
  final Curve? curve;

  /// Number of columns in the grid
  final int crossAxisCount;

  /// Spacing between items
  final double spacing;

  /// Custom animation builder for each item
  final Widget Function(Widget child, int index)? animationBuilder;

  const StaggeredGrid({
    super.key,
    required this.children,
    this.staggerDelay = const Duration(milliseconds: 50),
    this.itemDuration,
    this.curve,
    this.crossAxisCount = 2,
    this.spacing = 8.0,
    this.animationBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final accessibilityManager = AccessibilityManager.instance;
    final shouldAnimate = accessibilityManager.shouldAnimate(context);

    return GridView.count(
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: spacing,
      crossAxisSpacing: spacing,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: children.asMap().entries.map((entry) {
        final index = entry.key;
        final child = entry.value;

        // If animations disabled, return child directly
        if (!shouldAnimate) {
          return child;
        }

        // Use custom builder if provided, otherwise use default
        if (animationBuilder != null) {
          return animationBuilder!(child, index);
        }

        // Default animation: slide fade from bottom
        return SlideFadeIn.fromBottom(
          delay: staggerDelay * index,
          duration: itemDuration,
          curve: curve,
          child: child,
        );
      }).toList(),
    );
  }
}
