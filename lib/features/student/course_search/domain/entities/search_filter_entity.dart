import 'package:equatable/equatable.dart';

/// Sort Options for Course Search
enum CourseSortOption {
  relevance,
  newest,
  highestRated,
  mostReviewed,
  priceLowToHigh,
  priceHighToLow,
}

/// Course Level Filter
enum CourseLevel {
  all,
  beginner,
  intermediate,
  advanced,
}

/// Search Filter Entity - Pure Dart Object
class SearchFilterEntity extends Equatable {
  final String? query;
  final List<String> categoryIds;
  final double? minPrice;
  final double? maxPrice;
  final double? minRating;
  final CourseLevel? level;
  final CourseSortOption sortBy;
  final int page;
  final int pageSize;

  const SearchFilterEntity({
    this.query,
    this.categoryIds = const [],
    this.minPrice,
    this.maxPrice,
    this.minRating,
    this.level,
    this.sortBy = CourseSortOption.relevance,
    this.page = 1,
    this.pageSize = 20,
  });

  bool get hasActiveFilters =>
      categoryIds.isNotEmpty ||
      minPrice != null ||
      maxPrice != null ||
      minRating != null ||
      level != null ||
      sortBy != CourseSortOption.relevance;

  int get activeFilterCount {
    int count = 0;
    if (categoryIds.isNotEmpty) count++;
    if (minPrice != null || maxPrice != null) count++;
    if (minRating != null) count++;
    if (level != null) count++;
    if (sortBy != CourseSortOption.relevance) count++;
    return count;
  }

  SearchFilterEntity copyWith({
    String? query,
    List<String>? categoryIds,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    CourseLevel? level,
    CourseSortOption? sortBy,
    int? page,
    int? pageSize,
    bool clearMinPrice = false,
    bool clearMaxPrice = false,
    bool clearMinRating = false,
    bool clearLevel = false,
  }) {
    return SearchFilterEntity(
      query: query ?? this.query,
      categoryIds: categoryIds ?? this.categoryIds,
      minPrice: clearMinPrice ? null : (minPrice ?? this.minPrice),
      maxPrice: clearMaxPrice ? null : (maxPrice ?? this.maxPrice),
      minRating: clearMinRating ? null : (minRating ?? this.minRating),
      level: clearLevel ? null : (level ?? this.level),
      sortBy: sortBy ?? this.sortBy,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }

  SearchFilterEntity clearAllFilters() {
    return SearchFilterEntity(
      query: query,
      sortBy: sortBy,
      page: 1,
      pageSize: pageSize,
    );
  }

  @override
  List<Object?> get props => [
        query,
        categoryIds,
        minPrice,
        maxPrice,
        minRating,
        level,
        sortBy,
        page,
        pageSize,
      ];
}

/// Category Entity
class CategoryEntity extends Equatable {
  final String id;
  final String name;
  final String? iconName;
  final int courseCount;

  const CategoryEntity({
    required this.id,
    required this.name,
    this.iconName,
    this.courseCount = 0,
  });

  @override
  List<Object?> get props => [id, name, iconName, courseCount];
}
