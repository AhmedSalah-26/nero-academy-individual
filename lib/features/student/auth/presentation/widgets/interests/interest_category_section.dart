import 'package:flutter/material.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/core/theme/app_spacing.dart';
import 'package:lms_platform/features/student/auth/presentation/cubit/interests_state.dart';
import 'interest_chip.dart';

/// Interest Category Section - Category with interests
class InterestCategorySection extends StatelessWidget {
  final InterestCategory category;
  final Set<String> selectedInterests;
  final ValueChanged<String> onInterestTap;
  final bool isArabic;

  const InterestCategorySection({
    super.key,
    required this.category,
    required this.selectedInterests,
    required this.onInterestTap,
    this.isArabic = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isArabic ? category.nameAr : category.nameEn,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.white : AppColors.textMainLight,
              ),
            ),
            TextButton(
              onPressed: () {
                // TODO: Show more interests
              },
              child: const Text(
                'عرض المزيد',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        AppSpacing.verticalGapMd,
        // Interests Wrap
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: category.interests.map((interest) {
            return InterestChip(
              label: isArabic ? interest.nameAr : interest.nameEn,
              isSelected: selectedInterests.contains(interest.id),
              onTap: () => onInterestTap(interest.id),
            );
          }).toList(),
        ),
      ],
    );
  }
}
