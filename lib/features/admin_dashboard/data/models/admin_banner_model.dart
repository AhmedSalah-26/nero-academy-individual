/// Admin Banner Model - Complete schema fields
class AdminBannerModel {
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

  const AdminBannerModel({
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

  factory AdminBannerModel.fromJson(Map<String, dynamic> json) {
    return AdminBannerModel(
      id: json['id'] as String,
      titleAr: json['title_ar'] as String,
      titleEn: json['title_en'] as String?,
      subtitleAr: json['subtitle_ar'] as String?,
      subtitleEn: json['subtitle_en'] as String?,
      imageUrl: json['image_url'] as String,
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

  /// Check if banner is within date range (visible)
  bool get isWithinDateRange {
    final now = DateTime.now();
    if (startDate != null && now.isBefore(startDate!)) return false;
    if (endDate != null && now.isAfter(endDate!)) return false;
    return true;
  }

  /// Check if banner is currently visible
  bool get isVisible => isActive && isWithinDateRange;

  /// Check if banner is scheduled (future start date)
  bool get isScheduled =>
      startDate != null && DateTime.now().isBefore(startDate!);

  /// Check if banner is expired
  bool get isExpired => endDate != null && DateTime.now().isAfter(endDate!);

  /// Get status label
  String get statusLabel {
    if (!isActive) return 'inactive';
    if (isExpired) return 'expired';
    if (isScheduled) return 'scheduled';
    return 'active';
  }

  /// Get click-through rate
  double get clickThroughRate {
    if (viewsCount == 0) return 0;
    return (clicksCount / viewsCount) * 100;
  }

  AdminBannerModel copyWith({
    String? id,
    String? titleAr,
    String? titleEn,
    String? subtitleAr,
    String? subtitleEn,
    String? imageUrl,
    String? linkType,
    String? linkValue,
    int? sortOrder,
    bool? isActive,
    DateTime? startDate,
    DateTime? endDate,
    int? clicksCount,
    int? viewsCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AdminBannerModel(
      id: id ?? this.id,
      titleAr: titleAr ?? this.titleAr,
      titleEn: titleEn ?? this.titleEn,
      subtitleAr: subtitleAr ?? this.subtitleAr,
      subtitleEn: subtitleEn ?? this.subtitleEn,
      imageUrl: imageUrl ?? this.imageUrl,
      linkType: linkType ?? this.linkType,
      linkValue: linkValue ?? this.linkValue,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      clicksCount: clicksCount ?? this.clicksCount,
      viewsCount: viewsCount ?? this.viewsCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// DTO for creating/updating banners
class CreateBannerDto {
  final String titleAr;
  final String? titleEn;
  final String? subtitleAr;
  final String? subtitleEn;
  final String imageUrl;
  final String linkType;
  final String? linkValue;
  final int sortOrder;
  final DateTime? startDate;
  final DateTime? endDate;

  const CreateBannerDto({
    required this.titleAr,
    this.titleEn,
    this.subtitleAr,
    this.subtitleEn,
    required this.imageUrl,
    this.linkType = 'none',
    this.linkValue,
    this.sortOrder = 0,
    this.startDate,
    this.endDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'title_ar': titleAr,
      'title_en': titleEn,
      'subtitle_ar': subtitleAr,
      'subtitle_en': subtitleEn,
      'image_url': imageUrl,
      'link_type': linkType,
      'link_value': linkValue,
      'sort_order': sortOrder,
      'start_date': startDate?.toUtc().toIso8601String(),
      'end_date': endDate?.toUtc().toIso8601String(),
    };
  }

  /// Validate the DTO
  String? validate() {
    if (titleAr.isEmpty) return 'Arabic title is required';
    if (imageUrl.isEmpty) return 'Image URL is required';
    if (linkType != 'none' && (linkValue == null || linkValue!.isEmpty)) {
      return 'Link value is required when link type is set';
    }
    if (endDate != null && startDate != null && endDate!.isBefore(startDate!)) {
      return 'End date must be after start date';
    }
    return null;
  }
}
