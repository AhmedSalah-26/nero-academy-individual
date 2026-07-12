import 'dart:ui';

/// App Colors - Based on Design System
class AppColors {
  AppColors._();

  // ============ Primary Colors ============
  static const Color primary = Color(0xFF6F7A3A);
  static const Color primaryLight = Color(0xFF8C8B4A);
  static const Color primaryDark = Color(0xFF4F5A28);

  // Primary for dark mode (brighter/more visible)
  static const Color primaryOnDark = Color(0xFF8C8B4A);

  // ============ Background Colors ============
  static const Color backgroundLight = Color(0xFFEEF0E4);
  static const Color backgroundDark = Color(0xFF071008);

  // ============ Surface Colors ============
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF101B10);
  static const Color cardDark = Color(0xFF172414);

  // ============ Text Colors ============
  static const Color textMainLight = Color(0xFF182012);
  static const Color textMainDark = Color(0xFFFFFFFF);
  static const Color textMutedLight = Color(0xFF5F674C);
  static const Color textMutedDark =
      Color(0xFFD1D5DB); // Changed from 9CA3AF for better contrast
  static const Color textSecondary = Color(0xFF66704E);
  static const Color textSecondaryDark = Color(0xFFC8CCB0);

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
  static const Color info = Color(0xFF86A35A);
  static const Color infoLight = Color(0xFFE8F0D2);

  // ============ Rating Color (Accessible) ============
  static const Color rating =
      Color(0xFFB47D00); // Changed from E59819 for better contrast (4.5:1)
  static const Color ratingLight =
      Color(0xFFE59819); // Original color for backgrounds

  // ============ Border Colors ============
  static const Color borderLight = Color(0xFFD2D8C1);
  static const Color borderDark = Color(0xFF36452B);

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
  static const Color shimmerBase = Color(0xFFDDE3CF);
  static const Color shimmerHighlight = Color(0xFFF1F3E8);
  static const Color shimmerBaseDark = Color(0xFF182617);
  static const Color shimmerHighlightDark = Color(0xFF26381F);
}
