import 'package:flutter/material.dart';
import 'package:lms_platform/core/theme/app_colors.dart';

/// Responsive Dialog Widget
///
/// A dialog that adapts to screen size and prevents full-screen dialogs on mobile
class ResponsiveDialog extends StatelessWidget {
  final Widget? title;
  final Widget? content;
  final List<Widget>? actions;
  final EdgeInsetsGeometry? contentPadding;
  final EdgeInsetsGeometry? actionsPadding;
  final EdgeInsetsGeometry? titlePadding;
  final MainAxisAlignment? actionsAlignment;
  final bool scrollable;
  final Color? backgroundColor;
  final ShapeBorder? shape;
  final double? maxWidth;
  final double? maxHeight;

  const ResponsiveDialog({
    super.key,
    this.title,
    this.content,
    this.actions,
    this.contentPadding,
    this.actionsPadding,
    this.titlePadding,
    this.actionsAlignment,
    this.scrollable = false,
    this.backgroundColor,
    this.shape,
    this.maxWidth,
    this.maxHeight,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Calculate responsive width
    final dialogWidth = maxWidth ?? _calculateWidth(screenWidth);
    final dialogHeight = maxHeight ?? screenHeight * 0.8;

    return Dialog(
      backgroundColor:
          backgroundColor ?? (isDark ? AppColors.cardDark : AppColors.white),
      shape: shape ??
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogWidth,
          maxHeight: dialogHeight,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null)
              Padding(
                padding:
                    titlePadding ?? const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: DefaultTextStyle(
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.textMainDark
                        : AppColors.textMainLight,
                  ),
                  child: title!,
                ),
              ),
            if (content != null)
              Flexible(
                child: SingleChildScrollView(
                  padding: contentPadding ??
                      const EdgeInsets.symmetric(horizontal: 24),
                  child: DefaultTextStyle(
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? AppColors.textMutedDark
                          : AppColors.textMutedLight,
                    ),
                    child: content!,
                  ),
                ),
              ),
            if (actions != null && actions!.isNotEmpty)
              Padding(
                padding:
                    actionsPadding ?? const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Row(
                  mainAxisAlignment: actionsAlignment ?? MainAxisAlignment.end,
                  children: actions!,
                ),
              ),
          ],
        ),
      ),
    );
  }

  double _calculateWidth(double screenWidth) {
    if (screenWidth < 600) {
      // Mobile: 90% of screen width
      return screenWidth * 0.9;
    } else if (screenWidth < 900) {
      // Tablet: 70% of screen width
      return screenWidth * 0.7;
    } else {
      // Desktop: Fixed width
      return 500;
    }
  }
}

/// Show Responsive Dialog Helper
Future<T?> showResponsiveDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  Color? barrierColor,
  String? barrierLabel,
  bool useSafeArea = true,
  bool useRootNavigator = true,
  RouteSettings? routeSettings,
}) {
  return showDialog<T>(
    context: context,
    builder: builder,
    barrierDismissible: barrierDismissible,
    barrierColor: barrierColor,
    barrierLabel: barrierLabel,
    useSafeArea: useSafeArea,
    useRootNavigator: useRootNavigator,
    routeSettings: routeSettings,
  );
}

/// Responsive Alert Dialog
///
/// A pre-configured responsive dialog for common alert scenarios
class ResponsiveAlertDialog extends StatelessWidget {
  final String? title;
  final String? content;
  final String? confirmText;
  final String? cancelText;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final Color? confirmColor;
  final bool isDestructive;

  const ResponsiveAlertDialog({
    super.key,
    this.title,
    this.content,
    this.confirmText,
    this.cancelText,
    this.onConfirm,
    this.onCancel,
    this.confirmColor,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ResponsiveDialog(
      title: title != null ? Text(title!) : null,
      content: content != null ? Text(content!) : null,
      actions: [
        if (cancelText != null)
          TextButton(
            onPressed: onCancel ?? () => Navigator.of(context).pop(false),
            child: Text(
              cancelText!,
              style: TextStyle(
                color:
                    isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              ),
            ),
          ),
        if (confirmText != null) ...[
          if (cancelText != null) const SizedBox(width: 8),
          ElevatedButton(
            onPressed: onConfirm ?? () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor ??
                  (isDestructive ? AppColors.error : AppColors.primary),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(confirmText!),
          ),
        ],
      ],
    );
  }
}
