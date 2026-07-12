import 'package:dartz/dartz.dart';
import 'package:lms_platform/core/errors/failures.dart';
import 'package:lms_platform/core/usecase/usecase.dart';
import 'package:lms_platform/features/student/settings/domain/entities/settings_entity.dart';
import 'package:lms_platform/features/student/settings/domain/repositories/settings_repository.dart';

/// Update Settings Use Case
class UpdateSettingsUseCase
    implements UseCaseWithParams<SettingsEntity, UpdateSettingsParams> {
  final SettingsRepository repository;

  UpdateSettingsUseCase(this.repository);

  @override
  Future<Either<Failure, SettingsEntity>> call(UpdateSettingsParams params) {
    return repository.updateSettings(
      userId: params.userId,
      languageCode: params.languageCode,
      isDarkMode: params.isDarkMode,
      notificationsEnabled: params.notificationsEnabled,
      videoAutoplay: params.videoAutoplay,
    );
  }
}

/// Update Settings Params
class UpdateSettingsParams {
  final String userId;
  final String? languageCode;
  final bool? isDarkMode;
  final bool? notificationsEnabled;
  final bool? videoAutoplay;

  const UpdateSettingsParams({
    required this.userId,
    this.languageCode,
    this.isDarkMode,
    this.notificationsEnabled,
    this.videoAutoplay,
  });
}
