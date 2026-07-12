import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lms_platform/core/errors/exceptions.dart' as app_exceptions;
import 'package:lms_platform/core/services/app_logger.dart';
import 'package:lms_platform/features/student/auth/domain/entities/user_entity.dart';
import 'package:lms_platform/features/student/auth/data/models/user_model.dart';

mixin AuthHelpersMixin {
  SupabaseClient get supabase;

  Future<UserModel> getProfile(String userId) async {
    final response =
        await supabase.from('profiles').select().eq('id', userId).single();
    return UserModel.fromJson(response);
  }

  Future<UserModel> getOrCreateProfile(User user) async {
    AppLogger.i(
        '🔍 [DataSource] Getting or creating profile for user: ${user.id}');
    AppLogger.d('  User phone: ${user.phone}');
    AppLogger.d('  User email: ${user.email}');
    AppLogger.d('  User metadata: ${user.userMetadata}');

    // First: Try getting existing profile
    try {
      AppLogger.d('  Trying to get existing profile...');
      return await getProfile(user.id);
    } on PostgrestException catch (e) {
      // PGRST116 = no rows returned (profile doesn't exist)
      if (e.code != 'PGRST116') {
        AppLogger.e('❌ [DataSource] Unexpected error getting profile: $e');
        rethrow;
      }
      AppLogger.w('  Profile not found (PGRST116), will create new one...');
    } catch (e) {
      AppLogger.w('  Profile not found, creating new one...');
      AppLogger.e('  Error getting profile: $e');
    }

    // Second: Create new profile
    final phone = user.phone ?? user.userMetadata?['phone'];
    final email = user.email ?? user.userMetadata?['email'];
    final name = user.userMetadata?['full_name'] ??
        user.userMetadata?['name'] ??
        phone ??
        'مستخدم جديد';

    // If no email, use phone as temp email
    final profileEmail = email ?? '${phone?.replaceAll('+', '')}@phone.user';

    AppLogger.i('  Creating profile with:');
    AppLogger.d('    ID: ${user.id}');
    AppLogger.d('    Email: $profileEmail');
    AppLogger.d('    Phone: $phone');
    AppLogger.d('    Name: $name');

    try {
      // Attempt 1: RPC function (bypass RLS)
      AppLogger.d('  Trying RPC function create_profile_for_phone_auth...');
      await supabase.rpc('create_profile_for_phone_auth', params: {
        'user_id': user.id,
        'user_phone': phone,
        'user_email': profileEmail,
        'user_name': name,
      });
      AppLogger.i('✅ [DataSource] Profile created via RPC successfully');
    } catch (rpcError) {
      AppLogger.w('  RPC failed: $rpcError, trying direct upsert...');

      try {
        // Attempt 2: Direct upsert
        await supabase.from('profiles').upsert(
          {
            'id': user.id,
            'email': profileEmail,
            'phone': phone,
            'name': name,
            'avatar_url': user.userMetadata?['avatar_url'],
            'role': 'student',
            'is_active': true,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          },
          onConflict: 'id',
          ignoreDuplicates: true,
        );
        AppLogger.i('✅ [DataSource] Profile upserted successfully');
      } on PostgrestException catch (insertError) {
        AppLogger.e(
            '❌ [DataSource] PostgrestException: ${insertError.message}, code: ${insertError.code}');

        // If duplicate key, ignore
        if (insertError.code != '23505') {
          rethrow;
        }
        AppLogger.w('  Profile already exists (duplicate key), continuing...');
      }
    }

    // Wait for propagation
    await Future.delayed(const Duration(milliseconds: 300));

    // Get profile
    try {
      return await getProfile(user.id);
    } catch (e) {
      AppLogger.e('❌ [DataSource] Failed to get profile after creation: $e');
      // Return temp UserModel
      return UserModel(
        id: user.id,
        email: profileEmail,
        name: name,
        phone: phone,
        role: UserRole.student,
        isActive: true,
        createdAt: DateTime.now(),
      );
    }
  }

  void checkUserAccess(UserModel user) {
    if (!user.isActive) throw app_exceptions.AuthException.userInactive();
    if (user.isBanned) {
      throw app_exceptions.AuthException.userBanned(
          user.banReason, user.bannedUntil);
    }
  }

  app_exceptions.AuthException handleAuthError(AuthApiException e) {
    final message = e.message.toLowerCase();
    if (message.contains('invalid login credentials')) {
      return app_exceptions.AuthException.invalidCredentials();
    }
    if (message.contains('email already registered') ||
        message.contains('already registered')) {
      return app_exceptions.AuthException.emailAlreadyInUse();
    }
    if (message.contains('weak password')) {
      return app_exceptions.AuthException.weakPassword();
    }
    if (message.contains('user not found')) {
      return app_exceptions.AuthException.userNotFound();
    }
    if (message.contains('email not confirmed')) {
      return const app_exceptions.AuthException(
          'يرجى تأكيد بريدك الإلكتروني أولاً',
          code: 'email_not_confirmed');
    }
    return app_exceptions.AuthException(e.message, code: 'auth_error');
  }
}
