import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/features/student/home/domain/entities/category_entity.dart';

/// Home Categories Section - Horizontal scrollable categories
class HomeCategoriesSection extends StatelessWidget {
  final List<CategoryEntity> categories;
  final String? selectedCategoryId;
  final Function(String?) onCategoryTap;
  final VoidCallback? onSeeAll;

  const HomeCategoriesSection({
    super.key,
    required this.categories,
    this.selectedCategoryId,
    required this.onCategoryTap,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locale = context.locale.languageCode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'home.categories'.tr(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color:
                      isDark ? AppColors.textMainDark : AppColors.textMainLight,
                ),
              ),
              if (onSeeAll != null)
                GestureDetector(
                  onTap: onSeeAll,
                  child: Text(
                    'home.see_all'.tr(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Categories List
        SizedBox(
          height: 44,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: categories.length + 1, // +1 for "All" chip
            itemBuilder: (context, index) {
              if (index == 0) {
                return _CategoryChip(
                  label: 'home.all'.tr(),
                  icon: Icons.apps_rounded,
                  isSelected: selectedCategoryId == null,
                  isDark: isDark,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onCategoryTap(null);
                  },
                );
              }
              final category = categories[index - 1];
              return _CategoryChip(
                label: category.getName(locale),
                icon: _getCategoryIcon(category.iconName),
                isSelected: selectedCategoryId == category.id,
                isDark: isDark,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onCategoryTap(category.id);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  IconData _getCategoryIcon(String? iconName) {
    switch (iconName?.toLowerCase()) {
      case 'code':
        return Icons.code_rounded;
      case 'design':
        return Icons.palette_rounded;
      case 'business':
        return Icons.business_center_rounded;
      case 'marketing':
        return Icons.campaign_rounded;
      case 'photography':
        return Icons.camera_alt_rounded;
      case 'music':
        return Icons.music_note_rounded;
      case 'health':
        return Icons.favorite_rounded;
      case 'language':
        return Icons.translate_rounded;
      case 'science':
        return Icons.science_rounded;
      case 'math':
        return Icons.calculate_rounded;
      default:
        return Icons.category_rounded;
    }
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary
                  : isDark
                      ? AppColors.cardDark
                      : AppColors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : isDark
                        ? AppColors.borderDark
                        : AppColors.borderLight,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isSelected
                      ? AppColors.white
                      : isDark
                          ? AppColors.textMutedDark
                          : AppColors.textMutedLight,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? AppColors.white
                        : isDark
                            ? AppColors.textMainDark
                            : AppColors.textMainLight,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
