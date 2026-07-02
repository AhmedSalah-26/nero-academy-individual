import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../core/errors/exceptions.dart' as app_exceptions;
import '../../../../../core/utils/phone_utils.dart';
import '../../models/user_model.dart';
// import 'auth_helpers_mixin.dart';


mixin AuthProfileMixin {
  // Dependencies
  SupabaseClient get supabase;
  Logger get logger;
  Future<UserModel> getProfile(String userId);
  app_exceptions.AuthException handleAuthError(AuthApiException e);

  Future<void> forgotPassword(String email) async {
    try {
      // 1) Verify if the email exists in profiles table first (ilike for case-insensitivity)
      final profile = await supabase
          .from('profiles')
          .select('id')
          .ilike('email', email.trim())
          .maybeSingle();

      if (profile == null) {
        throw const app_exceptions.AuthException(
          'البريد الإلكتروني غير مسجل في النظام. يرجى التحقق من البريد أو إنشاء حساب جديد.',
          code: 'email_not_registered',
        );
      }

      // 2) Use signInWithOtp to send a 6-digit OTP code to the user's email.
      // resetPasswordForEmail sends a magic link, not an OTP code.
      await supabase.auth.signInWithOtp(
        email: email.trim(),
        shouldCreateUser: false,
      );
    } on app_exceptions.AuthException {
      rethrow;
    } on AuthApiException catch (e) {
      throw handleAuthError(e);
    }
  }


  Future<void> resetPassword(
      {required String token, required String newPassword}) async {
    try {
      await supabase.auth.updateUser(UserAttributes(password: newPassword));
    } on AuthApiException catch (e) {
      throw handleAuthError(e);
    }
  }

  Future<UserModel> updateInterests(List<String> interests) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw app_exceptions.AuthException.sessionExpired();

    try {
      await supabase.from('profiles').update({
        'interests': interests,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
      return await getProfile(userId);
    } on PostgrestException catch (e) {
      throw app_exceptions.ServerException(e.message, code: e.code);
    }
  }

  Future<UserModel> updateProfile(
      {String? name, String? phone, String? avatarUrl}) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw app_exceptions.AuthException.sessionExpired();

    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String()
      };
      if (name != null) updates['name'] = name;
      if (phone != null) {
        // Normalize phone number to remove spaces and format correctly
        final normalizedPhone = PhoneUtils.normalizeWhatsappNumber(phone);
        if (normalizedPhone == null) {
          throw const app_exceptions.AuthException(
            'رقم الهاتف غير صحيح. برجاء كتابة رقم مصري صحيح مثل 01012345678.',
            code: 'invalid_phone',
          );
        }
        updates['phone'] = '+$normalizedPhone';
      }
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

      await supabase.from('profiles').update(updates).eq('id', userId);
      return await getProfile(userId);
    } on PostgrestException catch (e) {
      throw app_exceptions.ServerException(e.message, code: e.code);
    }
  }
}
