part of 'admin_coupons_cubit.dart';

/// Status enum for AdminCoupons operations
enum AdminCouponsStatus {
  initial,
  loading,
  loadingMore,
  success,
  error,
  creating,
  updating,
  deleting,
}

/// State class for AdminCoupons
class AdminCouponsState extends Equatable {
  final AdminCouponsStatus status;
  final AdminCouponsStatus actionStatus;
  final List<AdminCouponModel> coupons;
  final String? currentStatus;
  final String? currentScope;
  final String? searchQuery;
  final int currentPage;
  final bool hasMore;
  final String? errorMessage;

  const AdminCouponsState({
    this.status = AdminCouponsStatus.initial,
    this.actionStatus = AdminCouponsStatus.initial,
    this.coupons = const [],
    this.currentStatus,
    this.currentScope,
    this.searchQuery,
    this.currentPage = 1,
    this.hasMore = true,
    this.errorMessage,
  });

  AdminCouponsState copyWith({
    AdminCouponsStatus? status,
    AdminCouponsStatus? actionStatus,
    List<AdminCouponModel>? coupons,
    String? currentStatus,
    String? currentScope,
    String? searchQuery,
    int? currentPage,
    bool? hasMore,
    String? errorMessage,
  }) {
    return AdminCouponsState(
      status: status ?? this.status,
      actionStatus: actionStatus ?? this.actionStatus,
      coupons: coupons ?? this.coupons,
      currentStatus: currentStatus ?? this.currentStatus,
      currentScope: currentScope ?? this.currentScope,
      searchQuery: searchQuery ?? this.searchQuery,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: errorMessage,
    );
  }

  /// Get coupons count by status
  int get activeCouponsCount =>
      coupons.where((c) => c.isActive && !c.isSuspended && !c.isExpired).length;
  int get inactiveCouponsCount => coupons.where((c) => !c.isActive).length;
  int get expiredCouponsCount => coupons.where((c) => c.isExpired).length;
  int get suspendedCouponsCount => coupons.where((c) => c.isSuspended).length;

  @override
  List<Object?> get props => [
        status,
        actionStatus,
        coupons,
        currentStatus,
        currentScope,
        searchQuery,
        currentPage,
        hasMore,
        errorMessage,
      ];
}
