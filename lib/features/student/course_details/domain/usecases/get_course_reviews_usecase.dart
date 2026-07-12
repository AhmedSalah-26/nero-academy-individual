import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:lms_platform/core/errors/failures.dart';
import 'package:lms_platform/core/usecase/usecase.dart';
import 'package:lms_platform/features/student/course_details/domain/entities/review_entity.dart';
import 'package:lms_platform/features/student/course_details/domain/repositories/course_details_repository.dart';

/// Get Course Reviews UseCase
class GetCourseReviewsUseCase
    extends UseCaseWithParams<List<ReviewEntity>, CourseReviewsParams> {
  final CourseDetailsRepository repository;

  GetCourseReviewsUseCase(this.repository);

  @override
  Future<Either<Failure, List<ReviewEntity>>> call(CourseReviewsParams params) {
    return repository.getCourseReviews(
      params.courseId,
      page: params.page,
      limit: params.limit,
      sortBy: params.sortBy,
    );
  }
}

/// Parameters for GetCourseReviewsUseCase
class CourseReviewsParams extends Equatable {
  final String courseId;
  final int page;
  final int limit;
  final String? sortBy;

  const CourseReviewsParams({
    required this.courseId,
    this.page = 1,
    this.limit = 10,
    this.sortBy,
  });

  @override
  List<Object?> get props => [courseId, page, limit, sortBy];
}
