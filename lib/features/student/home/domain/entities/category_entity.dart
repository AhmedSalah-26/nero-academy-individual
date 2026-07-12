import 'package:equatable/equatable.dart';

/// Category Entity - Pure Dart Object
class CategoryEntity extends Equatable {
  final String id;
  final String? nameAr;
  final String? nameEn;
  final String? descriptionAr;
  final String? descriptionEn;
  final String? iconName;
  final String? imageUrl;
  final String? parentId;
  final int coursesCount;
  final int sortOrder;
  final bool isActive;

  const CategoryEntity({
    required this.id,
    this.nameAr,
    this.nameEn,
    this.descriptionAr,
    this.descriptionEn,
    this.iconName,
    this.imageUrl,
    this.parentId,
    this.coursesCount = 0,
    this.sortOrder = 0,
    this.isActive = true,
  });

  String getName(String locale) =>
      locale == 'ar' ? (nameAr ?? nameEn ?? '') : (nameEn ?? nameAr ?? '');
  String getDescription(String locale) => locale == 'ar'
      ? (descriptionAr ?? descriptionEn ?? '')
      : (descriptionEn ?? descriptionAr ?? '');

  bool get isParentCategory => parentId == null;

  @override
  List<Object?> get props => [
        id,
        nameAr,
        nameEn,
        descriptionAr,
        descriptionEn,
        iconName,
        imageUrl,
        parentId,
        coursesCount,
        sortOrder,
        isActive
      ];
}
