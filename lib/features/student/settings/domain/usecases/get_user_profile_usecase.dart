import 'package:dartz/dartz.dart';
import 'package:lms_platform/core/errors/failures.dart';
import 'package:lms_platform/core/usecase/usecase.dart';
import 'package:lms_platform/features/student/settings/domain/entities/user_profile_entity.dart';
import 'package:lms_platform/features/student/settings/domain/repositories/settings_repository.dart';

/// Get User Profile Use Case
class GetUserProfileUseCase
    implements UseCaseWithParams<UserProfileEntity, GetUserProfileParams> {
  final SettingsRepository repository;

  GetUserProfileUseCase(this.repository);

  @override
  Future<Either<Failure, UserProfileEntity>> call(GetUserProfileParams params) {
    return repository.getUserProfile(userId: params.userId);
  }
}

/// Get User Profile Params
class GetUserProfileParams {
  final String userId;

  const GetUserProfileParams({required this.userId});
}
