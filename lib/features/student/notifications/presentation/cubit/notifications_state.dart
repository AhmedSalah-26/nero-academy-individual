import 'package:lms_platform/features/student/notifications/domain/entities/notification_entity.dart';

/// Notifications State
abstract class NotificationsState {
  const NotificationsState();
}

class NotificationsInitial extends NotificationsState {
  const NotificationsInitial();
}

class NotificationsLoading extends NotificationsState {
  const NotificationsLoading();
}

class NotificationsLoaded extends NotificationsState {
  final List<NotificationEntity> notifications;
  final int unreadCount;

  const NotificationsLoaded({
    required this.notifications,
    required this.unreadCount,
  });
}

class NotificationsError extends NotificationsState {
  final String message;

  const NotificationsError(this.message);
}
