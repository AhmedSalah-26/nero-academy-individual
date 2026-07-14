import 'package:flutter/foundation.dart';

/// App Constants - Central configuration
class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = '\u0646\u0633\u0642';
  static const String appNameEn = 'Nasaq';
  static const String appVersion = '1.0.0';

  // Supabase Configuration
  static const String supabaseUrl = 'https://ogudalsccnraguajiqku.supabase.co';
  static const String supabaseAnonKey =
      'sb_publishable_brbho9x2lHaslZR4e6Gyfg_BuwRjD49';
  static const String supabaseJwtAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9ndWRhbHNjY25yYWd1YWppcWt1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODM4NTkxOTksImV4cCI6MjA5OTQzNTE5OX0.umuFbHzz_ZR0OauUhJaUaqzu9ByWmEMHJGOkZ4Vxsro';
  static const String googleWebClientId =
      '901902911640-alaal9vjbd6d05qiodnhi7fetck05d5b.apps.googleusercontent.com';

  // Storage Buckets
  static const String avatarsBucket = 'avatars';
  static const String coursesBucket = 'courses';
  static const String certificatesBucket = 'certificates';

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Cache Duration
  static const Duration cacheDuration = Duration(hours: 1);
  static const Duration shortCacheDuration = Duration(minutes: 15);

  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Validation
  static const int minPasswordLength = 8;
  static const int maxNameLength = 100;
  static const int maxBioLength = 500;

  // Deep Links
  static const String deepLinkScheme = 'io.supabase.lms';
  static const String deepLinkHost = 'login-callback';

  // Dynamic Auth / Email Redirect URL
  static String get authRedirectUrl {
    if (kIsWeb) {
      try {
        final uri = Uri.parse(Uri.base.toString());
        // Clean the URI from fragments (like #/login) and query params
        return Uri(
          scheme: uri.scheme,
          host: uri.host,
          port: uri.port,
          path: uri.path,
        ).toString();
      } catch (_) {
        return 'https://ahmedsalah-26.github.io/nero-academy-individual-web-app/';
      }
    }
    return 'https://ahmedsalah-26.github.io/nero-academy-individual-web-app/';
  }

  // Password Reset Web Page
  static String get passwordResetRedirectUrl {
    if (kIsWeb) {
      try {
        final uri = Uri.base;
        final baseSegments = <String>[];

        // GitHub Pages project sites are hosted under /repo-name/.
        // Keep that first segment so /reset-password resolves inside the app.
        if (uri.host.endsWith('github.io') && uri.pathSegments.isNotEmpty) {
          final first = uri.pathSegments.first;
          if (first.isNotEmpty) {
            baseSegments.add(first);
          }
        }

        return Uri(
          scheme: uri.scheme,
          host: uri.host,
          port: uri.hasPort ? uri.port : null,
          pathSegments: [...baseSegments, 'reset-password'],
        ).toString();
      } catch (_) {
        return 'https://ahmedsalah-26.github.io/nero-academy-individual-web-app/reset-password';
      }
    }

    return 'https://ahmedsalah-26.github.io/nero-academy-individual-web-app/reset-password';
  }
}
