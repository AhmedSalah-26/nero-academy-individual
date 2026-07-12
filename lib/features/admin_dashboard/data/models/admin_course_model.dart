/// Admin Course Model
class AdminCourseModel {
  final String id;
  final String titleAr;
  final String? titleEn;
  final String? thumbnailUrl;
  final String instructorId;
  final String instructorName;
  final String? categoryName;
  final double price;
  final double? discountPrice;
  final bool isPublished;
  final bool isSuspended;
  final bool isFeatured;
  final String? suspensionReason;
  final int enrolledCount;
  final double rating;
  final int ratingCount;
  final double totalRevenue;
  final DateTime createdAt;

  const AdminCourseModel({
    required this.id,
    required this.titleAr,
    this.titleEn,
    this.thumbnailUrl,
    required this.instructorId,
    required this.instructorName,
    this.categoryName,
    required this.price,
    this.discountPrice,
    this.isPublished = false,
    this.isSuspended = false,
    this.isFeatured = false,
    this.suspensionReason,
    this.enrolledCount = 0,
    this.rating = 0,
    this.ratingCount = 0,
    this.totalRevenue = 0,
    required this.createdAt,
  });

  factory AdminCourseModel.fromJson(Map<String, dynamic> json) {
    return AdminCourseModel(
      id: json['id'] as String,
      titleAr: json['title_ar'] as String? ?? '',
      titleEn: json['title_en'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      instructorId: json['instructor_id'] as String,
      instructorName: json['instructor_name'] as String? ??
          json['instructor']?['name'] as String? ??
          'Unknown',
      categoryName: json['category_name'] as String? ??
          json['category']?['name_ar'] as String?,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      discountPrice: (json['discount_price'] as num?)?.toDouble(),
      isPublished: json['is_published'] as bool? ?? false,
      isSuspended: json['is_suspended'] as bool? ?? false,
      isFeatured: json['is_featured'] as bool? ?? false,
      suspensionReason: json['suspension_reason'] as String?,
      enrolledCount: json['enrolled_count'] as int? ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      ratingCount: json['rating_count'] as int? ?? 0,
      totalRevenue: (json['total_revenue'] as num?)?.toDouble() ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title_ar': titleAr,
      'title_en': titleEn,
      'thumbnail_url': thumbnailUrl,
      'instructor_id': instructorId,
      'instructor_name': instructorName,
      'category_name': categoryName,
      'price': price,
      'discount_price': discountPrice,
      'is_published': isPublished,
      'is_suspended': isSuspended,
      'is_featured': isFeatured,
      'suspension_reason': suspensionReason,
      'enrolled_count': enrolledCount,
      'rating': rating,
      'rating_count': ratingCount,
      'total_revenue': totalRevenue,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String getTitle(bool isArabic) => isArabic ? titleAr : (titleEn ?? titleAr);
}
