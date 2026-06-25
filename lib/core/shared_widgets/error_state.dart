import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'app_button.dart';

/// Error Type
enum ErrorType {
  network,
  server,
  notFound,
  unauthorized,
  generic,
}

/// Error State Display Density
enum ErrorStateDisplay {
  fullPage,
  section,
  compact,
}

/// Unified Error State Widget
class ErrorState extends StatelessWidget {
  final ErrorType type;
  final ErrorStateDisplay display;
  final String? title;
  final String? message;
  final String? retryText;
  final String? goBackText;
  final VoidCallback? onRetry;
  final VoidCallback? onGoBack;
  final IconData? icon;
  final bool showCard;
  final EdgeInsetsGeometry? padding;

  const ErrorState({
    super.key,
    this.type = ErrorType.generic,
    this.display = ErrorStateDisplay.fullPage,
    this.title,
    this.message,
    this.retryText,
    this.goBackText,
    this.onRetry,
    this.onGoBack,
    this.icon,
    this.showCard = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final config = _getConfig();
    final metrics = _ErrorStateMetrics.fromDisplay(display);

    final content = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: metrics.maxWidth),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: showCard
              ? (isDark
                  ? AppColors.surfaceDark.withValues(alpha: 0.72)
                  : AppColors.surfaceLight.withValues(alpha: 0.86))
              : AppColors.transparent,
          borderRadius: BorderRadius.circular(metrics.radius),
          border: showCard
              ? Border.all(
                  color: isDark
                      ? AppColors.primaryOnDark.withValues(alpha: 0.18)
                      : AppColors.primary.withValues(alpha: 0.14),
                )
              : null,
          boxShadow: showCard
              ? [
                  BoxShadow(
                    color: (isDark ? AppColors.black : AppColors.primary)
                        .withValues(alpha: isDark ? 0.22 : 0.08),
                    blurRadius: 28,
                    offset: const Offset(0, 14),
                  ),
                ]
              : null,
        ),
        child: Padding(
          padding: padding ?? metrics.padding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildIcon(isDark, config, metrics),
              SizedBox(height: metrics.iconGap),
              Text(
                title ?? config.titleKey.tr(),
                style: TextStyle(
                  fontFamily: 'Almarai',
                  fontSize: metrics.titleSize,
                  fontWeight: FontWeight.w800,
                  color:
                      isDark ? AppColors.textMainDark : AppColors.textMainLight,
                  height: 1.25,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: metrics.messageGap),
              Text(
                config.messageKey.tr(),
                style: TextStyle(
                  fontFamily: 'Almarai',
                  fontSize: metrics.messageSize,
                  fontWeight: FontWeight.w400,
                  color: isDark
                      ? AppColors.textMutedDark
                      : AppColors.textMutedLight,
                  height: 1.55,
                ),
                textAlign: TextAlign.center,
              ),
              if (onRetry != null || onGoBack != null) ...[
                SizedBox(height: metrics.actionGap),
                _buildActions(config, metrics),
              ],
            ],
          ),
        ),
      ),
    );

    if (display == ErrorStateDisplay.section) {
      return Center(child: content);
    }

    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: content,
        ),
      ),
    );
  }

  Widget _buildIcon(
    bool isDark,
    _ErrorConfig config,
    _ErrorStateMetrics metrics,
  ) {
    final accent = isDark ? config.darkAccent : config.accent;

    return Container(
      width: metrics.iconBoxSize,
      height: metrics.iconBoxSize,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: isDark ? 0.22 : 0.16),
            accent.withValues(alpha: isDark ? 0.08 : 0.05),
          ],
        ),
        shape: BoxShape.circle,
        border: Border.all(
          color: accent.withValues(alpha: isDark ? 0.32 : 0.22),
        ),
      ),
      child: Icon(
        icon ?? config.icon,
        size: metrics.iconSize,
        color: accent,
      ),
    );
  }

  Widget _buildActions(_ErrorConfig config, _ErrorStateMetrics metrics) {
    final children = <Widget>[
      if (onRetry != null)
        AppButton(
          text: retryText ?? config.retryKey.tr(),
          onPressed: onRetry!,
          variant: AppButtonVariant.primary,
          size: metrics.buttonSize,
          icon: Icons.refresh_rounded,
          isFullWidth: display == ErrorStateDisplay.fullPage,
        ),
      if (onGoBack != null)
        AppButton(
          text: goBackText ?? 'common.go_back'.tr(),
          onPressed: onGoBack!,
          variant: AppButtonVariant.outline,
          size: metrics.buttonSize,
          icon: Icons.arrow_back_rounded,
          isFullWidth: display == ErrorStateDisplay.fullPage,
        ),
    ];

    if (display == ErrorStateDisplay.fullPage) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children
            .expand((child) => [child, const SizedBox(height: 12)])
            .toList()
          ..removeLast(),
      );
    }

    return Wrap(
      alignment: WrapAlignment.center,
      runSpacing: 12,
      spacing: 12,
      children: [
        ...children,
      ],
    );
  }

  _ErrorConfig _getConfig() {
    switch (type) {
      case ErrorType.network:
        return _ErrorConfig(
          icon: Icons.wifi_off_rounded,
          titleKey: 'error_state.network_title',
          messageKey: 'error_state.network_message',
          retryKey: 'common.retry',
          accent: AppColors.info,
          darkAccent: AppColors.primaryOnDark,
        );
      case ErrorType.server:
        return _ErrorConfig(
          icon: Icons.cloud_off_rounded,
          titleKey: 'error_state.server_title',
          messageKey: 'error_state.server_message',
          retryKey: 'common.retry',
          accent: AppColors.warning,
          darkAccent: AppColors.warning,
        );
      case ErrorType.notFound:
        return _ErrorConfig(
          icon: Icons.search_off_rounded,
          titleKey: 'error_state.not_found_title',
          messageKey: 'error_state.not_found_message',
          retryKey: 'common.go_back',
          accent: AppColors.primary,
          darkAccent: AppColors.primaryOnDark,
        );
      case ErrorType.unauthorized:
        return _ErrorConfig(
          icon: Icons.lock_outline_rounded,
          titleKey: 'error_state.unauthorized_title',
          messageKey: 'error_state.unauthorized_message',
          retryKey: 'auth.login',
          accent: AppColors.warning,
          darkAccent: AppColors.warning,
        );
      case ErrorType.generic:
        return _ErrorConfig(
          icon: Icons.error_outline_rounded,
          titleKey: 'error_state.generic_title',
          messageKey: 'error_state.generic_message',
          retryKey: 'common.retry',
          accent: AppColors.error,
          darkAccent: AppColors.error,
        );
    }
  }
}

