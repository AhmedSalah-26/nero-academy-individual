/// Payout Status enum — matches NEW DB: pending, approved, rejected, paid
enum PayoutStatusType {
  pending,
  underReview, // mapped to 'approved' in new schema for backward compat
  completed, // mapped to 'paid' in new schema
  rejected;

  static PayoutStatusType fromString(String value) {
    switch (value) {
      case 'pending':
        return PayoutStatusType.pending;
      case 'approved':
      case 'under_review':
        return PayoutStatusType.underReview;
      case 'paid':
      case 'completed':
        return PayoutStatusType.completed;
      case 'rejected':
        return PayoutStatusType.rejected;
      default:
        return PayoutStatusType.pending;
    }
  }

  String toJsonValue() {
    switch (this) {
      case PayoutStatusType.pending:
        return 'pending';
      case PayoutStatusType.underReview:
        return 'approved';
      case PayoutStatusType.completed:
        return 'paid';
      case PayoutStatusType.rejected:
        return 'rejected';
    }
  }

  /// Valid transitions from this status
  List<PayoutStatusType> get validTransitions {
    switch (this) {
      case PayoutStatusType.pending:
        return [PayoutStatusType.underReview, PayoutStatusType.rejected];
      case PayoutStatusType.underReview:
        return [PayoutStatusType.completed, PayoutStatusType.rejected];
      case PayoutStatusType.completed:
      case PayoutStatusType.rejected:
        return []; // Terminal states
    }
  }

  bool canTransitionTo(PayoutStatusType target) =>
      validTransitions.contains(target);

  bool get isTerminal =>
      this == PayoutStatusType.completed || this == PayoutStatusType.rejected;
}

/// Payout Method enum
enum PayoutMethod {
  instapay,
  wallet,
  other;

  static PayoutMethod fromString(String value) {
    switch (value) {
      case 'instapay':
        return PayoutMethod.instapay;
      case 'wallet':
        return PayoutMethod.wallet;
      default:
        return PayoutMethod.other;
    }
  }

  String toJsonValue() {
    switch (this) {
      case PayoutMethod.instapay:
        return 'instapay';
      case PayoutMethod.wallet:
        return 'wallet';
      case PayoutMethod.other:
        return 'wallet';
    }
  }
}

