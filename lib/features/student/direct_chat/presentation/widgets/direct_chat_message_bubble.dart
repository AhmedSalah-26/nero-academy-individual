import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/core/services/user_role_service.dart';
import 'package:lms_platform/features/student/direct_chat/domain/entities/direct_message_entity.dart';

/// Message bubble widget for direct chat.
class DirectChatMessageBubble extends StatelessWidget {
  final DirectMessage message;
  final bool isMe;
  final bool isDark;
  final VoidCallback onReply;
  final ValueChanged<String>? onReplyTap;
  final VoidCallback onDelete;
  final void Function(String emoji) onReaction;
  final DirectMessage? repliedMessage;

  const DirectChatMessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.isDark,
    required this.onReply,
    this.onReplyTap,
    required this.onDelete,
    required this.onReaction,
    this.repliedMessage,
  });

  @override
  Widget build(BuildContext context) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final bubbleColor = isMe
        ? AppColors.primary.withValues(alpha: isDark ? 0.24 : 0.04)
        : (isDark ? AppColors.cardDark : AppColors.white);
    final borderColor = isMe
        ? AppColors.primary.withValues(alpha: 0.3)
        : (isDark ? AppColors.borderDark : AppColors.borderLight);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: GestureDetector(
          onTap: () => _showReactionPickerSheet(context),
          behavior: HitTestBehavior.opaque,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.78,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isMe ? 16 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 16),
              ),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      message.senderName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                if (repliedMessage != null) _buildRepliedMessage(),
                Text(
                  message.messageText ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? AppColors.textMainDark
                        : AppColors.textMainLight,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (message.groupedReactions.isNotEmpty)
                      _buildReactions(currentUserId),
                    if (message.groupedReactions.isNotEmpty)
                      const SizedBox(width: 6),
                    Text(
                      _formatTime(message.createdAt),
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark
                            ? AppColors.textMutedDark
                            : AppColors.textMutedLight,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 4),
                      Icon(
                        message.isRead ? Icons.done_all : Icons.done,
                        size: 14,
                        color: message.isRead
                            ? AppColors.primary
                            : (isDark
                                ? AppColors.textMutedDark
                                : AppColors.textMutedLight),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRepliedMessage() {
    return GestureDetector(
      onTap: () {
        if (repliedMessage != null && onReplyTap != null) {
          onReplyTap!(repliedMessage!.id);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: const Border(
            left: BorderSide(color: AppColors.primary, width: 3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              repliedMessage!.senderName,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            Text(
              repliedMessage!.messageText ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color:
                    isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReactions(String? currentUserId) {
    return Wrap(
      spacing: 4,
      children: message.groupedReactions.entries.map((entry) {
        final hasReacted = message.reactions
            .any((r) => r.reaction == entry.key && r.userId == currentUserId);
        return GestureDetector(
          onTap: () => onReaction(entry.key),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: hasReacted
                  ? AppColors.primary.withValues(alpha: 0.2)
                  : (isDark ? AppColors.surfaceDark : AppColors.grey100),
              borderRadius: BorderRadius.circular(10),
              border: hasReacted
                  ? Border.all(color: AppColors.primary.withValues(alpha: 0.4))
                  : null,
            ),
            child: Text(
              '${entry.key} ${entry.value}',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        );
      }).toList(),
    );
  }

  String _formatTime(DateTime date) {
    final h = date.hour.toString().padLeft(2, '0');
    final m = date.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  void _showReactionPickerSheet(BuildContext context) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final userReaction = message.reactions
        .where((r) => r.userId == currentUserId)
        .firstOrNull
        ?.reaction;
    const emojis = ['👍', '❤️', '😂', '😮', '😢', '🔥'];

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.cardDark : AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: emojis.map((emoji) {
                    final isSelected = userReaction == emoji;
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);
                        onReaction(emoji);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: 0.2)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child:
                            Text(emoji, style: const TextStyle(fontSize: 24)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.reply),
                  title: const Text('Reply'),
                  onTap: () {
                    Navigator.pop(ctx);
                    onReply();
                  },
                ),
                if (isMe || UserRoleService.getCachedRole() == 'admin')
                  ListTile(
                    leading: const Icon(Icons.delete_outline,
                        color: AppColors.error),
                    title: const Text('Delete',
                        style: TextStyle(color: AppColors.error)),
                    onTap: () {
                      Navigator.pop(ctx);
                      onDelete();
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
