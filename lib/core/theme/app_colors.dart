import 'package:flutter/material.dart';
import 'package:lms_platform/core/services/teacher_context_service.dart';
import 'package:lms_platform/core/services/theme_service.dart';

/// App Colors - Based on Design System
class AppColors {
  AppColors._();

  // ============ Primary Colors ============
  static const Color primary = DynamicPrimaryColor();
  static const Color primaryLight = DynamicPrimaryLightColor();
  static const Color primaryDark = DynamicPrimaryDarkColor();

  // Primary for dark mode (brighter/more visible)
  static const Color primaryOnDark = DynamicPrimaryOnDarkColor();

  // ============ Background Colors ============
  static const Color backgroundLight = DynamicBackgroundLightColor();
  static const Color backgroundDark = DynamicBackgroundDarkColor();

  // ============ Surface Colors ============
  static const Color surfaceLight = DynamicSurfaceLightColor();
  static const Color surfaceDark = DynamicSurfaceDarkColor();
  static const Color cardDark = DynamicCardDarkColor();

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
  static const Color borderLight = DynamicBorderLightColor();
  static const Color borderDark = DynamicBorderDarkColor();

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

// ============ Dynamic Color Overrides ============

class DynamicPrimaryColor extends Color {
  const DynamicPrimaryColor() : super(0xFF00BEB8);

  @override
  int get value {
    final teacher = TeacherContextService.instance.selectedTeacher.value;
    if (teacher != null && teacher.theme.hasColors) {
      final isDark = ThemeService.instance.isDarkMode.value;
      final color = teacher.theme.primaryFor(isDark);
      if (color != null) return color.toARGB32();
    }
    return 0xFF00BEB8;
  }
}

class DynamicPrimaryLightColor extends Color {
  const DynamicPrimaryLightColor() : super(0xFF54ECE3);

  @override
  int get value {
    final teacher = TeacherContextService.instance.selectedTeacher.value;
    if (teacher != null && teacher.theme.hasColors) {
      final isDark = ThemeService.instance.isDarkMode.value;
      final color = teacher.theme.secondaryFor(isDark);
      if (color != null) return color.toARGB32();
    }
    return 0xFF54ECE3;
  }
}

class DynamicPrimaryDarkColor extends Color {
  const DynamicPrimaryDarkColor() : super(0xFF008686);

  @override
  int get value {
    final teacher = TeacherContextService.instance.selectedTeacher.value;
    if (teacher != null && teacher.theme.hasColors) {
      final color = teacher.theme.darkPrimaryColor;
      if (color != null) return color.toARGB32();
    }
    return 0xFF008686;
  }
}

class DynamicPrimaryOnDarkColor extends Color {
  const DynamicPrimaryOnDarkColor() : super(0xFF20E5DC);

  @override
  int get value {
    final teacher = TeacherContextService.instance.selectedTeacher.value;
    if (teacher != null && teacher.theme.hasColors) {
      final color = teacher.theme.darkPrimaryColor;
      if (color != null) return color.toARGB32();
    }
    return 0xFF20E5DC;
  }
}

class DynamicBackgroundLightColor extends Color {
  const DynamicBackgroundLightColor() : super(0xFFF4F9FA);

  @override
  int get value {
    final teacher = TeacherContextService.instance.selectedTeacher.value;
    if (teacher != null && teacher.theme.hasColors) {
      final color = teacher.theme.lightBackgroundColor;
      if (color != null) return color.toARGB32();
    }
    return 0xFFF4F9FA;
  }
}

class DynamicBackgroundDarkColor extends Color {
  const DynamicBackgroundDarkColor() : super(0xFF01060B);

  @override
  int get value {
    final teacher = TeacherContextService.instance.selectedTeacher.value;
    if (teacher != null && teacher.theme.hasColors) {
      final color = teacher.theme.darkBackgroundColor;
      if (color != null) return color.toARGB32();
    }
    return 0xFF01060B;
  }
}

class DynamicSurfaceLightColor extends Color {
  const DynamicSurfaceLightColor() : super(0xFFFFFFFF);

  @override
  int get value {
    final teacher = TeacherContextService.instance.selectedTeacher.value;
    if (teacher != null && teacher.theme.hasColors) {
      final color = teacher.theme.lightCardColor;
      if (color != null) return color.toARGB32();
    }
    return 0xFFFFFFFF;
  }
}

class DynamicSurfaceDarkColor extends Color {
  const DynamicSurfaceDarkColor() : super(0xFF05111B);

  @override
  int get value {
    final teacher = TeacherContextService.instance.selectedTeacher.value;
    if (teacher != null && teacher.theme.hasColors) {
      final color = teacher.theme.darkCardColor;
      if (color != null) return color.toARGB32();
    }
    return 0xFF05111B;
  }
}

class DynamicCardDarkColor extends Color {
  const DynamicCardDarkColor() : super(0xFF081A27);

  @override
  int get value {
    final teacher = TeacherContextService.instance.selectedTeacher.value;
    if (teacher != null && teacher.theme.hasColors) {
      final color = teacher.theme.darkCardColor;
      if (color != null) return color.toARGB32();
    }
    return 0xFF081A27;
  }
}

class DynamicBorderLightColor extends Color {
  const DynamicBorderLightColor() : super(0xFFD6E5EA);

  @override
  int get value {
    final teacher = TeacherContextService.instance.selectedTeacher.value;
    if (teacher != null && teacher.theme.hasColors) {
      final isDark = ThemeService.instance.isDarkMode.value;
      final primary = teacher.theme.primaryFor(isDark) ?? const Color(0xFF00BEB8);
      final card = teacher.theme.cardFor(isDark) ?? const Color(0xFFFFFFFF);
      final color = Color.alphaBlend(
        primary.withValues(alpha: isDark ? 0.35 : 0.22),
        card,
      );
      return color.toARGB32();
    }
    return 0xFFD6E5EA;
  }
}

class DynamicBorderDarkColor extends Color {
  const DynamicBorderDarkColor() : super(0xFF0F2B39);

  @override
  int get value {
    final teacher = TeacherContextService.instance.selectedTeacher.value;
    if (teacher != null && teacher.theme.hasColors) {
      final primary = teacher.theme.darkPrimaryColor ?? const Color(0xFF20E5DC);
      final card = teacher.theme.darkCardColor ?? const Color(0xFF081A27);
      final color = Color.alphaBlend(
        primary.withValues(alpha: 0.35),
        card,
      );
      return color.toARGB32();
    }
    return 0xFF0F2B39;
  }
}
