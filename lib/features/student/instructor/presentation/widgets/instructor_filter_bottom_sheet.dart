import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lms_platform/core/theme/app_colors.dart';

/// Instructor Sort Options
enum InstructorSortOption {
  relevance,
  mostStudents,
  highestRated,
  mostCourses,
  newest,
}

/// Instructor Filter Entity
class InstructorFilterEntity {
  final InstructorSortOption sortBy;
  final double? minRating;
  final int? minStudents;
  final int? minCourses;
  final bool verifiedOnly;

  const InstructorFilterEntity({
    this.sortBy = InstructorSortOption.relevance,
    this.minRating,
    this.minStudents,
    this.minCourses,
    this.verifiedOnly = false,
  });

  InstructorFilterEntity copyWith({
    InstructorSortOption? sortBy,
    double? minRating,
    bool clearMinRating = false,
    int? minStudents,
    bool clearMinStudents = false,
    int? minCourses,
    bool clearMinCourses = false,
    bool? verifiedOnly,
  }) {
    return InstructorFilterEntity(
      sortBy: sortBy ?? this.sortBy,
      minRating: clearMinRating ? null : (minRating ?? this.minRating),
      minStudents: clearMinStudents ? null : (minStudents ?? this.minStudents),
      minCourses: clearMinCourses ? null : (minCourses ?? this.minCourses),
      verifiedOnly: verifiedOnly ?? this.verifiedOnly,
    );
  }

  InstructorFilterEntity clearAllFilters() {
    return const InstructorFilterEntity();
  }

  int get activeFilterCount {
    int count = 0;
    if (sortBy != InstructorSortOption.relevance) count++;
    if (minRating != null) count++;
    if (minStudents != null) count++;
    if (minCourses != null) count++;
    if (verifiedOnly) count++;
    return count;
  }

  bool get hasActiveFilters => activeFilterCount > 0;
}

/// Instructor Filter Bottom Sheet
class InstructorFilterBottomSheet extends StatefulWidget {
  final InstructorFilterEntity currentFilter;
  final ValueChanged<InstructorFilterEntity> onApply;

  const InstructorFilterBottomSheet({
    super.key,
    required this.currentFilter,
    required this.onApply,
  });

  static Future<void> show({
    required BuildContext context,
    required InstructorFilterEntity currentFilter,
    required ValueChanged<InstructorFilterEntity> onApply,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => InstructorFilterBottomSheet(
        currentFilter: currentFilter,
        onApply: onApply,
      ),
    );
  }

  @override
  State<InstructorFilterBottomSheet> createState() =>
      _InstructorFilterBottomSheetState();
}

class _InstructorFilterBottomSheetState
    extends State<InstructorFilterBottomSheet> {
  late InstructorFilterEntity _filter;

  @override
  void initState() {
    super.initState();
    _filter = widget.currentFilter;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
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
                  _buildRatingSection(theme, isDark),
                  const SizedBox(height: 24),
                  _buildStudentsSection(theme, isDark),
                  const SizedBox(height: 24),
                  _buildCoursesSection(theme, isDark),
                  const SizedBox(height: 24),
                  _buildVerifiedSection(theme, isDark),
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
          children: InstructorSortOption.values.map((option) {
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

  Widget _buildStudentsSection(ThemeData theme, bool isDark) {
    final studentCounts = [100, 500, 1000, 5000];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'instructor.min_students'.tr(),
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
              isSelected: _filter.minStudents == null,
              onTap: () => setState(
                  () => _filter = _filter.copyWith(clearMinStudents: true)),
              theme: theme,
              isDark: isDark,
            ),
            ...studentCounts.map((count) => _buildOptionChip(
                  label: '${_formatNumber(count)}+',
                  isSelected: _filter.minStudents == count,
                  onTap: () => setState(
                      () => _filter = _filter.copyWith(minStudents: count)),
                  theme: theme,
                  isDark: isDark,
                  icon: Icons.people_rounded,
                  iconColor: AppColors.info,
                )),
          ],
        ),
      ],
    );
  }

  Widget _buildCoursesSection(ThemeData theme, bool isDark) {
    final courseCounts = [3, 5, 10, 20];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'instructor.min_courses'.tr(),
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
              isSelected: _filter.minCourses == null,
              onTap: () => setState(
                  () => _filter = _filter.copyWith(clearMinCourses: true)),
              theme: theme,
              isDark: isDark,
            ),
            ...courseCounts.map((count) => _buildOptionChip(
                  label: '$count+',
                  isSelected: _filter.minCourses == count,
                  onTap: () => setState(
                      () => _filter = _filter.copyWith(minCourses: count)),
                  theme: theme,
                  isDark: isDark,
                  icon: Icons.play_circle_rounded,
                  iconColor: AppColors.primary,
                )),
          ],
        ),
      ],
    );
  }

  Widget _buildVerifiedSection(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'instructor.verification'.tr(),
          style:
              theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        _buildOptionChip(
          label: 'instructor.verified_only'.tr(),
          isSelected: _filter.verifiedOnly,
          onTap: () => setState(() =>
              _filter = _filter.copyWith(verifiedOnly: !_filter.verifiedOnly)),
          theme: theme,
          isDark: isDark,
          icon: Icons.verified_rounded,
          iconColor: AppColors.info,
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

  String _getSortLabel(InstructorSortOption option) {
    switch (option) {
      case InstructorSortOption.relevance:
        return 'search.relevance'.tr();
      case InstructorSortOption.mostStudents:
        return 'instructor.most_students'.tr();
      case InstructorSortOption.highestRated:
        return 'search.highest_rated'.tr();
      case InstructorSortOption.mostCourses:
        return 'instructor.most_courses'.tr();
      case InstructorSortOption.newest:
        return 'search.newest'.tr();
    }
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(number % 1000 == 0 ? 0 : 1)}K';
    }
    return number.toString();
  }
}
