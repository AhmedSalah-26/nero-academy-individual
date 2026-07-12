import 'package:flutter/material.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/core/theme/app_spacing.dart';

/// Social Login Buttons - Google, Apple, Facebook
class SocialLoginButtons extends StatelessWidget {
  final VoidCallback? onGoogleTap;
  final VoidCallback? onAppleTap;
  final VoidCallback? onFacebookTap;
  final bool isLoading;
  final bool showApple;
  final bool showFacebook;
  final String? googleLabel;

  const SocialLoginButtons({
    super.key,
    this.onGoogleTap,
    this.onAppleTap,
    this.onFacebookTap,
    this.isLoading = false,
    this.showApple = true,
    this.showFacebook = true,
    this.googleLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Divider with text
        _buildDivider(context),
        AppSpacing.verticalGapLg,
        // Social buttons
        if (!showApple && !showFacebook)
          _SocialButton(
            icon: _googleIcon,
            label: googleLabel,
            onTap: isLoading ? null : onGoogleTap,
          )
        else
          Row(
            children: [
              Expanded(
                child: _SocialButton(
                  icon: _googleIcon,
                  onTap: isLoading ? null : onGoogleTap,
                ),
              ),
              if (showApple) ...[
                AppSpacing.horizontalGapMd,
                Expanded(
                  child: _SocialButton(
                    icon: _appleIcon(context),
                    onTap: isLoading ? null : onAppleTap,
                  ),
                ),
              ],
              if (showFacebook) ...[
                AppSpacing.horizontalGapMd,
                Expanded(
                  child: _SocialButton(
                    icon: _facebookIcon,
                    onTap: isLoading ? null : onFacebookTap,
                  ),
                ),
              ],
            ],
          ),
      ],
    );
  }

  Widget _buildDivider(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? AppColors.grey700 : AppColors.grey200;
    final textColor = isDark ? AppColors.grey400 : AppColors.grey500;

    return Row(
      children: [
        Expanded(child: Divider(color: color)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'أو سجل بواسطة',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ),
        Expanded(child: Divider(color: color)),
      ],
    );
  }

  // Google Icon SVG
  Widget get _googleIcon => SizedBox(
        width: 24,
        height: 24,
        child: CustomPaint(
          painter: _GoogleIconPainter(),
        ),
      );

  // Apple Icon
  Widget _appleIcon(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Icon(
      Icons.apple,
      size: 24,
      color: isDark ? AppColors.white : AppColors.black,
    );
  }

  // Facebook Icon
  Widget get _facebookIcon => const Icon(
        Icons.facebook,
        size: 24,
        color: Color(0xFF1877F2),
      );
}

class _SocialButton extends StatelessWidget {
  final Widget icon;
  final String? label;
  final VoidCallback? onTap;

  const _SocialButton({
    required this.icon,
    this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? AppColors.grey800 : AppColors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark ? AppColors.grey700 : AppColors.grey200,
            ),
          ),
          child: Center(
            child: label == null
                ? icon
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      icon,
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          label!,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isDark ? AppColors.white : AppColors.black,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
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

// Google Icon Painter
class _GoogleIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Blue
    paint.color = const Color(0xFF4285F4);
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.94, size.height * 0.51)
        ..cubicTo(size.width * 0.94, size.height * 0.48, size.width * 0.94,
            size.height * 0.45, size.width * 0.93, size.height * 0.42)
        ..lineTo(size.width * 0.5, size.height * 0.42)
        ..lineTo(size.width * 0.5, size.height * 0.59)
        ..lineTo(size.width * 0.75, size.height * 0.59)
        ..cubicTo(size.width * 0.74, size.height * 0.65, size.width * 0.71,
            size.height * 0.7, size.width * 0.66, size.height * 0.73)
        ..lineTo(size.width * 0.81, size.height * 0.85)
        ..cubicTo(size.width * 0.9, size.height * 0.77, size.width * 0.94,
            size.height * 0.65, size.width * 0.94, size.height * 0.51)
        ..close(),
      paint,
    );

    // Green
    paint.color = const Color(0xFF34A853);
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.5, size.height * 0.96)
        ..cubicTo(size.width * 0.62, size.height * 0.96, size.width * 0.73,
            size.height * 0.92, size.width * 0.8, size.height * 0.85)
        ..lineTo(size.width * 0.66, size.height * 0.73)
        ..cubicTo(size.width * 0.62, size.height * 0.76, size.width * 0.56,
            size.height * 0.78, size.width * 0.5, size.height * 0.78)
        ..cubicTo(size.width * 0.38, size.height * 0.78, size.width * 0.28,
            size.height * 0.7, size.width * 0.24, size.height * 0.59)
        ..lineTo(size.width * 0.09, size.height * 0.71)
        ..cubicTo(size.width * 0.17, size.height * 0.86, size.width * 0.32,
            size.height * 0.96, size.width * 0.5, size.height * 0.96)
        ..close(),
      paint,
    );

    // Yellow
    paint.color = const Color(0xFFFBBC05);
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.24, size.height * 0.59)
        ..cubicTo(size.width * 0.23, size.height * 0.56, size.width * 0.22,
            size.height * 0.53, size.width * 0.22, size.height * 0.5)
        ..cubicTo(size.width * 0.22, size.height * 0.47, size.width * 0.23,
            size.height * 0.44, size.width * 0.24, size.height * 0.41)
        ..lineTo(size.width * 0.09, size.height * 0.29)
        ..cubicTo(size.width * 0.06, size.height * 0.36, size.width * 0.04,
            size.height * 0.43, size.width * 0.04, size.height * 0.5)
        ..cubicTo(size.width * 0.04, size.height * 0.57, size.width * 0.06,
            size.height * 0.64, size.width * 0.09, size.height * 0.71)
        ..lineTo(size.width * 0.24, size.height * 0.59)
        ..close(),
      paint,
    );

    // Red
    paint.color = const Color(0xFFEA4335);
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.5, size.height * 0.22)
        ..cubicTo(size.width * 0.57, size.height * 0.22, size.width * 0.63,
            size.height * 0.25, size.width * 0.68, size.height * 0.29)
        ..lineTo(size.width * 0.81, size.height * 0.16)
        ..cubicTo(size.width * 0.73, size.height * 0.09, size.width * 0.62,
            size.height * 0.04, size.width * 0.5, size.height * 0.04)
        ..cubicTo(size.width * 0.32, size.height * 0.04, size.width * 0.17,
            size.height * 0.14, size.width * 0.09, size.height * 0.29)
        ..lineTo(size.width * 0.24, size.height * 0.41)
        ..cubicTo(size.width * 0.28, size.height * 0.3, size.width * 0.38,
            size.height * 0.22, size.width * 0.5, size.height * 0.22)
        ..close(),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
