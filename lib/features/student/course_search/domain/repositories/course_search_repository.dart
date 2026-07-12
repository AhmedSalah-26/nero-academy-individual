import 'package:dartz/dartz.dart';
import 'package:lms_platform/core/errors/failures.dart';
import 'package:lms_platform/features/student/course_search/domain/entities/course_entity.dart';
import 'package:lms_platform/features/student/course_search/domain/entities/search_filter_entity.dart';

/// Course Search Repository - Abstract Contract
abstract class CourseSearchRepository {
  /// Search courses with filters
  Future<Either<Failure, CourseSearchResult>> searchCourses(
    SearchFilterEntity filter,
  );

  /// Get all categories
  Future<Either<Failure, List<CategoryEntity>>> getCategories();

  /// Get recent searches
  Future<Either<Failure, List<String>>> getRecentSearches();

  /// Save a search query to recent searches
  Future<Either<Failure, void>> saveRecentSearch(String query);

  /// Clear all recent searches
  Future<Either<Failure, void>> clearRecentSearches();

  /// Get popular/trending searches
  Future<Either<Failure, List<String>>> getPopularSearches();
}

/// Course Search Result with pagination info
class CourseSearchResult {
  final List<CourseEntity> courses;
  final int totalCount;
  final int currentPage;
  final bool hasMore;

  const CourseSearchResult({
    required this.courses,
    required this.totalCount,
    required this.currentPage,
    required this.hasMore,
  });
}
