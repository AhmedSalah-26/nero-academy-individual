import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lms_platform/core/routing/app_router.dart';
import 'package:lms_platform/core/shared_widgets/glass_icon_button.dart';
import 'package:lms_platform/core/shared_widgets/glass_search_bar.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/core/di/injection_container.dart';
import 'package:lms_platform/core/shared_widgets/empty_state.dart';
import 'package:lms_platform/core/shared_widgets/error_state.dart';
import 'package:lms_platform/core/shared_widgets/loading_skeleton.dart';
import 'package:lms_platform/core/utils/arabic_utils.dart';
import 'package:lms_platform/features/student/instructor/data/datasources/instructor_remote_data_source.dart';
import 'package:lms_platform/features/student/instructor/domain/entities/instructor_entity.dart';
import 'package:lms_platform/features/student/instructor/presentation/widgets/enhanced_instructor_card.dart';
import 'package:lms_platform/features/student/instructor/presentation/widgets/instructor_filter_bottom_sheet.dart';

/// Instructors Screen - Shows all instructors in a grid with live search and filters
class InstructorsScreen extends StatefulWidget {
  const InstructorsScreen({super.key});

  @override
  State<InstructorsScreen> createState() => _InstructorsScreenState();
}

class _InstructorsScreenState extends State<InstructorsScreen> {
  List<InstructorEntity> _allInstructors = [];
  List<InstructorEntity> _filteredInstructors = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _searchQuery = '';
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  InstructorFilterEntity _filter = const InstructorFilterEntity();
  bool _hasLoadedOnce = false;

  @override
  void initState() {
    super.initState();
    _loadInstructors();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload instructors every time the screen becomes visible
    if (_hasLoadedOnce && !_isLoading) {
      _loadInstructors();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadInstructors() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final dataSource = sl<InstructorRemoteDataSource>();
      final instructors = await dataSource.getTopInstructors(limit: 0);

      if (mounted) {
        setState(() {
          _allInstructors = instructors;
          _applyFilters();
          _isLoading = false;
          _hasError = false;
          _hasLoadedOnce = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _hasLoadedOnce = true;
        });
      }
    }
  }

  void _applyFilters() {
    var result = List<InstructorEntity>.from(_allInstructors);

    // Apply search query
    if (_searchQuery.isNotEmpty) {
      result = result.where((instructor) {
        // Use Arabic-aware search for better matching
        final nameMatch =
            ArabicUtils.searchMatch(instructor.name, _searchQuery);
        final headlineMatch = instructor.headline != null
            ? ArabicUtils.searchMatch(instructor.headline!, _searchQuery)
            : false;

        return nameMatch || headlineMatch;
      }).toList();
    }

    // Apply min rating filter
    if (_filter.minRating != null) {
      result =
          result.where((i) => i.averageRating >= _filter.minRating!).toList();
    }

    // Apply min students filter
    if (_filter.minStudents != null) {
      result =
          result.where((i) => i.totalStudents >= _filter.minStudents!).toList();
    }

    // Apply min courses filter
    if (_filter.minCourses != null) {
      result =
          result.where((i) => i.totalCourses >= _filter.minCourses!).toList();
    }

    // Apply verified only filter
    if (_filter.verifiedOnly) {
      result = result.where((i) => i.totalStudents > 1000).toList();
    }

    // Apply sorting
    switch (_filter.sortBy) {
      case InstructorSortOption.mostStudents:
        result.sort((a, b) => b.totalStudents.compareTo(a.totalStudents));
        break;
      case InstructorSortOption.highestRated:
        result.sort((a, b) => b.averageRating.compareTo(a.averageRating));
        break;
      case InstructorSortOption.mostCourses:
        result.sort((a, b) => b.totalCourses.compareTo(a.totalCourses));
        break;
      case InstructorSortOption.newest:
        result.sort((a, b) {
          if (a.joinedAt == null || b.joinedAt == null) return 0;
          return b.joinedAt!.compareTo(a.joinedAt!);
        });
        break;
      case InstructorSortOption.relevance:
        // Keep original order
        break;
    }

    _filteredInstructors = result;
  }

  void _filterInstructors(String query) {
    setState(() {
      _searchQuery = query;
      _applyFilters();
    });
  }

  void _onFilterApply(InstructorFilterEntity filter) {
    setState(() {
      _filter = filter;
      _applyFilters();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(isDark),
            Expanded(
              child: _isLoading
                  ? _buildLoading()
                  : _hasError
                      ? _buildError()
                      : _filteredInstructors.isEmpty
                          ? _buildEmpty()
                          : _buildGrid(isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    final iconSize = (screenWidth * 0.06).clamp(22.0, 26.0);
    final theme = Theme.of(context);

    return Container(
      color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.04,
          vertical: screenWidth * 0.025,
        ),
        child: Column(
          children: [
            // Title Row
            Row(
              children: [
                Text(
                  'nav.instructors'.tr(),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.textMainDark
                        : AppColors.textMainLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Search Bar with Filter Button - Same style as course search
            Row(
              children: [
                Expanded(
                  child: GlassSearchBar(
                    controller: _searchController,
                    focusNode: _focusNode,
                    hintText: 'instructor.search_instructors'.tr(),
                    onChanged: _filterInstructors,
                    height: 48,
                    iconSize: iconSize,
                    textStyle: theme.textTheme.bodyLarge,
                    hintStyle: theme.textTheme.bodyLarge?.copyWith(
                      color: isDark
                          ? AppColors.textMutedDark
                          : AppColors.textMutedLight,
                    ),
                    showClearButton: true,
                    onClear: () {
                      _searchController.clear();
                      _filterInstructors('');
                    },
                  ),
                ),
                const SizedBox(width: 12),
                GlassIconButton(
                  icon: Icons.tune_rounded,
                  onTap: _showFilterSheet,
                  size: 44,
                  iconSize: iconSize,
                  badgeCount: _filter.activeFilterCount > 0
                      ? _filter.activeFilterCount
                      : null,
                  compactBadge: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterSheet() {
    InstructorFilterBottomSheet.show(
      context: context,
      currentFilter: _filter,
      onApply: _onFilterApply,
    );
  }

  Widget _buildLoading() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return const LoadingSkeleton(
          type: SkeletonType.courseCard,
        );
      },
    );
  }

  Widget _buildEmpty() {
    return const EmptyState(
      type: EmptyStateType.instructors,
    );
  }

  Widget _buildError() {
    return ErrorState(
      type: ErrorType.network,
      display: ErrorStateDisplay.section,
      onRetry: _loadInstructors,
    );
  }

  Widget _buildGrid(bool isDark) {
    return RefreshIndicator(
      onRefresh: _loadInstructors,
      color: AppColors.primary,
      child: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.78,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: _filteredInstructors.length,
        itemBuilder: (context, index) {
          final instructor = _filteredInstructors[index];
          return EnhancedInstructorCard(
            instructor: instructor,
            isDark: isDark,
            isVerified: instructor.averageRating >= 4.5,
            onTap: () {
              HapticFeedback.lightImpact();
              AppRouter.goToInstructor(context, instructor.id);
            },
          );
        },
      ),
    );
  }
}
