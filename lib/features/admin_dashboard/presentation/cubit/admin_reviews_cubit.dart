import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/admin_repository.dart';

/// Admin Reviews State
enum AdminReviewsStatus { initial, loading, success, error }

class AdminReviewsState {
  final AdminReviewsStatus status;
  final List<Map<String, dynamic>> reviews;
  final String errorMessage;
  final int currentPage;
  final bool hasMore;
  final String? courseFilter;
  final int? ratingFilter;
  final String? searchQuery;

  const AdminReviewsState({
    this.status = AdminReviewsStatus.initial,
    this.reviews = const [],
    this.errorMessage = '',
    this.currentPage = 1,
    this.hasMore = true,
    this.courseFilter,
    this.ratingFilter,
    this.searchQuery,
  });

  AdminReviewsState copyWith({
    AdminReviewsStatus? status,
    List<Map<String, dynamic>>? reviews,
    String? errorMessage,
    int? currentPage,
    bool? hasMore,
    String? courseFilter,
    int? ratingFilter,
    String? searchQuery,
  }) {
    return AdminReviewsState(
      status: status ?? this.status,
      reviews: reviews ?? this.reviews,
      errorMessage: errorMessage ?? this.errorMessage,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      courseFilter: courseFilter ?? this.courseFilter,
      ratingFilter: ratingFilter ?? this.ratingFilter,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

/// Admin Reviews Cubit
class AdminReviewsCubit extends Cubit<AdminReviewsState> {
  final AdminRepository _repository;

  AdminReviewsCubit(this._repository) : super(const AdminReviewsState());

  Future<void> loadReviews({
    String? courseId,
    int? rating,
    String? search,
    bool refresh = false,
  }) async {
    if (refresh) {
      emit(state.copyWith(
        status: AdminReviewsStatus.loading,
        reviews: [],
        currentPage: 1,
        hasMore: true,
      ));
    } else {
      emit(state.copyWith(status: AdminReviewsStatus.loading));
    }

    try {
      final reviews = await _repository.getAllReviews(
        courseId: courseId,
        minRating: rating,
        maxRating: rating,
        search: search,
        page: 1,
      );
      emit(state.copyWith(
        status: AdminReviewsStatus.success,
        reviews: reviews,
        courseFilter: courseId,
        ratingFilter: rating,
        searchQuery: search,
        currentPage: 1,
        hasMore: reviews.length >= 20,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AdminReviewsStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore) return;
    final nextPage = state.currentPage + 1;

    try {
      final reviews = await _repository.getAllReviews(
        courseId: state.courseFilter,
        minRating: state.ratingFilter,
        maxRating: state.ratingFilter,
        search: state.searchQuery,
        page: nextPage,
      );
      emit(state.copyWith(
        reviews: [...state.reviews, ...reviews],
        currentPage: nextPage,
        hasMore: reviews.length >= 20,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AdminReviewsStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> deleteReview(String reviewId) async {
    try {
      await _repository.deleteReview(reviewId);
      emit(state.copyWith(
        reviews: state.reviews.where((r) => r['id'] != reviewId).toList(),
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AdminReviewsStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> hideReview(String reviewId) async {
    try {
      await _repository.hideReview(reviewId);
      emit(state.copyWith(
        reviews: state.reviews.map((r) {
          if (r['id'] == reviewId) {
            return {...r, 'is_hidden': true};
          }
          return r;
        }).toList(),
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AdminReviewsStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> unhideReview(String reviewId) async {
    try {
      await _repository.unhideReview(reviewId);
      emit(state.copyWith(
        reviews: state.reviews.map((r) {
          if (r['id'] == reviewId) {
            return {...r, 'is_hidden': false};
          }
          return r;
        }).toList(),
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AdminReviewsStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }
}
