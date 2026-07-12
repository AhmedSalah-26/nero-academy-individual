import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lms_platform/core/shared_widgets/empty_state.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/features/student/course_forum/presentation/widgets/forum_chat_widgets.dart';
import 'package:lms_platform/features/student/direct_chat/domain/entities/direct_message_entity.dart';
import 'direct_chat_message_bubble.dart';

/// Messages list with reply swipe behavior.
class DirectChatMessagesList extends StatelessWidget {
  final List<DirectMessage> messages;
  final bool isDark;
  final bool isArabic;
  final String? currentUserId;
  final ScrollController scrollController;
  final Map<String, GlobalKey> messageKeys;
  final ValueChanged<DirectMessage> onReplyMessage;
  final ValueChanged<String> onDeleteMessage;
  final void Function(String messageId, String emoji) onReaction;
  final ValueChanged<String> onReplyTap;

  const DirectChatMessagesList({
    super.key,
    required this.messages,
    required this.isDark,
    required this.isArabic,
    required this.currentUserId,
    required this.scrollController,
    required this.messageKeys,
    required this.onReplyMessage,
    required this.onDeleteMessage,
    required this.onReaction,
    required this.onReplyTap,
  });

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return Center(
        child: EmptyState(
          type: EmptyStateType.forum,
          compact: false,
          title: isArabic ? 'ابدأ المحادثة' : 'Start the conversation',
          message: isArabic
              ? 'أرسل أول رسالة لبدء المحادثة'
              : 'Send the first message to start chatting',
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isMe = message.senderId == currentUserId;
        final showDate = index == 0 ||
            !_isSameDay(messages[index - 1].createdAt, message.createdAt);

        return Column(
          children: [
            if (showDate)
              DateDivider(
                date: message.createdAt,
                isDark: isDark,
                isArabic: isArabic,
              ),
            _wrapWithSwipeReply(
              messageId: message.id,
              onReply: () {
                HapticFeedback.lightImpact();
                onReplyMessage(message);
              },
              child: DirectChatMessageBubble(
                key: messageKeys[message.id] ??= GlobalKey(),
                message: message,
                isMe: isMe,
                isDark: isDark,
                onReply: () => onReplyMessage(message),
                onReplyTap: onReplyTap,
                onDelete: () => onDeleteMessage(message.id),
                onReaction: (emoji) => onReaction(message.id, emoji),
                repliedMessage: _findRepliedMessage(message, messages),
              ),
            ),
          ],
        );
      },
    );
  }

  DirectMessage? _findRepliedMessage(
      DirectMessage message, List<DirectMessage> allMessages) {
    if (message.replyToMessageId == null) return null;
    try {
      return allMessages.firstWhere((m) => m.id == message.replyToMessageId);
    } catch (_) {
      return message.replyToMessage;
    }
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  Widget _buildReplySwipeBackground({required bool alignLeft}) {
    return Container(
      alignment: alignLeft ? Alignment.centerLeft : Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment:
            alignLeft ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          const Icon(Icons.reply, color: AppColors.primary, size: 20),
          const SizedBox(width: 6),
          Text(
            isArabic ? 'رد' : 'Reply',
            style: TextStyle(
              color:
                  isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _wrapWithSwipeReply({
    required String messageId,
    required VoidCallback onReply,
    required Widget child,
  }) {
    return Dismissible(
      key: ValueKey('direct-reply-$messageId'),
      direction: DismissDirection.horizontal,
      dismissThresholds: const {
        DismissDirection.startToEnd: 0.70,
        DismissDirection.endToStart: 0.70,
      },
      background: _buildReplySwipeBackground(alignLeft: true),
      secondaryBackground: _buildReplySwipeBackground(alignLeft: false),
      confirmDismiss: (_) async {
        onReply();
        return false;
      },
      child: child,
    );
  }
}
