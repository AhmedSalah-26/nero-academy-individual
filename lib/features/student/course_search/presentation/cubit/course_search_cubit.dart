import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lms_platform/features/student/course_search/domain/entities/search_filter_entity.dart';
import 'package:lms_platform/features/student/course_search/domain/usecases/get_categories_usecase.dart';
import 'package:lms_platform/features/student/course_search/domain/usecases/get_recent_searches_usecase.dart';
import 'package:lms_platform/features/student/course_search/domain/usecases/save_recent_search_usecase.dart';
import 'package:lms_platform/features/student/course_search/domain/usecases/search_courses_usecase.dart';
import 'course_search_state.dart';

/// Course Search Cubit
class CourseSearchCubit extends Cubit<CourseSearchState> {
  final SearchCoursesUseCase _searchCoursesUseCase;
  final GetCategoriesUseCase _getCategoriesUseCase;
  final GetRecentSearchesUseCase _getRecentSearchesUseCase;
  final SaveRecentSearchUseCase _saveRecentSearchUseCase;

  Timer? _debounceTimer;
  bool _isClosed = false;

  CourseSearchCubit({
    required SearchCoursesUseCase searchCoursesUseCase,
    required GetCategoriesUseCase getCategoriesUseCase,
    required GetRecentSearchesUseCase getRecentSearchesUseCase,
    required SaveRecentSearchUseCase saveRecentSearchUseCase,
  })  : _searchCoursesUseCase = searchCoursesUseCase,
        _getCategoriesUseCase = getCategoriesUseCase,
        _getRecentSearchesUseCase = getRecentSearchesUseCase,
        _saveRecentSearchUseCase = saveRecentSearchUseCase,
        super(const CourseSearchState());

  void _safeEmit(CourseSearchState newState) {
    if (!_isClosed) {
      emit(newState);
    }
  }

  /// Initialize - Load categories and recent searches
  Future<void> init() async {
    await Future.wait([
      _loadCategories(),
      _loadRecentSearches(),
    ]);
  }

  Future<void> _loadCategories() async {
    final result = await _getCategoriesUseCase();
    result.fold(
      (failure) {},
      (categories) => _safeEmit(state.copyWith(categories: categories)),
    );
  }

  Future<void> _loadRecentSearches() async {
    final result = await _getRecentSearchesUseCase();
    result.fold(
      (failure) {},
      (searches) => _safeEmit(state.copyWith(recentSearches: searches)),
    );
  }

  /// Search with debounce
  void searchWithDebounce(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      search(query);
    });
  }

  /// Search courses
  Future<void> search(String query) async {
    if (_isClosed) return;

    if (query.trim().isEmpty) {
      _safeEmit(state.copyWith(
        status: CourseSearchStatus.initial,
        courses: [],
        filter: const SearchFilterEntity(),
        totalCount: 0,
      ));
      return;
    }

    final updatedFilter = state.filter.copyWith(query: query.trim(), page: 1);

    _safeEmit(state.copyWith(
      status: CourseSearchStatus.loading,
      filter: updatedFilter,
    ));

    await _saveRecentSearchUseCase(query.trim());
    await _loadRecentSearches();

    if (_isClosed) return;

    final result = await _searchCoursesUseCase(updatedFilter);

    result.fold(
      (failure) => _safeEmit(state.copyWith(
        status: CourseSearchStatus.error,
        errorMessage: failure.message,
      )),
      (searchResult) => _safeEmit(state.copyWith(
        status: CourseSearchStatus.success,
        courses: searchResult.courses,
        totalCount: searchResult.totalCount,
        hasMore: searchResult.hasMore,
      )),
    );
  }

  /// Load more courses (pagination)
  Future<void> loadMore() async {
    if (_isClosed) return;
    if (!state.hasMore || state.isLoadingMore || state.isLoading) return;

    _safeEmit(state.copyWith(
      status: CourseSearchStatus.loadingMore,
      filter: state.filter.copyWith(page: state.filter.page + 1),
    ));

    final result = await _searchCoursesUseCase(state.filter);

    result.fold(
      (failure) => _safeEmit(state.copyWith(
        status: CourseSearchStatus.success,
        filter: state.filter.copyWith(page: state.filter.page - 1),
      )),
      (searchResult) => _safeEmit(state.copyWith(
        status: CourseSearchStatus.success,
        courses: [...state.courses, ...searchResult.courses],
        totalCount: searchResult.totalCount,
        hasMore: searchResult.hasMore,
      )),
    );
  }

  /// Apply filters
  Future<void> applyFilters(SearchFilterEntity newFilter) async {
    if (_isClosed) return;

    final updatedFilter = newFilter.copyWith(page: 1);

    _safeEmit(state.copyWith(
      status: CourseSearchStatus.loading,
      filter: updatedFilter,
    ));

    final result = await _searchCoursesUseCase(updatedFilter);

    result.fold(
      (failure) => _safeEmit(state.copyWith(
        status: CourseSearchStatus.error,
        errorMessage: failure.message,
      )),
      (searchResult) => _safeEmit(state.copyWith(
        status: CourseSearchStatus.success,
        courses: searchResult.courses,
        totalCount: searchResult.totalCount,
        hasMore: searchResult.hasMore,
      )),
    );
  }

  /// Update sort option
  Future<void> updateSort(CourseSortOption sortBy) async {
    await applyFilters(state.filter.copyWith(sortBy: sortBy));
  }

  /// Clear all filters
  Future<void> clearFilters() async {
    await applyFilters(state.filter.clearAllFilters());
  }

  /// Clear error
  void clearError() {
    _safeEmit(state.copyWith(clearError: true));
  }

  @override
  Future<void> close() {
    _isClosed = true;
    _debounceTimer?.cancel();
    return super.close();
  }
}
