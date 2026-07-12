import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lms_platform/core/base/base_state.dart';
import 'package:lms_platform/core/services/app_logger.dart';
import 'package:lms_platform/features/student/my_learning/domain/entities/enrollment_entity.dart';
import 'package:lms_platform/features/student/my_learning/domain/usecases/get_continue_learning_usecase.dart';
import 'package:lms_platform/features/student/my_learning/domain/usecases/get_enrollments_usecase.dart';
import 'my_learning_state.dart';

/// My Learning Cubit - Manages My Learning screen state
class MyLearningCubit extends Cubit<MyLearningState> {
  final GetEnrollmentsUseCase _getEnrollmentsUseCase;
  final GetContinueLearningUseCase _getContinueLearningUseCase;

  String? _currentUserId;

  MyLearningCubit({
    required GetEnrollmentsUseCase getEnrollmentsUseCase,
    required GetContinueLearningUseCase getContinueLearningUseCase,
  })  : _getEnrollmentsUseCase = getEnrollmentsUseCase,
        _getContinueLearningUseCase = getContinueLearningUseCase,
        super(const MyLearningState());

  String? get currentUserId => _currentUserId;

  /// Load initial data
  Future<void> loadMyLearning(String userId) async {
    if (state.isLoading) return;

    _currentUserId = userId;
    emit(state.copyWith(status: StateStatus.loading, clearFailure: true));

    AppLogger.i('📚 [MyLearningCubit] Loading data for user: $userId');

    // Load continue learning and enrollments in parallel
    final results = await Future.wait([
      _getContinueLearningUseCase(userId),
      _getEnrollmentsUseCase(GetEnrollmentsParams(userId: userId)),
    ]);

    final continueResult = results[0];
    final enrollmentsResult = results[1];

    EnrollmentEntity? continueLearning;
    List<EnrollmentEntity> enrollments = [];

    continueResult.fold(
      (failure) => AppLogger.w('Continue learning failed: ${failure.message}'),
      (data) => continueLearning = data as EnrollmentEntity?,
    );

    enrollmentsResult.fold(
      (failure) {
        emit(state.copyWith(
          status: StateStatus.error,
          failure: failure,
        ));
        return;
      },
      (data) => enrollments = data as List<EnrollmentEntity>,
    );

    emit(state.copyWith(
      status: StateStatus.success,
      continueLearning: continueLearning,
      enrollments: enrollments,
      hasMore: enrollments.length >= 20,
      page: 1,
      clearContinueLearning: continueLearning == null,
    ));

    AppLogger.i(
        '📚 [MyLearningCubit] Loaded ${enrollments.length} enrollments');
  }

  /// Refresh data
  Future<void> refresh() async {
    if (_currentUserId == null || state.isRefreshing) return;

    emit(state.copyWith(isRefreshing: true));
    await loadMyLearning(_currentUserId!);
    emit(state.copyWith(isRefreshing: false));
  }

  /// Load more enrollments (pagination)
  Future<void> loadMore() async {
    if (_currentUserId == null || state.isLoadingMore || !state.hasMore) return;

    emit(state.copyWith(isLoadingMore: true));

    final nextPage = state.page + 1;
    final result = await _getEnrollmentsUseCase(
      GetEnrollmentsParams(userId: _currentUserId!, page: nextPage),
    );

    result.fold(
      (failure) {
        emit(state.copyWith(isLoadingMore: false));
        AppLogger.w('Load more failed: ${failure.message}');
      },
      (newEnrollments) {
        emit(state.copyWith(
          enrollments: [...state.enrollments, ...newEnrollments],
          hasMore: newEnrollments.length >= 20,
          page: nextPage,
          isLoadingMore: false,
        ));
      },
    );
  }

  /// Change filter
  void setFilter(MyLearningFilter filter) {
    if (state.filter == filter) return;
    emit(state.copyWith(filter: filter));
  }

  /// Clear error
  void clearError() {
    emit(state.copyWith(clearFailure: true));
  }
}
