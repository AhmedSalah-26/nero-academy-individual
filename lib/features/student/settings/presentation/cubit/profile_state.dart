import 'package:equatable/equatable.dart';
import 'package:lms_platform/features/student/settings/domain/entities/user_profile_entity.dart';

/// Profile State
class ProfileState extends Equatable {
  final bool isLoading;
  final bool isError;
  final String? errorMessage;
  final UserProfileEntity? profile;
  final bool isSaving;

  const ProfileState({
    this.isLoading = false,
    this.isError = false,
    this.errorMessage,
    this.profile,
    this.isSaving = false,
  });

  /// Initial state
  factory ProfileState.initial() => const ProfileState();

  /// Loading state
  factory ProfileState.loading() => const ProfileState(isLoading: true);

  /// Loaded state
  factory ProfileState.loaded(UserProfileEntity profile) =>
      ProfileState(profile: profile);

  /// Error state
  factory ProfileState.error(String message) =>
      ProfileState(isError: true, errorMessage: message);

  /// Copy with
  ProfileState copyWith({
    bool? isLoading,
    bool? isError,
    String? errorMessage,
    UserProfileEntity? profile,
    bool? isSaving,
  }) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      isError: isError ?? this.isError,
      errorMessage: errorMessage ?? this.errorMessage,
      profile: profile ?? this.profile,
      isSaving: isSaving ?? this.isSaving,
    );
  }

  /// Getters
  String get userName => profile?.name ?? '';
  String get userEmail => profile?.email ?? '';
  String? get userAvatar => profile?.avatarUrl;
  int get coursesCount => profile?.coursesCount ?? 0;
  String get formattedWatchTime => profile?.formattedWatchTime ?? '0m';
  int get dayStreak => profile?.dayStreak ?? 0;
  List<AchievementEntity> get achievements => profile?.achievements ?? [];

  @override
  List<Object?> get props => [
        isLoading,
        isError,
        errorMessage,
        profile,
        isSaving,
      ];
}
