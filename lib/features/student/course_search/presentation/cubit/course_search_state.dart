import 'package:equatable/equatable.dart';
import 'package:lms_platform/features/student/course_search/domain/entities/course_entity.dart';
import 'package:lms_platform/features/student/course_search/domain/entities/search_filter_entity.dart';

/// Course Search Status
enum CourseSearchStatus {
  initial,
  loading,
  loadingMore,
  success,
  error,
}

/// Course Search State
class CourseSearchState extends Equatable {
  final CourseSearchStatus status;
  final List<CourseEntity> courses;
  final SearchFilterEntity filter;
  final List<CategoryEntity> categories;
  final List<String> recentSearches;
  final int totalCount;
  final bool hasMore;
  final String? errorMessage;

  const CourseSearchState({
    this.status = CourseSearchStatus.initial,
    this.courses = const [],
    this.filter = const SearchFilterEntity(),
    this.categories = const [],
    this.recentSearches = const [],
    this.totalCount = 0,
    this.hasMore = true,
    this.errorMessage,
  });

  // ============ Getters ============

  bool get isInitial => status == CourseSearchStatus.initial;
  bool get isLoading => status == CourseSearchStatus.loading;
  bool get isLoadingMore => status == CourseSearchStatus.loadingMore;
  bool get isSuccess => status == CourseSearchStatus.success;
  bool get isError => status == CourseSearchStatus.error;

  bool get hasResults => courses.isNotEmpty;
  bool get hasQuery => filter.query != null && filter.query!.isNotEmpty;
  bool get hasActiveFilters => filter.hasActiveFilters;
  int get activeFilterCount => filter.activeFilterCount;

  // ============ Copy With ============

  CourseSearchState copyWith({
    CourseSearchStatus? status,
    List<CourseEntity>? courses,
    SearchFilterEntity? filter,
    List<CategoryEntity>? categories,
    List<String>? recentSearches,
    int? totalCount,
    bool? hasMore,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CourseSearchState(
      status: status ?? this.status,
      courses: courses ?? this.courses,
      filter: filter ?? this.filter,
      categories: categories ?? this.categories,
      recentSearches: recentSearches ?? this.recentSearches,
      totalCount: totalCount ?? this.totalCount,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        status,
        courses,
        filter,
        categories,
        recentSearches,
        totalCount,
        hasMore,
        errorMessage,
      ];
}
