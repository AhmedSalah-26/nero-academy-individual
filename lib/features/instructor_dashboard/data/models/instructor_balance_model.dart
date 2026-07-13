/// Wallet Summary Model — mirrors user balance fields
class WalletSummaryModel {
  final String teacherId;
  final double availableBalance;
  final double pendingBalance;
  final double totalEarnings;
  final double totalWithdrawn;
  final DateTime updatedAt;

  const WalletSummaryModel({
    required this.teacherId,
    required this.availableBalance,
    required this.pendingBalance,
    required this.totalEarnings,
    required this.totalWithdrawn,
    required this.updatedAt,
  });

  factory WalletSummaryModel.fromJson(Map<String, dynamic> json) {
    return WalletSummaryModel(
      teacherId: json['teacher_id'] as String,
      availableBalance: (json['available_balance'] as num?)?.toDouble() ?? 0,
      pendingBalance: (json['pending_balance'] as num?)?.toDouble() ?? 0,
      totalEarnings: (json['total_earnings'] as num?)?.toDouble() ?? 0,
      totalWithdrawn: (json['total_withdrawn'] as num?)?.toDouble() ?? 0,
      updatedAt: DateTime.parse(
          json['updated_at'] as String? ?? DateTime.now().toIso8601String()),
    );
  }

  /// Empty balance (fallback when no row exists yet)
  static final empty = WalletSummaryModel(
    teacherId: '',
    availableBalance: 0,
    pendingBalance: 0,
    totalEarnings: 0,
    totalWithdrawn: 0,
    updatedAt: DateTime.utc(1970),
  );
}
