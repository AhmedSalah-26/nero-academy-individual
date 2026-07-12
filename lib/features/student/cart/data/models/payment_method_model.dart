import 'package:lms_platform/features/student/cart/domain/entities/payment_method_entity.dart';

/// Saved Payment Method Model - Data Model with JSON serialization
class SavedPaymentMethodModel extends SavedPaymentMethodEntity {
  const SavedPaymentMethodModel({
    required super.id,
    required super.type,
    super.cardBrand,
    super.lastFourDigits,
    super.expiryDate,
    super.isDefault,
  });

  factory SavedPaymentMethodModel.fromJson(Map<String, dynamic> json) {
    return SavedPaymentMethodModel(
      id: json['id'] as String,
      type: PaymentMethodType.fromString(json['type'] as String?),
      cardBrand: json['card_brand'] as String?,
      lastFourDigits: json['last_four_digits'] as String?,
      expiryDate: json['expiry_date'] as String?,
      isDefault: json['is_default'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'card_brand': cardBrand,
      'last_four_digits': lastFourDigits,
      'expiry_date': expiryDate,
      'is_default': isDefault,
    };
  }
}
