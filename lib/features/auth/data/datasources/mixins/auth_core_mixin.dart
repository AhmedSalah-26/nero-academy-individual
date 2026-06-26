import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/errors/exceptions.dart' as app_exceptions;
import '../../../../../core/utils/phone_utils.dart';
import '../../../domain/entities/user_entity.dart';
import '../../models/user_model.dart';

mixin AuthCoreMixin {
  // Dependencies
  SupabaseClient get supabase;
  Logger get logger;
  Future<UserModel> getProfile(String userId);
  Future<UserModel> getOrCreateProfile(User user);
  void checkUserAccess(UserModel user);
  app_exceptions.AuthException handleAuthError(AuthApiException e);

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    logger.i('🔐 [DataSource] Login: $email');
    try {
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        logger.e('❌ [DataSource] Login failed: user is null');
        throw app_exceptions.AuthException.invalidCredentials();
      }

      logger.i('✅ [DataSource] Auth successful, fetching profile...');
      final profile = await getOrCreateProfile(response.user!);
      checkUserAccess(profile);
      return profile;
    } on AuthApiException catch (e) {
      logger.e('❌ [DataSource] AuthApiException: ${e.message}');
      throw handleAuthError(e);
    }
  }

  Future<UserModel> register({
    required String email,
    required String password,
    required String name,
    required UserRole role,
    String? phone,
    String? headline,
    String? bio,
    List<String>? expertise,
    Uint8List? avatarBytes,
  }) async {
    logger.i('📝 [DataSource] Register: $email, role: ${role.name}');
    try {
      if (role == UserRole.instructor) {
        throw const app_exceptions.AuthException(
          'تسجيل المدرس المباشر متوقف. برجاء إرسال طلب تدريس من شاشة التسجيل.',
          code: 'instructor_signup_disabled',
        );
      }

      // Normalize phone number
      String? normalizedPhone;
      if (phone != null && phone.isNotEmpty) {
        final cleaned = PhoneUtils.normalizeWhatsappNumber(phone);
        normalizedPhone = cleaned != null ? '+$cleaned' : phone;
      }

      logger.d('  Calling supabase.auth.signUp...');
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {'name': name, 'role': role.toJson(), 'phone': normalizedPhone},
        emailRedirectTo: AppConstants.authRedirectUrl,
      );

      if (response.user == null) {
        logger.e('❌ [DataSource] SignUp failed: user is null');
        throw const app_exceptions.AuthException('فشل في إنشاء الحساب');
      }
      logger
          .i('✅ [DataSource] SignUp successful, userId: ${response.user!.id}');

      String? avatarUrl;
      // Upload avatar if provided
      if (avatarBytes != null) {
        logger.d('  Uploading avatar (${avatarBytes.length} bytes)...');
        final fileName = '${response.user!.id}/avatar.jpg';
        await supabase.storage.from('avatars').uploadBinary(
              fileName,
              avatarBytes,
              fileOptions: const FileOptions(upsert: true),
            );
        avatarUrl = supabase.storage.from('avatars').getPublicUrl(fileName);
        logger.i('✅ [DataSource] Avatar uploaded: $avatarUrl');
      }

      final profileData = <String, dynamic>{
        'id': response.user!.id,
        'email': email,
        'name': name,
        'role': role.toJson(),
        'phone': normalizedPhone,
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
      };

      if (avatarUrl != null) profileData['avatar_url'] = avatarUrl;

      logger.d('  Upserting profile data: $profileData');
      await supabase.from('profiles').upsert(profileData);
      logger.i('✅ [DataSource] Profile created successfully');

      if (role == UserRole.instructor) {
        final instructorProfileData = <String, dynamic>{
          'instructor_id': response.user!.id,
          'display_name': name,
          if (avatarUrl != null) 'avatar_url': avatarUrl,
          if (headline != null) 'headline_ar': headline,
          if (bio != null) 'bio_ar': bio,
          if (expertise != null && expertise.isNotEmpty) 'expertise': expertise,
          'updated_at': DateTime.now().toIso8601String(),
        };

        final existingInstructorProfile = await supabase
            .from('instructor_profiles')
            .select('id')
            .eq('instructor_id', response.user!.id)
            .maybeSingle();

        if (existingInstructorProfile != null) {
          await supabase
              .from('instructor_profiles')
              .update(instructorProfileData)
              .eq('instructor_id', response.user!.id);
        } else {
          await supabase.from('instructor_profiles').insert({
            ...instructorProfileData,
            'payout_method': 'wallet',
          });
        }
      }

      // Note: Phone will be added to auth.users later when user verifies it
      // We don't add it here to avoid triggering OTP during registration

      final profile = await getOrCreateProfile(response.user!);
      checkUserAccess(profile);
      return profile;
    } on AuthApiException catch (e) {
      logger.e('❌ [DataSource] AuthApiException: ${e.message}');
      final message = e.message.toLowerCase();

      // If account already exists, try logging in directly to avoid blocking user.
      if (message.contains('email already registered') ||
          message.contains('already registered')) {
        logger
            .w('⚠️ [DataSource] Email already exists, trying direct login...');
        return await login(email: email, password: password);
      }

      throw handleAuthError(e);
    } on PostgrestException catch (e) {
      logger.e(
          '❌ [DataSource] PostgrestException: ${e.message}, code: ${e.code}');
      throw app_exceptions.ServerException(e.message, code: e.code);
    } catch (e) {
      logger.e('❌ [DataSource] Unknown error: $e');
      rethrow;
    }
  }

      logger.d('  Calling supabase.auth.signUp...');
      
      // Normalize phone number before signup
      final normalizedPhone = phone != null 
          ? PhoneUtils.normalizeWhatsappNumber(phone) 
          : null;
      final formattedPhone = normalizedPhone != null ? '+$normalizedPhone' : null;
      
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {'name': name, 'role': role.toJson(), 'phone': formattedPhone},
        emailRedirectTo: AppConstants.authRedirectUrl,
      );

      if (response.user == null) {
        logger.e('❌ [DataSource] SignUp failed: user is null');
        throw const app_exceptions.AuthException('فشل في إنشاء الحساب');
      }
      logger
          .i('✅ [DataSource] SignUp successful, userId: ${response.user!.id}');

      String? avatarUrl;
      // Upload avatar if provided
      if (avatarBytes != null) {
        logger.d('  Uploading avatar (${avatarBytes.length} bytes)...');
        final fileName = '${response.user!.id}/avatar.jpg';
        await supabase.storage.from('avatars').uploadBinary(
              fileName,
              avatarBytes,
              fileOptions: const FileOptions(upsert: true),
            );
        avatarUrl = supabase.storage.from('avatars').getPublicUrl(fileName);
        logger.i('✅ [DataSource] Avatar uploaded: $avatarUrl');
      }

      final profileData = <String, dynamic>{
        'id': response.user!.id,
        'email': email,
        'name': name,
        'role': role.toJson(),
        'phone': phone,
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
      };

      if (avatarUrl != null) profileData['avatar_url'] = avatarUrl;

      logger.d('  Upserting profile data: $profileData');
      await supabase.from('profiles').upsert(profileData);
      logger.i('✅ [DataSource] Profile created successfully');

      if (role == UserRole.instructor) {
        final instructorProfileData = <String, dynamic>{
          'instructor_id': response.user!.id,
          'display_name': name,
          if (avatarUrl != null) 'avatar_url': avatarUrl,
          if (headline != null) 'headline_ar': headline,
          if (bio != null) 'bio_ar': bio,
          if (expertise != null && expertise.isNotEmpty) 'expertise': expertise,
          'updated_at': DateTime.now().toIso8601String(),
        };

        final existingInstructorProfile = await supabase
            .from('instructor_profiles')
            .select('id')
            .eq('instructor_id', response.user!.id)
            .maybeSingle();

        if (existingInstructorProfile != null) {
          await supabase
              .from('instructor_profiles')
              .update(instructorProfileData)
              .eq('instructor_id', response.user!.id);
        } else {
          await supabase.from('instructor_profiles').insert({
            ...instructorProfileData,
            'payout_method': 'wallet',
          });
        }
      }

      // Note: Phone will be added to auth.users later when user verifies it
      // We don't add it here to avoid triggering OTP during registration

      final profile = await getOrCreateProfile(response.user!);
      checkUserAccess(profile);
      return profile;
    } on AuthApiException catch (e) {
      logger.e('❌ [DataSource] AuthApiException: ${e.message}');
      final message = e.message.toLowerCase();

      // If account already exists, try logging in directly to avoid blocking user.
      if (message.contains('email already registered') ||
          message.contains('already registered')) {
        logger
            .w('⚠️ [DataSource] Email already exists, trying direct login...');
        return await login(email: email, password: password);
      }

      throw handleAuthError(e);
    } on PostgrestException catch (e) {
      logger.e(
          '❌ [DataSource] PostgrestException: ${e.message}, code: ${e.code}');
      throw app_exceptions.ServerException(e.message, code: e.code);
    } catch (e) {
      logger.e('❌ [DataSource] Unknown error: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      // Sign out from all devices
      await supabase.auth.signOut(scope: SignOutScope.global);
    } catch (e) {
      // Fallback to local sign out
      await supabase.auth.signOut(scope: SignOutScope.local);
    }
  }

  Future<UserModel?> getCurrentUser() async {
    final user = supabase.auth.currentUser;
    if (user == null) return null;
    try {
      return await getProfile(user.id);
    } catch (e) {
      return null;
    }
  }

  Stream<UserModel?> get authStateChanges {
    return supabase.auth.onAuthStateChange.asyncMap((event) async {
      if (event.session?.user == null) return null;
      try {
        final profile = await getOrCreateProfile(event.session!.user);
        checkUserAccess(profile);
        return profile;
      } catch (e) {
        return null;
      }
    });
  }
}
