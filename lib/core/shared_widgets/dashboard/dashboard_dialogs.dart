import 'package:flutter/material.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/core/shared_widgets/app_button.dart';

/// Dashboard Confirmation Dialog
class DashboardConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final Color? confirmColor;
  final IconData? icon;
  final bool isDestructive;

  const DashboardConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = 'Confirm',
    this.cancelText = 'Cancel',
    this.confirmColor,
    this.icon,
    this.isDestructive = false,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    Color? confirmColor,
    IconData? icon,
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => DashboardConfirmDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        confirmColor: confirmColor,
        icon: icon,
        isDestructive: isDestructive,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final buttonColor =
        confirmColor ?? (isDestructive ? AppColors.error : AppColors.primary);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: isDark ? AppColors.cardDark : AppColors.white,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: buttonColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: buttonColor, size: 28),
              ),
              const SizedBox(height: 16),
            ],
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color:
                    isDark ? AppColors.textMainDark : AppColors.textMainLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color:
                    isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: cancelText,
                    variant: AppButtonVariant.outline,
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    text: confirmText,
                    variant: isDestructive
                        ? AppButtonVariant.error
                        : AppButtonVariant.primary,
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Dashboard Input Dialog
class DashboardInputDialog extends StatefulWidget {
  final String title;
  final String? message;
  final String? hintText;
  final String? initialValue;
  final String confirmText;
  final String cancelText;
  final int maxLines;
  final bool isRequired;

  const DashboardInputDialog({
    super.key,
    required this.title,
    this.message,
    this.hintText,
    this.initialValue,
    this.confirmText = 'Submit',
    this.cancelText = 'Cancel',
    this.maxLines = 1,
    this.isRequired = true,
  });

  static Future<String?> show(
    BuildContext context, {
    required String title,
    String? message,
    String? hintText,
    String? initialValue,
    String confirmText = 'Submit',
    String cancelText = 'Cancel',
    int maxLines = 1,
    bool isRequired = true,
  }) {
    return showDialog<String>(
      context: context,
      builder: (context) => DashboardInputDialog(
        title: title,
        message: message,
        hintText: hintText,
        initialValue: initialValue,
        confirmText: confirmText,
        cancelText: cancelText,
        maxLines: maxLines,
        isRequired: isRequired,
      ),
    );
  }

  @override
  State<DashboardInputDialog> createState() => _DashboardInputDialogState();
}

class _DashboardInputDialogState extends State<DashboardInputDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    if (widget.isRequired && value.isEmpty) return;
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: isDark ? AppColors.cardDark : AppColors.white,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color:
                    isDark ? AppColors.textMainDark : AppColors.textMainLight,
              ),
            ),
            if (widget.message != null) ...[
              const SizedBox(height: 8),
              Text(
                widget.message!,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? AppColors.textMutedDark
                      : AppColors.textMutedLight,
                ),
              ),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              maxLines: widget.maxLines,
              autofocus: true,
              style: TextStyle(
                color:
                    isDark ? AppColors.textMainDark : AppColors.textMainLight,
              ),
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: TextStyle(
                  color:
                      isDark ? AppColors.textHintDark : AppColors.textHintLight,
                ),
                filled: true,
                fillColor: isDark ? AppColors.surfaceDark : AppColors.grey50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color:
                        isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color:
                        isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: widget.cancelText,
                    variant: AppButtonVariant.outline,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    text: widget.confirmText,
                    onPressed: _submit,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
