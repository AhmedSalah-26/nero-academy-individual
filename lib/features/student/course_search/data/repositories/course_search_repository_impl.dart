import 'package:dartz/dartz.dart';
import 'package:lms_platform/core/errors/exceptions.dart';
import 'package:lms_platform/core/errors/failures.dart';
import 'package:lms_platform/core/network/network_info.dart';
import 'package:lms_platform/features/student/course_search/domain/entities/course_entity.dart';
import 'package:lms_platform/features/student/course_search/domain/entities/search_filter_entity.dart';
import 'package:lms_platform/features/student/course_search/domain/repositories/course_search_repository.dart';
import 'package:lms_platform/features/student/course_search/data/datasources/course_search_local_data_source.dart';
import 'package:lms_platform/features/student/course_search/data/datasources/course_search_remote_data_source.dart';
import 'package:lms_platform/features/student/course_search/data/models/search_filter_model.dart';

/// Course Search Repository Implementation
class CourseSearchRepositoryImpl implements CourseSearchRepository {
  final CourseSearchRemoteDataSource _remoteDataSource;
  final CourseSearchLocalDataSource _localDataSource;
  final NetworkInfo _networkInfo;

  CourseSearchRepositoryImpl({
    required CourseSearchRemoteDataSource remoteDataSource,
    required CourseSearchLocalDataSource localDataSource,
    required NetworkInfo networkInfo,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _networkInfo = networkInfo;

  @override
  Future<Either<Failure, CourseSearchResult>> searchCourses(
    SearchFilterEntity filter,
  ) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure('لا يوجد اتصال بالإنترنت'));
    }

    try {
      final filterModel = SearchFilterModel.fromEntity(filter);
      final result = await _remoteDataSource.searchCourses(filterModel);

      final hasMore = (filter.page * filter.pageSize) < result.totalCount;

      return Right(CourseSearchResult(
        courses: result.courses.map((m) => m as CourseEntity).toList(),
        totalCount: result.totalCount,
        currentPage: filter.page,
        hasMore: hasMore,
      ));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('حدث خطأ أثناء البحث: $e'));
    }
  }

  @override
  Future<Either<Failure, List<CategoryEntity>>> getCategories() async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure('لا يوجد اتصال بالإنترنت'));
    }

    try {
      final categories = await _remoteDataSource.getCategories();
      return Right(categories.map((m) => m as CategoryEntity).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('حدث خطأ أثناء جلب التصنيفات: $e'));
    }
  }

  @override
  Future<Either<Failure, List<String>>> getRecentSearches() async {
    try {
      final searches = await _localDataSource.getRecentSearches();
      return Right(searches);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return const Right([]);
    }
  }

  @override
  Future<Either<Failure, void>> saveRecentSearch(String query) async {
    try {
      await _localDataSource.saveRecentSearch(query);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return const Right(null);
    }
  }

  @override
  Future<Either<Failure, void>> clearRecentSearches() async {
    try {
      await _localDataSource.clearRecentSearches();
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<String>>> getPopularSearches() async {
    if (!await _networkInfo.isConnected) {
      return const Right([]);
    }

    try {
      final searches = await _remoteDataSource.getPopularSearches();
      return Right(searches);
    } catch (e) {
      return const Right([]);
    }
  }
}
