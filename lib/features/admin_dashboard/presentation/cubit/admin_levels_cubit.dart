import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/app_logger.dart';
import '../../data/datasources/admin_levels_data_source.dart';
import '../../data/models/level_model.dart';
import '../../domain/entities/level_entity.dart';

part 'admin_levels_state.dart';

/// Admin Levels Cubit
class AdminLevelsCubit extends Cubit<AdminLevelsState> {
  final AdminLevelsDataSource _dataSource;
  static const _tag = 'AdminLevelsCubit';

  AdminLevelsCubit(this._dataSource) : super(const AdminLevelsState());

  /// Load levels
  Future<void> loadLevels({bool? isActive, bool refresh = false}) async {
    AppLogger.i('[$_tag] loadLevels: isActive=$isActive, refresh=$refresh');

    if (refresh || state.status == AdminLevelsStatus.initial) {
      emit(state.copyWith(status: AdminLevelsStatus.loading));
    }

    try {
      final levels = await _dataSource.getLevels(isActive: isActive);

      final activeLevels = levels.where((l) => l.isActive).toList();
      final inactiveLevels = levels.where((l) => !l.isActive).toList();

      emit(state.copyWith(
        status: AdminLevelsStatus.success,
        activeLevels: activeLevels,
        inactiveLevels: inactiveLevels,
        isActiveFilter: isActive,
      ));

      AppLogger.success('[$_tag] loadLevels: ${levels.length} levels loaded');
    } catch (e, s) {
      AppLogger.e('[$_tag] loadLevels error', e, s);
      emit(state.copyWith(
        status: AdminLevelsStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Create level
  Future<bool> createLevel(LevelCreateDto dto) async {
    AppLogger.i('[$_tag] createLevel: ${dto.nameAr}');

    try {
      await _dataSource.createLevel(dto);
      await loadLevels(isActive: state.isActiveFilter, refresh: true);
      AppLogger.success('[$_tag] createLevel: Success');
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] createLevel error', e, s);
      emit(state.copyWith(errorMessage: e.toString()));
      return false;
    }
  }

  /// Update level
  Future<bool> updateLevel(String id, LevelUpdateDto dto) async {
    AppLogger.i('[$_tag] updateLevel: $id');

    try {
      await _dataSource.updateLevel(id, dto);
      await loadLevels(isActive: state.isActiveFilter, refresh: true);
      AppLogger.success('[$_tag] updateLevel: Success');
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] updateLevel error', e, s);
      emit(state.copyWith(errorMessage: e.toString()));
      return false;
    }
  }

  /// Toggle level status
  Future<void> toggleLevelStatus(String id) async {
    AppLogger.i('[$_tag] toggleLevelStatus: $id');

    try {
      await _dataSource.toggleLevelStatus(id);
      await loadLevels(isActive: state.isActiveFilter, refresh: true);
      AppLogger.success('[$_tag] toggleLevelStatus: Success');
    } catch (e, s) {
      AppLogger.e('[$_tag] toggleLevelStatus error', e, s);
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  /// Delete level
  Future<bool> deleteLevel(String id) async {
    AppLogger.i('[$_tag] deleteLevel: $id');

    try {
      await _dataSource.deleteLevel(id);
      await loadLevels(isActive: state.isActiveFilter, refresh: true);
      AppLogger.success('[$_tag] deleteLevel: Success');
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] deleteLevel error', e, s);
      emit(state.copyWith(errorMessage: e.toString()));
      return false;
    }
  }

  /// Change active filter
  void changeActiveFilter(bool? isActive) {
    if (isActive != state.isActiveFilter) {
      loadLevels(isActive: isActive, refresh: true);
    }
  }
}
