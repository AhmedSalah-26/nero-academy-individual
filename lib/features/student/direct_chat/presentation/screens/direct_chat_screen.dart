import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lms_platform/core/shared_widgets/user_avatar.dart';
import 'package:lms_platform/core/shared_widgets/error_state.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/features/student/course_forum/presentation/widgets/forum_chat_widgets.dart';
import 'package:lms_platform/features/student/direct_chat/domain/entities/direct_message_entity.dart';
import 'package:lms_platform/features/student/direct_chat/presentation/cubit/direct_chat_cubit.dart';
import 'package:lms_platform/features/student/direct_chat/presentation/cubit/direct_chat_state.dart';
import 'package:lms_platform/features/student/direct_chat/presentation/widgets/direct_chat_messages_list.dart';
import 'package:lms_platform/features/student/direct_chat/presentation/widgets/direct_chat_reply_preview.dart';

/// Direct Chat Screen - 1-on-1 private messaging.
class DirectChatScreen extends StatelessWidget {
  final String otherUserId;
  final String otherUserName;
  final String? otherUserAvatar;

  const DirectChatScreen({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserAvatar,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DirectChatCubit(
        Supabase.instance.client,
        otherUserId,
      )..loadMessages(),
      child: _DirectChatView(
        otherUserName: otherUserName,
        otherUserAvatar: otherUserAvatar,
      ),
    );
  }
}

class _DirectChatView extends StatefulWidget {
  final String otherUserName;
  final String? otherUserAvatar;

  const _DirectChatView({
    required this.otherUserName,
    this.otherUserAvatar,
  });

  @override
  State<_DirectChatView> createState() => _DirectChatViewState();
}

class _DirectChatViewState extends State<_DirectChatView> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();
  final Map<String, GlobalKey> _messageKeys = {};
  DirectMessage? _replyToMessage;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = Supabase.instance.client.auth.currentUser?.id;
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = context.locale.languageCode == 'ar';

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            UserAvatar(
              imageUrl: widget.otherUserAvatar,
              name: widget.otherUserName,
              size: AvatarSize.sm,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUserName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.textMainDark
                          : AppColors.textMainLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    isArabic ? 'محادثة خاصة' : 'Private Chat',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.textMutedDark
                          : AppColors.textMutedLight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: BlocBuilder<DirectChatCubit, DirectChatState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const SizedBox.shrink();
          }

          if (state.isError) {
            return ErrorState(
              type: ErrorType.generic,
              message: state.errorMessage,
              onRetry: () => context.read<DirectChatCubit>().loadMessages(),
            );
          }

          return Column(
            children: [
              Expanded(
                child: DirectChatMessagesList(
                  messages: state.messages,
                  isDark: isDark,
                  isArabic: isArabic,
                  currentUserId: _currentUserId,
                  scrollController: _scrollController,
                  messageKeys: _messageKeys,
                  onReplyMessage: (message) {
                    setState(() => _replyToMessage = message);
                  },
                  onDeleteMessage: (messageId) {
                    context.read<DirectChatCubit>().deleteMessage(messageId);
                  },
                  onReaction: (messageId, emoji) {
                    context
                        .read<DirectChatCubit>()
                        .toggleReaction(messageId, emoji);
                  },
                  onReplyTap: _scrollToMessage,
                ),
              ),
              if (_replyToMessage != null)
                DirectChatReplyPreview(
                  message: _replyToMessage!,
                  isDark: isDark,
                  onCancel: () => setState(() => _replyToMessage = null),
                ),
              ForumChatInput(
                controller: _messageController,
                focusNode: _messageFocusNode,
                isDark: isDark,
                isArabic: isArabic,
                onSend: _sendMessage,
              ),
            ],
          );
        },
      ),
    );
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    context.read<DirectChatCubit>().sendMessage(
          text,
          replyToId: _replyToMessage?.id,
        );

    _messageController.clear();
    setState(() => _replyToMessage = null);

    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _scrollToMessage(String messageId) {
    final key = _messageKeys[messageId];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        alignment: 0.5,
      );
    }
  }
}
