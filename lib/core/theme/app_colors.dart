import 'dart:ui';

/// App Colors - Based on Design System
class AppColors {
  AppColors._();

  // ============ Primary Colors ============
  static const Color primary = Color(0xFF00BEB8);
  static const Color primaryLight = Color(0xFF54ECE3);
  static const Color primaryDark = Color(0xFF008686);

  // Primary for dark mode (brighter/more visible)
  static const Color primaryOnDark = Color(0xFF20E5DC);

  // ============ Background Colors ============
  static const Color backgroundLight = Color(0xFFF4F9FA);
  static const Color backgroundDark = Color(0xFF01060B);

  // ============ Surface Colors ============
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF05111B);
  static const Color cardDark = Color(0xFF081A27);

  // ============ Text Colors ============
  static const Color textMainLight = Color(0xFF071722);
  static const Color textMainDark = Color(0xFFFFFFFF);
  static const Color textMutedLight = Color(0xFF50616B);
  static const Color textMutedDark =
      Color(0xFFD1D5DB); // Changed from 9CA3AF for better contrast
  static const Color textSecondary = Color(0xFF50616B);
  static const Color textSecondaryDark = Color(0xFFB8D3DD);

  // ============ Accessible Text Colors ============
  static const Color textHintLight = Color(0xFF6B7280); // For placeholders only
  static const Color textHintDark = Color(0xFF9CA3AF); // For placeholders only

  // ============ Status Colors ============
  static const Color success = Color(0xFF22C55E);
  static const Color successLight = Color(0xFFDCFCE7);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color info = Color(0xFF0EA5E9);
  static const Color infoLight = Color(0xFFE0F7FF);


  // ============ Rating Color (Accessible) ============
  static const Color rating =
      Color(0xFFB47D00); // Changed from E59819 for better contrast (4.5:1)
  static const Color ratingLight =
      Color(0xFFE59819); // Original color for backgrounds

  // ============ Border Colors ============
  static const Color borderLight = Color(0xFFD6E5EA);
  static const Color borderDark = Color(0xFF0F2B39);

  // ============ Common Colors ============
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color transparent = Color(0x00000000);

  // ============ Grey Scale ============
  static const Color grey50 = Color(0xFFF9FAFB);
  static const Color grey100 = Color(0xFFF3F4F6);
  static const Color grey200 = Color(0xFFE5E7EB);
  static const Color grey300 = Color(0xFFD1D5DB);
  static const Color grey400 = Color(0xFF9CA3AF);
  static const Color grey500 = Color(0xFF6B7280);
  static const Color grey600 = Color(0xFF4B5563);
  static const Color grey700 = Color(0xFF374151);
  static const Color grey800 = Color(0xFF1F2937);
  static const Color grey900 = Color(0xFF111827);

  // ============ Shimmer Colors ============
  static const Color shimmerBase = Color(0xFFDCECEF);
  static const Color shimmerHighlight = Color(0xFFF5FBFC);
  static const Color shimmerBaseDark = Color(0xFF071822);
  static const Color shimmerHighlightDark = Color(0xFF0C2737);
}
