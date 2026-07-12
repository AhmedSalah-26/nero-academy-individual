part of 'admin_payouts_cubit.dart';

/// Status for admin payouts operations
enum AdminPayoutsStatus {
  initial,
  loading,
  loadingMore,
  success,
  error,
  processing,
}

/// State for admin payouts management
class AdminPayoutsState extends Equatable {
  final AdminPayoutsStatus status;
  final AdminPayoutsStatus actionStatus;
  final List<AdminPayoutModel> payouts;
  final PayoutStatsModel? stats;
  final AdminPayoutModel? selectedPayout;
  final PayoutStatusType? currentStatus;
  final String? searchQuery;
  final DateTime? fromDate;
  final DateTime? toDate;
  final int currentPage;
  final bool hasMore;
  final String? errorMessage;

  const AdminPayoutsState({
    this.status = AdminPayoutsStatus.initial,
    this.actionStatus = AdminPayoutsStatus.initial,
    this.payouts = const [],
    this.stats,
    this.selectedPayout,
    this.currentStatus,
    this.searchQuery,
    this.fromDate,
    this.toDate,
    this.currentPage = 1,
    this.hasMore = true,
    this.errorMessage,
  });

  /// Get pending count for badge
  int get pendingCount =>
      stats?.awaitingActionCount ??
      payouts.where((p) => p.isPending || p.isUnderReview).length;

  /// Get total pending amount
  double get pendingAmount =>
      stats?.awaitingActionAmount ??
      payouts
          .where((p) => p.isPending || p.isUnderReview)
          .fold(0, (sum, p) => sum + p.amount);

  AdminPayoutsState copyWith({
    AdminPayoutsStatus? status,
    AdminPayoutsStatus? actionStatus,
    List<AdminPayoutModel>? payouts,
    PayoutStatsModel? stats,
    AdminPayoutModel? selectedPayout,
    PayoutStatusType? currentStatus,
    String? searchQuery,
    DateTime? fromDate,
    DateTime? toDate,
    int? currentPage,
    bool? hasMore,
    String? errorMessage,
    bool clearStatus = false,
    bool clearSelectedPayout = false,
  }) {
    return AdminPayoutsState(
      status: status ?? this.status,
      actionStatus: actionStatus ?? this.actionStatus,
      payouts: payouts ?? this.payouts,
      stats: stats ?? this.stats,
      selectedPayout:
          clearSelectedPayout ? null : (selectedPayout ?? this.selectedPayout),
      currentStatus: clearStatus ? null : (currentStatus ?? this.currentStatus),
      searchQuery: searchQuery ?? this.searchQuery,
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        actionStatus,
        payouts,
        stats,
        selectedPayout,
        currentStatus,
        searchQuery,
        fromDate,
        toDate,
        currentPage,
        hasMore,
        errorMessage,
      ];
}
