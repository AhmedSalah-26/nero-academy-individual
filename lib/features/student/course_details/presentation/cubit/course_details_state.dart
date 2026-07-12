import 'package:equatable/equatable.dart';
import 'package:lms_platform/core/base/base_state.dart';
import 'package:lms_platform/core/errors/failures.dart';
import 'package:lms_platform/features/student/course_details/domain/entities/course_details_entity.dart';
import 'package:lms_platform/features/student/course_details/domain/entities/review_entity.dart';

/// Course Details State
class CourseDetailsState extends Equatable {
  final StateStatus status;
  final CourseDetailsEntity? course;
  final List<ReviewEntity> reviews;
  final RatingSummary? ratingSummary;
  final Map<int, int> ratingDistribution;
  final Failure? failure;
  final bool isWishlistLoading;
  final bool isReviewsLoading;
  final bool hasMoreReviews;
  final int reviewsPage;
  final List<int> expandedSections;

  const CourseDetailsState({
    this.status = StateStatus.initial,
    this.course,
    this.reviews = const [],
    this.ratingSummary,
    this.ratingDistribution = const {5: 0, 4: 0, 3: 0, 2: 0, 1: 0},
    this.failure,
    this.isWishlistLoading = false,
    this.isReviewsLoading = false,
    this.hasMoreReviews = true,
    this.reviewsPage = 1,
    this.expandedSections = const [],
  });

  bool get isLoading => status == StateStatus.loading;
  bool get isSuccess => status == StateStatus.success;
  bool get isError => status == StateStatus.error;
  String? get errorMessage => failure?.message;

  CourseDetailsState copyWith({
    StateStatus? status,
    CourseDetailsEntity? course,
    List<ReviewEntity>? reviews,
    RatingSummary? ratingSummary,
    Map<int, int>? ratingDistribution,
    Failure? failure,
    bool? isWishlistLoading,
    bool? isReviewsLoading,
    bool? hasMoreReviews,
    int? reviewsPage,
    List<int>? expandedSections,
  }) {
    return CourseDetailsState(
      status: status ?? this.status,
      course: course ?? this.course,
      reviews: reviews ?? this.reviews,
      ratingSummary: ratingSummary ?? this.ratingSummary,
      ratingDistribution: ratingDistribution ?? this.ratingDistribution,
      failure: failure,
      isWishlistLoading: isWishlistLoading ?? this.isWishlistLoading,
      isReviewsLoading: isReviewsLoading ?? this.isReviewsLoading,
      hasMoreReviews: hasMoreReviews ?? this.hasMoreReviews,
      reviewsPage: reviewsPage ?? this.reviewsPage,
      expandedSections: expandedSections ?? this.expandedSections,
    );
  }

  @override
  List<Object?> get props => [
        status,
        course,
        reviews,
        ratingSummary,
        ratingDistribution,
        failure,
        isWishlistLoading,
        isReviewsLoading,
        hasMoreReviews,
        reviewsPage,
        expandedSections,
      ];
}
