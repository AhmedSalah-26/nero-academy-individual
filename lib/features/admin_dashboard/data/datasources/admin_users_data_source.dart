import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/app_logger.dart';
import '../../domain/entities/admin_entities.dart';
import '../models/admin_models.dart';

/// Admin Users Data Source - User management
class AdminUsersDataSource {
  final SupabaseClient _client;
  static const _tag = 'AdminUsersDS';

  AdminUsersDataSource(this._client);

  /// Get users by role
  Future<List<AdminUserModel>> getUsers({
    required UserRole role,
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    AppLogger.d('[$_tag] getUsers: role=$role, search=$search, page=$page');
    try {
      var query = _client.from('profiles').select('''
            id, email, name, phone, role, avatar_url, interests,
            headline_ar, headline_en, bio_ar, bio_en, expertise, social_links,
            is_verified_instructor,
            is_active, is_banned, banned_until, ban_reason, created_at, updated_at
          ''').eq('role', role.name);

      if (search != null && search.isNotEmpty) {
        query = query.or('name.ilike.%$search%,email.ilike.%$search%');
      }

      final response = await query
          .order('created_at', ascending: false)
          .range((page - 1) * limit, page * limit - 1);

      AppLogger.success('[$_tag] getUsers: ${response.length} users');
      return (response as List)
          .map((row) => AdminUserModel.fromJson(
                Map<String, dynamic>.from(row as Map),
              ))
          .toList();
    } catch (e, s) {
      AppLogger.e('[$_tag] getUsers error', e, s);
      rethrow;
    }
  }

  /// Ban user
  Future<bool> banUser(
      String userId, BanDuration duration, String reason) async {
    AppLogger.d('[$_tag] banUser: userId=$userId, duration=$duration');
    try {
      await _client.rpc('admin_ban_user', params: {
        'p_user_id': userId,
        'p_duration': duration.value,
        'p_reason': reason,
      });
      AppLogger.success('[$_tag] banUser success');
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] banUser error', e, s);
      rethrow;
    }
  }

  /// Unban user
  Future<bool> unbanUser(String userId) async {
    AppLogger.d('[$_tag] unbanUser: $userId');
    try {
      await _client.from('profiles').update({
        'is_banned': false,
        'banned_until': null,
        'ban_reason': null,
      }).eq('id', userId);
      AppLogger.success('[$_tag] unbanUser success');
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] getUsers error', e, s);
      rethrow;
    }
  }

  /// Update user
  Future<bool> updateUser(String userId, Map<String, dynamic> data) async {
    AppLogger.d('[$_tag] updateUser: userId=$userId');
    try {
      final now = DateTime.now().toIso8601String();
      data['updated_at'] = now;

      final profileFields = Map<String, dynamic>.from(data);
      final hasAvatar = profileFields.containsKey('avatar_url');
      final hasName = profileFields.containsKey('name');
      final hasBio = profileFields.containsKey('bio_ar');

      await _client.from('profiles').update(profileFields).eq('id', userId);

      if (hasAvatar || hasName || hasBio) {
        final roleRow = await _client
            .from('profiles')
            .select('role, name, avatar_url, bio_ar')
            .eq('id', userId)
            .maybeSingle();

        if (roleRow?['role'] == 'instructor') {
          await _client.from('teachers').upsert({
            'profile_id': userId,
            'display_name': roleRow?['name'] ?? 'Instructor',
            'avatar_url': roleRow?['avatar_url'],
            'bio': roleRow?['bio_ar'],
            'is_active': true,
            'updated_at': now,
          }, onConflict: 'profile_id');
        }
      }

      AppLogger.success('[$_tag] updateUser success');
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] updateUser error', e, s);
      rethrow;
    }
  }

  /// Delete user (soft delete / deactivate)
  Future<bool> deleteUser(String userId) async {
    AppLogger.d('[$_tag] deleteUser: $userId');
    try {
      await _client.rpc('admin_delete_user', params: {
        'p_user_id': userId,
      });
      AppLogger.success('[$_tag] deleteUser success');
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] deleteUser error', e, s);
      rethrow;
    }
  }

  /// Change user role
  Future<bool> changeUserRole(String userId, String newRole) async {
    AppLogger.d('[$_tag] changeUserRole: $userId -> $newRole');
    try {
      await _client.rpc('admin_change_user_role', params: {
        'p_user_id': userId,
        'p_new_role': newRole,
      });
      AppLogger.success('[$_tag] changeUserRole success');
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] changeUserRole error', e, s);
      rethrow;
    }
  }

  /// Send notification to a specific user
  Future<bool> sendNotification({
    required String userId,
    required String titleAr,
    String? titleEn,
    String? bodyAr,
    String? bodyEn,
    String type = 'system',
  }) async {
    AppLogger.d('[$_tag] sendNotification: userId=$userId');
    try {
      await _client.from('notifications').insert({
        'user_id': userId,
        'type': type,
        'title_ar': titleAr,
        'title_en': titleEn,
        'body_ar': bodyAr,
        'body_en': bodyEn,
        'sender_id': _client.auth.currentUser!.id,
      });
      AppLogger.success('[$_tag] sendNotification success');
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] sendNotification error', e, s);
      rethrow;
    }
  }

  /// Broadcast notification to all users of a specific role
  Future<int> broadcastNotification({
    required String role,
    required String titleAr,
    String? titleEn,
    String? bodyAr,
    String? bodyEn,
    String type = 'announcement',
  }) async {
    AppLogger.d('[$_tag] broadcastNotification: role=$role');
    try {
      // Get all users of the role
      final users = await _client
          .from('profiles')
          .select('id')
          .eq('role', role)
          .eq('is_active', true);

      final senderId = _client.auth.currentUser!.id;
      final notifications = (users as List)
          .map((u) => {
                'user_id': u['id'],
                'type': type,
                'title_ar': titleAr,
                'title_en': titleEn,
                'body_ar': bodyAr,
                'body_en': bodyEn,
                'sender_id': senderId,
              })
          .toList();

      if (notifications.isNotEmpty) {
        await _client.from('notifications').insert(notifications);
      }

      AppLogger.success(
          '[$_tag] broadcastNotification: sent to ${notifications.length} users');
      return notifications.length;
    } catch (e, s) {
      AppLogger.e('[$_tag] broadcastNotification error', e, s);
      rethrow;
    }
  }
}
