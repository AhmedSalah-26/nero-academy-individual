import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:lms_platform/features/instructor_dashboard/domain/repositories/instructor_repository.dart';
import 'package:lms_platform/features/instructor_dashboard/data/models/instructor_review_model.dart';

part 'instructor_reviews_state.dart';

/// Instructor Reviews Cubit
class InstructorReviewsCubit extends Cubit<InstructorReviewsState> {
  final InstructorRepository _repository;

  InstructorReviewsCubit(this._repository)
      : super(const InstructorReviewsState());

  /// Load reviews
  Future<void> loadReviews(
      {String? courseId,
      int? minRating,
      int? maxRating,
      bool refresh = false}) async {
    if (refresh) {
      emit(state.copyWith(
          status: InstructorReviewsStatus.loading,
          reviews: [],
          currentPage: 1,
          hasMore: true));
    } else {
      emit(state.copyWith(status: InstructorReviewsStatus.loading));
    }

    try {
      final reviews = await _repository.getReviews(
        courseId: courseId,
        minRating: minRating,
        maxRating: maxRating,
        page: 1,
      );
      emit(state.copyWith(
        status: InstructorReviewsStatus.success,
        reviews: reviews,
        currentCourseId: courseId,
        currentMinRating: minRating,
        currentMaxRating: maxRating,
        currentPage: 1,
        hasMore: reviews.length >= 20,
      ));
    } catch (e) {
      emit(state.copyWith(
          status: InstructorReviewsStatus.error, errorMessage: e.toString()));
    }
  }

  /// Load more reviews
  Future<void> loadMoreReviews() async {
    if (!state.hasMore || state.status == InstructorReviewsStatus.loadingMore) {
      return;
    }
    emit(state.copyWith(status: InstructorReviewsStatus.loadingMore));

    try {
      final nextPage = state.currentPage + 1;
      final reviews = await _repository.getReviews(
        courseId: state.currentCourseId,
        minRating: state.currentMinRating,
        maxRating: state.currentMaxRating,
        page: nextPage,
      );
      emit(state.copyWith(
        status: InstructorReviewsStatus.success,
        reviews: [...state.reviews, ...reviews],
        currentPage: nextPage,
        hasMore: reviews.length >= 20,
      ));
    } catch (e) {
      emit(state.copyWith(
          status: InstructorReviewsStatus.error, errorMessage: e.toString()));
    }
  }

  /// Filter by course
  void filterByCourse(String? courseId) {
    loadReviews(
        courseId: courseId,
        minRating: state.currentMinRating,
        maxRating: state.currentMaxRating,
        refresh: true);
  }

  /// Filter by rating
  void filterByRating(int? minRating, int? maxRating) {
    loadReviews(
        courseId: state.currentCourseId,
        minRating: minRating,
        maxRating: maxRating,
        refresh: true);
  }

  /// Reply to a review
  Future<void> replyToReview(String reviewId, String reply) async {
    emit(state.copyWith(status: InstructorReviewsStatus.loading));
    try {
      await _repository.replyToReview(reviewId, reply);
      await loadReviews(
        courseId: state.currentCourseId,
        minRating: state.currentMinRating,
        maxRating: state.currentMaxRating,
        refresh: true,
      );
    } catch (e) {
      emit(state.copyWith(
          status: InstructorReviewsStatus.error, errorMessage: e.toString()));
    }
  }
}
