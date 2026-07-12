import 'package:dartz/dartz.dart';
import 'package:lms_platform/core/errors/exceptions.dart';
import 'package:lms_platform/core/errors/failures.dart';
import 'package:lms_platform/core/network/network_info.dart';
import 'package:lms_platform/features/student/my_learning/domain/entities/enrollment_entity.dart';
import 'package:lms_platform/features/student/my_learning/domain/entities/learning_progress_entity.dart';
import 'package:lms_platform/features/student/my_learning/domain/repositories/my_learning_repository.dart';
import 'package:lms_platform/features/student/my_learning/data/datasources/my_learning_local_data_source.dart';
import 'package:lms_platform/features/student/my_learning/data/datasources/my_learning_remote_data_source.dart';

/// My Learning Repository Implementation
class MyLearningRepositoryImpl implements MyLearningRepository {
  final MyLearningRemoteDataSource remoteDataSource;
  final MyLearningLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  MyLearningRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<EnrollmentEntity>>> getEnrollments({
    required String userId,
    EnrollmentStatus? status,
    int page = 1,
    int limit = 20,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final enrollments = await remoteDataSource.getEnrollments(
          userId: userId,
          status: status,
          page: page,
          limit: limit,
        );
        // Cache first page only
        if (page == 1 && status == null) {
          await localDataSource.cacheEnrollments(userId, enrollments);
        }
        return Right(enrollments);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      // Return cached data when offline
      final cached = await localDataSource.getCachedEnrollments(userId);
      if (cached.isNotEmpty) {
        return Right(cached);
      }
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, EnrollmentEntity?>> getContinueLearning(
    String userId,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final enrollment = await remoteDataSource.getContinueLearning(userId);
        if (enrollment != null) {
          await localDataSource.cacheContinueLearning(userId, enrollment);
        }
        return Right(enrollment);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      final cached = await localDataSource.getCachedContinueLearning(userId);
      return Right(cached);
    }
  }

  @override
  Future<Either<Failure, EnrollmentEntity>> getEnrollmentById(
    String enrollmentId,
  ) async {
    try {
      final enrollment = await remoteDataSource.getEnrollmentById(enrollmentId);
      return Right(enrollment);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, LearningProgressEntity>> updateLessonProgress({
    required String enrollmentId,
    required String lessonId,
    required int watchedSeconds,
    bool isCompleted = false,
  }) async {
    try {
      final progress = await remoteDataSource.updateLessonProgress(
        enrollmentId: enrollmentId,
        lessonId: lessonId,
        watchedSeconds: watchedSeconds,
        isCompleted: isCompleted,
      );
      return Right(progress);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, LearningProgressEntity?>> getLessonProgress({
    required String enrollmentId,
    required String lessonId,
  }) async {
    try {
      final progress = await remoteDataSource.getLessonProgress(
        enrollmentId: enrollmentId,
        lessonId: lessonId,
      );
      return Right(progress);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, EnrollmentEntity>> markCourseCompleted(
    String enrollmentId,
  ) async {
    try {
      final enrollment = await remoteDataSource.markCourseCompleted(
        enrollmentId,
      );
      return Right(enrollment);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<EnrollmentEntity>>> getRecommendedCourses({
    required String userId,
    int limit = 5,
  }) async {
    try {
      final courses = await remoteDataSource.getRecommendedCourses(
        userId: userId,
        limit: limit,
      );
      return Right(courses);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}
