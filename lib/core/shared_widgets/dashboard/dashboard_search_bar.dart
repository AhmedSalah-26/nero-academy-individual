import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lms_platform/core/shared_widgets/glass_search_bar.dart';

/// Dashboard Search Bar - Search input with debounce
class DashboardSearchBar extends StatefulWidget {
  final String? hintText;
  final String? hintTextAr;
  final ValueChanged<String> onSearch;
  final Duration debounceDuration;
  final String? initialValue;

  const DashboardSearchBar({
    super.key,
    this.hintText,
    this.hintTextAr,
    required this.onSearch,
    this.debounceDuration = const Duration(milliseconds: 500),
    this.initialValue,
  });

  @override
  State<DashboardSearchBar> createState() => _DashboardSearchBarState();
}

class _DashboardSearchBarState extends State<DashboardSearchBar> {
  late TextEditingController _controller;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onChanged(String value) {
    setState(() {});
    _debounceTimer?.cancel();
    _debounceTimer = Timer(widget.debounceDuration, () {
      widget.onSearch(value);
    });
  }

  void _clear() {
    _controller.clear();
    widget.onSearch('');
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final hint = isArabic
        ? (widget.hintTextAr ?? 'بحث...')
        : (widget.hintText ?? 'Search...');

    return GlassSearchBar(
      controller: _controller,
      hintText: hint,
      onChanged: _onChanged,
      onClear: _clear,
      showClearButton: true,
      height: 44,
      borderRadius: 10,
      iconSize: 20,
    );
  }
}
