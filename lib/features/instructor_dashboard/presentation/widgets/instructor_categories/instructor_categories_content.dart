import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lms_platform/core/shared_widgets/loading_skeleton.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/core/routing/app_router.dart';
import 'package:lms_platform/features/instructor_dashboard/presentation/cubit/instructor_categories_cubit.dart';
import 'category_list_item.dart';

/// Instructor Categories Content
class InstructorCategoriesContent extends StatefulWidget {
  const InstructorCategoriesContent({super.key});

  @override
  State<InstructorCategoriesContent> createState() =>
      _InstructorCategoriesContentState();
}

class _InstructorCategoriesContentState
    extends State<InstructorCategoriesContent> {
  @override
  void initState() {
    super.initState();
    context.read<InstructorCategoriesCubit>().loadCategories();
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<InstructorCategoriesCubit, InstructorCategoriesState>(
      builder: (context, state) {
        return Stack(
          children: [
            Column(
              children: [
                _buildHeader(context, state, isArabic, isDark),
                Expanded(child: _buildCategoriesList(context, state, isArabic)),
              ],
            ),
            Positioned(
              bottom: 16,
              right: isArabic ? null : 16,
              left: isArabic ? 16 : null,
              child: FloatingActionButton(
                onPressed: () => _showCategoryDialog(context, isArabic),
                backgroundColor: AppColors.primary,
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(
    BuildContext context,
    InstructorCategoriesState state,
    bool isArabic,
    bool isDark,
  ) {
    final statusOptions = [
      {'value': 'active', 'label': 'Active', 'labelAr': 'نشط'},
      {'value': 'inactive', 'label': 'Inactive', 'labelAr': 'غير نشط'},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          child: DropdownButton<int>(
            value: state.isActiveFilter == false ? 1 : 0,
            underline: const SizedBox(),
            items: statusOptions.asMap().entries.map((entry) {
              return DropdownMenuItem<int>(
                value: entry.key,
                child: Text(
                  isArabic
                      ? entry.value['labelAr'] as String
                      : entry.value['label'] as String,
                ),
              );
            }).toList(),
            onChanged: (index) {
              if (index != null) {
                context
                    .read<InstructorCategoriesCubit>()
                    .changeActiveFilter(index == 0 ? true : false);
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesList(
    BuildContext context,
    InstructorCategoriesState state,
    bool isArabic,
  ) {
    if (state.isLoading) {
      return _buildLoadingSkeleton();
    }

    final categories = state.isActiveFilter == false
        ? state.inactiveCategories
        : state.activeCategories;

    if (categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.category_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              isArabic ? 'لا توجد تصنيفات' : 'No categories found',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<InstructorCategoriesCubit>().loadCategories(
            isActive: state.isActiveFilter,
            refresh: true,
          ),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return CategoryListItem(
            category: category,
            onEdit: () => _showCategoryDialog(context, isArabic, category),
            onToggleStatus: () => context
                .read<InstructorCategoriesCubit>()
                .toggleCategoryStatus(category.id),
          );
        },
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 8,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.cardDark
                : AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.borderDark
                  : AppColors.borderLight,
            ),
          ),
          child: const Row(
            children: [
              LoadingSkeleton(width: 48, height: 48),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LoadingSkeleton(height: 16, width: 150),
                    SizedBox(height: 8),
                    LoadingSkeleton(height: 14, width: 100),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCategoryDialog(BuildContext context, bool isArabic,
      [dynamic category]) {
    final cubit = context.read<InstructorCategoriesCubit>();
    AppRouter.goToCategoryEditor(
      context,
      category: category,
      onSave: (dto) {
        if (category != null) {
          cubit.updateCategory(category.id, dto);
        } else {
          cubit.createCategory(dto);
        }
      },
    );
  }
}
