import 'package:lms_platform/features/student/cart/domain/entities/cart_entity.dart';
import 'cart_item_model.dart';
import 'coupon_model.dart';

/// Cart Model - Data Model with JSON serialization
class CartModel extends CartEntity {
  const CartModel({
    required super.id,
    required super.userId,
    super.items,
    super.appliedCoupon,
    super.updatedAt,
  });

  factory CartModel.fromJson(Map<String, dynamic> json) {
    // Parse cart items
    List<CartItemModel> items = [];
    if (json['cart_items'] != null) {
      items = (json['cart_items'] as List)
          .map((e) => CartItemModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    // Parse applied coupon
    CouponModel? coupon;
    if (json['coupon'] != null) {
      coupon = CouponModel.fromJson(json['coupon'] as Map<String, dynamic>);
    }

    return CartModel(
      id: json['id'] as String? ?? json['user_id'] as String,
      userId: json['user_id'] as String,
      items: items,
      appliedCoupon: coupon,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// Create from list of cart items
  factory CartModel.fromItems({
    required String userId,
    required List<CartItemModel> items,
    CouponModel? coupon,
  }) {
    return CartModel(
      id: userId,
      userId: userId,
      items: items,
      appliedCoupon: coupon,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
