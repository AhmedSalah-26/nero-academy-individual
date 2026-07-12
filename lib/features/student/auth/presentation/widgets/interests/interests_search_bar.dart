import 'package:flutter/material.dart';
import 'package:lms_platform/core/shared_widgets/glass_search_bar.dart';

/// Interests Search Bar
class InterestsSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const InterestsSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GlassSearchBar(
      controller: controller,
      hintText: 'ابحث عن موضوعات مثل "Python"...',
      onChanged: onChanged,
      height: 48,
      borderRadius: 12,
    );
  }
}
