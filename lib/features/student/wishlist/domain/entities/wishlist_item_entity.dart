import 'package:equatable/equatable.dart';

/// Wishlist Item Entity - Pure Dart Object
class WishlistItemEntity extends Equatable {
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
  final String currency;
  final bool isFree;
  final bool isEnrolled;
  final bool isBestseller;
  final DateTime addedAt;

  const WishlistItemEntity({
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
    this.currency = 'EGP',
    this.isFree = false,
    this.isEnrolled = false,
    this.isBestseller = false,
    required this.addedAt,
  });

  /// Get title based on locale
  String getTitle(String locale) =>
      locale == 'ar' ? (titleAr ?? titleEn ?? '') : (titleEn ?? titleAr ?? '');

  /// Get current effective price
  double get currentPrice {
    if (isFree) return 0;
    final price = discountPrice ?? this.price;
    return price.round().toDouble();
  }

  /// Get discount percentage
  int? get discountPercentage {
    if (isFree || price <= 0) return null;
    if (discountPrice == null || discountPrice! >= price) return null;
    return ((price - discountPrice!) / price * 100).round();
  }

  /// Check if has price drop
  bool get hasPriceDrop =>
      discountPercentage != null && discountPercentage! > 0;

  @override
  List<Object?> get props => [
        id,
        courseId,
        titleAr,
        titleEn,
        price,
        discountPrice,
        isEnrolled,
        addedAt,
      ];
}
