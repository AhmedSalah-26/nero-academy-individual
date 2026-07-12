/// Banner Model
class BannerModel {
  final String id;
  final String titleAr;
  final String? titleEn;
  final String? subtitleAr;
  final String? subtitleEn;
  final String imageUrl;
  final String
      linkType; // 'none' | 'course' | 'category' | 'url' | 'instructor'
  final String? linkValue;
  final int sortOrder;
  final bool isActive;
  final DateTime? startDate;
  final DateTime? endDate;
  final int clicksCount;
  final int viewsCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BannerModel({
    required this.id,
    required this.titleAr,
    this.titleEn,
    this.subtitleAr,
    this.subtitleEn,
    required this.imageUrl,
    this.linkType = 'none',
    this.linkValue,
    this.sortOrder = 0,
    this.isActive = true,
    this.startDate,
    this.endDate,
    this.clicksCount = 0,
    this.viewsCount = 0,
    required this.createdAt,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? createdAt;

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['id'] as String,
      titleAr: json['title_ar'] as String? ?? '',
      titleEn: json['title_en'] as String?,
      subtitleAr: json['subtitle_ar'] as String?,
      subtitleEn: json['subtitle_en'] as String?,
      imageUrl: json['image_url'] as String? ?? '',
      linkType: json['link_type'] as String? ?? 'none',
      linkValue: json['link_value'] as String?,
      sortOrder: json['sort_order'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'] as String)
          : null,
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : null,
      clicksCount: json['clicks_count'] as int? ?? 0,
      viewsCount: json['views_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title_ar': titleAr,
      'title_en': titleEn,
      'subtitle_ar': subtitleAr,
      'subtitle_en': subtitleEn,
      'image_url': imageUrl,
      'link_type': linkType,
      'link_value': linkValue,
      'sort_order': sortOrder,
      'is_active': isActive,
      'start_date': startDate?.toUtc().toIso8601String(),
      'end_date': endDate?.toUtc().toIso8601String(),
      'clicks_count': clicksCount,
      'views_count': viewsCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool get isWithinDateRange {
    final now = DateTime.now();
    if (startDate != null && now.isBefore(startDate!)) return false;
    if (endDate != null && now.isAfter(endDate!)) return false;
    return true;
  }

  bool get isVisible => isActive && isWithinDateRange;
  bool get isScheduled =>
      startDate != null && DateTime.now().isBefore(startDate!);
  bool get isExpired => endDate != null && DateTime.now().isAfter(endDate!);

  String get statusLabel {
    if (!isActive) return 'inactive';
    if (isExpired) return 'expired';
    if (isScheduled) return 'scheduled';
    return 'active';
  }

  double get clickThroughRate {
    if (viewsCount == 0) return 0;
    return (clicksCount / viewsCount) * 100;
  }
}
