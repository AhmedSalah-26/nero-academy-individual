import 'package:equatable/equatable.dart';
import 'package:lms_platform/core/base/base_state.dart';
import 'package:lms_platform/core/errors/failures.dart';
import 'package:lms_platform/features/student/my_learning/domain/entities/enrollment_entity.dart';

/// Filter type for My Learning screen
enum MyLearningFilter { all, inProgress, completed }

/// My Learning State
class MyLearningState extends Equatable {
  final StateStatus status;
  final EnrollmentEntity? continueLearning;
  final List<EnrollmentEntity> enrollments;
  final List<EnrollmentEntity> recommendedCourses;
  final MyLearningFilter filter;
  final Failure? failure;
  final bool hasMore;
  final int page;
  final bool isLoadingMore;
  final bool isRefreshing;

  const MyLearningState({
    this.status = StateStatus.initial,
    this.continueLearning,
    this.enrollments = const [],
    this.recommendedCourses = const [],
    this.filter = MyLearningFilter.all,
    this.failure,
    this.hasMore = true,
    this.page = 1,
    this.isLoadingMore = false,
    this.isRefreshing = false,
  });

  bool get isLoading => status == StateStatus.loading;
  bool get isSuccess => status == StateStatus.success;
  bool get isError => status == StateStatus.error;
  String? get errorMessage => failure?.message;

  bool get isEmpty => enrollments.isEmpty && continueLearning == null;
  bool get hasContinueLearning => continueLearning != null;

  /// Get filtered enrollments based on current filter
  List<EnrollmentEntity> get filteredEnrollments {
    switch (filter) {
      case MyLearningFilter.inProgress:
        return enrollments
            .where((e) => e.status == EnrollmentStatus.active)
            .toList();
      case MyLearningFilter.completed:
        return enrollments
            .where((e) => e.status == EnrollmentStatus.completed)
            .toList();
      case MyLearningFilter.all:
        return enrollments;
    }
  }

  /// Get count for each filter
  int get inProgressCount =>
      enrollments.where((e) => e.status == EnrollmentStatus.active).length;

  int get completedCount =>
      enrollments.where((e) => e.status == EnrollmentStatus.completed).length;

  MyLearningState copyWith({
    StateStatus? status,
    EnrollmentEntity? continueLearning,
    List<EnrollmentEntity>? enrollments,
    List<EnrollmentEntity>? recommendedCourses,
    MyLearningFilter? filter,
    Failure? failure,
    bool? hasMore,
    int? page,
    bool? isLoadingMore,
    bool? isRefreshing,
    bool clearContinueLearning = false,
    bool clearFailure = false,
  }) {
    return MyLearningState(
      status: status ?? this.status,
      continueLearning: clearContinueLearning
          ? null
          : (continueLearning ?? this.continueLearning),
      enrollments: enrollments ?? this.enrollments,
      recommendedCourses: recommendedCourses ?? this.recommendedCourses,
      filter: filter ?? this.filter,
      failure: clearFailure ? null : (failure ?? this.failure),
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  @override
  List<Object?> get props => [
        status,
        continueLearning,
        enrollments,
        recommendedCourses,
        filter,
        failure,
        hasMore,
        page,
        isLoadingMore,
        isRefreshing,
      ];
}
