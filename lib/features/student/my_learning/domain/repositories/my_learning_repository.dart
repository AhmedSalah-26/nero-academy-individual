import 'package:dartz/dartz.dart';
import 'package:lms_platform/core/errors/failures.dart';
import 'package:lms_platform/features/student/my_learning/domain/entities/enrollment_entity.dart';
import 'package:lms_platform/features/student/my_learning/domain/entities/learning_progress_entity.dart';

/// My Learning Repository - Abstract Contract
abstract class MyLearningRepository {
  /// Get user's enrollments with optional filter
  Future<Either<Failure, List<EnrollmentEntity>>> getEnrollments({
    required String userId,
    EnrollmentStatus? status,
    int page = 1,
    int limit = 20,
  });

  /// Get continue learning course (most recent active)
  Future<Either<Failure, EnrollmentEntity?>> getContinueLearning(
    String userId,
  );

  /// Get enrollment by ID
  Future<Either<Failure, EnrollmentEntity>> getEnrollmentById(
    String enrollmentId,
  );

  /// Update lesson progress
  Future<Either<Failure, LearningProgressEntity>> updateLessonProgress({
    required String enrollmentId,
    required String lessonId,
    required int watchedSeconds,
    bool isCompleted = false,
  });

  /// Get lesson progress
  Future<Either<Failure, LearningProgressEntity?>> getLessonProgress({
    required String enrollmentId,
    required String lessonId,
  });

  /// Mark course as completed
  Future<Either<Failure, EnrollmentEntity>> markCourseCompleted(
    String enrollmentId,
  );

  /// Get recommended courses based on user's learning
  Future<Either<Failure, List<EnrollmentEntity>>> getRecommendedCourses({
    required String userId,
    int limit = 5,
  });
}
