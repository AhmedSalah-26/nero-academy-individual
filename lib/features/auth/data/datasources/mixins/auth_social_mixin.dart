import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart' as google_sign_in;

import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/errors/exceptions.dart' as app_exceptions;
import '../../models/user_model.dart';

mixin AuthSocialMixin {
  SupabaseClient get supabase;
  
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

      if (AppConstants.googleWebClientId.isEmpty) {
        throw const app_exceptions.AuthException(
          'معرف عميل جوجل مفقود، يرجى تحديث الإعدادات.',
          code: 'missing_client_id',
        );
      }

      await google_sign_in.GoogleSignIn.instance.initialize(
        serverClientId: AppConstants.googleWebClientId,
      );

      final google_sign_in.GoogleSignInAccount googleUser =
          await google_sign_in.GoogleSignIn.instance.authenticate();

      // In v7, .authentication is a sync getter (not a Future)
      final idToken = googleUser.authentication.idToken;
      if (idToken == null) {
        throw const app_exceptions.AuthException(
          'لم يتم استلام idToken من جوجل.',
          code: 'missing_id_token',
        );
      }

      await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );

      // Web does not redirect out, so we can await and get the current user.
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw const app_exceptions.AuthException(
          'فشل تسجيل الدخول بجوجل',
          code: 'oauth_failed',
        );
      }

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

