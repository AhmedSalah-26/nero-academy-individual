import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/base/base_state.dart';
import '../../domain/usecases/get_course_details_usecase.dart';
import '../../domain/usecases/get_course_reviews_usecase.dart';
import '../../domain/usecases/enroll_free_course_usecase.dart';
import '../../domain/entities/course_details_entity.dart';
import '../../../wishlist/presentation/cubit/wishlist_cubit.dart';
import 'course_details_state.dart';

/// Course Details Cubit
class CourseDetailsCubit extends Cubit<CourseDetailsState> {
  final GetCourseDetailsUseCase getCourseDetailsUseCase;
  final GetCourseReviewsUseCase getCourseReviewsUseCase;
  final EnrollFreeCourseUseCase enrollFreeCourseUseCase;
  final WishlistCubit wishlistCubit;

  CourseDetailsCubit({
    required this.getCourseDetailsUseCase,
    required this.getCourseReviewsUseCase,
    required this.enrollFreeCourseUseCase,
    required this.wishlistCubit,
  }) : super(const CourseDetailsState());

  String? _currentCourseId;

  /// Load course details
  Future<void> loadCourseDetails(String courseId, {String? userId}) async {
    _currentCourseId = courseId;

    emit(state.copyWith(status: StateStatus.loading));

    final result = await getCourseDetailsUseCase(
      CourseDetailsParams(courseId: courseId, userId: userId),
    );

    result.fold(
      (failure) => emit(state.copyWith(
        status: StateStatus.error,
        failure: failure,
      )),
      (course) {
        emit(state.copyWith(
          status: StateStatus.success,
          course: course,
          expandedSections: [0], // Expand first section by default
        ));
        // Load reviews after course details
        loadReviews(courseId);
      },
    );
  }

  /// Load course reviews
  Future<void> loadReviews(String courseId, {bool loadMore = false}) async {
    if (state.isReviewsLoading) return;
    if (loadMore && !state.hasMoreReviews) return;

    final page = loadMore ? state.reviewsPage + 1 : 1;

    emit(state.copyWith(isReviewsLoading: true));

    final result = await getCourseReviewsUseCase(
      CourseReviewsParams(courseId: courseId, page: page),
    );

    result.fold(
      (failure) => emit(state.copyWith(isReviewsLoading: false)),
      (reviews) {
        final allReviews = loadMore ? [...state.reviews, ...reviews] : reviews;

        // Calculate rating distribution
        final distribution = <int, int>{5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
        for (var review in allReviews) {
          distribution[review.rating] = (distribution[review.rating] ?? 0) + 1;
        }

        emit(state.copyWith(
          reviews: allReviews,
          ratingDistribution: distribution,
          reviewsPage: page,
          hasMoreReviews: reviews.length >= 10,
          isReviewsLoading: false,
        ));
      },
    );
  }

  /// Toggle wishlist
  Future<void> toggleWishlist() async {
    if (_currentCourseId == null) return;
    if (state.isWishlistLoading) return;

    emit(state.copyWith(isWishlistLoading: true));

    // Use the shared WishlistCubit instead of local logic
    final isAdded = await wishlistCubit.toggleWishlist(_currentCourseId!);

    if (isAdded != null && state.course != null) {
      final updatedCourse = _updateCourseWishlist(isAdded);
      emit(state.copyWith(
        course: updatedCourse,
        isWishlistLoading: false,
      ));
    } else {
      emit(state.copyWith(isWishlistLoading: false));
    }
  }

  /// Toggle section expansion
  void toggleSection(int index) {
    final expanded = List<int>.from(state.expandedSections);
    if (expanded.contains(index)) {
      expanded.remove(index);
    } else {
      expanded.add(index);
    }
    emit(state.copyWith(expandedSections: expanded));
  }

  /// Enroll in a free course directly
  Future<bool> enrollFreeCourse(String userId) async {
    if (_currentCourseId == null) return false;

    // Ideally set a loading state specifically for enrollment if needed
    // but here we just return a bool to show loading in the UI button
    final result = await enrollFreeCourseUseCase(_currentCourseId!, userId);

    return result.fold(
      (failure) => false,
      (_) {
        // Upon success, reload the course details to reflect enrollment status
        loadCourseDetails(_currentCourseId!, userId: userId);
        return true;
      },
    );
  }

  /// Check if section is expanded
  bool isSectionExpanded(int index) {
    return state.expandedSections.contains(index);
  }

  CourseDetailsEntity _updateCourseWishlist(bool isInWishlist) {
    final course = state.course!;
    return CourseDetailsEntity(
      id: course.id,
      titleAr: course.titleAr,
      titleEn: course.titleEn,
      subtitleAr: course.subtitleAr,
      subtitleEn: course.subtitleEn,
      descriptionAr: course.descriptionAr,
      descriptionEn: course.descriptionEn,
      thumbnailUrl: course.thumbnailUrl,
      previewVideoUrl: course.previewVideoUrl,
      level: course.level,
      language: course.language,
      price: course.price,
      discountPrice: course.discountPrice,
      currency: course.currency,
      isFree: course.isFree,
      isFlashSale: course.isFlashSale,
      flashSaleStart: course.flashSaleStart,
      flashSaleEnd: course.flashSaleEnd,
      badge: course.badge,
      pricingOptions: course.pricingOptions,
      groupLinks: course.groupLinks,
      rating: course.rating,
      ratingCount: course.ratingCount,
      enrolledCount: course.enrolledCount,
      totalDuration: course.totalDuration,
      totalLessons: course.totalLessons,
      totalQuizzes: course.totalQuizzes,
      isFeatured: course.isFeatured,
      updatedAt: course.updatedAt,
      publishedAt: course.publishedAt,
      objectives: course.objectives,
      requirements: course.requirements,
      targetAudience: course.targetAudience,
      hasCertificate: course.hasCertificate,
      instructor: course.instructor,
      sections: course.sections,
      ratingSummary: course.ratingSummary,
      topReviews: course.topReviews,
      enrollmentStatus: course.enrollmentStatus,
      enrollmentId: course.enrollmentId,
      progressPercentage: course.progressPercentage,
      isInWishlist: isInWishlist,
      isInCart: course.isInCart,
    );
  }
}
