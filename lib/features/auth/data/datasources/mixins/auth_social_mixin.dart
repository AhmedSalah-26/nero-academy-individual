import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/errors/exceptions.dart' as app_exceptions;
import '../../models/user_model.dart';

mixin AuthSocialMixin {
  SupabaseClient get supabase;
  Logger get logger;
  Future<UserModel> getOrCreateProfile(User user);
  void checkUserAccess(UserModel user);
  app_exceptions.AuthException handleAuthError(AuthApiException e);

  Future<UserModel> loginWithGoogle() async {
    try {
      final currentUser = supabase.auth.currentUser;
      if (currentUser != null) {
        final profile = await getOrCreateProfile(currentUser);
        checkUserAccess(profile);
        return profile;
      }

      await supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: _oauthRedirectUrl,
      );

      // Web redirects the browser to Google. Supabase restores the session when
      // the user returns to the app, so there is no synchronous user to return.
      if (kIsWeb) {
        throw const app_exceptions.AuthException(
          'جاري تحويلك إلى Google لإكمال تسجيل الدخول...',
          code: 'oauth_redirect_started',
        );
      }

      final user = await _waitForOAuthUser();
      final profile = await getOrCreateProfile(user);
      checkUserAccess(profile);
      return profile;
    } on AuthApiException catch (e) {
      throw handleAuthError(e);
    }
  }

  Future<UserModel> loginWithApple() async {
    try {
      await supabase.auth.signInWithOAuth(
        OAuthProvider.apple,
        redirectTo: _oauthRedirectUrl,
      );
      final user = await _waitForOAuthUser();
      final profile = await getOrCreateProfile(user);
      checkUserAccess(profile);
      return profile;
    } on AuthApiException catch (e) {
      throw handleAuthError(e);
    }
  }

  Future<UserModel> loginWithFacebook() async {
    try {
      await supabase.auth.signInWithOAuth(
        OAuthProvider.facebook,
        redirectTo: _oauthRedirectUrl,
      );
      final user = await _waitForOAuthUser();
      final profile = await getOrCreateProfile(user);
      checkUserAccess(profile);
      return profile;
    } on AuthApiException catch (e) {
      throw handleAuthError(e);
    }
  }

  String get _oauthRedirectUrl {
    if (kIsWeb) return AppConstants.authRedirectUrl;
    return '${AppConstants.deepLinkScheme}://${AppConstants.deepLinkHost}/';
  }

  Future<User> _waitForOAuthUser() async {
    final existingUser = supabase.auth.currentUser;
    if (existingUser != null) return existingUser;

    try {
      final authState = await supabase.auth.onAuthStateChange
          .firstWhere(
            (event) => event.session?.user != null,
          )
          .timeout(const Duration(seconds: 90));
      final user = authState.session?.user;
      if (user != null) return user;
    } on TimeoutException {
      throw const app_exceptions.AuthException(
        'لم يكتمل تسجيل الدخول بجوجل. حاول مرة أخرى.',
        code: 'oauth_timeout',
      );
    }

    throw const app_exceptions.AuthException(
      'فشل تسجيل الدخول بجوجل',
      code: 'oauth_failed',
    );
  }
}
