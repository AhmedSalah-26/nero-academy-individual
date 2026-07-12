import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:lms_platform/features/student/auth/domain/entities/user_entity.dart';
import 'package:lms_platform/features/student/auth/data/models/user_model.dart';
import 'mixins/auth_core_mixin.dart';
import 'mixins/auth_helpers_mixin.dart';
import 'mixins/auth_phone_mixin.dart';
import 'mixins/auth_profile_mixin.dart';
import 'mixins/auth_social_mixin.dart';

/// Auth Remote Data Source - Handles Supabase Auth operations
abstract class AuthRemoteDataSource {
  Future<UserModel> login({required String email, required String password});
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
  });
  Future<void> logout();
  Future<UserModel?> getCurrentUser();
  Future<void> forgotPassword(String email);
  Future<void> resetPassword(
      {required String token, required String newPassword});
  Future<UserModel> updateInterests(List<String> interests);
  Future<UserModel> updateProfile(
      {String? name, String? phone, String? avatarUrl});
  Future<UserModel> loginWithGoogle();
  Future<UserModel> loginWithApple();
  Future<UserModel> loginWithFacebook();
  Future<void> sendPhoneOtp(String phoneNumber);
  Future<UserModel> verifyPhoneOtp(String phoneNumber, String otp);
  // ربط الهاتف بحساب موجود
  Future<void> sendLinkPhoneOtp(String phoneNumber);
  Future<UserModel> verifyLinkPhoneOtp(String phoneNumber, String otp);
  Stream<UserModel?> get authStateChanges;
}

class AuthRemoteDataSourceImpl
    with
        AuthHelpersMixin,
        AuthCoreMixin,
        AuthSocialMixin,
        AuthPhoneMixin,
        AuthProfileMixin
    implements AuthRemoteDataSource {
  final SupabaseClient _supabase;

  AuthRemoteDataSourceImpl(this._supabase);

  @override
  SupabaseClient get supabase => _supabase;
}
