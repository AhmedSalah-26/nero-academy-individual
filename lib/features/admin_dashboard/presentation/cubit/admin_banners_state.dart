part of 'admin_banners_cubit.dart';

enum AdminBannersStatus {
  initial,
  loading,
  loadingMore,
  success,
  error,
  creating,
  updating,
  deleting,
  reordering,
}

class AdminBannersState extends Equatable {
  final AdminBannersStatus status;
  final AdminBannersStatus actionStatus;
  final List<AdminBannerModel> banners;
  final String? currentStatus;
  final int currentPage;
  final bool hasMore;
  final String? errorMessage;

  const AdminBannersState({
    this.status = AdminBannersStatus.initial,
    this.actionStatus = AdminBannersStatus.initial,
    this.banners = const [],
    this.currentStatus,
    this.currentPage = 1,
    this.hasMore = true,
    this.errorMessage,
  });

  AdminBannersState copyWith({
    AdminBannersStatus? status,
    AdminBannersStatus? actionStatus,
    List<AdminBannerModel>? banners,
    String? Function()? currentStatus,
    int? currentPage,
    bool? hasMore,
    String? errorMessage,
  }) {
    return AdminBannersState(
      status: status ?? this.status,
      actionStatus: actionStatus ?? this.actionStatus,
      banners: banners ?? this.banners,
      currentStatus:
          currentStatus != null ? currentStatus() : this.currentStatus,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        actionStatus,
        banners,
        currentStatus,
        currentPage,
        hasMore,
        errorMessage,
      ];
}
