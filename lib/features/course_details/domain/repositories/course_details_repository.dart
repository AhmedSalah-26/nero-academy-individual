import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/course_details_entity.dart';
import '../entities/review_entity.dart';
import '../entities/section_entity.dart';

/// Course Details Repository Contract - Abstract Interface
abstract class CourseDetailsRepository {
  /// Get full course details by ID
  Future<Either<Failure, CourseDetailsEntity>> getCourseDetails(
    String courseId, {
    String? userId,
  });

  /// Get course curriculum (sections with lessons)
  Future<Either<Failure, List<SectionEntity>>> getCourseCurriculum(
    String courseId, {
    String? userId,
  });

  /// Get course reviews with pagination
  Future<Either<Failure, List<ReviewEntity>>> getCourseReviews(
    String courseId, {
    int page = 1,
    int limit = 10,
    String? sortBy,
  });

  /// Get rating summary for course
  Future<Either<Failure, RatingSummary>> getRatingSummary(String courseId);

  /// Toggle wishlist status
  Future<Either<Failure, bool>> toggleWishlist(String courseId, String userId);

  /// Check if course is in wishlist
  Future<Either<Failure, bool>> isInWishlist(String courseId, String userId);

  /// Check if course is in cart
  Future<Either<Failure, bool>> isInCart(String courseId, String userId);

  Future<Either<Failure, EnrollmentStatus>> getEnrollmentStatus(
    String courseId,
    String userId,
  );

  /// Enroll in a free course directly
  Future<Either<Failure, void>> enrollFreeCourse(
      String courseId, String userId);
}
