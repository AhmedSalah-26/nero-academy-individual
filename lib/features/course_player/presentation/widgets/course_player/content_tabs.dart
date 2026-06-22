import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

/// Content Tabs Widget
class ContentTabs extends StatelessWidget {
  final int currentIndex;
  final bool isDark;
  final ValueChanged<int> onTabChanged;

  const ContentTabs({
    super.key,
    required this.currentIndex,
    required this.isDark,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          _buildTab(0, 'course_player.lectures'.tr()),
          _buildTab(1, 'course_player.more'.tr()),
          _buildTab(2, 'course_player.qa'.tr()),
          _buildTab(3, 'course_player.quizzes'.tr()),
          _buildTab(4, 'course_player.rating'.tr()),
        ],
      ),
    );
  }

  Widget _buildTab(int index, String label) {
    final isSelected = currentIndex == index;

    return Expanded(
      child: InkWell(
        onTap: () => onTabChanged(index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 4),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? AppColors.primary : Colors.transparent,
                width: 2.4,
              ),
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              style: TextStyle(
                color: isSelected
                    ? AppColors.primary
                    : (isDark
                        ? AppColors.textMutedDark
                        : AppColors.textMutedLight),
                fontSize: 13.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
