import 'package:equatable/equatable.dart';

/// Instructor Course Entity - Course shown in instructor portfolio
class InstructorCourseEntity extends Equatable {
  final String id;
  final String title;
  final String? titleAr;
  final String? thumbnailUrl;
  final double price;
  final double? discountPrice;
  final bool isFlashSale;
  final DateTime? flashSaleStart;
  final DateTime? flashSaleEnd;
  final String currency;
  final double rating;
  final int ratingCount;
  final int enrolledCount;
  final bool isFree;
  final bool isBestseller;

  const InstructorCourseEntity({
    required this.id,
    required this.title,
    this.titleAr,
    this.thumbnailUrl,
    required this.price,
    this.discountPrice,
    this.isFlashSale = false,
    this.flashSaleStart,
    this.flashSaleEnd,
    this.currency = 'EGP',
    this.rating = 0.0,
    this.ratingCount = 0,
    this.enrolledCount = 0,
    this.isFree = false,
    this.isBestseller = false,
  });

  String getTitle(String locale) {
    if (locale == 'ar' && titleAr != null && titleAr!.isNotEmpty) {
      return titleAr!;
    }
    return title;
  }

  bool get isFlashSaleActive {
    if (!isFlashSale) return false;
    final now = DateTime.now();
    if (flashSaleStart != null && now.isBefore(flashSaleStart!)) return false;
    if (flashSaleEnd != null && now.isAfter(flashSaleEnd!)) return false;
    return true;
  }

  double get currentPrice {
    if (isFree) return 0;
    if (isFlashSale) {
      final price =
          isFlashSaleActive ? (discountPrice ?? this.price) : this.price;
      return price.round().toDouble();
    }
    final price = discountPrice ?? this.price;
    return price.round().toDouble();
  }

  int? get discountPercentage {
    if (isFree || price <= 0) return null;
    if (discountPrice == null || discountPrice! >= price) return null;
    if (isFlashSale && !isFlashSaleActive) return null;
    return ((price - discountPrice!) / price * 100).round();
  }

  @override
  List<Object?> get props => [
        id,
        title,
        price,
        discountPrice,
        isFlashSale,
        flashSaleStart,
        flashSaleEnd,
        rating,
        enrolledCount,
      ];
}
