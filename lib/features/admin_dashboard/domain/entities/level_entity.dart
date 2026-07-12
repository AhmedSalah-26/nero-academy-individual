import 'package:equatable/equatable.dart';

/// Level Entity
class LevelEntity extends Equatable {
  final String id;
  final String nameAr;
  final String nameEn;
  final String slug;
  final String? descriptionAr;
  final String? descriptionEn;
  final int displayOrder;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const LevelEntity({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.slug,
    this.descriptionAr,
    this.descriptionEn,
    required this.displayOrder,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  String getName(bool isArabic) => isArabic ? nameAr : nameEn;
  String? getDescription(bool isArabic) =>
      isArabic ? descriptionAr : descriptionEn;

  @override
  List<Object?> get props => [
        id,
        nameAr,
        nameEn,
        slug,
        descriptionAr,
        descriptionEn,
        displayOrder,
        isActive,
        createdAt,
        updatedAt,
      ];
}

/// Level Create DTO
class LevelCreateDto {
  final String nameAr;
  final String nameEn;
  final String slug;
  final String? descriptionAr;
  final String? descriptionEn;
  final int displayOrder;
  final bool isActive;

  const LevelCreateDto({
    required this.nameAr,
    required this.nameEn,
    required this.slug,
    this.descriptionAr,
    this.descriptionEn,
    this.displayOrder = 0,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() => {
        'name_ar': nameAr,
        'name_en': nameEn,
        'slug': slug,
        'description_ar': descriptionAr,
        'description_en': descriptionEn,
        'display_order': displayOrder,
        'is_active': isActive,
      };
}

/// Level Update DTO
class LevelUpdateDto {
  final String? nameAr;
  final String? nameEn;
  final String? slug;
  final String? descriptionAr;
  final String? descriptionEn;
  final int? displayOrder;
  final bool? isActive;

  const LevelUpdateDto({
    this.nameAr,
    this.nameEn,
    this.slug,
    this.descriptionAr,
    this.descriptionEn,
    this.displayOrder,
    this.isActive,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (nameAr != null) map['name_ar'] = nameAr;
    if (nameEn != null) map['name_en'] = nameEn;
    if (slug != null) map['slug'] = slug;
    if (descriptionAr != null) map['description_ar'] = descriptionAr;
    if (descriptionEn != null) map['description_en'] = descriptionEn;
    if (displayOrder != null) map['display_order'] = displayOrder;
    if (isActive != null) map['is_active'] = isActive;
    return map;
  }
}
