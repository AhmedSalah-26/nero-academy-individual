import 'package:equatable/equatable.dart';
import 'package:lms_platform/features/student/settings/domain/entities/settings_entity.dart';

/// Settings State
class SettingsState extends Equatable {
  final bool isLoading;
  final bool isError;
  final String? errorMessage;
  final SettingsEntity? settings;
  final bool isSaving;

  const SettingsState({
    this.isLoading = false,
    this.isError = false,
    this.errorMessage,
    this.settings,
    this.isSaving = false,
  });

  /// Initial state
  factory SettingsState.initial() => const SettingsState();

  /// Loading state
  factory SettingsState.loading() => const SettingsState(isLoading: true);

  /// Loaded state
  factory SettingsState.loaded(SettingsEntity settings) =>
      SettingsState(settings: settings);

  /// Error state
  factory SettingsState.error(String message) =>
      SettingsState(isError: true, errorMessage: message);

  /// Copy with
  SettingsState copyWith({
    bool? isLoading,
    bool? isError,
    String? errorMessage,
    SettingsEntity? settings,
    bool? isSaving,
  }) {
    return SettingsState(
      isLoading: isLoading ?? this.isLoading,
      isError: isError ?? this.isError,
      errorMessage: errorMessage ?? this.errorMessage,
      settings: settings ?? this.settings,
      isSaving: isSaving ?? this.isSaving,
    );
  }

  /// Getters
  bool get isDarkMode => settings?.isDarkMode ?? false;
  bool get notificationsEnabled => settings?.notificationsEnabled ?? true;
  bool get videoAutoplay => settings?.videoAutoplay ?? true;
  String get languageCode =>
      settings?.languageCode ?? 'ar'; // Default to Arabic to match app default

  @override
  List<Object?> get props => [
        isLoading,
        isError,
        errorMessage,
        settings,
        isSaving,
      ];
}
