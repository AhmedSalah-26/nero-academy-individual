import '../../domain/entities/admin_entities.dart';

/// Payout Model
class PayoutModel {
  final String id;
  final String instructorId;
  final String instructorName;
  final double amount;
  final String currency;
  final String payoutMethod;
  final PayoutStatus status;
  final String? transactionId;
  final String? failureReason;
  final DateTime requestedAt;
  final DateTime? processedAt;

  const PayoutModel({
    required this.id,
    required this.instructorId,
    required this.instructorName,
    required this.amount,
    this.currency = 'EGP',
    required this.payoutMethod,
    required this.status,
    this.transactionId,
    this.failureReason,
    required this.requestedAt,
    this.processedAt,
  });

  factory PayoutModel.fromJson(Map<String, dynamic> json) {
    return PayoutModel(
      id: json['id'] as String,
      instructorId: json['instructor_id'] as String,
      instructorName: json['instructor_name'] as String? ??
          json['instructor']?['name'] as String? ??
          'Unknown',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? 'EGP',
      payoutMethod: json['payout_method'] as String? ?? 'bank_transfer',
      status: _parseStatus(json['status'] as String?),
      transactionId: json['transaction_id'] as String?,
      failureReason: json['failure_reason'] as String?,
      requestedAt: DateTime.parse(json['requested_at'] as String),
      processedAt: json['processed_at'] != null
          ? DateTime.parse(json['processed_at'] as String)
          : null,
    );
  }

  static PayoutStatus _parseStatus(String? status) {
    switch (status) {
      case 'pending':
        return PayoutStatus.pending;
      case 'processing':
        return PayoutStatus.processing;
      case 'completed':
        return PayoutStatus.completed;
      case 'failed':
        return PayoutStatus.failed;
      case 'cancelled':
        return PayoutStatus.cancelled;
      default:
        return PayoutStatus.pending;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'instructor_id': instructorId,
      'instructor_name': instructorName,
      'amount': amount,
      'currency': currency,
      'payout_method': payoutMethod,
      'status': status.name,
      'transaction_id': transactionId,
      'failure_reason': failureReason,
      'requested_at': requestedAt.toIso8601String(),
      'processed_at': processedAt?.toIso8601String(),
    };
  }
}
