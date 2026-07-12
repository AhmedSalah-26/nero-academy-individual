import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lms_platform/core/theme/app_colors.dart';

/// Help FAQ Section Widget
class HelpFaqSection extends StatelessWidget {
  final String title;
  final List<FaqItem> items;
  final VoidCallback? onViewAll;
  final bool isDark;

  const HelpFaqSection({
    super.key,
    required this.title,
    required this.items,
    this.onViewAll,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppColors.grey700 : AppColors.grey200,
            ),
          ),
          child: Column(
            children: [
              ...items.map((item) => _buildFaqItem(item)),
              if (onViewAll != null) _buildViewAllButton(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFaqItem(FaqItem item) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isDark ? AppColors.grey800 : AppColors.grey100,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  item.question,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.grey200 : AppColors.grey700,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: isDark ? AppColors.grey600 : AppColors.grey400,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildViewAllButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onViewAll,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(12),
        ),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.grey800.withValues(alpha: 0.5)
                : AppColors.grey50,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(12),
            ),
          ),
          child: Center(
            child: Text(
              'help_support.view_all_faqs'.tr(),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// FAQ Item Model
class FaqItem {
  final String question;
  final String? answer;
  final VoidCallback? onTap;

  const FaqItem({
    required this.question,
    this.answer,
    this.onTap,
  });
}
