import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/app_logger.dart';
import '../../domain/entities/level_entity.dart';
import '../models/level_model.dart';

/// Admin Levels Data Source
class AdminLevelsDataSource {
  final SupabaseClient _client;
  static const _tag = 'AdminLevelsDS';

  AdminLevelsDataSource(this._client);

  /// Get all levels
  Future<List<LevelModel>> getLevels({bool? isActive}) async {
    AppLogger.d('[$_tag] getLevels: isActive=$isActive');

    try {
      var query = _client.from('levels').select();

      if (isActive != null) {
        query = query.eq('is_active', isActive);
      }

      final response = await query.order('display_order');
      AppLogger.success(
          '[$_tag] getLevels: ${(response as List).length} levels');

      return (response).map((json) => LevelModel.fromJson(json)).toList();
    } catch (e, s) {
      AppLogger.e('[$_tag] getLevels error', e, s);
      rethrow;
    }
  }

  /// Create level
  Future<LevelModel> createLevel(LevelCreateDto dto) async {
    AppLogger.i('[$_tag] createLevel: ${dto.nameAr}');

    try {
      final response =
          await _client.from('levels').insert(dto.toJson()).select().single();

      AppLogger.success('[$_tag] createLevel: Level created');
      return LevelModel.fromJson(response);
    } catch (e, s) {
      AppLogger.e('[$_tag] createLevel error', e, s);
      rethrow;
    }
  }

  /// Update level
  Future<LevelModel> updateLevel(String id, LevelUpdateDto dto) async {
    AppLogger.i('[$_tag] updateLevel: $id');

    try {
      final updates = dto.toJson();
      updates['updated_at'] = DateTime.now().toIso8601String();

      final response = await _client
          .from('levels')
          .update(updates)
          .eq('id', id)
          .select()
          .single();

      AppLogger.success('[$_tag] updateLevel: Level updated');
      return LevelModel.fromJson(response);
    } catch (e, s) {
      AppLogger.e('[$_tag] updateLevel error', e, s);
      rethrow;
    }
  }

  /// Toggle level status
  Future<void> toggleLevelStatus(String id) async {
    AppLogger.i('[$_tag] toggleLevelStatus: $id');

    try {
      // Get current status
      final current = await _client
          .from('levels')
          .select('is_active')
          .eq('id', id)
          .single();

      final newStatus = !(current['is_active'] as bool);

      await _client.from('levels').update({
        'is_active': newStatus,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', id);

      AppLogger.success('[$_tag] toggleLevelStatus: Status toggled');
    } catch (e, s) {
      AppLogger.e('[$_tag] toggleLevelStatus error', e, s);
      rethrow;
    }
  }

  /// Delete level
  Future<void> deleteLevel(String id) async {
    AppLogger.i('[$_tag] deleteLevel: $id');

    try {
      await _client.from('levels').delete().eq('id', id);
      AppLogger.success('[$_tag] deleteLevel: Level deleted');
    } catch (e, s) {
      AppLogger.e('[$_tag] deleteLevel error', e, s);
      rethrow;
    }
  }
}
