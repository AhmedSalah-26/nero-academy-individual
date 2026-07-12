import 'package:lms_platform/features/student/home/domain/entities/category_entity.dart';

/// Category Model - Data Model with JSON serialization
class CategoryModel extends CategoryEntity {
  const CategoryModel({
    required super.id,
    super.nameAr,
    super.nameEn,
    super.descriptionAr,
    super.descriptionEn,
    super.iconName,
    super.imageUrl,
    super.parentId,
    super.coursesCount,
    super.sortOrder,
    super.isActive,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      nameAr: json['name_ar'] as String?,
      nameEn: json['name_en'] as String?,
      descriptionAr: json['description_ar'] as String?,
      descriptionEn: json['description_en'] as String?,
      iconName: json['icon_name'] as String?,
      imageUrl: json['image_url'] as String?,
      parentId: json['parent_id'] as String?,
      coursesCount: json['courses_count'] as int? ?? 0,
      sortOrder: json['sort_order'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name_ar': nameAr,
      'name_en': nameEn,
      'description_ar': descriptionAr,
      'description_en': descriptionEn,
      'icon_name': iconName,
      'image_url': imageUrl,
      'parent_id': parentId,
      'courses_count': coursesCount,
      'sort_order': sortOrder,
      'is_active': isActive,
    };
  }

  factory CategoryModel.fromEntity(CategoryEntity entity) {
    return CategoryModel(
      id: entity.id,
      nameAr: entity.nameAr,
      nameEn: entity.nameEn,
      descriptionAr: entity.descriptionAr,
      descriptionEn: entity.descriptionEn,
      iconName: entity.iconName,
      imageUrl: entity.imageUrl,
      parentId: entity.parentId,
      coursesCount: entity.coursesCount,
      sortOrder: entity.sortOrder,
      isActive: entity.isActive,
    );
  }
}
