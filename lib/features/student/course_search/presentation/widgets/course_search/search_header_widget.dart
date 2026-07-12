import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lms_platform/core/shared_widgets/glass_icon_button.dart';
import 'package:lms_platform/core/shared_widgets/glass_search_bar.dart';
import 'package:lms_platform/core/theme/app_colors.dart';

/// Search Header Widget - Glass search field with filter action
class SearchHeaderWidget extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback? onBackPressed;
  final VoidCallback onFilterPressed;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmitted;
  final int activeFilterCount;
  final bool showBackButton;

  const SearchHeaderWidget({
    super.key,
    required this.controller,
    this.onBackPressed,
    required this.onFilterPressed,
    required this.onChanged,
    required this.onSubmitted,
    this.activeFilterCount = 0,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final iconSize = (screenWidth * 0.06).clamp(22.0, 26.0);

    return Container(
      color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.04,
            vertical: screenWidth * 0.025,
          ),
          child: Row(
            children: [
              if (showBackButton && onBackPressed != null)
                GestureDetector(
                  onTap: onBackPressed,
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: theme.colorScheme.onSurface,
                    size: iconSize,
                  ),
                ),
              SizedBox(width: showBackButton ? 12 : 0),
              Expanded(
                child: GlassSearchBar(
                  controller: controller,
                  hintText: 'home.search_placeholder'.tr(),
                  onChanged: onChanged,
                  onSubmitted: (_) => onSubmitted(),
                  autofocus: true,
                  height: 48,
                  iconSize: iconSize,
                  textStyle: theme.textTheme.bodyLarge,
                  hintStyle: theme.textTheme.bodyLarge?.copyWith(
                    color: isDark
                        ? AppColors.textMutedDark
                        : AppColors.textMutedLight,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GlassIconButton(
                icon: Icons.tune_rounded,
                onTap: onFilterPressed,
                size: 44,
                iconSize: iconSize,
                badgeCount: activeFilterCount > 0 ? activeFilterCount : null,
                compactBadge: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
