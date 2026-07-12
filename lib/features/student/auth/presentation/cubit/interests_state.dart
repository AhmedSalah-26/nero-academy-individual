import 'package:equatable/equatable.dart';

/// Interest Category
class InterestCategory {
  final String id;
  final String nameAr;
  final String nameEn;
  final List<Interest> interests;

  const InterestCategory({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.interests,
  });
}

/// Interest Item
class Interest {
  final String id;
  final String nameAr;
  final String nameEn;

  const Interest({
    required this.id,
    required this.nameAr,
    required this.nameEn,
  });
}

/// Interests State
class InterestsState extends Equatable {
  final List<InterestCategory> categories;
  final Set<String> selectedInterests;
  final String searchQuery;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;

  const InterestsState({
    this.categories = const [],
    this.selectedInterests = const {},
    this.searchQuery = '',
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
  });

  int get selectedCount => selectedInterests.length;
  bool get canContinue => selectedCount >= 3;

  List<InterestCategory> get filteredCategories {
    if (searchQuery.isEmpty) return categories;

    return categories
        .map((category) {
          final filteredInterests = category.interests.where((interest) {
            final query = searchQuery.toLowerCase();
            return interest.nameAr.toLowerCase().contains(query) ||
                interest.nameEn.toLowerCase().contains(query);
          }).toList();

          return InterestCategory(
            id: category.id,
            nameAr: category.nameAr,
            nameEn: category.nameEn,
            interests: filteredInterests,
          );
        })
        .where((category) => category.interests.isNotEmpty)
        .toList();
  }

  InterestsState copyWith({
    List<InterestCategory>? categories,
    Set<String>? selectedInterests,
    String? searchQuery,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
  }) {
    return InterestsState(
      categories: categories ?? this.categories,
      selectedInterests: selectedInterests ?? this.selectedInterests,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        categories,
        selectedInterests,
        searchQuery,
        isLoading,
        isSaving,
        errorMessage,
      ];
}