class _ErrorConfig {
  final IconData icon;
  final String titleKey;
  final String messageKey;
  final String retryKey;
  final Color accent;
  final Color darkAccent;

  _ErrorConfig({
    required this.icon,
    required this.titleKey,
    required this.messageKey,
    required this.retryKey,
    required this.accent,
    required this.darkAccent,
  });
}

class _ErrorStateMetrics {
  final EdgeInsetsGeometry padding;
  final double maxWidth;
  final double radius;
  final double iconBoxSize;
  final double iconSize;
  final double iconGap;
  final double messageGap;
  final double actionGap;
  final double titleSize;
  final double messageSize;
  final AppButtonSize buttonSize;

  const _ErrorStateMetrics({
    required this.padding,
    required this.maxWidth,
    required this.radius,
    required this.iconBoxSize,
    required this.iconSize,
    required this.iconGap,
    required this.messageGap,
    required this.actionGap,
    required this.titleSize,
    required this.messageSize,
    required this.buttonSize,
  });

  factory _ErrorStateMetrics.fromDisplay(ErrorStateDisplay display) {
    switch (display) {
      case ErrorStateDisplay.fullPage:
        return const _ErrorStateMetrics(
          padding: EdgeInsets.symmetric(horizontal: 28, vertical: 34),
          maxWidth: 420,
          radius: 24,
          iconBoxSize: 96,
          iconSize: 44,
          iconGap: 22,
          messageGap: 10,
          actionGap: 26,
          titleSize: 21,
          messageSize: 14.5,
          buttonSize: AppButtonSize.medium,
        );
      case ErrorStateDisplay.section:
        return const _ErrorStateMetrics(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          maxWidth: 380,
          radius: 20,
          iconBoxSize: 78,
          iconSize: 36,
          iconGap: 18,
          messageGap: 8,
          actionGap: 22,
          titleSize: 18,
          messageSize: 13.5,
          buttonSize: AppButtonSize.medium,
        );
      case ErrorStateDisplay.compact:
        return const _ErrorStateMetrics(
          padding: EdgeInsets.symmetric(horizontal: 18, vertical: 20),
          maxWidth: 320,
          radius: 16,
          iconBoxSize: 58,
          iconSize: 28,
          iconGap: 14,
          messageGap: 6,
          actionGap: 16,
          titleSize: 15.5,
          messageSize: 12.5,
          buttonSize: AppButtonSize.small,
        );
    }
  }
}
