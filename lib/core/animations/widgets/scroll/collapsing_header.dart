import 'package:flutter/material.dart';
import 'package:lms_platform/core/animations/foundation/accessibility_manager.dart';

/// A widget that collapses a header based on scroll position
///
/// Transitions between an expanded and collapsed state as the user scrolls.
/// Useful for app bars, headers, and hero sections.
///
/// Example:
/// ```dart
/// CollapsingHeader(
///   expandedWidget: Image.network('header.jpg'),
///   collapsedWidget: Text('Course Title'),
///   expandedHeight: 200,
///   collapsedHeight: 56,
///   scrollController: _scrollController,
/// )
/// ```
class CollapsingHeader extends StatefulWidget {
  /// Widget to show when expanded
  final Widget expandedWidget;

  /// Widget to show when collapsed
  final Widget collapsedWidget;

  /// Height when fully expanded
  final double expandedHeight;

  /// Height when fully collapsed
  final double collapsedHeight;

  /// Scroll controller to listen to
  final ScrollController scrollController;

  /// Background color
  final Color? backgroundColor;

  /// Whether to show elevation when collapsed
  final bool showElevation;

  const CollapsingHeader({
    super.key,
    required this.expandedWidget,
    required this.collapsedWidget,
    required this.expandedHeight,
    required this.collapsedHeight,
    required this.scrollController,
    this.backgroundColor,
    this.showElevation = true,
  });

  @override
  State<CollapsingHeader> createState() => _CollapsingHeaderState();
}

class _CollapsingHeaderState extends State<CollapsingHeader> {
  double _scrollProgress = 0.0;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!mounted) return;

    final shouldAnimate = AccessibilityManager.instance.shouldAnimate(context);
    if (!shouldAnimate) {
      // If animations disabled, snap to collapsed or expanded
      setState(() {
        _scrollProgress = widget.scrollController.offset > 0 ? 1.0 : 0.0;
      });
      return;
    }

    final offset = widget.scrollController.offset;
    final maxScroll = widget.expandedHeight - widget.collapsedHeight;

    setState(() {
      _scrollProgress = (offset / maxScroll).clamp(0.0, 1.0);
    });
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentHeight = widget.expandedHeight -
        (widget.expandedHeight - widget.collapsedHeight) * _scrollProgress;

    final expandedOpacity = 1.0 - _scrollProgress;
    final collapsedOpacity = _scrollProgress;

    final elevation = widget.showElevation ? _scrollProgress * 4.0 : 0.0;

    return Material(
      elevation: elevation,
      color:
          widget.backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
      child: SizedBox(
        height: currentHeight,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Expanded widget (fades out)
            Opacity(
              opacity: expandedOpacity,
              child: widget.expandedWidget,
            ),
            // Collapsed widget (fades in)
            Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox(
                height: widget.collapsedHeight,
                child: Opacity(
                  opacity: collapsedOpacity,
                  child: widget.collapsedWidget,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
