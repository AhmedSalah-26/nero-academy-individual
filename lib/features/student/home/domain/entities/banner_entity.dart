import 'package:equatable/equatable.dart';

/// Banner Entity - Pure Dart Object for Home Carousel
class BannerEntity extends Equatable {
  final String id;
  final String imageUrl;
  final String? titleAr;
  final String? titleEn;
  final String? subtitleAr;
  final String? subtitleEn;
  final BannerLinkType linkType;
  final String? linkValue;
  final int sortOrder;
  final bool isActive;
  final DateTime? startDate;
  final DateTime? endDate;

  const BannerEntity({
    required this.id,
    required this.imageUrl,
    this.titleAr,
    this.titleEn,
    this.subtitleAr,
    this.subtitleEn,
    this.linkType = BannerLinkType.none,
    this.linkValue,
    this.sortOrder = 0,
    this.isActive = true,
    this.startDate,
    this.endDate,
  });

  String getTitle(String locale) =>
      locale == 'ar' ? (titleAr ?? titleEn ?? '') : (titleEn ?? titleAr ?? '');
  String getSubtitle(String locale) => locale == 'ar'
      ? (subtitleAr ?? subtitleEn ?? '')
      : (subtitleEn ?? subtitleAr ?? '');

  bool get isCurrentlyActive {
    if (!isActive) return false;
    final now = DateTime.now();
    if (startDate != null && now.isBefore(startDate!)) return false;
    if (endDate != null && now.isAfter(endDate!)) return false;
    return true;
  }

  @override
  List<Object?> get props => [
        id,
        imageUrl,
        titleAr,
        titleEn,
        subtitleAr,
        subtitleEn,
        linkType,
        linkValue,
        sortOrder,
        isActive,
        startDate,
        endDate
      ];
}

/// Banner Link Type Enum
enum BannerLinkType {
  none,
  course,
  category,
  url,
  instructor;

  static BannerLinkType fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'course':
        return BannerLinkType.course;
      case 'category':
        return BannerLinkType.category;
      case 'url':
        return BannerLinkType.url;
      case 'instructor':
        return BannerLinkType.instructor;
      default:
        return BannerLinkType.none;
    }
  }

  String toJson() => name;
}
