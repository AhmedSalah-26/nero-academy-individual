import 'package:flutter/foundation.dart';

/// App Constants - Central configuration
class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'منصة التعليم';
  static const String appNameEn = 'Learning Platform';
  static const String appVersion = '1.0.0';

  // Supabase Configuration
  static const String supabaseUrl = 'https://ubjhdafxmncfbaldfivd.supabase.co';
  static const String supabaseAnonKey =
      'sb_publishable_wJvu57s6WvTFFi9JTZhBbg_mS3tYCE7';
  static const String googleWebClientId =
      '1083887222364-3jlne3f2n5jqdht1nvbp4i0trev8sgca.apps.googleusercontent.com';

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
  static String get passwordResetRedirectUrl => authRedirectUrl;
}

