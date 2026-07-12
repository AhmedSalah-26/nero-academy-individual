import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import 'package:lms_platform/core/errors/failures.dart';
import 'package:lms_platform/features/student/auth/domain/entities/user_entity.dart';

/// Auth Repository Contract - Abstract Interface
abstract class AuthRepository {
  /// Login with email and password
  Future<Either<Failure, UserEntity>> login({
    required String email,
    required String password,
  });

  /// Register new user
  Future<Either<Failure, UserEntity>> register({
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

  /// Logout current user
  Future<Either<Failure, void>> logout();

  /// Get current logged in user
  Future<Either<Failure, UserEntity?>> getCurrentUser();

  /// Check if user is logged in
  Future<bool> isLoggedIn();

  /// Send password reset email
  Future<Either<Failure, void>> forgotPassword(String email);

  /// Reset password with token
  Future<Either<Failure, void>> resetPassword({
    required String token,
    required String newPassword,
  });

  /// Update user interests
  Future<Either<Failure, UserEntity>> updateInterests(List<String> interests);

  /// Update user profile
  Future<Either<Failure, UserEntity>> updateProfile({
    String? name,
    String? phone,
    String? avatarUrl,
  });

  /// Login with Google
  Future<Either<Failure, UserEntity>> loginWithGoogle();

  /// Login with Apple
  Future<Either<Failure, UserEntity>> loginWithApple();

  /// Login with Facebook
  Future<Either<Failure, UserEntity>> loginWithFacebook();

  /// Send OTP to phone number (for login)
  Future<Either<Failure, void>> sendPhoneOtp(String phoneNumber);

  /// Verify OTP and login
  Future<Either<Failure, UserEntity>> verifyPhoneOtp(
      String phoneNumber, String otp);

  /// Send OTP to link phone to existing account
  Future<Either<Failure, void>> sendLinkPhoneOtp(String phoneNumber);

  /// Verify OTP and link phone to account
  Future<Either<Failure, UserEntity>> verifyLinkPhoneOtp(
      String phoneNumber, String otp);

  /// Stream of auth state changes
  Stream<UserEntity?> get authStateChanges;
}
