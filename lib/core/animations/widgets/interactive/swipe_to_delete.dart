import 'package:flutter/material.dart';
import 'package:lms_platform/core/animations/foundation/rtl_handler.dart';
import 'package:lms_platform/core/animations/foundation/accessibility_manager.dart';

/// A widget that allows swipe-to-delete gesture
///
/// Swipe left or right to reveal a delete action. Useful for lists
/// where items can be removed (cart items, notifications, etc.).
///
/// Example:
/// ```dart
/// SwipeToDelete(
///   onDelete: () => removeItem(item),
///   child: ListTile(
///     title: Text('Swipe me to delete'),
///   ),
/// )
/// ```
class SwipeToDelete extends StatelessWidget {
  /// Stable key for the inner Dismissible widget
  final Key dismissKey;

  /// The child widget to make swipeable
  final Widget child;

  /// Callback when item is deleted
  final VoidCallback onDelete;

  /// Background color when swiping
  final Color backgroundColor;

  /// Icon to show when swiping
  final Widget? deleteIcon;

  /// Threshold to trigger delete (0.0 to 1.0)
  final double dismissThreshold;

  /// Direction to allow swipe
  final DismissDirection direction;

  const SwipeToDelete({
    super.key,
    required this.dismissKey,
    required this.child,
    required this.onDelete,
    this.backgroundColor = Colors.red,
    this.deleteIcon,
    this.dismissThreshold = 0.4,
    this.direction = DismissDirection.horizontal,
  });

  @override
  Widget build(BuildContext context) {
    const rtlHandler = RTLHandler();
    final isRTL = rtlHandler.isRTL(context);
    final shouldAnimate = AccessibilityManager.instance.shouldAnimate(context);

    // Adjust direction for RTL
    DismissDirection effectiveDirection = direction;
    if (isRTL && direction == DismissDirection.horizontal) {
      // In RTL, we keep horizontal but the visual direction is reversed
      effectiveDirection = DismissDirection.horizontal;
    }

    return Dismissible(
      key: dismissKey,
      direction: effectiveDirection,
      dismissThresholds: {
        DismissDirection.startToEnd: dismissThreshold,
        DismissDirection.endToStart: dismissThreshold,
      },
      onDismissed: (direction) {
        onDelete();
      },
      background: _buildBackground(context, isRTL, true),
      secondaryBackground: _buildBackground(context, isRTL, false),
      movementDuration:
          shouldAnimate ? const Duration(milliseconds: 200) : Duration.zero,
      resizeDuration:
          shouldAnimate ? const Duration(milliseconds: 300) : Duration.zero,
      child: child,
    );
  }

  Widget _buildBackground(BuildContext context, bool isRTL, bool isPrimary) {
    final alignment = isPrimary
        ? (isRTL ? Alignment.centerRight : Alignment.centerLeft)
        : (isRTL ? Alignment.centerLeft : Alignment.centerRight);

    return Container(
      color: backgroundColor,
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: deleteIcon ??
          const Icon(
            Icons.delete,
            color: Colors.white,
            size: 32,
          ),
    );
  }
}
