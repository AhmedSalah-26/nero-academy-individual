import 'package:dartz/dartz.dart';
import 'package:lms_platform/core/errors/exceptions.dart';
import 'package:lms_platform/core/errors/failures.dart';
import 'package:lms_platform/core/network/network_info.dart';
import 'package:lms_platform/features/student/course_details/domain/entities/course_details_entity.dart';
import 'package:lms_platform/features/student/course_details/domain/entities/review_entity.dart';
import 'package:lms_platform/features/student/course_details/domain/entities/section_entity.dart';
import 'package:lms_platform/features/student/course_details/domain/repositories/course_details_repository.dart';
import 'package:lms_platform/features/student/course_details/data/datasources/course_details_remote_data_source.dart';
import 'package:lms_platform/features/student/course_details/data/datasources/course_details_local_data_source.dart';

/// Course Details Repository Implementation
class CourseDetailsRepositoryImpl implements CourseDetailsRepository {
  final CourseDetailsRemoteDataSource remoteDataSource;
  final CourseDetailsLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  CourseDetailsRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, CourseDetailsEntity>> getCourseDetails(
    String courseId, {
    String? userId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getCourseDetails(
          courseId,
          userId: userId,
        );
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      // Try to get from cache
      final cached = await localDataSource.getCachedCourseDetails(courseId);
      if (cached != null) {
        return Right(cached);
      }
      return const Left(NetworkFailure('لا يوجد اتصال بالإنترنت'));
    }
  }

  @override
  Future<Either<Failure, List<SectionEntity>>> getCourseCurriculum(
    String courseId, {
    String? userId,
  }) async {
    try {
      final result = await remoteDataSource.getCourseCurriculum(
        courseId,
        userId: userId,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ReviewEntity>>> getCourseReviews(
    String courseId, {
    int page = 1,
    int limit = 10,
    String? sortBy,
  }) async {
    try {
      final result = await remoteDataSource.getCourseReviews(
        courseId,
        page: page,
        limit: limit,
        sortBy: sortBy,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, RatingSummary>> getRatingSummary(
      String courseId) async {
    try {
      final result = await remoteDataSource.getRatingSummary(courseId);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> toggleWishlist(
      String courseId, String userId) async {
    try {
      final result = await remoteDataSource.toggleWishlist(courseId, userId);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> isInWishlist(
      String courseId, String userId) async {
    try {
      final result = await remoteDataSource.isInWishlist(courseId, userId);
      return Right(result);
    } catch (e) {
      return const Right(false);
    }
  }

  @override
  Future<Either<Failure, bool>> isInCart(String courseId, String userId) async {
    try {
      final result = await remoteDataSource.isInCart(courseId, userId);
      return Right(result);
    } catch (e) {
      return const Right(false);
    }
  }

  @override
  Future<Either<Failure, EnrollmentStatus>> getEnrollmentStatus(
    String courseId,
    String userId,
  ) async {
    // This would be implemented with actual enrollment check
    return const Right(EnrollmentStatus.notEnrolled);
  }

  @override
  Future<Either<Failure, void>> enrollFreeCourse(
      String courseId, String userId) async {
    try {
      await remoteDataSource.enrollFreeCourse(courseId, userId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
