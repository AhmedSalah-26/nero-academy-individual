import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/app_logger.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/notifications_repository.dart';
import 'notifications_state.dart';

/// Notifications Cubit
class NotificationsCubit extends Cubit<NotificationsState> {
  final NotificationsRepository _repository;
  static const _tag = 'NotificationsCubit';

  NotificationsCubit(this._repository) : super(const NotificationsInitial());

  List<NotificationEntity> _notifications = [];
  String? _loadedUserId;

  String? get _currentUserId => Supabase.instance.client.auth.currentUser?.id;

  Future<void> loadNotifications({bool refresh = false}) async {
    AppLogger.d('[$_tag] loadNotifications: refresh=$refresh');

    final currentUserId = _currentUserId;
    if (currentUserId == null) {
      _loadedUserId = null;
      _notifications = [];
      if (!isClosed) {
        emit(const NotificationsLoaded(notifications: [], unreadCount: 0));
      }
      return;
    }

    final userChanged = _loadedUserId != null && _loadedUserId != currentUserId;
    if (userChanged) {
      _notifications = [];
      if (!isClosed) emit(const NotificationsInitial());
    }

    if (!refresh && !userChanged && state is NotificationsLoaded) {
      return;
    }

    if (isClosed) return;
    emit(const NotificationsLoading());

    try {
      _notifications = await _repository.getNotifications();
      _loadedUserId = currentUserId;
      final unreadCount = _notifications.where((n) => !n.isRead).length;

      AppLogger.success(
          '[$_tag] Loaded ${_notifications.length} notifications, $unreadCount unread');

      if (isClosed) return;
      emit(NotificationsLoaded(
        notifications: _notifications,
        unreadCount: unreadCount,
      ));
    } catch (e, s) {
      AppLogger.e('[$_tag] loadNotifications error', e, s);
      if (isClosed) return;
      emit(NotificationsError(e.toString()));
    }
  }

  Future<void> refreshNotifications() async {
    await loadNotifications(refresh: true);
  }

  Future<void> markAsRead(String notificationId) async {
    AppLogger.d('[$_tag] markAsRead: $notificationId');

    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index == -1 || _notifications[index].isRead) return;

    // Optimistic update: mark as read locally first
    final previous = _notifications[index];
    _notifications[index] =
        _notifications[index].copyWith(isRead: true, readAt: DateTime.now());
    final unreadCount = _notifications.where((n) => !n.isRead).length;
    if (isClosed) return;
    emit(NotificationsLoaded(
      notifications: List.from(_notifications),
      unreadCount: unreadCount,
    ));

    try {
      await _repository.markAsRead(notificationId);
    } catch (e, s) {
      AppLogger.e('[$_tag] markAsRead error — rolling back', e, s);
      // Rollback if server call fails
      _notifications[index] = previous;
      if (isClosed) return;
      emit(NotificationsLoaded(
        notifications: List.from(_notifications),
        unreadCount: _notifications.where((n) => !n.isRead).length,
      ));
    }
  }

  Future<void> markAllAsRead() async {
    AppLogger.d('[$_tag] markAllAsRead');

    // Optimistic update: update UI immediately so button feels responsive
    final previousNotifications =
        List<NotificationEntity>.from(_notifications);
    _notifications = _notifications
        .map((n) => n.copyWith(isRead: true, readAt: DateTime.now()))
        .toList();
    if (isClosed) return;
    emit(NotificationsLoaded(
      notifications: List.from(_notifications),
      unreadCount: 0,
    ));

    try {
      await _repository.markAllAsRead();
    } catch (e, s) {
      AppLogger.e('[$_tag] markAllAsRead error — rolling back', e, s);
      // Rollback if server call fails
      _notifications = previousNotifications;
      if (isClosed) return;
      emit(NotificationsLoaded(
        notifications: List.from(_notifications),
        unreadCount: _notifications.where((n) => !n.isRead).length,
      ));
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    AppLogger.d('[$_tag] deleteNotification: $notificationId');

    final removedIndex =
        _notifications.indexWhere((n) => n.id == notificationId);
    if (removedIndex == -1) return;

    final removedNotification = _notifications[removedIndex];
    _notifications.removeAt(removedIndex);
    if (isClosed) return;
    emit(NotificationsLoaded(
      notifications: List.from(_notifications),
      unreadCount: _notifications.where((n) => !n.isRead).length,
    ));

    try {
      await _repository.deleteNotification(notificationId);
    } catch (e, s) {
      AppLogger.e('[$_tag] deleteNotification error', e, s);
      // Rollback item if remote delete fails.
      _notifications.insert(removedIndex, removedNotification);
      if (isClosed) return;
      emit(NotificationsLoaded(
        notifications: List.from(_notifications),
        unreadCount: _notifications.where((n) => !n.isRead).length,
      ));
    }
  }

  Future<void> deleteAllNotifications() async {
    AppLogger.d('[$_tag] deleteAllNotifications');

    try {
      await _repository.deleteAllNotifications();

      _notifications.clear();
      if (isClosed) return;
      emit(const NotificationsLoaded(
        notifications: [],
        unreadCount: 0,
      ));
    } catch (e, s) {
      AppLogger.e('[$_tag] deleteAllNotifications error', e, s);
    }
  }

  /// Get unread count without loading all notifications
  Future<int> getUnreadCount() async {
    try {
      return await _repository.getUnreadCount();
    } catch (e) {
      AppLogger.e('[$_tag] getUnreadCount error', e);
      return 0;
    }
  }

  /// Add notification locally (for real-time updates)
  void addNotification(NotificationEntity notification) {
    if (notification.userId != _currentUserId) return;
    _notifications.insert(0, notification);
    final unreadCount = _notifications.where((n) => !n.isRead).length;
    if (isClosed) return;
    emit(NotificationsLoaded(
      notifications: List.from(_notifications),
      unreadCount: unreadCount,
    ));
  }
}