/// Admin Payout Model — reads from withdraw_requests table
class AdminPayoutModel {
  final String id;
  final String instructorId;
  final String? instructorName;
  final String? instructorEmail;
  final String? instructorAvatar;
  final double amount;
  final String currency;
  final PayoutMethod payoutMethod;
  final Map<String, dynamic>? payoutDetails;
  final PayoutStatusType status;
  final String? notes;
  final DateTime requestedAt;
  final DateTime? processedAt;
  final String? processedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AdminPayoutModel({
    required this.id,
    required this.instructorId,
    this.instructorName,
    this.instructorEmail,
    this.instructorAvatar,
    required this.amount,
    this.currency = 'EGP',
    required this.payoutMethod,
    this.payoutDetails,
    required this.status,
    this.notes,
    required this.requestedAt,
    this.processedAt,
    this.processedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AdminPayoutModel.fromJson(Map<String, dynamic> json) {
    return AdminPayoutModel(
      id: json['id'] as String,
      instructorId:
          json['user_id'] as String? ?? json['instructor_id'] as String? ?? '',
      instructorName: _extractField(json['instructor'], 'name'),
      instructorEmail: _extractField(json['instructor'], 'email'),
      instructorAvatar: _extractField(json['instructor'], 'avatar_url'),
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'EGP',
      payoutMethod: PayoutMethod.fromString(json['method'] as String? ??
          json['payout_method'] as String? ??
          'other'),
      payoutDetails: json['account_details'] as Map<String, dynamic>? ??
          json['payout_details'] as Map<String, dynamic>?,
      status:
          PayoutStatusType.fromString(json['status'] as String? ?? 'pending'),
      notes: json['notes'] as String?,
      requestedAt: DateTime.parse(json['requested_at'] as String),
      processedAt: json['approved_at'] != null
          ? DateTime.parse(json['approved_at'] as String)
          : json['processed_at'] != null
              ? DateTime.parse(json['processed_at'] as String)
              : null,
      processedBy:
          json['admin_id'] as String? ?? json['processed_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(
          json['updated_at'] as String? ?? json['created_at'] as String),
    );
  }

  static String? _extractField(dynamic instructor, String field) {
    if (instructor == null) return null;
    if (instructor is Map<String, dynamic>) {
      return instructor[field] as String?;
    }
    return null;
  }

  bool get isPending => status == PayoutStatusType.pending;
  bool get isUnderReview => status == PayoutStatusType.underReview;
  bool get isCompleted => status == PayoutStatusType.completed;
  bool get isRejected => status == PayoutStatusType.rejected;
  bool get isTerminal => status.isTerminal;

  bool canTransitionTo(PayoutStatusType target) =>
      status.canTransitionTo(target);

  String get formattedAmount => '$currency ${amount.toStringAsFixed(0)}';

  AdminPayoutModel copyWith({
    String? id,
    String? instructorId,
    String? instructorName,
    String? instructorEmail,
    String? instructorAvatar,
    double? amount,
    String? currency,
    PayoutMethod? payoutMethod,
    Map<String, dynamic>? payoutDetails,
    PayoutStatusType? status,
    String? notes,
    DateTime? requestedAt,
    DateTime? processedAt,
    String? processedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AdminPayoutModel(
      id: id ?? this.id,
      instructorId: instructorId ?? this.instructorId,
      instructorName: instructorName ?? this.instructorName,
      instructorEmail: instructorEmail ?? this.instructorEmail,
      instructorAvatar: instructorAvatar ?? this.instructorAvatar,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      payoutMethod: payoutMethod ?? this.payoutMethod,
      payoutDetails: payoutDetails ?? this.payoutDetails,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      requestedAt: requestedAt ?? this.requestedAt,
      processedAt: processedAt ?? this.processedAt,
      processedBy: processedBy ?? this.processedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AdminPayoutModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// DTO for processing payouts
class ProcessPayoutDto {
  final PayoutStatusType status;
  final String? notes;

  const ProcessPayoutDto({
    required this.status,
    this.notes,
  });
}

/// Model for payout statistics
class PayoutStatsModel {
  final int totalPayouts;
  final int pendingPayouts;
  final int underReviewPayouts;
  final int completedPayouts;
  final int rejectedPayouts;
  final double totalPendingAmount;
  final double totalUnderReviewAmount;
  final double totalCompletedAmount;

  const PayoutStatsModel({
    this.totalPayouts = 0,
    this.pendingPayouts = 0,
    this.underReviewPayouts = 0,
    this.completedPayouts = 0,
    this.rejectedPayouts = 0,
    this.totalPendingAmount = 0,
    this.totalUnderReviewAmount = 0,
    this.totalCompletedAmount = 0,
  });

  factory PayoutStatsModel.fromPayouts(List<AdminPayoutModel> payouts) {
    final pending = payouts.where((p) => p.status == PayoutStatusType.pending);
    final underReview =
        payouts.where((p) => p.status == PayoutStatusType.underReview);
    final completed =
        payouts.where((p) => p.status == PayoutStatusType.completed);
    final rejected =
        payouts.where((p) => p.status == PayoutStatusType.rejected);

    return PayoutStatsModel(
      totalPayouts: payouts.length,
      pendingPayouts: pending.length,
      underReviewPayouts: underReview.length,
      completedPayouts: completed.length,
      rejectedPayouts: rejected.length,
      totalPendingAmount: pending.fold(0, (sum, p) => sum + p.amount),
      totalUnderReviewAmount: underReview.fold(0, (sum, p) => sum + p.amount),
      totalCompletedAmount: completed.fold(0, (sum, p) => sum + p.amount),
    );
  }

  int get awaitingActionCount => pendingPayouts + underReviewPayouts;
  double get awaitingActionAmount =>
      totalPendingAmount + totalUnderReviewAmount;
}
