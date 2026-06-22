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
    return ValueListenableBuilder<bool>(
      valueListenable: ThemeService.instance.isDarkMode,
      builder: (context, isDark, _) {
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
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
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
