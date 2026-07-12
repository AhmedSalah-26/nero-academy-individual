part of 'admin_categories_cubit.dart';

enum AdminCategoriesStatus { initial, loading, success, error }

class AdminCategoriesState extends Equatable {
  final AdminCategoriesStatus status;
  final AdminCategoriesStatus actionStatus;
  final List<CategoryModel> categories;
  final bool? isActiveFilter;
  final String? errorMessage;

  const AdminCategoriesState({
    this.status = AdminCategoriesStatus.initial,
    this.actionStatus = AdminCategoriesStatus.initial,
    this.categories = const [],
    this.isActiveFilter,
    this.errorMessage,
  });

  bool get isLoading => status == AdminCategoriesStatus.loading;
  bool get hasError => status == AdminCategoriesStatus.error;

  List<CategoryModel> get activeCategories =>
      categories.where((c) => c.isActive).toList();

  List<CategoryModel> get inactiveCategories =>
      categories.where((c) => !c.isActive).toList();

  AdminCategoriesState copyWith({
    AdminCategoriesStatus? status,
    AdminCategoriesStatus? actionStatus,
    List<CategoryModel>? categories,
    bool? isActiveFilter,
    String? errorMessage,
  }) {
    return AdminCategoriesState(
      status: status ?? this.status,
      actionStatus: actionStatus ?? this.actionStatus,
      categories: categories ?? this.categories,
      isActiveFilter: isActiveFilter ?? this.isActiveFilter,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        actionStatus,
        categories,
        isActiveFilter,
        errorMessage,
      ];
}
