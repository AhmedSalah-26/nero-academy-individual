/// Payment method types
enum PaymentMethodType {
  cashOnDelivery,
  card,
  wallet,
}

/// Extension for payment method display
extension PaymentMethodTypeExtension on PaymentMethodType {
  String get nameAr {
    switch (this) {
      case PaymentMethodType.cashOnDelivery:
        return 'الدفع عند الاستلام';
      case PaymentMethodType.card:
        return 'بطاقة ائتمان';
      case PaymentMethodType.wallet:
        return 'محفظة إلكترونية';
    }
  }

  String get nameEn {
    switch (this) {
      case PaymentMethodType.cashOnDelivery:
        return 'Cash on Delivery';
      case PaymentMethodType.card:
        return 'Credit Card';
      case PaymentMethodType.wallet:
        return 'Mobile Wallet';
    }
  }

  String getName(String locale) => locale == 'ar' ? nameAr : nameEn;
}
