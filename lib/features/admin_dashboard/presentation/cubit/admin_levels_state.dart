part of 'admin_levels_cubit.dart';

enum AdminLevelsStatus { initial, loading, success, error }

class AdminLevelsState extends Equatable {
  final AdminLevelsStatus status;
  final List<LevelModel> activeLevels;
  final List<LevelModel> inactiveLevels;
  final bool? isActiveFilter;
  final String? errorMessage;

  const AdminLevelsState({
    this.status = AdminLevelsStatus.initial,
    this.activeLevels = const [],
    this.inactiveLevels = const [],
    this.isActiveFilter,
    this.errorMessage,
  });

  bool get isLoading => status == AdminLevelsStatus.loading;
  bool get hasError => status == AdminLevelsStatus.error;

  AdminLevelsState copyWith({
    AdminLevelsStatus? status,
    List<LevelModel>? activeLevels,
    List<LevelModel>? inactiveLevels,
    bool? isActiveFilter,
    String? errorMessage,
  }) {
    return AdminLevelsState(
      status: status ?? this.status,
      activeLevels: activeLevels ?? this.activeLevels,
      inactiveLevels: inactiveLevels ?? this.inactiveLevels,
      isActiveFilter: isActiveFilter ?? this.isActiveFilter,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        activeLevels,
        inactiveLevels,
        isActiveFilter,
        errorMessage,
      ];
}
