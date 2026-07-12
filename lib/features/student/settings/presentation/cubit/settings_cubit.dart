import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lms_platform/core/services/app_logger.dart';
import 'package:lms_platform/core/services/theme_service.dart';
import 'package:lms_platform/core/services/user_role_service.dart';
import 'package:lms_platform/features/student/settings/domain/repositories/settings_repository.dart';
import 'package:lms_platform/features/student/settings/domain/entities/settings_entity.dart';
import 'settings_state.dart';

/// Settings Cubit
class SettingsCubit extends Cubit<SettingsState> {
  final SettingsRepository repository;
  String? _currentUserId;

  SettingsCubit({required this.repository}) : super(SettingsState.initial());

  String? get currentUserId => _currentUserId;

  /// Load settings
  Future<void> loadSettings(String userId) async {
    _currentUserId = userId;
    emit(SettingsState.loading());
    AppLogger.i('⚙️ [SettingsCubit] Loading settings for: $userId');

    final result = await repository.getSettings(userId: userId);

    result.fold(
      (failure) {
        AppLogger.e('[SettingsCubit] Failed: ${failure.message}');
        emit(SettingsState.error(failure.message));
      },
      (settings) {
        AppLogger.success('[SettingsCubit] Settings loaded');
        // Theme is managed by ThemeService (local only)
        // Update settings state with current theme from ThemeService
        final updatedSettings = settings.copyWith(
          isDarkMode: ThemeService.instance.currentDarkMode,
        );
        emit(SettingsState.loaded(updatedSettings));
      },
    );
  }

  /// Load guest settings (e.g. for Parent Portal)
  void loadGuestSettings() {
    _currentUserId = null;
    emit(SettingsState.loaded(
      SettingsEntity(
        userId: 'guest',
        isDarkMode: ThemeService.instance.currentDarkMode,
        notificationsEnabled: false,
        videoAutoplay: false,
        languageCode: 'ar',
      ),
    ));
  }

  /// Toggle dark mode
  Future<void> toggleDarkMode(bool value) async {
    AppLogger.i('[SettingsCubit] Toggle dark mode: $value');

    // Update ThemeService immediately for instant UI update
    ThemeService.instance.setDarkMode(value);

    // Update local state optimistic
    final currentSettings =
        state.settings ?? const SettingsEntity(userId: 'guest');
    emit(state.copyWith(settings: currentSettings.copyWith(isDarkMode: value)));

    if (_currentUserId == null) return;

    emit(state.copyWith(isSaving: true));

    final result = await repository.updateSettings(
      userId: _currentUserId!,
      isDarkMode: value,
    );

    result.fold(
      (failure) {
        AppLogger.e('[SettingsCubit] Failed: ${failure.message}');
        emit(state.copyWith(isSaving: false));
      },
      (settings) {
        AppLogger.success('[SettingsCubit] Dark mode updated');
        emit(state.copyWith(settings: settings, isSaving: false));
      },
    );
  }

  /// Toggle notifications
  Future<void> toggleNotifications(bool value) async {
    if (_currentUserId == null) return;

    AppLogger.i('[SettingsCubit] Toggle notifications: $value');
    emit(state.copyWith(isSaving: true));

    final result = await repository.updateSettings(
      userId: _currentUserId!,
      notificationsEnabled: value,
    );

    result.fold(
      (failure) {
        AppLogger.e('[SettingsCubit] Failed: ${failure.message}');
        emit(state.copyWith(isSaving: false));
      },
      (settings) {
        AppLogger.success('[SettingsCubit] Notifications updated');
        emit(state.copyWith(settings: settings, isSaving: false));
      },
    );
  }

  /// Toggle video autoplay
  Future<void> toggleVideoAutoplay(bool value) async {
    if (_currentUserId == null) return;

    AppLogger.i('[SettingsCubit] Toggle video autoplay: $value');
    emit(state.copyWith(isSaving: true));

    final result = await repository.updateSettings(
      userId: _currentUserId!,
      videoAutoplay: value,
    );

    result.fold(
      (failure) {
        AppLogger.e('[SettingsCubit] Failed: ${failure.message}');
        emit(state.copyWith(isSaving: false));
      },
      (settings) {
        AppLogger.success('[SettingsCubit] Video autoplay updated');
        emit(state.copyWith(settings: settings, isSaving: false));
      },
    );
  }

  Future<void> updateLanguage(String languageCode) async {
    AppLogger.i('[SettingsCubit] Update language: $languageCode');

    // Update local state optimistic
    final currentSettings =
        state.settings ?? const SettingsEntity(userId: 'guest');
    emit(state.copyWith(
        settings: currentSettings.copyWith(languageCode: languageCode)));

    if (_currentUserId == null) return;

    emit(state.copyWith(isSaving: true));

    final result = await repository.updateSettings(
      userId: _currentUserId!,
      languageCode: languageCode,
    );

    result.fold(
      (failure) {
        AppLogger.e('[SettingsCubit] Failed: ${failure.message}');
        emit(state.copyWith(isSaving: false));
      },
      (settings) {
        AppLogger.success('[SettingsCubit] Language updated');
        emit(state.copyWith(settings: settings, isSaving: false));
      },
    );
  }

  /// Logout
  Future<bool> logout() async {
    AppLogger.i('[SettingsCubit] Logging out');

    final result = await repository.logout();

    return result.fold(
      (failure) {
        AppLogger.e('[SettingsCubit] Logout failed: ${failure.message}');
        return false;
      },
      (success) {
        AppLogger.success('[SettingsCubit] Logged out');
        _currentUserId = null;
        // Clear user role cache
        UserRoleService.clearCache();
        emit(SettingsState.initial());
        return success;
      },
    );
  }

  /// Delete account
  Future<bool> deleteAccount() async {
    if (_currentUserId == null) return false;

    AppLogger.i('[SettingsCubit] Deleting account');

    final result = await repository.deleteAccount(userId: _currentUserId!);

    return result.fold(
      (failure) {
        AppLogger.e('[SettingsCubit] Delete failed: ${failure.message}');
        return false;
      },
      (success) {
        AppLogger.success('[SettingsCubit] Account deleted');
        _currentUserId = null;
        emit(SettingsState.initial());
        return success;
      },
    );
  }
}
