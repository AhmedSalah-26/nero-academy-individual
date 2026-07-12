import 'package:flutter/material.dart';
import 'package:lms_platform/core/animations/foundation/accessibility_manager.dart';

/// A card that can expand and collapse
///
/// Shows a header that can be tapped to reveal expanded content.
/// Useful for FAQs, course curriculum, settings groups, etc.
///
/// Example:
/// ```dart
/// ExpandableCard(
///   header: Text('Click to expand'),
///   expandedContent: Text('Hidden content here'),
///   initiallyExpanded: false,
/// )
/// ```
class ExpandableCard extends StatefulWidget {
  /// Widget to show as the header (always visible)
  final Widget header;

  /// Widget to show when expanded
  final Widget expandedContent;

  /// Whether to start expanded
  final bool initiallyExpanded;

  /// Duration of expand/collapse animation
  final Duration duration;

  /// Curve for the animation
  final Curve curve;

  /// Callback when expansion state changes
  final void Function(bool isExpanded)? onExpansionChanged;

  /// Background color
  final Color? backgroundColor;

  /// Border radius
  final BorderRadius? borderRadius;

  /// Padding for header
  final EdgeInsets? headerPadding;

  /// Padding for content
  final EdgeInsets? contentPadding;

  /// Icon to show for expand/collapse
  final Widget? expandIcon;

  const ExpandableCard({
    super.key,
    required this.header,
    required this.expandedContent,
    this.initiallyExpanded = false,
    Duration? duration,
    Curve? curve,
    this.onExpansionChanged,
    this.backgroundColor,
    this.borderRadius,
    this.headerPadding,
    this.contentPadding,
    this.expandIcon,
  })  : duration = duration ?? const Duration(milliseconds: 300),
        curve = curve ?? Curves.easeInOut;

  @override
  State<ExpandableCard> createState() => _ExpandableCardState();
}

class _ExpandableCardState extends State<ExpandableCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _heightFactor;
  late Animation<double> _iconRotation;
  late bool _isExpanded;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_initialized) {
      _initialized = true;
      final shouldAnimate =
          AccessibilityManager.instance.shouldAnimate(context);

      _controller = AnimationController(
        vsync: this,
        duration: shouldAnimate ? widget.duration : Duration.zero,
      );

      _heightFactor = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: widget.curve,
      ));

      _iconRotation = Tween<double>(
        begin: 0.0,
        end: 0.5, // 180 degrees (0.5 * pi * 2)
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: widget.curve,
      ));

      if (_isExpanded) {
        _controller.value = 1.0;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
    });

    if (_isExpanded) {
      _controller.forward();
    } else {
      _controller.reverse();
    }

    if (widget.onExpansionChanged != null) {
      widget.onExpansionChanged!(_isExpanded);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: widget.backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header (always visible)
          InkWell(
            onTap: _toggleExpansion,
            borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
            child: Padding(
              padding: widget.headerPadding ??
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(child: widget.header),
                  RotationTransition(
                    turns: _iconRotation,
                    child: widget.expandIcon ??
                        Icon(
                          Icons.expand_more,
                          color: theme.iconTheme.color,
                        ),
                  ),
                ],
              ),
            ),
          ),
          // Expanded content
          ClipRect(
            child: AnimatedBuilder(
              animation: _heightFactor,
              builder: (context, child) {
                return Align(
                  alignment: Alignment.topCenter,
                  heightFactor: _heightFactor.value,
                  child: child,
                );
              },
              child: Padding(
                padding: widget.contentPadding ??
                    const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: widget.expandedContent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
