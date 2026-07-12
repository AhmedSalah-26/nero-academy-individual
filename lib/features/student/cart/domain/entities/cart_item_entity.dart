import 'package:equatable/equatable.dart';
import 'package:lms_platform/core/models/course_commerce_models.dart';

/// Cart Item Entity - Pure Dart Object
class CartItemEntity extends Equatable {
  final String id;
  final String courseId;
  final String? titleAr;
  final String? titleEn;
  final String? thumbnailUrl;
  final String? instructorName;
  final double rating;
  final int ratingCount;
  final double price;
  final double? discountPrice;
  final double priceAtAdd;
  final String currency;
  final bool isFree;
  final CoursePricingOption? pricingOption;
  final DateTime addedAt;

  const CartItemEntity({
    required this.id,
    required this.courseId,
    this.titleAr,
    this.titleEn,
    this.thumbnailUrl,
    this.instructorName,
    this.rating = 0,
    this.ratingCount = 0,
    this.price = 0,
    this.discountPrice,
    this.priceAtAdd = 0,
    this.currency = 'EGP',
    this.isFree = false,
    this.pricingOption,
    required this.addedAt,
  });

  /// Get title based on locale
  String getTitle(String locale) =>
      locale == 'ar' ? (titleAr ?? titleEn ?? '') : (titleEn ?? titleAr ?? '');

  /// Get current effective price
  double get currentPrice {
    if (isFree) return 0;
    if (pricingOption != null) return priceAtAdd.round().toDouble();
    final price = discountPrice ?? this.price;
    return price.round().toDouble();
  }

  /// Check if price changed since added
  bool get hasPriceChanged => priceAtAdd != currentPrice;

  /// Get discount percentage
  int? get discountPercentage {
    if (isFree || price <= 0) return null;
    if (discountPrice == null || discountPrice! >= price) return null;
    return ((price - discountPrice!) / price * 100).round();
  }

  @override
  List<Object?> get props => [
        id,
        courseId,
        titleAr,
        titleEn,
        price,
        discountPrice,
        priceAtAdd,
        pricingOption,
        addedAt,
      ];
}
