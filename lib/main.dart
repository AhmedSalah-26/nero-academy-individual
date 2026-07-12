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
    final background = teacherTheme.backgroundFor(isDarkMode) ??
        baseTheme.scaffoldBackgroundColor;

    return baseTheme.copyWith(
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      colorScheme: baseTheme.colorScheme.copyWith(
        primary: primary,
        secondary: secondary,
        surface: background,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: baseTheme.elevatedButtonTheme.style?.copyWith(
          backgroundColor: WidgetStatePropertyAll(primary),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: baseTheme.textButtonTheme.style?.copyWith(
          foregroundColor: WidgetStatePropertyAll(primary),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: baseTheme.outlinedButtonTheme.style?.copyWith(
          foregroundColor: WidgetStatePropertyAll(primary),
          side: WidgetStatePropertyAll(BorderSide(color: primary)),
        ),
      ),
    );
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
