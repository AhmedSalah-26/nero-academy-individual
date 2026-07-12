import 'package:lms_platform/features/student/notifications/domain/entities/notification_entity.dart';
import 'package:lms_platform/features/student/notifications/domain/repositories/notifications_repository.dart';
import 'package:lms_platform/features/student/notifications/data/datasources/notifications_remote_data_source.dart';

/// Notifications Repository Implementation
class NotificationsRepositoryImpl implements NotificationsRepository {
  final NotificationsRemoteDataSource _remoteDataSource;

  NotificationsRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<NotificationEntity>> getNotifications({
    int page = 1,
    int limit = 20,
    bool? unreadOnly,
  }) async {
    return await _remoteDataSource.getNotifications(
      page: page,
      limit: limit,
      unreadOnly: unreadOnly,
    );
  }

  @override
  Future<int> getUnreadCount() async {
    return await _remoteDataSource.getUnreadCount();
  }

  @override
  Future<bool> markAsRead(String notificationId) async {
    return await _remoteDataSource.markAsRead(notificationId);
  }

  @override
  Future<int> markAllAsRead() async {
    return await _remoteDataSource.markAllAsRead();
  }

  @override
  Future<bool> deleteNotification(String notificationId) async {
    return await _remoteDataSource.deleteNotification(notificationId);
  }

  @override
  Future<bool> deleteAllNotifications() async {
    return await _remoteDataSource.deleteAllNotifications();
  }
}
