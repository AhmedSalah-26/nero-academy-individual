import 'dart:ui' as ui;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:toastification/toastification.dart';

import 'core/core.dart';
import 'core/di/injection_container.dart';
import 'core/routing/app_router.dart';
import 'core/services/dev_http_overrides.dart';
import 'core/services/teacher_context_service.dart';
import 'core/services/theme_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // DEVELOPMENT ONLY: Allow self-signed certificates
  // Remove this in production!
  if (kDebugMode) {
    configureDevHttpOverrides();
  }

  // Initialize EasyLocalization
  await EasyLocalization.ensureInitialized();

  // Initialize Supabase with error handling
  try {
    await SupabaseServiceImpl.instance.initialize();
  } catch (e) {
    debugPrint('⚠️ [Main] Failed to initialize Supabase: $e');
    // Continue app initialization even if Supabase fails
    // User will see error when trying to use features that need Supabase
  }

  // Initialize Dependencies
  await initDependencies();

  // Initialize Theme Service
  await ThemeService.instance.init();
  await TeacherContextService.instance
      .init(SupabaseServiceImpl.instance.client);

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('ar'), Locale('en')],
      path: 'assets/translations',
      fallbackLocale: const Locale('ar'),
      startLocale: const Locale('ar'),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        ThemeService.instance.isDarkMode,
        TeacherContextService.instance.selectedTeacher,
      ]),
      builder: (context, _) {
        final isDark = ThemeService.instance.isDarkMode.value;
        final teacherTheme =
            TeacherContextService.instance.selectedTeacher.value?.theme;
        final lightTheme = _applyTeacherTheme(
          AppTheme.lightTheme,
          teacherTheme,
          isDarkMode: false,
        );
        final darkTheme = _applyTeacherTheme(
          AppTheme.darkTheme,
          teacherTheme,
          isDarkMode: true,
        );

        return ToastificationWrapper(
          child: MaterialApp.router(
            title: 'app_name'.tr(),
            debugShowCheckedModeBanner: false,
            // Disable stretch/glow overscroll indicator globally.
            // This avoids _StretchController assertions seen on some Android ROMs (e.g. MIUI).
            scrollBehavior:
                const MaterialScrollBehavior().copyWith(overscroll: false),
            // Localization
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            // Theme
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
            // Router
            routerConfig: AppRouter.router,
            // Builder for RTL support
            builder: (context, child) {
              final app = Directionality(
                textDirection: context.locale.languageCode == 'ar'
                    ? ui.TextDirection.rtl
                    : ui.TextDirection.ltr,
                child: child ?? const SizedBox(),
              );

              return kIsWeb ? MobileWebViewport(child: app) : app;
            },
          ),
        );
      },
    );
  }

  ThemeData _applyTeacherTheme(
    ThemeData baseTheme,
    TeacherThemeConfig? teacherTheme, {
    required bool isDarkMode,
  }) {
    if (teacherTheme == null || !teacherTheme.hasColors) return baseTheme;

    final primary =
        teacherTheme.primaryFor(isDarkMode) ?? baseTheme.colorScheme.primary;
    final secondary = teacherTheme.secondaryFor(isDarkMode) ??
        baseTheme.colorScheme.secondary;
    final requestedBackground = teacherTheme.backgroundFor(isDarkMode);
    final background = _safeScaffoldBackground(
      requestedBackground,
      baseTheme.scaffoldBackgroundColor,
      isDarkMode: isDarkMode,
    );
    final button = teacherTheme.buttonFor(isDarkMode) ?? primary;
    final requestedCard = teacherTheme.cardFor(isDarkMode);
    final card = _safeCardColor(
      requestedCard,
      baseTheme.cardColor,
      isDarkMode: isDarkMode,
    );
    final onBackground = _readableTextColor(background);
    final onCard = _readableTextColor(card);
    final outline = Color.alphaBlend(
      primary.withValues(alpha: isDarkMode ? 0.35 : 0.22),
      card,
    );

    return baseTheme.copyWith(
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      cardColor: card,
      dividerColor: outline,
      appBarTheme: baseTheme.appBarTheme.copyWith(
        backgroundColor: background,
        foregroundColor: onBackground,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: onBackground),
        actionsIconTheme: IconThemeData(color: onBackground),
        titleTextStyle: baseTheme.appBarTheme.titleTextStyle?.copyWith(
          color: onBackground,
        ),
      ),
      cardTheme: baseTheme.cardTheme.copyWith(
        color: card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: outline),
        ),
      ),
      colorScheme: baseTheme.colorScheme.copyWith(
        primary: primary,
        onPrimary: _readableTextColor(primary),
        secondary: secondary,
        onSecondary: _readableTextColor(secondary),
        surface: card,
        onSurface: onCard,
        outline: outline,
        tertiary: button,
        onTertiary: _readableTextColor(button),
      ),
      inputDecorationTheme: baseTheme.inputDecorationTheme.copyWith(
        fillColor: card,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: button, width: 1.4),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: outline),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: outline),
        ),
      ),
      navigationBarTheme: baseTheme.navigationBarTheme.copyWith(
        backgroundColor: card,
        indicatorColor: button.withValues(alpha: isDarkMode ? 0.24 : 0.14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: baseTheme.elevatedButtonTheme.style?.copyWith(
          backgroundColor: WidgetStatePropertyAll(button),
          foregroundColor: WidgetStatePropertyAll(_readableTextColor(button)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: baseTheme.textButtonTheme.style?.copyWith(
          foregroundColor: WidgetStatePropertyAll(button),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: baseTheme.outlinedButtonTheme.style?.copyWith(
          foregroundColor: WidgetStatePropertyAll(button),
          side: WidgetStatePropertyAll(BorderSide(color: button)),
        ),
      ),
    );
  }

  Color _readableTextColor(Color background) {
    return background.computeLuminance() > 0.48
        ? AppColors.textMainLight
        : AppColors.textMainDark;
  }

  Color _safeScaffoldBackground(
    Color? requested,
    Color fallback, {
    required bool isDarkMode,
  }) {
    if (requested == null) return fallback;
    final hsl = HSLColor.fromColor(requested);
    final isTintedLight = !isDarkMode && hsl.lightness > 0.88;
    final isHeavyLight = !isDarkMode && hsl.lightness <= 0.88;
    final isTintedDark = isDarkMode && hsl.saturation > 0.46;

    if (isHeavyLight || isTintedDark) return fallback;
    if (isTintedLight && hsl.saturation > 0.22) return fallback;
    return requested;
  }

  Color _safeCardColor(
    Color? requested,
    Color fallback, {
    required bool isDarkMode,
  }) {
    if (requested == null) return fallback;
    final hsl = HSLColor.fromColor(requested);
    final badLightCard =
        !isDarkMode && (hsl.lightness < 0.94 || hsl.saturation > 0.18);
    final badDarkCard =
        isDarkMode && (hsl.lightness > 0.22 || hsl.saturation > 0.52);

    return badLightCard || badDarkCard ? fallback : requested;
  }
}

class MobileWebViewport extends StatelessWidget {
  const MobileWebViewport({super.key, required this.child});

  static const double maxMobileWidth = 430;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportWidth = constraints.maxWidth > maxMobileWidth
            ? maxMobileWidth
            : constraints.maxWidth;
        final viewportHeight = constraints.maxHeight;
        final constrainedMediaQuery = mediaQuery.copyWith(
          size: Size(viewportWidth, viewportHeight),
        );

        if (constraints.maxWidth <= maxMobileWidth) {
          return MediaQuery(
            data: constrainedMediaQuery,
            child: child,
          );
        }

        final isDark = Theme.of(context).brightness == Brightness.dark;

        return ColoredBox(
          color: isDark ? const Color(0xFF111827) : const Color(0xFFE5E7EB),
          child: Center(
            child: Container(
              width: viewportWidth,
              height: viewportHeight,
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 30,
                    offset: Offset(0, 16),
                  ),
                ],
              ),
              clipBehavior: Clip.hardEdge,
              child: MediaQuery(
                data: constrainedMediaQuery,
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}
