import 'package:equatable/equatable.dart';

/// Payment Method Type Enum
enum PaymentMethodType {
  manual,
  card,
  wallet,
  vodafoneCash,
  applePay,
  paypal;

  static PaymentMethodType fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'manual':
        return PaymentMethodType.manual;
      case 'card':
        return PaymentMethodType.card;
      case 'wallet':
        return PaymentMethodType.wallet;
      case 'vodafone_cash':
      case 'vodafone':
        return PaymentMethodType.vodafoneCash;
      case 'apple_pay':
        return PaymentMethodType.applePay;
      case 'paypal':
        return PaymentMethodType.paypal;
      default:
        return PaymentMethodType.card;
    }
  }

  String get displayName {
    switch (this) {
      case PaymentMethodType.manual:
        return 'Manual Payment';
      case PaymentMethodType.card:
        return 'Credit/Debit Card';
      case PaymentMethodType.wallet:
        return 'Wallet';
      case PaymentMethodType.vodafoneCash:
        return 'Vodafone Cash';
      case PaymentMethodType.applePay:
        return 'Apple Pay';
      case PaymentMethodType.paypal:
        return 'PayPal';
    }
  }
}

/// Saved Payment Method Entity
class SavedPaymentMethodEntity extends Equatable {
  final String id;
  final PaymentMethodType type;
  final String? cardBrand;
  final String? lastFourDigits;
  final String? expiryDate;
  final bool isDefault;

  const SavedPaymentMethodEntity({
    required this.id,
    required this.type,
    this.cardBrand,
    this.lastFourDigits,
    this.expiryDate,
    this.isDefault = false,
  });

  /// Get display text for card
  String get displayText {
    if (type == PaymentMethodType.card && lastFourDigits != null) {
      return '${cardBrand ?? 'Card'} ending in $lastFourDigits';
    }
    return type.displayName;
  }

  @override
  List<Object?> get props => [id, type, cardBrand, lastFourDigits, isDefault];
}
