part of 'admin_courses_cubit.dart';

enum AdminCoursesStatus { initial, loading, loadingMore, success, error }

class AdminCoursesState extends Equatable {
  final AdminCoursesStatus status;
  final AdminCoursesStatus actionStatus;
  final List<AdminCourseModel> courses;
  final CourseStatus currentStatus;
  final String? searchQuery;
  final int currentPage;
  final bool hasMore;
  final String? errorMessage;

  const AdminCoursesState({
    this.status = AdminCoursesStatus.initial,
    this.actionStatus = AdminCoursesStatus.initial,
    this.courses = const [],
    this.currentStatus = CourseStatus.all,
    this.searchQuery,
    this.currentPage = 1,
    this.hasMore = true,
    this.errorMessage,
  });

  bool get isLoading => status == AdminCoursesStatus.loading;
  bool get isLoadingMore => status == AdminCoursesStatus.loadingMore;
  bool get hasError => status == AdminCoursesStatus.error;

  AdminCoursesState copyWith({
    AdminCoursesStatus? status,
    AdminCoursesStatus? actionStatus,
    List<AdminCourseModel>? courses,
    CourseStatus? currentStatus,
    String? searchQuery,
    int? currentPage,
    bool? hasMore,
    String? errorMessage,
  }) {
    return AdminCoursesState(
      status: status ?? this.status,
      actionStatus: actionStatus ?? this.actionStatus,
      courses: courses ?? this.courses,
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
        courses,
        currentStatus,
        searchQuery,
        currentPage,
        hasMore,
        errorMessage,
      ];
}
