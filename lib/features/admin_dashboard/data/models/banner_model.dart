import '../../domain/entities/admin_entities.dart';

/// Banner Model
class BannerModel {
  final String id;
  final String imageUrl;
  final String? titleAr;
  final String? titleEn;
  final String? linkUrl;
  final BannerType type;
  final int sortOrder;
  final bool isActive;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime createdAt;

  const BannerModel({
    required this.id,
    required this.imageUrl,
    this.titleAr,
    this.titleEn,
    this.linkUrl,
    required this.type,
    required this.sortOrder,
    required this.isActive,
    this.startDate,
    this.endDate,
    required this.createdAt,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['id'] as String,
      imageUrl: json['image_url'] as String? ?? '',
      titleAr: json['title_ar'] as String?,
      titleEn: json['title_en'] as String?,
      linkUrl: json['link_url'] as String?,
      type: _parseType(json['type'] as String?),
      sortOrder: json['sort_order'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'] as String)
          : null,
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  static BannerType _parseType(String? type) {
    switch (type) {
      case 'home':
        return BannerType.home;
      case 'course':
        return BannerType.course;
      case 'category':
        return BannerType.category;
      default:
        return BannerType.home;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'image_url': imageUrl,
      'title_ar': titleAr,
      'title_en': titleEn,
      'link_url': linkUrl,
      'type': type.name,
      'sort_order': sortOrder,
      'is_active': isActive,
      'start_date': startDate?.toUtc().toIso8601String(),
      'end_date': endDate?.toUtc().toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}
