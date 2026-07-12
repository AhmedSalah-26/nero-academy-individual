import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/features/student/course_search/domain/entities/search_filter_entity.dart';

/// Filter Bottom Sheet - Full filter options
class FilterBottomSheet extends StatefulWidget {
  final SearchFilterEntity currentFilter;
  final List<CategoryEntity> categories;
  final ValueChanged<SearchFilterEntity> onApply;

  const FilterBottomSheet({
    super.key,
    required this.currentFilter,
    required this.categories,
    required this.onApply,
  });

  static Future<void> show({
    required BuildContext context,
    required SearchFilterEntity currentFilter,
    required List<CategoryEntity> categories,
    required ValueChanged<SearchFilterEntity> onApply,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FilterBottomSheet(
        currentFilter: currentFilter,
        categories: categories,
        onApply: onApply,
      ),
    );
  }

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late SearchFilterEntity _filter;
  late TextEditingController _minPriceController;
  late TextEditingController _maxPriceController;

  @override
  void initState() {
    super.initState();
    _filter = widget.currentFilter;
    _minPriceController = TextEditingController(
      text: _filter.minPrice?.toInt().toString() ?? '',
    );
    _maxPriceController = TextEditingController(
      text: _filter.maxPrice?.toInt().toString() ?? '',
    );
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(theme, isDark),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSortSection(theme, isDark),
                  const SizedBox(height: 24),
                  _buildPriceSection(theme, isDark),
                  const SizedBox(height: 24),
                  _buildRatingSection(theme, isDark),
                  const SizedBox(height: 24),
                  _buildLevelSection(theme, isDark),
                  const SizedBox(height: 24),
                  if (widget.categories.isNotEmpty)
                    _buildCategoriesSection(theme, isDark),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
          _buildBottomButtons(theme),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'search.filters'.tr(),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildSortSection(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'search.sort_by'.tr(),
          style:
              theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: CourseSortOption.values.map((option) {
            final isSelected = _filter.sortBy == option;
            return _buildOptionChip(
              label: _getSortLabel(option),
              isSelected: isSelected,
              onTap: () =>
                  setState(() => _filter = _filter.copyWith(sortBy: option)),
              theme: theme,
              isDark: isDark,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPriceSection(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'search.price_range'.tr(),
          style:
              theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _minPriceController,
                keyboardType: TextInputType.number,
                decoration:
                    _priceInputDecoration(isDark, 'search.min_price'.tr()),
                onChanged: (value) {
                  final price = double.tryParse(value);
                  setState(() {
                    _filter = _filter.copyWith(
                      minPrice: price,
                      clearMinPrice: price == null || value.isEmpty,
                    );
                  });
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('-', style: theme.textTheme.titleMedium),
            ),
            Expanded(
              child: TextField(
                controller: _maxPriceController,
                keyboardType: TextInputType.number,
                decoration:
                    _priceInputDecoration(isDark, 'search.max_price'.tr()),
                onChanged: (value) {
                  final price = double.tryParse(value);
                  setState(() {
                    _filter = _filter.copyWith(
                      maxPrice: price,
                      clearMaxPrice: price == null || value.isEmpty,
                    );
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  InputDecoration _priceInputDecoration(bool isDark, String hint) {
    return InputDecoration(
      hintText: hint,
      prefixText: 'EGP ',
      prefixStyle: const TextStyle(fontFamily: 'Almarai'),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
  }

  Widget _buildRatingSection(ThemeData theme, bool isDark) {
    final ratings = [4.5, 4.0, 3.5, 3.0];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'search.min_rating'.tr(),
          style:
              theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildOptionChip(
              label: 'common.all'.tr(),
              isSelected: _filter.minRating == null,
              onTap: () => setState(
                  () => _filter = _filter.copyWith(clearMinRating: true)),
              theme: theme,
              isDark: isDark,
            ),
            ...ratings.map((rating) => _buildOptionChip(
                  label: '$rating+',
                  isSelected: _filter.minRating == rating,
                  onTap: () => setState(
                      () => _filter = _filter.copyWith(minRating: rating)),
                  theme: theme,
                  isDark: isDark,
                  icon: Icons.star_rounded,
                  iconColor: AppColors.rating,
                )),
          ],
        ),
      ],
    );
  }

  Widget _buildLevelSection(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'search.level'.tr(),
          style:
              theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: CourseLevel.values.map((level) {
            final isSelected = _filter.level == level ||
                (level == CourseLevel.all && _filter.level == null);
            return _buildOptionChip(
              label: _getLevelLabel(level),
              isSelected: isSelected,
              onTap: () => setState(() {
                _filter = level == CourseLevel.all
                    ? _filter.copyWith(clearLevel: true)
                    : _filter.copyWith(level: level);
              }),
              theme: theme,
              isDark: isDark,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCategoriesSection(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'common.categories'.tr(),
          style:
              theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.categories.map((category) {
            final isSelected = _filter.categoryIds.contains(category.id);
            return _buildOptionChip(
              label: category.name,
              isSelected: isSelected,
              onTap: () => setState(() {
                final newCategories = List<String>.from(_filter.categoryIds);
                isSelected
                    ? newCategories.remove(category.id)
                    : newCategories.add(category.id);
                _filter = _filter.copyWith(categoryIds: newCategories);
              }),
              theme: theme,
              isDark: isDark,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildOptionChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required ThemeData theme,
    required bool isDark,
    IconData? icon,
    Color? iconColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : AppColors.grey100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isSelected ? AppColors.primary : Colors.transparent),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: iconColor ?? AppColors.primary),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isSelected
                    ? AppColors.primary
                    : isDark
                        ? Colors.white
                        : AppColors.grey700,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButtons(ThemeData theme) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, 16 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                setState(() {
                  _filter = _filter.clearAllFilters();
                  _minPriceController.clear();
                  _maxPriceController.clear();
                });
              },
              child: Text('search.clear_filters'.tr()),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: () {
                widget.onApply(_filter);
                Navigator.pop(context);
              },
              child: Text('search.apply_filters'.tr()),
            ),
          ),
        ],
      ),
    );
  }

  String _getSortLabel(CourseSortOption option) {
    switch (option) {
      case CourseSortOption.relevance:
        return 'search.relevance'.tr();
      case CourseSortOption.newest:
        return 'search.newest'.tr();
      case CourseSortOption.highestRated:
        return 'search.highest_rated'.tr();
      case CourseSortOption.mostReviewed:
        return 'search.most_reviewed'.tr();
      case CourseSortOption.priceLowToHigh:
        return 'search.price_low_high'.tr();
      case CourseSortOption.priceHighToLow:
        return 'search.price_high_low'.tr();
    }
  }

  String _getLevelLabel(CourseLevel level) {
    switch (level) {
      case CourseLevel.all:
        return 'search.all_levels'.tr();
      case CourseLevel.beginner:
        return 'course.beginner'.tr();
      case CourseLevel.intermediate:
        return 'course.intermediate'.tr();
      case CourseLevel.advanced:
        return 'course.advanced'.tr();
    }
  }
}
