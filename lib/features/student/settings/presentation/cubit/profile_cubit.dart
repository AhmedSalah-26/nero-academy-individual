import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lms_platform/core/services/app_logger.dart';
import 'package:lms_platform/features/student/settings/domain/repositories/settings_repository.dart';
import 'profile_state.dart';

/// Profile Cubit
class ProfileCubit extends Cubit<ProfileState> {
  final SettingsRepository repository;
  String? _currentUserId;

  ProfileCubit({required this.repository}) : super(ProfileState.initial());

  String? get currentUserId => _currentUserId;

  /// Load profile
  Future<void> loadProfile(String userId) async {
    _currentUserId = userId;
    emit(ProfileState.loading());
    AppLogger.i('👤 [ProfileCubit] Loading profile for: $userId');

    final result = await repository.getUserProfile(userId: userId);

    result.fold(
      (failure) {
        AppLogger.e('[ProfileCubit] Failed: ${failure.message}');
        emit(ProfileState.error(failure.message));
      },
      (profile) {
        AppLogger.success('[ProfileCubit] Profile loaded');
        emit(ProfileState.loaded(profile));
      },
    );
  }

  /// Update profile
  Future<bool> updateProfile({
    String? name,
    String? phone,
    String? avatarUrl,
    List<String>? interests,
    String? parentPhone,
    // Instructor fields
    String? displayName,
    String? headlineAr,
    String? headlineEn,
    String? bioAr,
    String? bioEn,
    String? websiteUrl,
    String? coverImageUrl,
    List<String>? expertise,
    Map<String, String>? socialLinks,
  }) async {
    if (_currentUserId == null) return false;

    AppLogger.i('[ProfileCubit] Updating profile');
    emit(state.copyWith(isSaving: true));

    final result = await repository.updateUserProfile(
      userId: _currentUserId!,
      name: name,
      phone: phone,
      avatarUrl: avatarUrl,
      interests: interests,
      parentPhone: parentPhone,
      displayName: displayName,
      headlineAr: headlineAr,
      headlineEn: headlineEn,
      bioAr: bioAr,
      bioEn: bioEn,
      websiteUrl: websiteUrl,
      coverImageUrl: coverImageUrl,
      expertise: expertise,
      socialLinks: socialLinks,
    );

    return result.fold(
      (failure) {
        AppLogger.e('[ProfileCubit] Failed: ${failure.message}');
        emit(state.copyWith(isSaving: false));
        return false;
      },
      (profile) {
        AppLogger.success('[ProfileCubit] Profile updated');
        emit(state.copyWith(profile: profile, isSaving: false));
        return true;
      },
    );
  }

  /// Refresh profile
  Future<void> refreshProfile() async {
    if (_currentUserId == null) return;
    await loadProfile(_currentUserId!);
  }
}
