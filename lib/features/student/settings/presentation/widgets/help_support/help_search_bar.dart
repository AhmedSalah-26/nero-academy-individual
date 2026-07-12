import 'package:flutter/material.dart';
import 'package:lms_platform/core/shared_widgets/glass_search_bar.dart';

/// Help Search Bar Widget
class HelpSearchBar extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final String hintText;
  final bool isDark;

  const HelpSearchBar({
    super.key,
    this.controller,
    this.onChanged,
    required this.hintText,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GlassSearchBar(
      controller: controller,
      hintText: hintText,
      onChanged: onChanged,
      height: 56,
      borderRadius: 12,
      iconSize: 24,
    );
  }
}
