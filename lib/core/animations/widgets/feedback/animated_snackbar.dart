import 'package:flutter/material.dart';
import 'package:lms_platform/core/animations/foundation/accessibility_manager.dart';

/// Type of snackbar to display
enum SnackbarType {
  /// Success message (green)
  success,

  /// Error message (red)
  error,

  /// Warning message (orange)
  warning,

  /// Info message (blue)
  info,
}

/// Helper class for showing animated snackbars
///
/// Provides a convenient way to show snackbars with slide animations
/// and different types (success, error, warning, info).
///
/// Example:
/// ```dart
/// AnimatedSnackbar.show(
///   context: context,
///   message: 'Course added to cart!',
///   type: SnackbarType.success,
///   duration: Duration(seconds: 3),
/// );
/// ```
class AnimatedSnackbar {
  /// Show an animated snackbar
  static void show({
    required BuildContext context,
    required String message,
    SnackbarType type = SnackbarType.info,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onDismissed,
    String? actionLabel,
    VoidCallback? onActionPressed,
  }) {
    final shouldAnimate = AccessibilityManager.instance.shouldAnimate(context);

    // Get colors based on type
    final colors = _getColorsForType(type, context);

    // Get icon based on type
    final icon = _getIconForType(type);

    final snackBar = SnackBar(
      content: Row(
        children: [
          Icon(
            icon,
            color: colors.iconColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: colors.textColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: colors.backgroundColor,
      behavior: SnackBarBehavior.floating,
      duration: duration,
      action: actionLabel != null
          ? SnackBarAction(
              label: actionLabel,
              textColor: colors.actionColor,
              onPressed: onActionPressed ?? () {},
            )
          : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.all(16),
      elevation: 6,
      // Animation duration
      animation: shouldAnimate
          ? null // Use default animation
          : const AlwaysStoppedAnimation(1.0), // Skip animation
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar).closed.then((reason) {
      if (onDismissed != null) {
        onDismissed();
      }
    });
  }

  /// Show a success snackbar
  static void showSuccess({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onDismissed,
  }) {
    show(
      context: context,
      message: message,
      type: SnackbarType.success,
      duration: duration,
      onDismissed: onDismissed,
    );
  }

  /// Show an error snackbar
  static void showError({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onDismissed,
    String? actionLabel,
    VoidCallback? onActionPressed,
  }) {
    show(
      context: context,
      message: message,
      type: SnackbarType.error,
      duration: duration,
      onDismissed: onDismissed,
      actionLabel: actionLabel,
      onActionPressed: onActionPressed,
    );
  }

  /// Show a warning snackbar
  static void showWarning({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onDismissed,
  }) {
    show(
      context: context,
      message: message,
      type: SnackbarType.warning,
      duration: duration,
      onDismissed: onDismissed,
    );
  }

  /// Show an info snackbar
  static void showInfo({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onDismissed,
  }) {
    show(
      context: context,
      message: message,
      type: SnackbarType.info,
      duration: duration,
      onDismissed: onDismissed,
    );
  }

  static _SnackbarColors _getColorsForType(
    SnackbarType type,
    BuildContext context,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    switch (type) {
      case SnackbarType.success:
        return _SnackbarColors(
          backgroundColor:
              isDark ? Colors.green.shade800 : Colors.green.shade600,
          textColor: Colors.white,
          iconColor: Colors.white,
          actionColor: Colors.white,
        );
      case SnackbarType.error:
        return _SnackbarColors(
          backgroundColor: isDark ? Colors.red.shade800 : Colors.red.shade600,
          textColor: Colors.white,
          iconColor: Colors.white,
          actionColor: Colors.white,
        );
      case SnackbarType.warning:
        return _SnackbarColors(
          backgroundColor:
              isDark ? Colors.orange.shade800 : Colors.orange.shade600,
          textColor: Colors.white,
          iconColor: Colors.white,
          actionColor: Colors.white,
        );
      case SnackbarType.info:
        return _SnackbarColors(
          backgroundColor: isDark ? Colors.blue.shade800 : Colors.blue.shade600,
          textColor: Colors.white,
          iconColor: Colors.white,
          actionColor: Colors.white,
        );
    }
  }

  static IconData _getIconForType(SnackbarType type) {
    switch (type) {
      case SnackbarType.success:
        return Icons.check_circle;
      case SnackbarType.error:
        return Icons.error;
      case SnackbarType.warning:
        return Icons.warning;
      case SnackbarType.info:
        return Icons.info;
    }
  }
}

class _SnackbarColors {
  final Color backgroundColor;
  final Color textColor;
  final Color iconColor;
  final Color actionColor;

  const _SnackbarColors({
    required this.backgroundColor,
    required this.textColor,
    required this.iconColor,
    required this.actionColor,
  });
}
