import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lms_platform/core/shared_widgets/glass_search_bar.dart';
import 'package:lms_platform/core/theme/app_colors.dart';

/// Instructor Search Bar with Filter
class InstructorSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String? selectedExpertise;
  final List<String> expertiseOptions;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onExpertiseChanged;
  final VoidCallback? onFilterTap;

  const InstructorSearchBar({
    super.key,
    required this.controller,
    this.selectedExpertise,
    this.expertiseOptions = const [],
    required this.onSearchChanged,
    required this.onExpertiseChanged,
    this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Search Field
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GlassSearchBar(
            controller: controller,
            hintText: 'instructor.search_instructors'.tr(),
            onChanged: onSearchChanged,
            height: 48,
            borderRadius: 12,
            iconSize: 22,
            showClearButton: true,
            onClear: () {
              controller.clear();
              onSearchChanged('');
            },
            trailing: GestureDetector(
              onTap: onFilterTap ?? () => _showFilterSheet(context, isDark),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Icon(
                  Icons.tune_rounded,
                  color: selectedExpertise != null
                      ? AppColors.primary
                      : (isDark ? AppColors.grey400 : AppColors.grey500),
                  size: 20,
                ),
              ),
            ),
          ),
        ),
        // Expertise Filter Chips
        if (expertiseOptions.isNotEmpty) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 36,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: expertiseOptions.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _FilterChip(
                    label: 'common.all'.tr(),
                    isSelected: selectedExpertise == null,
                    isDark: isDark,
                    onTap: () => onExpertiseChanged(null),
                  );
                }
                final expertise = expertiseOptions[index - 1];
                return _FilterChip(
                  label: expertise,
                  isSelected: selectedExpertise == expertise,
                  isDark: isDark,
                  onTap: () => onExpertiseChanged(expertise),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  void _showFilterSheet(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.cardDark : AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _FilterBottomSheet(
        expertiseOptions: expertiseOptions,
        selectedExpertise: selectedExpertise,
        onExpertiseChanged: (value) {
          onExpertiseChanged(value);
          Navigator.pop(context);
        },
        isDark: isDark,
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary
                : isDark
                    ? AppColors.cardDark
                    : AppColors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : isDark
                      ? AppColors.borderDark
                      : AppColors.borderLight,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected
                  ? AppColors.white
                  : isDark
                      ? AppColors.textMainDark
                      : AppColors.textMainLight,
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterBottomSheet extends StatelessWidget {
  final List<String> expertiseOptions;
  final String? selectedExpertise;
  final ValueChanged<String?> onExpertiseChanged;
  final bool isDark;

  const _FilterBottomSheet({
    required this.expertiseOptions,
    this.selectedExpertise,
    required this.onExpertiseChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.grey600 : AppColors.grey300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Title
          Text(
            'instructor.filter_by_expertise'.tr(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
            ),
          ),
          const SizedBox(height: 16),
          // Options
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _FilterChip(
                label: 'common.all'.tr(),
                isSelected: selectedExpertise == null,
                isDark: isDark,
                onTap: () => onExpertiseChanged(null),
              ),
              ...expertiseOptions.map((expertise) => _FilterChip(
                    label: expertise,
                    isSelected: selectedExpertise == expertise,
                    isDark: isDark,
                    onTap: () => onExpertiseChanged(expertise),
                  )),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
