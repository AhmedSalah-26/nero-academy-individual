import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lms_platform/core/theme/app_colors.dart';

enum LoadingStateDisplay {
  fullPage,
  section,
  compact,
}

class AppLoadingState extends StatelessWidget {
  final LoadingStateDisplay display;
  final String? message;
  final bool showMessage;

  const AppLoadingState({
    super.key,
    this.display = LoadingStateDisplay.fullPage,
    this.message,
    this.showMessage = true,
  });

  const AppLoadingState.section({
    super.key,
    this.message,
    this.showMessage = true,
  }) : display = LoadingStateDisplay.section;

  const AppLoadingState.compact({
    super.key,
    this.message,
    this.showMessage = false,
  }) : display = LoadingStateDisplay.compact;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final metrics = _LoadingMetrics.fromDisplay(display);

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: metrics.size,
          height: metrics.size,
          child: CircularProgressIndicator(
            strokeWidth: metrics.strokeWidth,
            color: isDark ? AppColors.primaryOnDark : AppColors.primary,
          ),
        ),
        if (showMessage) ...[
          SizedBox(height: metrics.gap),
          Text(
            message ?? 'common.loading'.tr(),
            style: TextStyle(
              fontFamily: 'Almarai',
              fontSize: metrics.fontSize,
              fontWeight: FontWeight.w600,
              color:
                  isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );

    if (display == LoadingStateDisplay.compact) {
      return content;
    }

    return Center(
      child: Padding(
        padding: metrics.padding,
        child: content,
      ),
    );
  }
}

class _LoadingMetrics {
  final double size;
  final double strokeWidth;
  final double gap;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  const _LoadingMetrics({
    required this.size,
    required this.strokeWidth,
    required this.gap,
    required this.fontSize,
    required this.padding,
  });

  factory _LoadingMetrics.fromDisplay(LoadingStateDisplay display) {
    switch (display) {
      case LoadingStateDisplay.fullPage:
        return const _LoadingMetrics(
          size: 48,
          strokeWidth: 3,
          gap: 18,
          fontSize: 14,
          padding: EdgeInsets.all(32),
        );
      case LoadingStateDisplay.section:
        return const _LoadingMetrics(
          size: 38,
          strokeWidth: 3,
          gap: 14,
          fontSize: 13,
          padding: EdgeInsets.all(24),
        );
      case LoadingStateDisplay.compact:
        return const _LoadingMetrics(
          size: 20,
          strokeWidth: 2,
          gap: 8,
          fontSize: 12,
          padding: EdgeInsets.zero,
        );
    }
  }
}
