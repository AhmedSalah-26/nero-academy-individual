import '../../domain/entities/level_entity.dart';

/// Level Model
class LevelModel extends LevelEntity {
  const LevelModel({
    required super.id,
    required super.nameAr,
    required super.nameEn,
    required super.slug,
    super.descriptionAr,
    super.descriptionEn,
    required super.displayOrder,
    required super.isActive,
    required super.createdAt,
    required super.updatedAt,
  });

  factory LevelModel.fromJson(Map<String, dynamic> json) {
    return LevelModel(
      id: json['id'] as String,
      nameAr: json['name_ar'] as String? ?? '',
      nameEn: json['name_en'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      descriptionAr: json['description_ar'] as String?,
      descriptionEn: json['description_en'] as String?,
      displayOrder: json['display_order'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name_ar': nameAr,
        'name_en': nameEn,
        'slug': slug,
        'description_ar': descriptionAr,
        'description_en': descriptionEn,
        'display_order': displayOrder,
        'is_active': isActive,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}
