import 'package:flutter/material.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/core/shared_widgets/empty_state.dart';

/// Cart Empty State Widget
class CartEmptyState extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onBrowseCourses;
  final bool isDark;

  const CartEmptyState({
    super.key,
    required this.onBack,
    required this.onBrowseCourses,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // App Bar
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : AppColors.grey100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 18,
                      color: isDark ? AppColors.white : AppColors.textMainLight,
                    ),
                  ),
                  onPressed: onBack,
                ),
              ],
            ),
          ),
          // Empty state
          Expanded(
            child: EmptyState(
              type: EmptyStateType.cart,
              onAction: onBrowseCourses,
            ),
          ),
        ],
      ),
    );
  }
}
