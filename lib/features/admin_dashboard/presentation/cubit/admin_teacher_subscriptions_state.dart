part of 'admin_teacher_subscriptions_cubit.dart';

enum AdminTeacherSubscriptionsStatus {
  initial,
  loading,
  loadingMore,
  success,
  error,
}

class AdminTeacherSubscriptionsState extends Equatable {
  final AdminTeacherSubscriptionsStatus status;
  final AdminTeacherSubscriptionsStatus actionStatus;
  final List<AdminTeacherSubscriptionModel> teachers;
  final String? selectedTeacherId;
  final String? searchQuery;
  final int currentPage;
  final bool hasMore;
  final String? errorMessage;

  const AdminTeacherSubscriptionsState({
    this.status = AdminTeacherSubscriptionsStatus.initial,
    this.actionStatus = AdminTeacherSubscriptionsStatus.initial,
    this.teachers = const [],
    this.selectedTeacherId,
    this.searchQuery,
    this.currentPage = 1,
    this.hasMore = true,
    this.errorMessage,
  });

  bool get isLoading => status == AdminTeacherSubscriptionsStatus.loading;
  bool get isLoadingMore =>
      status == AdminTeacherSubscriptionsStatus.loadingMore;

  AdminTeacherSubscriptionModel? get selectedTeacher {
    for (final teacher in teachers) {
      if (teacher.teacherId == selectedTeacherId) return teacher;
    }
    return teachers.isEmpty ? null : teachers.first;
  }

  AdminTeacherSubscriptionsState copyWith({
    AdminTeacherSubscriptionsStatus? status,
    AdminTeacherSubscriptionsStatus? actionStatus,
    List<AdminTeacherSubscriptionModel>? teachers,
    String? selectedTeacherId,
    String? searchQuery,
    int? currentPage,
    bool? hasMore,
    String? errorMessage,
  }) {
    return AdminTeacherSubscriptionsState(
      status: status ?? this.status,
      actionStatus: actionStatus ?? this.actionStatus,
      teachers: teachers ?? this.teachers,
      selectedTeacherId: selectedTeacherId ?? this.selectedTeacherId,
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
        teachers,
        selectedTeacherId,
        searchQuery,
        currentPage,
        hasMore,
        errorMessage,
      ];
}
