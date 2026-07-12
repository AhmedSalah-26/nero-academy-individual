import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/core/shared_widgets/app_card.dart';
import 'package:lms_platform/core/services/user_role_service.dart';
import 'package:lms_platform/features/student/course_forum/domain/entities/forum_entities.dart';

/// Message Bubble Widget - Displays a single message in the chat
class MessageBubble extends StatelessWidget {
  final ConversationMessage message;
  final bool isMe;
  final bool isDark;
  final bool isArabic;
  final Function(String)? onReplyTap;
  final VoidCallback? onReply;
  final VoidCallback? onDelete;
  final Function(String)? onReaction;
  final ConversationMessage? repliedMessage;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.isDark,
    required this.isArabic,
    this.onReplyTap,
    this.onReply,
    this.onDelete,
    this.onReaction,
    this.repliedMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) _buildAvatar(),
          if (!isMe) const SizedBox(width: 8),
          Flexible(
            child: _buildMessageCard(context),
          ),
          if (isMe) const SizedBox(width: 8),
          if (isMe) _buildAvatar(),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return CircleAvatar(
      radius: 16,
      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
      backgroundImage:
          message.userAvatar != null ? NetworkImage(message.userAvatar!) : null,
      child: message.userAvatar == null
          ? Text(
              message.userName.isNotEmpty
                  ? message.userName[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            )
          : null,
    );
  }

  Widget _buildMessageCard(BuildContext context) {
    return AppCard(
      variant: AppCardVariant.filled,
      padding: EdgeInsets.zero,
      backgroundColor: isMe
          ? AppColors.primary.withValues(alpha: isDark ? 0.24 : 0.04)
          : (isDark ? AppColors.cardDark : AppColors.white),
      borderRadius: 16,
      enableGlow: false,
      onTap:
          onReaction != null ? () => _showReactionPickerSheet(context) : null,
      onLongPress: () => _showMessageOptions(context),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe) _buildSenderName(),
            if (repliedMessage != null) _buildRepliedMessage(),
            _buildMessageText(),
            _buildTimeAndReactions(),
          ],
        ),
      ),
    );
  }

  Widget _buildSenderName() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        message.userName,
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
          fontSize: 13,
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
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: const Border(
            left: BorderSide(
              color: AppColors.primary,
              width: 3,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              repliedMessage?.userName ?? 'Unknown',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              repliedMessage?.messageText ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color:
                    isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageText() {
    return Text(
      message.messageText ?? '',
      style: TextStyle(
        color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
        fontSize: 14,
        height: 1.4,
      ),
    );
  }

  Widget _buildTimeAndReactions() {
    final time = DateFormat('HH:mm').format(message.createdAt.toLocal());

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (message.reactions.isNotEmpty) ...[
            _buildReactionsPreview(),
            const SizedBox(width: 8),
          ],
          Text(
            time,
            style: TextStyle(
              color:
                  isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              fontSize: 11,
            ),
          ),
          if (message.isEdited) ...[
            const SizedBox(width: 4),
            Text(
              isArabic ? '(معدلة)' : '(edited)',
              style: TextStyle(
                color:
                    isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                fontSize: 10,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReactionsPreview() {
    final grouped = message.groupedReactions;
    return Wrap(
      spacing: 4,
      children: grouped.entries.map((entry) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.primary.withValues(alpha: 0.2)
                : AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${entry.key} ${entry.value}',
            style: const TextStyle(fontSize: 12),
          ),
        );
      }).toList(),
    );
  }

  void _showMessageOptions(BuildContext context) {
    final userReaction = _currentUserReaction();

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.cardDark : AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Reaction picker
                if (onReaction != null) _buildReactionPicker(ctx, userReaction),
                const SizedBox(height: 8),
                // Copy
                ListTile(
                  leading: const Icon(Icons.copy),
                  title: Text(isArabic ? 'نسخ' : 'Copy'),
                  onTap: () {
                    Clipboard.setData(
                        ClipboardData(text: message.messageText ?? ''));
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(isArabic ? 'تم النسخ' : 'Copied')),
                    );
                  },
                ),
                // Reply
                if (onReply != null)
                  ListTile(
                    leading: const Icon(Icons.reply),
                    title: Text(isArabic ? 'رد' : 'Reply'),
                    onTap: () {
                      Navigator.pop(ctx);
                      onReply!();
                    },
                  ),
                // Delete (only for own messages or admins)
                if ((isMe || UserRoleService.getCachedRole() == 'admin') &&
                    onDelete != null)
                  ListTile(
                    leading: const Icon(Icons.delete_outline,
                        color: AppColors.error),
                    title: Text(
                      isArabic ? 'حذف' : 'Delete',
                      style: const TextStyle(color: AppColors.error),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      onDelete!();
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showReactionPickerSheet(BuildContext context) {
    final userReaction = _currentUserReaction();

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.cardDark : AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: _buildReactionPicker(ctx, userReaction),
          ),
        );
      },
    );
  }

  String? _currentUserReaction() {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    return message.reactions
        .where((r) => r.userId == currentUserId)
        .firstOrNull
        ?.reaction;
  }

  Widget _buildReactionPicker(BuildContext ctx, String? userReaction) {
    final emojis = ['👍', '❤️', '😂', '😮', '😢', '🙏'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: emojis.map((emoji) {
          final isSelected = userReaction == emoji;
          return GestureDetector(
            onTap: () {
              Navigator.pop(ctx);
              onReaction!(emoji);
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(emoji, style: const TextStyle(fontSize: 24)),
            ),
          );
        }).toList(),
      ),
    );
  }
}
