import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/features/student/course_search/domain/entities/search_filter_entity.dart';

/// Course Filter Screen - Full page replacement for filter bottom sheet
class CourseFilterScreen extends StatefulWidget {
  final SearchFilterEntity initialFilter;
  final List<Map<String, dynamic>> categories;

  const CourseFilterScreen({
    super.key,
    required this.initialFilter,
    required this.categories,
  });

  @override
  State<CourseFilterScreen> createState() => _CourseFilterScreenState();
}

class _CourseFilterScreenState extends State<CourseFilterScreen> {
  late SearchFilterEntity _filter;
  double _minPrice = 0;
  double _maxPrice = 1000;

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter;
    _minPrice = _filter.minPrice ?? 0;
    _maxPrice = _filter.maxPrice ?? 1000;
  }

  void _applyFilters() {
    Navigator.of(context).pop(_filter.copyWith(
      minPrice: _minPrice,
      maxPrice: _maxPrice,
    ));
  }

  void _resetFilters() {
    setState(() {
      _filter = const SearchFilterEntity();
      _minPrice = 0;
      _maxPrice = 1000;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = context.locale.languageCode == 'ar';

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(isArabic ? 'تصفية الكورسات' : 'Filter Courses'),
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _resetFilters,
            child: Text(
              isArabic ? 'إعادة تعيين' : 'Reset',
              style: const TextStyle(
                fontFamily: 'Almarai',
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(
                      isArabic ? 'الفئات' : 'Categories', isDark),
                  const SizedBox(height: 12),
                  _buildCategoryChips(isDark),
                  const SizedBox(height: 24),
                  _buildSectionTitle(
                      isArabic ? 'نطاق السعر' : 'Price Range', isDark),
                  const SizedBox(height: 12),
                  _buildPriceRange(isDark),
                  const SizedBox(height: 24),
                  _buildSectionTitle(isArabic ? 'المستوى' : 'Level', isDark),
                  const SizedBox(height: 12),
                  _buildLevelChips(isDark, isArabic),
                  const SizedBox(height: 24),
                  _buildSectionTitle(isArabic ? 'التقييم' : 'Rating', isDark),
                  const SizedBox(height: 12),
                  _buildRatingOptions(isDark, isArabic),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _applyFilters,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    isArabic ? 'تطبيق الفلاتر' : 'Apply Filters',
                    style: const TextStyle(
                      fontFamily: 'Almarai',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontFamily: 'Almarai',
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: isDark ? AppColors.white : AppColors.textMainLight,
      ),
    );
  }

  Widget _buildCategoryChips(bool isDark) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: widget.categories.map((category) {
        final id = category['id'] as String;
        final name = category['name'] as String;
        final isSelected = _filter.categoryIds.contains(id);

        return FilterChip(
          label: Text(name),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              final categories = List<String>.from(_filter.categoryIds);
              if (selected) {
                categories.add(id);
              } else {
                categories.remove(id);
              }
              _filter = _filter.copyWith(categoryIds: categories);
            });
          },
          backgroundColor: isDark ? AppColors.surfaceDark : AppColors.grey100,
          selectedColor: AppColors.primary.withValues(alpha: 0.2),
          checkmarkColor: AppColors.primary,
          labelStyle: TextStyle(
            fontFamily: 'Almarai',
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.textMainDark : AppColors.textMainLight),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
          side: BorderSide(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.borderDark : AppColors.borderLight),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPriceRange(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '\$${_minPrice.toInt()}',
                style: const TextStyle(
                  fontFamily: 'Almarai',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              Text(
                '\$${_maxPrice.toInt()}',
                style: const TextStyle(
                  fontFamily: 'Almarai',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          RangeSlider(
            values: RangeValues(_minPrice, _maxPrice),
            min: 0,
            max: 1000,
            divisions: 20,
            activeColor: AppColors.primary,
            inactiveColor: isDark ? AppColors.grey700 : AppColors.grey300,
            onChanged: (values) {
              setState(() {
                _minPrice = values.start;
                _maxPrice = values.end;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLevelChips(bool isDark, bool isArabic) {
    final levels = [
      {'id': CourseLevel.beginner, 'name': isArabic ? 'مبتدئ' : 'Beginner'},
      {
        'id': CourseLevel.intermediate,
        'name': isArabic ? 'متوسط' : 'Intermediate'
      },
      {'id': CourseLevel.advanced, 'name': isArabic ? 'متقدم' : 'Advanced'},
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: levels.map((level) {
        final id = level['id'] as CourseLevel;
        final name = level['name'] as String;
        final isSelected = _filter.level == id;

        return ChoiceChip(
          label: Text(name),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              _filter = _filter.copyWith(
                level: selected ? id : null,
                clearLevel: !selected,
              );
            });
          },
          backgroundColor: isDark ? AppColors.surfaceDark : AppColors.grey100,
          selectedColor: AppColors.primary.withValues(alpha: 0.2),
          labelStyle: TextStyle(
            fontFamily: 'Almarai',
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.textMainDark : AppColors.textMainLight),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
          side: BorderSide(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.borderDark : AppColors.borderLight),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRatingOptions(bool isDark, bool isArabic) {
    final ratings = [4.5, 4.0, 3.5, 3.0];

    return Column(
      children: ratings.map((rating) {
        final isSelected = _filter.minRating == rating;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () {
              setState(() {
                _filter = _filter.copyWith(
                  minRating: isSelected ? null : rating,
                  clearMinRating: isSelected,
                );
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : (isDark ? AppColors.surfaceDark : AppColors.white),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : (isDark ? AppColors.borderDark : AppColors.borderLight),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected ? Icons.check_circle : Icons.circle_outlined,
                    color: isSelected ? AppColors.primary : AppColors.grey400,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.star, color: AppColors.warning, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    '$rating ${isArabic ? 'وأعلى' : '& up'}',
                    style: TextStyle(
                      fontFamily: 'Almarai',
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected
                          ? AppColors.primary
                          : (isDark
                              ? AppColors.textMainDark
                              : AppColors.textMainLight),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
