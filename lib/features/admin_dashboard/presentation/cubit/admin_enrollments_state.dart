part of 'admin_enrollments_cubit.dart';

enum AdminEnrollmentsStatus { initial, loading, loadingMore, success, error }

class AdminEnrollmentsState extends Equatable {
  final AdminEnrollmentsStatus status;
  final AdminEnrollmentsStatus actionStatus;
  final List<AdminEnrollmentModel> enrollments;
  final EnrollmentStatus currentStatus;
  final String? searchQuery;
  final int currentPage;
  final bool hasMore;
  final String? errorMessage;

  const AdminEnrollmentsState({
    this.status = AdminEnrollmentsStatus.initial,
    this.actionStatus = AdminEnrollmentsStatus.initial,
    this.enrollments = const [],
    this.currentStatus = EnrollmentStatus.all,
    this.searchQuery,
    this.currentPage = 1,
    this.hasMore = true,
    this.errorMessage,
  });

  bool get isLoading => status == AdminEnrollmentsStatus.loading;
  bool get isLoadingMore => status == AdminEnrollmentsStatus.loadingMore;
  bool get hasError => status == AdminEnrollmentsStatus.error;

  AdminEnrollmentsState copyWith({
    AdminEnrollmentsStatus? status,
    AdminEnrollmentsStatus? actionStatus,
    List<AdminEnrollmentModel>? enrollments,
    EnrollmentStatus? currentStatus,
    String? searchQuery,
    int? currentPage,
    bool? hasMore,
    String? errorMessage,
  }) {
    return AdminEnrollmentsState(
      status: status ?? this.status,
      actionStatus: actionStatus ?? this.actionStatus,
      enrollments: enrollments ?? this.enrollments,
      currentStatus: currentStatus ?? this.currentStatus,
      searchQuery: searchQuery ?? this.searchQuery,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        actionStatus,
        enrollments,
        currentStatus,
        searchQuery,
        currentPage,
        hasMore,
        errorMessage,
      ];
}
