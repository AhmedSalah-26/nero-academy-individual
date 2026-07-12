part of 'admin_users_cubit.dart';

enum AdminUsersStatus { initial, loading, loadingMore, success, error }

class AdminUsersState extends Equatable {
  final AdminUsersStatus status;
  final AdminUsersStatus actionStatus;
  final List<AdminUserModel> users;
  final UserRole currentRole;
  final String? searchQuery;
  final int currentPage;
  final bool hasMore;
  final String? errorMessage;

  const AdminUsersState({
    this.status = AdminUsersStatus.initial,
    this.actionStatus = AdminUsersStatus.initial,
    this.users = const [],
    this.currentRole = UserRole.student,
    this.searchQuery,
    this.currentPage = 1,
    this.hasMore = true,
    this.errorMessage,
  });

  bool get isLoading => status == AdminUsersStatus.loading;
  bool get isLoadingMore => status == AdminUsersStatus.loadingMore;
  bool get hasError => status == AdminUsersStatus.error;

  AdminUsersState copyWith({
    AdminUsersStatus? status,
    AdminUsersStatus? actionStatus,
    List<AdminUserModel>? users,
    UserRole? currentRole,
    String? searchQuery,
    int? currentPage,
    bool? hasMore,
    String? errorMessage,
  }) {
    return AdminUsersState(
      status: status ?? this.status,
      actionStatus: actionStatus ?? this.actionStatus,
      users: users ?? this.users,
      currentRole: currentRole ?? this.currentRole,
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
        users,
        currentRole,
        searchQuery,
        currentPage,
        hasMore,
        errorMessage,
      ];
}
