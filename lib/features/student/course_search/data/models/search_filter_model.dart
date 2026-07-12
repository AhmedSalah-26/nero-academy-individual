import 'package:lms_platform/features/student/course_search/domain/entities/search_filter_entity.dart';

/// Search Filter Model - Data Model with JSON serialization
class SearchFilterModel extends SearchFilterEntity {
  const SearchFilterModel({
    super.query,
    super.categoryIds,
    super.minPrice,
    super.maxPrice,
    super.minRating,
    super.level,
    super.sortBy,
    super.page,
    super.pageSize,
  });

  factory SearchFilterModel.fromEntity(SearchFilterEntity entity) {
    return SearchFilterModel(
      query: entity.query,
      categoryIds: entity.categoryIds,
      minPrice: entity.minPrice,
      maxPrice: entity.maxPrice,
      minRating: entity.minRating,
      level: entity.level,
      sortBy: entity.sortBy,
      page: entity.page,
      pageSize: entity.pageSize,
    );
  }

  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{};

    if (query != null && query!.isNotEmpty) {
      params['q'] = query;
    }
    if (categoryIds.isNotEmpty) {
      params['categories'] = categoryIds.join(',');
    }
    if (minPrice != null) {
      params['min_price'] = minPrice.toString();
    }
    if (maxPrice != null) {
      params['max_price'] = maxPrice.toString();
    }
    if (minRating != null) {
      params['min_rating'] = minRating.toString();
    }
    if (level != null && level != CourseLevel.all) {
      params['level'] = level!.name;
    }
    params['sort'] = _sortToString(sortBy);
    params['page'] = page.toString();
    params['page_size'] = pageSize.toString();

    return params;
  }

  String _sortToString(CourseSortOption sort) {
    switch (sort) {
      case CourseSortOption.relevance:
        return 'relevance';
      case CourseSortOption.newest:
        return 'newest';
      case CourseSortOption.highestRated:
        return 'highest_rated';
      case CourseSortOption.mostReviewed:
        return 'most_reviewed';
      case CourseSortOption.priceLowToHigh:
        return 'price_asc';
      case CourseSortOption.priceHighToLow:
        return 'price_desc';
    }
  }
}

/// Category Model
class CategoryModel extends CategoryEntity {
  const CategoryModel({
    required super.id,
    required super.name,
    super.iconName,
    super.courseCount,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      iconName: json['icon_name'] ?? json['iconName'],
      courseCount: json['course_count'] ?? json['courseCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon_name': iconName,
      'course_count': courseCount,
    };
  }
}
