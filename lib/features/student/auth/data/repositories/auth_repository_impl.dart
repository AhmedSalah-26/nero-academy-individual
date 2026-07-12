import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import 'package:lms_platform/core/base/base_repository.dart';
import 'package:lms_platform/core/errors/failures.dart';
import 'package:lms_platform/core/network/network_info.dart';
import 'package:lms_platform/features/student/auth/domain/entities/user_entity.dart';
import 'package:lms_platform/features/student/auth/domain/repositories/auth_repository.dart';
import 'package:lms_platform/features/student/auth/data/datasources/auth_local_data_source.dart';
import 'package:lms_platform/features/student/auth/data/datasources/auth_remote_data_source.dart';
import 'package:lms_platform/core/services/app_logger.dart';

/// Auth Repository Implementation
class AuthRepositoryImpl extends BaseRepository implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required NetworkInfo networkInfo,
  }) : super(networkInfo);

  @override
  Future<Either<Failure, UserEntity>> login({
    required String email,
    required String password,
  }) async {
    AppLogger.i('?? Login attempt for: $email');
    return safeCall(() async {
      final user = await remoteDataSource.login(
        email: email,
        password: password,
      );
      await localDataSource.cacheUser(user);
      AppLogger.i('? Login successful for: ${user.email}');
      return user;
    });
  }

  @override
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
  }) async {
    AppLogger.i('?? Register attempt:');
    AppLogger.d('  Email: $email');
    AppLogger.d('  Name: $name');
    AppLogger.d('  Role: ${role.name}');
    AppLogger.d('  Phone: $phone');
    AppLogger.d('  Headline: $headline');
    AppLogger.d('  Bio: ${bio != null ? '${bio.length} chars' : 'null'}');
    AppLogger.d('  Expertise: $expertise');
    AppLogger.d(
        '  Avatar: ${avatarBytes != null ? '${avatarBytes.length} bytes' : 'null'}');

    return safeCall(() async {
      final user = await remoteDataSource.register(
        email: email,
        password: password,
        name: name,
        role: role,
        phone: phone,
        headline: headline,
        bio: bio,
        expertise: expertise,
        avatarBytes: avatarBytes,
      );
      await localDataSource.cacheUser(user);
      AppLogger.i('? Registration successful for: ${user.email}');
      return user;
    });
  }

  @override
  Future<Either<Failure, void>> logout() async {
    return safeCall(() async {
      await remoteDataSource.logout();
      await localDataSource.clearCache();
    }, checkConnection: false);
  }

  @override
  Future<Either<Failure, UserEntity?>> getCurrentUser() async {
    // Try to get from remote first
    if (await networkInfo.isConnected) {
      try {
        final user = await remoteDataSource.getCurrentUser();
        if (user != null) {
          await localDataSource.cacheUser(user);
        }
        return Right(user);
      } catch (e) {
        // Fall back to cache
        final cachedUser = await localDataSource.getCachedUser();
        return Right(cachedUser);
      }
    } else {
      // No network, use cache
      final cachedUser = await localDataSource.getCachedUser();
      return Right(cachedUser);
    }
  }

  @override
  Future<bool> isLoggedIn() async {
    final result = await getCurrentUser();
    return result.fold(
      (_) => false,
      (user) => user != null,
    );
  }

  @override
  Future<Either<Failure, void>> forgotPassword(String email) async {
    return safeCall(() => remoteDataSource.forgotPassword(email));
  }

  @override
  Future<Either<Failure, void>> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    return safeCall(() => remoteDataSource.resetPassword(
          token: token,
          newPassword: newPassword,
        ));
  }

  @override
  Future<Either<Failure, UserEntity>> updateInterests(
      List<String> interests) async {
    return safeCall(() async {
      final user = await remoteDataSource.updateInterests(interests);
      await localDataSource.cacheUser(user);
      await localDataSource.cacheInterests(interests);
      return user;
    });
  }

  @override
  Future<Either<Failure, UserEntity>> updateProfile({
    String? name,
    String? phone,
    String? avatarUrl,
  }) async {
    return safeCall(() async {
      final user = await remoteDataSource.updateProfile(
        name: name,
        phone: phone,
        avatarUrl: avatarUrl,
      );
      await localDataSource.cacheUser(user);
      return user;
    });
  }

  @override
  Future<Either<Failure, UserEntity>> loginWithGoogle() async {
    return safeCall(() async {
      final user = await remoteDataSource.loginWithGoogle();
      await localDataSource.cacheUser(user);
      return user;
    });
  }

  @override
  Future<Either<Failure, UserEntity>> loginWithApple() async {
    return safeCall(() async {
      final user = await remoteDataSource.loginWithApple();
      await localDataSource.cacheUser(user);
      return user;
    });
  }

  @override
  Future<Either<Failure, UserEntity>> loginWithFacebook() async {
    return safeCall(() async {
      final user = await remoteDataSource.loginWithFacebook();
      await localDataSource.cacheUser(user);
      return user;
    });
  }

  @override
  Future<Either<Failure, void>> sendPhoneOtp(String phoneNumber) async {
    return safeCall(() => remoteDataSource.sendPhoneOtp(phoneNumber));
  }

  @override
  Future<Either<Failure, UserEntity>> verifyPhoneOtp(
      String phoneNumber, String otp) async {
    AppLogger.i('?? [Repository] Verifying phone OTP');
    AppLogger.d('  Phone: $phoneNumber');
    AppLogger.d('  OTP: $otp');

    return safeCall(() async {
      AppLogger.d('  Calling remote data source...');
      final user = await remoteDataSource.verifyPhoneOtp(phoneNumber, otp);

      AppLogger.i('? [Repository] User verified: ${user.name}');
      AppLogger.d('  Caching user...');
      await localDataSource.cacheUser(user);

      AppLogger.i('? [Repository] User cached successfully');
      return user;
    });
  }

  @override
  Future<Either<Failure, void>> sendLinkPhoneOtp(String phoneNumber) async {
    AppLogger.i('?? [Repository] Sending OTP to link phone: $phoneNumber');
    return safeCall(() => remoteDataSource.sendLinkPhoneOtp(phoneNumber));
  }

  @override
  Future<Either<Failure, UserEntity>> verifyLinkPhoneOtp(
      String phoneNumber, String otp) async {
    AppLogger.i('?? [Repository] Verifying OTP to link phone');
    return safeCall(() async {
      final user = await remoteDataSource.verifyLinkPhoneOtp(phoneNumber, otp);
      await localDataSource.cacheUser(user);
      AppLogger.i('? [Repository] Phone linked successfully');
      return user;
    });
  }

  @override
  Stream<UserEntity?> get authStateChanges => remoteDataSource.authStateChanges;
}
