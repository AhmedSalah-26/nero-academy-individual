import 'package:flutter/material.dart';
import 'package:lms_platform/core/animations/foundation/animation_config.dart';
import 'package:lms_platform/core/animations/foundation/accessibility_manager.dart';

/// A floating action button that shows/hides based on scroll direction
///
/// Hides when scrolling down, shows when scrolling up or at the top.
/// Useful for keeping the FAB out of the way during scrolling.
///
/// Example:
/// ```dart
/// AnimatedFAB(
///   scrollController: _scrollController,
///   onPressed: () => print('FAB pressed'),
///   child: Icon(Icons.add),
/// )
/// ```
class AnimatedFAB extends StatefulWidget {
  /// The child widget (typically an Icon)
  final Widget child;

  /// Callback when FAB is pressed
  final VoidCallback onPressed;

  /// Scroll controller to listen to
  final ScrollController scrollController;

  /// Scroll offset threshold to trigger hide
  final double hideOffset;

  /// Duration of show/hide animation
  final Duration duration;

  /// Background color of the FAB
  final Color? backgroundColor;

  /// Foreground color of the FAB
  final Color? foregroundColor;

  /// Tooltip text
  final String? tooltip;

  /// Hero tag for hero animations
  final Object? heroTag;

  const AnimatedFAB({
    super.key,
    required this.child,
    required this.onPressed,
    required this.scrollController,
    this.hideOffset = 100.0,
    Duration? duration,
    this.backgroundColor,
    this.foregroundColor,
    this.tooltip,
    this.heroTag,
  }) : duration = duration ?? const Duration(milliseconds: 300);

  @override
  State<AnimatedFAB> createState() => _AnimatedFABState();
}

class _AnimatedFABState extends State<AnimatedFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  bool _isVisible = true;
  double _lastScrollOffset = 0.0;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_initialized) {
      _initialized = true;
      final config = AnimationConfig.instance;
      final shouldAnimate =
          AccessibilityManager.instance.shouldAnimate(context);

      _controller = AnimationController(
        vsync: this,
        duration: shouldAnimate ? widget.duration : Duration.zero,
      );

      _slideAnimation = Tween<Offset>(
        begin: const Offset(0, 2),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: config.emphasizedCurve,
      ));

      _scaleAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: config.emphasizedCurve,
      ));

      _controller.value = 1.0; // Start visible

      widget.scrollController.addListener(_onScroll);
    }
  }

  void _onScroll() {
    if (!mounted) return;

    final currentOffset = widget.scrollController.offset;
    final scrollDelta = currentOffset - _lastScrollOffset;
    _lastScrollOffset = currentOffset;

    // Determine if FAB should be visible
    bool shouldBeVisible;

    if (currentOffset <= widget.hideOffset) {
      // Always show at top
      shouldBeVisible = true;
    } else if (scrollDelta < 0) {
      // Scrolling up - show
      shouldBeVisible = true;
    } else if (scrollDelta > 0) {
      // Scrolling down - hide
      shouldBeVisible = false;
    } else {
      // No scroll change - maintain current state
      shouldBeVisible = _isVisible;
    }

    if (shouldBeVisible != _isVisible) {
      setState(() {
        _isVisible = shouldBeVisible;
      });

      if (_isVisible) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!AccessibilityManager.instance.shouldAnimate(context)) {
      // If animations disabled, just show/hide without animation
      return _isVisible
          ? FloatingActionButton(
              onPressed: widget.onPressed,
              backgroundColor: widget.backgroundColor,
              foregroundColor: widget.foregroundColor,
              tooltip: widget.tooltip,
              heroTag: widget.heroTag,
              child: widget.child,
            )
          : const SizedBox.shrink();
    }

    return SlideTransition(
      position: _slideAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: FloatingActionButton(
          onPressed: widget.onPressed,
          backgroundColor: widget.backgroundColor,
          foregroundColor: widget.foregroundColor,
          tooltip: widget.tooltip,
          heroTag: widget.heroTag,
          child: widget.child,
        ),
      ),
    );
  }
}
