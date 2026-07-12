import 'package:flutter/material.dart';
import 'package:lms_platform/core/animations/foundation/accessibility_manager.dart';

/// A widget that creates a parallax scrolling effect for images
///
/// The image moves at a different rate than the scroll, creating
/// a depth effect. Useful for hero images, headers, and backgrounds.
///
/// Example:
/// ```dart
/// ParallaxImage(
///   image: NetworkImage('https://example.com/image.jpg'),
///   height: 300,
///   parallaxFactor: 0.5,
/// )
/// ```
class ParallaxImage extends StatelessWidget {
  /// The image to display
  final ImageProvider image;

  /// Height of the image container
  final double height;

  /// Parallax factor (0.0 = no parallax, 1.0 = full parallax)
  /// Higher values create more pronounced parallax effect
  final double parallaxFactor;

  /// Box fit for the image
  final BoxFit fit;

  /// Alignment of the image
  final Alignment alignment;

  const ParallaxImage({
    super.key,
    required this.image,
    required this.height,
    this.parallaxFactor = 0.5,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    final shouldAnimate = AccessibilityManager.instance.shouldAnimate(context);

    if (!shouldAnimate) {
      // If animations are disabled, show static image
      return SizedBox(
        height: height,
        child: Image(
          image: image,
          fit: fit,
          alignment: alignment,
        ),
      );
    }

    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Flow(
            delegate: _ParallaxFlowDelegate(
              scrollable: Scrollable.of(context),
              listItemContext: context,
              backgroundImageKey: GlobalKey(),
              parallaxFactor: parallaxFactor,
            ),
            children: [
              Image(
                image: image,
                fit: fit,
                alignment: alignment,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ParallaxFlowDelegate extends FlowDelegate {
  final ScrollableState scrollable;
  final BuildContext listItemContext;
  final GlobalKey backgroundImageKey;
  final double parallaxFactor;

  _ParallaxFlowDelegate({
    required this.scrollable,
    required this.listItemContext,
    required this.backgroundImageKey,
    required this.parallaxFactor,
  }) : super(repaint: scrollable.position);

  @override
  BoxConstraints getConstraintsForChild(int i, BoxConstraints constraints) {
    return BoxConstraints.tightFor(
      width: constraints.maxWidth,
      height: constraints.maxHeight * (1 + parallaxFactor),
    );
  }

  @override
  void paintChildren(FlowPaintingContext context) {
    // Calculate the position of this list item within the viewport
    final scrollableBox = scrollable.context.findRenderObject() as RenderBox;
    final listItemBox = listItemContext.findRenderObject() as RenderBox;

    if (!listItemBox.attached) {
      return;
    }

    final listItemOffset = listItemBox.localToGlobal(
      listItemBox.size.centerLeft(Offset.zero),
      ancestor: scrollableBox,
    );

    final viewportDimension = scrollable.position.viewportDimension;
    final scrollFraction =
        (listItemOffset.dy / viewportDimension).clamp(0.0, 1.0);

    // Calculate parallax offset
    final verticalAlignment = (scrollFraction - 0.5) * 2 * parallaxFactor;
    final backgroundSize = context.getChildSize(0)!;
    final listItemSize = context.size;

    final childRect = verticalAlignment.isNegative
        ? Alignment(0.0, verticalAlignment).inscribe(
            backgroundSize,
            Offset.zero & listItemSize,
          )
        : Alignment(0.0, verticalAlignment).inscribe(
            backgroundSize,
            Offset.zero & listItemSize,
          );

    // Paint the image with parallax offset
    context.paintChild(
      0,
      transform: Transform.translate(
        offset: Offset(0.0, childRect.top),
      ).transform,
    );
  }

  @override
  bool shouldRepaint(_ParallaxFlowDelegate oldDelegate) {
    return scrollable != oldDelegate.scrollable ||
        listItemContext != oldDelegate.listItemContext ||
        backgroundImageKey != oldDelegate.backgroundImageKey ||
        parallaxFactor != oldDelegate.parallaxFactor;
  }
}
