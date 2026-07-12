import 'package:flutter/material.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/core/shared_widgets/loading_skeleton.dart';

/// Stats Card - Displays a statistic with icon and optional change indicator
class StatsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;
  final double? changePercentage;
  final bool isLoading;
  final VoidCallback? onTap;

  const StatsCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.color = AppColors.primary,
    this.subtitle,
    this.changePercentage,
    this.isLoading = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isLoading) return _buildSkeleton(context, isDark);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildIcon(isDark),
                  if (changePercentage != null) _buildChangeIndicator(),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                value,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color:
                      isDark ? AppColors.textMainDark : AppColors.textMainLight,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? AppColors.textMutedDark
                      : AppColors.textMutedLight,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.textMutedDark.withValues(alpha: 0.7)
                        : AppColors.textMutedLight.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(bool isDark) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  Widget _buildChangeIndicator() {
    final isPositive = changePercentage! >= 0;
    final changeColor = isPositive ? AppColors.success : AppColors.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: changeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive
                ? Icons.trending_up_rounded
                : Icons.trending_down_rounded,
            size: 14,
            color: changeColor,
          ),
          const SizedBox(width: 4),
          Text(
            '${isPositive ? '+' : ''}${changePercentage!.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: changeColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LoadingSkeleton(width: 48, height: 48),
          SizedBox(height: 16),
          LoadingSkeleton(width: 80, height: 28),
          SizedBox(height: 8),
          LoadingSkeleton(width: 100, height: 14),
        ],
      ),
    );
  }
}
