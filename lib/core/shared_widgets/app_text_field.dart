import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lms_platform/core/theme/app_colors.dart';

/// Unified App TextField Widget
class AppTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? errorText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final int maxLines;
  final int? maxLength;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final void Function()? onTap;
  final FocusNode? focusNode;
  final bool autofocus;

  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.maxLength,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.focusNode,
    this.autofocus = false,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: textTheme.labelLarge?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: hasError
                      ? AppColors.error
                      : (isDark ? AppColors.grey300 : AppColors.grey700),
                ) ??
                TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: hasError
                      ? AppColors.error
                      : (isDark ? AppColors.grey300 : AppColors.grey700),
                ),
          ),
          const SizedBox(height: 8),
        ],
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: _isFocused && !hasError
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            obscureText: widget.obscureText,
            enabled: widget.enabled,
            readOnly: widget.readOnly,
            maxLines: widget.maxLines,
            maxLength: widget.maxLength,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            inputFormatters: widget.inputFormatters,
            validator: widget.validator,
            onChanged: widget.onChanged,
            onFieldSubmitted: widget.onSubmitted,
            onTap: widget.onTap,
            autofocus: widget.autofocus,
            style: textTheme.bodyLarge?.copyWith(
                  fontSize: 16,
                  color: isDark ? AppColors.white : AppColors.textMainLight,
                ) ??
                TextStyle(
                  fontSize: 16,
                  color: isDark ? AppColors.white : AppColors.textMainLight,
                ),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: (textTheme.bodyMedium ?? const TextStyle()).copyWith(
                color:
                    isDark ? AppColors.textHintDark : AppColors.textHintLight,
              ),
              errorText: widget.errorText,
              errorStyle: (textTheme.bodySmall ?? const TextStyle()).copyWith(
                fontSize: 12,
                color: AppColors.error,
              ),
              prefixIcon: widget.prefixIcon != null
                  ? Icon(
                      widget.prefixIcon,
                      color: hasError
                          ? AppColors.error
                          : (_isFocused
                              ? AppColors.primary
                              : (isDark
                                  ? AppColors.grey500
                                  : AppColors.grey400)),
                    )
                  : null,
              suffixIcon: widget.suffixIcon,
              filled: true,
              fillColor: isDark ? AppColors.cardDark : Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark ? AppColors.grey700 : AppColors.grey200,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark ? AppColors.grey700 : AppColors.grey200,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 1),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.error),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.error, width: 1),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark ? AppColors.grey800 : AppColors.grey100,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
