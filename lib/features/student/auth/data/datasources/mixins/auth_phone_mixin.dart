import 'dart:io';

import 'package:lms_platform/core/services/app_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:lms_platform/core/errors/exceptions.dart' as app_exceptions;
import 'package:lms_platform/features/student/auth/data/models/user_model.dart';
// import 'auth_helpers_mixin.dart';

mixin AuthPhoneMixin {
  // Dependencies
  SupabaseClient get supabase;

  Future<UserModel> getProfile(String userId);
  void checkUserAccess(UserModel user);
  app_exceptions.AuthException handleAuthError(AuthApiException e);

  Future<void> sendPhoneOtp(String phoneNumber) async {
    AppLogger.i('📱 [DataSource] Sending OTP to: $phoneNumber');

    // In development mode, bypass account check
    // We will use 000000 to verify later
    AppLogger.i('✅ [DataSource] Skipping account check in development mode');
    AppLogger.i('   Use OTP: 000000 to login');

    // Currently we don't send real OTP, just success
    AppLogger.i('✅ [DataSource] OTP ready (bypass mode)');
  }

  Future<UserModel> verifyPhoneOtp(String phoneNumber, String otp) async {
    AppLogger.i('🔐 [DataSource] Verifying OTP for: $phoneNumber');
    AppLogger.d('  OTP token: $otp');

    try {
      // ✅ BYPASS MODE: Accept 000000 as valid OTP for development
      if (otp == '000000') {
        AppLogger.w(
            '⚠️ [DataSource] BYPASS MODE: Using development OTP 000000');

        // Search for profile related to this number
        AppLogger.i('📝 [DataSource] Getting profile by phone...');
        final profilesData = await supabase
            .from('profiles')
            .select()
            .eq('phone', phoneNumber)
            .limit(10); // Fetch up to 10 to check

        if (profilesData.isEmpty) {
          AppLogger.e(
              '❌ [DataSource] No profile found with phone: $phoneNumber');
          throw const app_exceptions.AuthException(
            'لا يوجد حساب مرتبط بهذا الرقم.\nيرجى إنشاء حساب جديد أولاً.',
            code: 'phone_not_registered',
          );
        }

        // If multiple profiles, take first & warn
        final profilesList = profilesData as List;
        if (profilesList.length > 1) {
          AppLogger.w(
              '⚠️ [DataSource] Multiple profiles found with phone: $phoneNumber (${profilesList.length} profiles)');
          AppLogger.w('   Taking the first profile...');
        }

        final profileData = profilesList.first as Map<String, dynamic>;
        final userId = profileData['id'] as String;
        final userEmail = profileData['email'] as String;

        AppLogger.i('🔑 [DataSource] User found: $userEmail (ID: $userId)');
        AppLogger.i(
            '🔑 [DataSource] Calling add_phone_to_auth_user for: $userId');

        try {
          await supabase.rpc('add_phone_to_auth_user', params: {
            'user_id': userId,
            'phone_number': phoneNumber,
          });
          AppLogger.i('✅ [DataSource] Phone added to auth.users successfully');

          // Attempt login via Supabase OTP
          AppLogger.i('🔐 [DataSource] Attempting Supabase OTP verification');
          try {
            final response = await supabase.auth.verifyOTP(
              type: OtpType.sms,
              phone: phoneNumber,
              token: otp,
            );

            if (response.user != null) {
              AppLogger.i(
                  '✅ [DataSource] Supabase OTP verified, user logged in');
            } else {
              AppLogger.w(
                  '⚠️ [DataSource] Supabase OTP verification returned null user');
            }
          } catch (otpError) {
            AppLogger.w(
                '⚠️ [DataSource] Supabase OTP verification failed: $otpError');
            AppLogger.w(
                '   Continuing with profile data only (no auth session)');
          }
        } catch (e) {
          AppLogger.w('⚠️ [DataSource] Failed to add phone to auth.users: $e');
          // Continue even if fail
        }

        final userModel = UserModel.fromJson(profileData);
        AppLogger.i(
            '✅ [DataSource] User profile ready (BYPASS): ${userModel.name}');
        checkUserAccess(userModel);
        return userModel;
      }

      // Normal OTP verification flow
      AppLogger.d('  Calling supabase.auth.verifyOTP...');
      final response = await supabase.auth.verifyOTP(
        type: OtpType.sms,
        phone: phoneNumber,
        token: otp,
      );

      AppLogger.d('  Response received');
      AppLogger.d('  User: ${response.user?.id}');
      AppLogger.d(
          '  Session: ${response.session?.accessToken != null ? "exists" : "null"}');

      if (response.user == null) {
        AppLogger.e('❌ [DataSource] OTP verification failed: user is null');
        throw const app_exceptions.AuthException('فشل التحقق من رمز OTP');
      }

      AppLogger.i('✅ [DataSource] OTP verified successfully!');

      // Get profile by phone
      AppLogger.i('📝 [DataSource] Getting profile by phone...');
      final profileData = await supabase
          .from('profiles')
          .select()
          .eq('phone', phoneNumber)
          .maybeSingle();

      if (profileData == null) {
        AppLogger.e('❌ [DataSource] No profile found with phone: $phoneNumber');
        // Sign out
        await supabase.auth.signOut();
        throw const app_exceptions.AuthException(
          'لا يوجد حساب مرتبط بهذا الرقم.\nيرجى إنشاء حساب جديد أولاً.',
          code: 'phone_not_registered',
        );
      }

      final userModel = UserModel.fromJson(profileData);
      AppLogger.i('✅ [DataSource] User profile ready: ${userModel.name}');
      checkUserAccess(userModel);
      return userModel;
    } on AuthApiException catch (e) {
      AppLogger.e('❌ [DataSource] AuthApiException: ${e.message}');
      AppLogger.e('   Code: ${e.code}');
      AppLogger.e('   Status: ${e.statusCode}');
      throw handleAuthError(e);
    } catch (e, stackTrace) {
      AppLogger.e('❌ [DataSource] Unexpected error: $e');
      AppLogger.e('   Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> sendLinkPhoneOtp(String phoneNumber) async {
    AppLogger.i('📱 [DataSource] Adding phone directly (no OTP): $phoneNumber');

    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) {
      throw const app_exceptions.AuthException(
        'يجب تسجيل الدخول أولاً لربط رقم الهاتف',
        code: 'not_authenticated',
      );
    }

    // Check if phone used
    try {
      final existingProfile = await supabase
          .from('profiles')
          .select('id')
          .eq('phone', phoneNumber)
          .neq('id', currentUser.id)
          .maybeSingle();

      if (existingProfile != null) {
        AppLogger.w('❌ [DataSource] Phone already used by another account');
        throw const app_exceptions.AuthException(
          'هذا الرقم مرتبط بحساب آخر',
          code: 'phone_already_used',
        );
      }
    } catch (e) {
      if (e is app_exceptions.AuthException) rethrow;
      AppLogger.e('❌ [DataSource] Error checking phone: $e');
    }

    // Add phone directly to auth.users without OTP
    try {
      final result = await supabase.rpc('add_phone_to_auth_user', params: {
        'user_id': currentUser.id,
        'phone_number': phoneNumber,
      });
      AppLogger.i('✅ [DataSource] Phone added directly to auth.users');
      AppLogger.d('   Result: $result');
    } on SocketException catch (e) {
      AppLogger.e('❌ [DataSource] Network error: $e');
      throw const app_exceptions.AuthException(
        'لا يوجد اتصال بالإنترنت. يرجى التحقق من الاتصال والمحاولة مرة أخرى.',
        code: 'network_error',
      );
    } on PostgrestException catch (e) {
      AppLogger.e('❌ [DataSource] Failed to add phone: ${e.message}');
      AppLogger.e('   Error code: ${e.code}');
      AppLogger.e('   Details: ${e.details}');
      AppLogger.e('   Hint: ${e.hint}');

      // Check if it's a function not found error
      if (e.code == '42883' ||
          e.message.contains('function') &&
              e.message.contains('does not exist')) {
        throw const app_exceptions.AuthException(
          'خطأ في الإعدادات. يرجى التواصل مع الدعم الفني.\n(RPC function not found)',
          code: 'function_not_found',
        );
      }

      throw app_exceptions.ServerException(e.message, code: e.code);
    } catch (e) {
      AppLogger.e('❌ [DataSource] Unexpected error: $e');
      rethrow;
    }
  }

  Future<UserModel> verifyLinkPhoneOtp(String phoneNumber, String otp) async {
    AppLogger.i(
        '🔐 [DataSource] Verifying phone link (bypass mode): $phoneNumber');

    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) {
      throw const app_exceptions.AuthException(
        'يجب تسجيل الدخول أولاً',
        code: 'not_authenticated',
      );
    }

    try {
      // ✅ BYPASS MODE: Accept 000000 as valid OTP for development
      if (otp == '000000') {
        AppLogger.w(
            '⚠️ [DataSource] BYPASS MODE: Using development OTP 000000 for phone linking');

        // Update profile with phone
        await supabase.from('profiles').update({
          'phone': phoneNumber,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', currentUser.id);

        // Call RPC
        AppLogger.i(
            '🔑 [DataSource] Calling add_phone_to_auth_user for: ${currentUser.id}');
        try {
          await supabase.rpc('add_phone_to_auth_user', params: {
            'user_id': currentUser.id,
            'phone_number': phoneNumber,
          });
          AppLogger.i('✅ [DataSource] Phone added to auth.users successfully');

          // Refresh session
          AppLogger.i('🔄 [DataSource] Refreshing session to update user data');
          await supabase.auth.refreshSession();
          AppLogger.i('✅ [DataSource] Session refreshed successfully');
        } catch (e) {
          AppLogger.w('⚠️ [DataSource] Failed to add phone to auth.users: $e');
        }

        AppLogger.i('✅ [DataSource] Phone linked successfully (BYPASS)!');
        return await getProfile(currentUser.id);
      }

      // Normal flow: update profile
      await supabase.from('profiles').update({
        'phone': phoneNumber,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', currentUser.id);

      AppLogger.i('✅ [DataSource] Phone linked successfully!');
      return await getProfile(currentUser.id);
    } on PostgrestException catch (e) {
      AppLogger.e('❌ [DataSource] PostgrestException: ${e.message}');
      throw app_exceptions.ServerException(e.message, code: e.code);
    }
  }
}
