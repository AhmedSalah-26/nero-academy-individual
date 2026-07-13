import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/core/shared_widgets/empty_state.dart';
import 'package:lms_platform/core/shared_widgets/error_state.dart';
import 'package:lms_platform/core/animations/widgets/entry/staggered_list.dart';
import 'package:lms_platform/core/animations/widgets/loading/custom_refresh_indicator.dart';
import 'package:lms_platform/generated/locale_keys.g.dart';
import 'package:lms_platform/features/student/course_search/presentation/cubit/course_search_cubit.dart';
import 'package:lms_platform/features/student/course_search/presentation/cubit/course_search_state.dart';
import 'package:lms_platform/features/student/course_search/presentation/widgets/course_search/course_card_widget.dart';
import 'package:lms_platform/features/student/course_search/presentation/widgets/course_search/filter_bottom_sheet.dart';
import 'package:lms_platform/features/student/course_search/presentation/widgets/course_search/search_header_widget.dart';
import 'package:lms_platform/features/student/course_search/presentation/widgets/course_search/search_skeleton_widget.dart';

/// Course Search Screen - Main search screen
class CourseSearchScreen extends StatefulWidget {
  const CourseSearchScreen({super.key});

  @override
  State<CourseSearchScreen> createState() => _CourseSearchScreenState();
}

class _CourseSearchScreenState extends State<CourseSearchScreen> {
  late final TextEditingController _searchController;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    // Initialize cubit
    context.read<CourseSearchCubit>().init();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<CourseSearchCubit>().loadMore();
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          // Header with search bar
          _buildHeader(),

          // Content
          Expanded(
            child: BlocBuilder<CourseSearchCubit, CourseSearchState>(
              builder: (context, state) {
                if (state.isInitial && !state.hasQuery) {
                  return _buildInitialState(theme, isDark, state);
                }

                if (state.isLoading) {
                  return const SearchSkeletonList();
                }

                if (state.isError) {
                  return _buildErrorState(state);
                }

                if (!state.hasResults) {
                  return _buildEmptyState(theme, isDark);
                }

                return _buildResultsList(state, isDark);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return BlocBuilder<CourseSearchCubit, CourseSearchState>(
      buildWhen: (prev, curr) =>
          prev.activeFilterCount != curr.activeFilterCount,
      builder: (context, state) {
        return SearchHeaderWidget(
          controller: _searchController,
          showBackButton: true,
          activeFilterCount: state.activeFilterCount,
          onBackPressed: () => Navigator.of(context).pop(),
          onFilterPressed: () => _showFilterSheet(context),
          onChanged: (value) {
            setState(() {});
            context.read<CourseSearchCubit>().searchWithDebounce(value);
          },
          onSubmitted: () {
            context.read<CourseSearchCubit>().search(_searchController.text);
          },
        );
      },
    );
  }

  Widget _buildInitialState(
    ThemeData theme,
    bool isDark,
    CourseSearchState state,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recent Searches
          if (state.recentSearches.isNotEmpty) ...[
            _buildSectionHeader(
              theme,
              'search.recent_searches'.tr(),
              onClear: () {
                // Clear recent searches
              },
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: state.recentSearches.map((query) {
                return _buildSearchChip(
                  query,
                  Icons.history_rounded,
                  isDark,
                  theme,
                  onTap: () {
                    _searchController.text = query;
                    context.read<CourseSearchCubit>().search(query);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
          ],

          // Categories
          if (state.categories.isNotEmpty) ...[
            _buildSectionHeader(theme, 'common.categories'.tr()),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: state.categories.map((category) {
                return _buildSearchChip(
                  category.displayName,
                  Icons.category_outlined,
                  isDark,
                  theme,
                  onTap: () {
                    context.read<CourseSearchCubit>().applyFilters(
                          state.filter.copyWith(categoryIds: [category.id]),
                        );
                  },
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    ThemeData theme,
    String title, {
    VoidCallback? onClear,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        if (onClear != null)
          TextButton(
            onPressed: onClear,
            child: Text(
              LocaleKeys.clear_all.tr(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSearchChip(
    String label,
    IconData icon,
    bool isDark,
    ThemeData theme, {
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color:
              isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.grey100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color:
                  isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? Colors.white : AppColors.grey700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(CourseSearchState state) {
    return ErrorState(
      type: ErrorType.generic,
      message: state.errorMessage ?? LocaleKeys.common_error.tr(),
      onRetry: () {
        context.read<CourseSearchCubit>().search(_searchController.text);
      },
    );
  }

  Widget _buildEmptyState(ThemeData theme, bool isDark) {
    final state = context.read<CourseSearchCubit>().state;
    final hasFilters = state.activeFilterCount > 0;

    return EmptyState(
      type: EmptyStateType.search,
      title: 'empty.search_title'.tr(),
      message: _searchController.text.isNotEmpty
          ? 'empty.search_no_results_for'.tr(args: [_searchController.text])
          : 'empty.search_message'.tr(),
      actionText: hasFilters ? 'empty.clear_filters'.tr() : null,
      onAction: hasFilters
          ? () {
              context.read<CourseSearchCubit>().clearFilters();
            }
          : null,
    );
  }

  Widget _buildResultsList(CourseSearchState state, bool isDark) {
    return CustomRefreshIndicator(
      onRefresh: () async {
        context.read<CourseSearchCubit>().search(_searchController.text);
      },
      color: AppColors.primary,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Results header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                'search.results_count'
                    .tr(namedArgs: {'count': state.totalCount.toString()}),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ),

          // Course list with StaggeredGrid animation
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(
              child: StaggeredList(
                staggerDelay: const Duration(milliseconds: 50),
                children: state.courses.map((course) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: CourseCardWidget(
                      course: course,
                      onTap: () => context.push('/course/${course.id}'),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Loading more indicator
          if (state.isLoadingMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),

          // Bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    final state = context.read<CourseSearchCubit>().state;
    FilterBottomSheet.show(
      context: context,
      currentFilter: state.filter,
      categories: state.categories,
      onApply: (filter) {
        context.read<CourseSearchCubit>().applyFilters(filter);
      },
    );
  }
}
