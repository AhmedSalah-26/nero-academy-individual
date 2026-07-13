import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:lms_platform/core/theme/app_colors.dart';

class GlassSearchBar extends StatelessWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final VoidCallback? onClear;
  final Widget? trailing;
  final bool readOnly;
  final bool autofocus;
  final bool showClearButton;
  final TextDirection? textDirection;
  final TextStyle? textStyle;
  final TextStyle? hintStyle;
  final double height;
  final double borderRadius;
  final double iconSize;
  final EdgeInsetsGeometry contentPadding;

  const GlassSearchBar({
    super.key,
    this.controller,
    this.focusNode,
    required this.hintText,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.onClear,
    this.trailing,
    this.readOnly = false,
    this.autofocus = false,
    this.showClearButton = false,
    this.textDirection,
    this.textStyle,
    this.hintStyle,
    this.height = 52,
    this.borderRadius = 14,
    this.iconSize = 22,
    this.contentPadding = const EdgeInsets.symmetric(horizontal: 14),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primary = AppColors.primary;
    final fieldTextStyle = textStyle ??
        TextStyle(
          fontSize: 15,
          color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
        );
    final fieldHintStyle = hintStyle ??
        TextStyle(
          fontSize: 15,
          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
        );
    const borderWidth = 1.5;
    final radius = BorderRadius.circular(borderRadius);
    final innerRadius = BorderRadius.circular(borderRadius - borderWidth);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.15)
        : primary.withValues(alpha: 0.32);
    final fillColor = isDark
        ? AppColors.surfaceDark.withValues(alpha: 0.92)
        : Colors.white.withValues(alpha: 0.82);

    return Container(
      height: height,
      padding: const EdgeInsets.all(borderWidth),
      decoration: BoxDecoration(
        color: borderColor,
        borderRadius: radius,
      ),
      child: ClipRRect(
        borderRadius: innerRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: fillColor,
              borderRadius: innerRadius,
            ),
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              onTap: onTap,
              readOnly: readOnly,
              autofocus: autofocus,
              textInputAction: TextInputAction.search,
              textDirection: textDirection,
              textAlignVertical: TextAlignVertical.center,
              cursorColor: isDark ? AppColors.grey400 : primary,
              style: fieldTextStyle,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: fieldHintStyle,
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: isDark ? AppColors.grey400 : primary,
                  size: iconSize,
                ),
                suffixIcon: _buildSuffix(isDark),
                suffixIconColor: isDark ? AppColors.grey400 : primary,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: contentPadding,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget? _buildSuffix(bool isDark) {
    if (showClearButton && controller != null && controller!.text.isNotEmpty) {
      return IconButton(
        onPressed: onClear,
        icon: Icon(
          Icons.close_rounded,
          color: isDark ? AppColors.grey400 : AppColors.grey500,
          size: 20,
        ),
      );
    }

    return trailing;
  }
}
