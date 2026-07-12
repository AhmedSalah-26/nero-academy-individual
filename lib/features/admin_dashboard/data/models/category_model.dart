/// Category Model
class CategoryModel {
  final String id;
  final String nameAr;
  final String? nameEn;
  final String? description;
  final String? icon;
  final String? parentId;
  final bool isActive;
  final int sortOrder;
  final int courseCount;
  final DateTime createdAt;

  const CategoryModel({
    required this.id,
    required this.nameAr,
    this.nameEn,
    this.description,
    this.icon,
    this.parentId,
    this.isActive = true,
    this.sortOrder = 0,
    this.courseCount = 0,
    required this.createdAt,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      nameAr: json['name_ar'] as String? ?? '',
      nameEn: json['name_en'] as String?,
      description: json['description'] as String?,
      icon: json['icon'] as String?,
      parentId: json['parent_id'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      sortOrder: json['sort_order'] as int? ?? 0,
      courseCount: json['course_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name_ar': nameAr,
      'name_en': nameEn,
      'description': description,
      'icon': icon,
      'parent_id': parentId,
      'is_active': isActive,
      'sort_order': sortOrder,
      'course_count': courseCount,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String getName(bool isArabic) => isArabic ? nameAr : (nameEn ?? nameAr);

  CategoryModel copyWith({
    String? id,
    String? nameAr,
    String? nameEn,
    String? description,
    String? icon,
    String? parentId,
    bool? isActive,
    int? sortOrder,
    int? courseCount,
    DateTime? createdAt,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      nameAr: nameAr ?? this.nameAr,
      nameEn: nameEn ?? this.nameEn,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      parentId: parentId ?? this.parentId,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
      courseCount: courseCount ?? this.courseCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
