import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/animations/animations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/shared_widgets/empty_state.dart';
import '../../../../core/shared_widgets/error_state.dart';
import '../../../../core/shared_widgets/loading_skeleton.dart';
import '../../domain/entities/notification_entity.dart';
import '../cubit/notifications_cubit.dart';
import '../cubit/notifications_state.dart';

/// Notifications Screen
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<NotificationsCubit>().loadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = context.locale.languageCode == 'ar';

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, isDark, isArabic),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () =>
                    context.read<NotificationsCubit>().refreshNotifications(),
                child: BlocBuilder<NotificationsCubit, NotificationsState>(
                  builder: (context, state) {
                    if (state is NotificationsLoading) {
                      return _buildLoadingState();
                    }

                    if (state is NotificationsError) {
                      return ErrorState(
                        type: ErrorType.generic,
                        message: state.message,
                        onRetry: () => context
                            .read<NotificationsCubit>()
                            .loadNotifications(),
                      );
                    }

                    if (state is NotificationsLoaded) {
                      if (state.notifications.isEmpty) {
                        return const EmptyState(
                            type: EmptyStateType.notifications);
                      }
                      return _buildNotificationsList(
                          state.notifications, isDark, isArabic);
                    }

                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, bool isArabic) {
    final screenWidth = MediaQuery.of(context).size.width;
    final iconSize = (screenWidth * 0.06).clamp(22.0, 26.0);

    return Container(
      color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04,
        vertical: screenWidth * 0.025,
      ),
      child: Row(
        children: [
          // Back Button
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : AppColors.grey100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: iconSize * 0.8,
                color: isDark ? AppColors.grey400 : AppColors.grey600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Title
          Expanded(
            child: Text(
              'notifications.notifications'.tr(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.white : AppColors.textMainLight,
              ),
            ),
          ),
          // Mark all as read button
          BlocBuilder<NotificationsCubit, NotificationsState>(
            builder: (context, state) {
              if (state is NotificationsLoaded && state.unreadCount > 0) {
                return Tooltip(
                  message: 'notifications.mark_all_read'.tr(),
                  child: IconButton.filledTonal(
                    visualDensity: VisualDensity.compact,
                    style: IconButton.styleFrom(
                      backgroundColor:
                          AppColors.primary.withValues(alpha: 0.12),
                      foregroundColor: AppColors.primary,
                    ),
                    onPressed: () {
                      context.read<NotificationsCubit>().markAllAsRead();
                    },
                    icon: const Icon(
                      Icons.done_all_rounded,
                      size: 20,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) => const Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: LoadingSkeleton.listItem(),
      ),
    );
  }

  Widget _buildNotificationsList(
      List<NotificationEntity> notifications, bool isDark, bool isArabic) {
    // Group by date
    final grouped = _groupByDate(notifications);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        final group = grouped[index];
        return SlideFadeIn.fromBottom(
          delay: Duration(milliseconds: 100 * index),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date header
              Padding(
                padding: EdgeInsets.only(bottom: 12, top: index > 0 ? 16 : 0),
                child: Text(
                  group.dateLabel,
                  style: TextStyle(
                    fontFamily: 'Almarai',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.grey400 : AppColors.grey500,
                  ),
                ),
              ),
              // Notifications
              ...group.notifications.asMap().entries.map((entry) {
                final notifIndex = entry.key;
                final notification = entry.value;
                return SlideFadeIn.fromBottom(
                  delay: Duration(milliseconds: 50 * notifIndex),
                  child: _buildNotificationCard(notification, isDark, isArabic),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNotificationCard(
      NotificationEntity notification, bool isDark, bool isArabic) {
    final languageCode = isArabic ? 'ar' : 'en';
    final title = notification.getTitle(languageCode);
    final body = notification.getBody(languageCode);

    return SwipeToDelete(
      key: Key(notification.id),
      dismissKey: ValueKey('dismiss-${notification.id}'),
      onDelete: () {
        context.read<NotificationsCubit>().deleteNotification(notification.id);
      },
      child: GestureDetector(
        onTap: () {
          context.read<NotificationsCubit>().markAsRead(notification.id);
          _handleNotificationTap(notification);
        },
        child: AnimatedCard(
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: notification.isRead
                  ? (isDark ? AppColors.surfaceDark : AppColors.surfaceLight)
                  : (isDark
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : AppColors.primaryLight.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _getTypeColor(notification.type)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: BounceIcon(
                    icon: _getTypeIcon(notification.type),
                    color: _getTypeColor(notification.type),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontFamily: 'Almarai',
                                fontSize: 15,
                                fontWeight: notification.isRead
                                    ? FontWeight.w500
                                    : FontWeight.w700,
                                color: isDark
                                    ? AppColors.white
                                    : AppColors.textMainLight,
                              ),
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      if (body != null && body.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          body,
                          style: TextStyle(
                            fontFamily: 'Almarai',
                            fontSize: 13,
                            color: isDark
                                ? AppColors.textMutedDark
                                : AppColors.textMutedLight,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        _formatTime(notification.createdAt, isArabic),
                        style: TextStyle(
                          fontFamily: 'Almarai',
                          fontSize: 11,
                          color: isDark ? AppColors.grey500 : AppColors.grey400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleNotificationTap(NotificationEntity notification) {
    final actionType = notification.actionType;
    final actionValue = notification.actionValue;

    if (actionType == null || actionValue == null) return;

    switch (actionType) {
      case 'course':
        context.push('/course/$actionValue');
        break;
      case 'lesson':
        // Navigate to lesson - need course context
        break;
      case 'certificate':
        context.push('/certificates/$actionValue');
        break;
      case 'quiz':
        // Navigate to quiz
        break;
      case 'url':
        // Open external URL
        break;
      case 'screen':
        context.push('/$actionValue');
        break;
    }
  }

  IconData _getTypeIcon(NotificationType type) {
    switch (type) {
      case NotificationType.instructorMessage:
        return Icons.message_rounded;
      case NotificationType.courseUpdate:
      case NotificationType.newLesson:
        return Icons.school_rounded;
      case NotificationType.quizResult:
        return Icons.quiz_rounded;
      case NotificationType.certificateIssued:
        return Icons.workspace_premium_rounded;
      case NotificationType.enrollmentConfirmed:
        return Icons.check_circle_rounded;
      case NotificationType.paymentConfirmed:
        return Icons.payment_rounded;
      case NotificationType.courseCompleted:
        return Icons.emoji_events_rounded;
      case NotificationType.announcement:
        return Icons.campaign_rounded;
      case NotificationType.promotion:
        return Icons.local_offer_rounded;
      case NotificationType.reminder:
        return Icons.notifications_active_rounded;
      case NotificationType.system:
        return Icons.info_outline_rounded;
    }
  }

  Color _getTypeColor(NotificationType type) {
    switch (type) {
      case NotificationType.instructorMessage:
        return AppColors.primary;
      case NotificationType.courseUpdate:
      case NotificationType.newLesson:
        return AppColors.info;
      case NotificationType.quizResult:
        return AppColors.warning;
      case NotificationType.certificateIssued:
      case NotificationType.courseCompleted:
        return const Color(0xFFFFD700); // Gold
      case NotificationType.enrollmentConfirmed:
      case NotificationType.paymentConfirmed:
        return AppColors.success;
      case NotificationType.announcement:
        return AppColors.primary;
      case NotificationType.promotion:
        return AppColors.error;
      case NotificationType.reminder:
        return AppColors.warning;
      case NotificationType.system:
        return AppColors.grey500;
    }
  }

  String _formatTime(DateTime dateTime, bool isArabic) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) {
      return isArabic ? 'الآن' : 'Just now';
    } else if (diff.inMinutes < 60) {
      return isArabic
          ? 'منذ ${diff.inMinutes} دقيقة'
          : '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return isArabic ? 'منذ ${diff.inHours} ساعة' : '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return isArabic ? 'منذ ${diff.inDays} يوم' : '${diff.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  List<_NotificationGroup> _groupByDate(
      List<NotificationEntity> notifications) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final Map<String, List<NotificationEntity>> groups = {};

    for (final n in notifications) {
      final date =
          DateTime(n.createdAt.year, n.createdAt.month, n.createdAt.day);
      String label;

      if (date == today) {
        label = 'common.today'.tr();
      } else if (date == yesterday) {
        label = 'common.yesterday'.tr();
      } else {
        label = '${date.day}/${date.month}/${date.year}';
      }

      groups.putIfAbsent(label, () => []).add(n);
    }

    return groups.entries
        .map(
            (e) => _NotificationGroup(dateLabel: e.key, notifications: e.value))
        .toList();
  }
}

class _NotificationGroup {
  final String dateLabel;
  final List<NotificationEntity> notifications;

  _NotificationGroup({required this.dateLabel, required this.notifications});
}
