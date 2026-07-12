import 'package:dartz/dartz.dart';
import 'package:lms_platform/core/errors/failures.dart';
import 'package:lms_platform/core/usecase/usecase.dart';
import 'package:lms_platform/features/student/settings/domain/entities/settings_entity.dart';
import 'package:lms_platform/features/student/settings/domain/repositories/settings_repository.dart';

/// Get Settings Use Case
class GetSettingsUseCase
    implements UseCaseWithParams<SettingsEntity, GetSettingsParams> {
  final SettingsRepository repository;

  GetSettingsUseCase(this.repository);

  @override
  Future<Either<Failure, SettingsEntity>> call(GetSettingsParams params) {
    return repository.getSettings(userId: params.userId);
  }
}

/// Get Settings Params
class GetSettingsParams {
  final String userId;

  const GetSettingsParams({required this.userId});
}
