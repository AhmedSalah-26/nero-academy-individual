/// Payment status for orders
enum PaymentStatus {
  pending, // Waiting for payment
  paid, // Payment successful
  failed, // Payment failed
  refunded, // Payment refunded
  cashOnDelivery; // Cash on delivery (no online payment)

  static PaymentStatus fromString(String? value) {
    if (value == null) return PaymentStatus.cashOnDelivery;
    return PaymentStatus.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => PaymentStatus.pending,
    );
  }

  String get displayNameAr {
    switch (this) {
      case PaymentStatus.pending:
        return 'في انتظار الدفع';
      case PaymentStatus.paid:
        return 'مدفوع';
      case PaymentStatus.failed:
        return 'فشل الدفع';
      case PaymentStatus.refunded:
        return 'مسترد';
      case PaymentStatus.cashOnDelivery:
        return 'الدفع عند الاستلام';
    }
  }

  String get displayNameEn {
    switch (this) {
      case PaymentStatus.pending:
        return 'Pending Payment';
      case PaymentStatus.paid:
        return 'Paid';
      case PaymentStatus.failed:
        return 'Payment Failed';
      case PaymentStatus.refunded:
        return 'Refunded';
      case PaymentStatus.cashOnDelivery:
        return 'Cash on Delivery';
    }
  }

  String getDisplayName(String locale) =>
      locale == 'ar' ? displayNameAr : displayNameEn;
}
