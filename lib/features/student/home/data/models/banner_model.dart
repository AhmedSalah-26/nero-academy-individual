import 'package:lms_platform/features/student/home/domain/entities/banner_entity.dart';

/// Banner Model - Data Model with JSON serialization
class BannerModel extends BannerEntity {
  const BannerModel({
    required super.id,
    required super.imageUrl,
    super.titleAr,
    super.titleEn,
    super.subtitleAr,
    super.subtitleEn,
    super.linkType,
    super.linkValue,
    super.sortOrder,
    super.isActive,
    super.startDate,
    super.endDate,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['id'] as String,
      imageUrl: json['image_url'] as String,
      titleAr: json['title_ar'] as String?,
      titleEn: json['title_en'] as String?,
      subtitleAr: json['subtitle_ar'] as String?,
      subtitleEn: json['subtitle_en'] as String?,
      linkType: BannerLinkType.fromString(json['link_type'] as String?),
      linkValue: json['link_value'] as String?,
      sortOrder: json['sort_order'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'] as String)
          : null,
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'image_url': imageUrl,
      'title_ar': titleAr,
      'title_en': titleEn,
      'subtitle_ar': subtitleAr,
      'subtitle_en': subtitleEn,
      'link_type': linkType.toJson(),
      'link_value': linkValue,
      'sort_order': sortOrder,
      'is_active': isActive,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
    };
  }

  factory BannerModel.fromEntity(BannerEntity entity) {
    return BannerModel(
      id: entity.id,
      imageUrl: entity.imageUrl,
      titleAr: entity.titleAr,
      titleEn: entity.titleEn,
      subtitleAr: entity.subtitleAr,
      subtitleEn: entity.subtitleEn,
      linkType: entity.linkType,
      linkValue: entity.linkValue,
      sortOrder: entity.sortOrder,
      isActive: entity.isActive,
      startDate: entity.startDate,
      endDate: entity.endDate,
    );
  }
}
