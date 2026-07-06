import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/app_logger.dart';
import '../models/notification_model.dart';

/// Notifications Remote Data Source
class NotificationsRemoteDataSource {
  final SupabaseClient _client;
  static const _tag = 'NotificationsDS';

  NotificationsRemoteDataSource(this._client);

  String get _userId => _client.auth.currentUser!.id;

  Future<DateTime?> _getCurrentProfileCreatedAt() async {
    final response = await _client
        .from('profiles')
        .select('created_at')
        .eq('id', _userId)
        .maybeSingle();
    final createdAt = response?['created_at'];
    if (createdAt == null) return null;
    return DateTime.tryParse(createdAt.toString());
  }

  /// Get all notifications for current user
  Future<List<NotificationModel>> getNotifications({
    int page = 1,
    int limit = 20,
    bool? unreadOnly,
  }) async {
    AppLogger.d('[$_tag] getNotifications: page=$page, limit=$limit');
    try {
      final profileCreatedAt = await _getCurrentProfileCreatedAt();
      var query = _client.from('notifications').select().eq('user_id', _userId);
      if (profileCreatedAt != null) {
        query = query.gte(
          'created_at',
          profileCreatedAt.toUtc().toIso8601String(),
        );
      }

      if (unreadOnly == true) {
        query = query.eq('is_read', false);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range((page - 1) * limit, page * limit - 1);

      AppLogger.success(
          '[$_tag] getNotifications: ${(response as List).length} notifications');
      return response.map((e) => NotificationModel.fromJson(e)).toList();
    } catch (e, s) {
      AppLogger.e('[$_tag] getNotifications error', e, s);
      rethrow;
    }
  }

  /// Get unread notifications count
  Future<int> getUnreadCount() async {
    AppLogger.d('[$_tag] getUnreadCount');
    try {
      final profileCreatedAt = await _getCurrentProfileCreatedAt();
      var query = _client
          .from('notifications')
          .select('id')
          .eq('user_id', _userId)
          .eq('is_read', false);
      if (profileCreatedAt != null) {
        query = query.gte(
          'created_at',
          profileCreatedAt.toUtc().toIso8601String(),
        );
      }
      final response = await query;
      final count = (response as List).length;
      AppLogger.success('[$_tag] getUnreadCount: $count');
      return count;
    } catch (e, s) {
      AppLogger.e('[$_tag] getUnreadCount error', e, s);
      return 0;
    }
  }

  /// Mark notification as read
  Future<bool> markAsRead(String notificationId) async {
    AppLogger.d('[$_tag] markAsRead: $notificationId');
    try {
      await _client
          .from('notifications')
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', notificationId)
          .eq('user_id', _userId);

      AppLogger.success('[$_tag] markAsRead success');
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] markAsRead error', e, s);
      rethrow;
    }
  }

  /// Mark all notifications as read
  Future<int> markAllAsRead() async {
    AppLogger.d('[$_tag] markAllAsRead');
    try {
      final profileCreatedAt = await _getCurrentProfileCreatedAt();
      var query = _client.from('notifications').update({
        'is_read': true,
        'read_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('user_id', _userId).eq('is_read', false);
      if (profileCreatedAt != null) {
        query = query.gte(
          'created_at',
          profileCreatedAt.toUtc().toIso8601String(),
        );
      }
      await query;
      AppLogger.success('[$_tag] markAllAsRead success');
      return 0;
    } catch (e, s) {
      AppLogger.e('[$_tag] markAllAsRead error', e, s);
      rethrow;
    }
  }

  /// Delete notification
  Future<bool> deleteNotification(String notificationId) async {
    AppLogger.d('[$_tag] deleteNotification: $notificationId');
    try {
      await _client
          .from('notifications')
          .delete()
          .eq('id', notificationId)
          .eq('user_id', _userId);

      AppLogger.success('[$_tag] deleteNotification success');
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] deleteNotification error', e, s);
      rethrow;
    }
  }

  /// Delete all notifications
  Future<bool> deleteAllNotifications() async {
    AppLogger.d('[$_tag] deleteAllNotifications');
    try {
      await _client.from('notifications').delete().eq('user_id', _userId);

      AppLogger.success('[$_tag] deleteAllNotifications success');
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] deleteAllNotifications error', e, s);
      rethrow;
    }
  }

  /// Subscribe to real-time notifications
  RealtimeChannel subscribeToNotifications(
    void Function(NotificationModel notification) onNewNotification,
  ) {
    AppLogger.d('[$_tag] subscribeToNotifications');
    return _client
        .channel('notifications:$_userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: _userId,
          ),
          callback: (payload) {
            AppLogger.d(
                '[$_tag] New notification received: ${payload.newRecord}');
            try {
              final notification =
                  NotificationModel.fromJson(payload.newRecord);
              onNewNotification(notification);
            } catch (e) {
              AppLogger.e('[$_tag] Failed to parse notification', e);
            }
          },
        )
        .subscribe();
  }
}
