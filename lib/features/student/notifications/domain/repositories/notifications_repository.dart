import 'package:lms_platform/features/student/notifications/domain/entities/notification_entity.dart';

/// Notifications Repository Interface
abstract class NotificationsRepository {
  /// Get all notifications for current user
  Future<List<NotificationEntity>> getNotifications({
    int page = 1,
    int limit = 20,
    bool? unreadOnly,
  });

  /// Get unread notifications count
  Future<int> getUnreadCount();

  /// Mark notification as read
  Future<bool> markAsRead(String notificationId);

  /// Mark all notifications as read
  Future<int> markAllAsRead();

  /// Delete notification
  Future<bool> deleteNotification(String notificationId);

  /// Delete all notifications
  Future<bool> deleteAllNotifications();
}
