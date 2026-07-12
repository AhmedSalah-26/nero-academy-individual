import 'package:dartz/dartz.dart';
import 'package:lms_platform/core/errors/exceptions.dart';
import 'package:lms_platform/core/errors/failures.dart';
import 'package:lms_platform/core/network/network_info.dart';
import 'package:lms_platform/features/student/home/domain/entities/banner_entity.dart';
import 'package:lms_platform/features/student/home/domain/entities/category_entity.dart';
import 'package:lms_platform/features/student/home/domain/entities/course_entity.dart';
import 'package:lms_platform/features/student/home/domain/repositories/home_repository.dart';
import 'package:lms_platform/features/student/home/data/datasources/home_local_data_source.dart';
import 'package:lms_platform/features/student/home/data/datasources/home_remote_data_source.dart';

/// Home Repository Implementation
class HomeRepositoryImpl implements HomeRepository {
  final HomeRemoteDataSource remoteDataSource;
  final HomeLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  HomeRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<BannerEntity>>> getBanners() async {
    if (await networkInfo.isConnected) {
      try {
        final banners = await remoteDataSource.getBanners();
        await localDataSource.cacheBanners(banners);
        return Right(banners);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message, code: e.code));
      }
    } else {
      try {
        final cachedBanners = await localDataSource.getCachedBanners();
        return Right(cachedBanners);
      } on CacheException {
        return const Left(NetworkFailure('لا يوجد اتصال بالإنترنت'));
      }
    }
  }

  @override
  Future<Either<Failure, List<CategoryEntity>>> getCategories() async {
    if (await networkInfo.isConnected) {
      try {
        final categories = await remoteDataSource.getCategories();
        await localDataSource.cacheCategories(categories);
        return Right(categories);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message, code: e.code));
      }
    } else {
      try {
        final cachedCategories = await localDataSource.getCachedCategories();
        return Right(cachedCategories);
      } on CacheException {
        return const Left(NetworkFailure('لا يوجد اتصال بالإنترنت'));
      }
    }
  }

  @override
  Future<Either<Failure, List<CourseEntity>>> getFeaturedCourses(
      {int limit = 10}) async {
    return _getCourses(
        () => remoteDataSource.getFeaturedCourses(limit: limit), 'featured');
  }

  @override
  Future<Either<Failure, List<CourseEntity>>> getPopularCourses(
      {int limit = 10}) async {
    return _getCourses(
        () => remoteDataSource.getPopularCourses(limit: limit), 'popular');
  }

  @override
  Future<Either<Failure, List<CourseEntity>>> getNewCourses(
      {int limit = 10}) async {
    return _getCourses(
        () => remoteDataSource.getNewCourses(limit: limit), 'new');
  }

  @override
  Future<Either<Failure, List<CourseEntity>>> getFlashSaleCourses(
      {int limit = 10}) async {
    return _getCourses(
        () => remoteDataSource.getFlashSaleCourses(limit: limit), 'flash_sale');
  }

  @override
  Future<Either<Failure, List<CourseEntity>>> getCoursesByCategory(
      String categoryId,
      {int limit = 10}) async {
    return _getCourses(
        () => remoteDataSource.getCoursesByCategory(categoryId, limit: limit),
        'category_$categoryId');
  }

  Future<Either<Failure, List<CourseEntity>>> _getCourses(
    Future<List<CourseEntity>> Function() remoteFetch,
    String cacheKey,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final courses = await remoteFetch();
        return Right(courses);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message, code: e.code));
      }
    } else {
      try {
        final cachedCourses = await localDataSource.getCachedCourses(cacheKey);
        return Right(cachedCourses);
      } on CacheException {
        return const Left(NetworkFailure('لا يوجد اتصال بالإنترنت'));
      }
    }
  }
}
