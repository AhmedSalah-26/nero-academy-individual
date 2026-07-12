import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/core/animations/animations.dart';
import 'package:lms_platform/core/shared_widgets/empty_state.dart';
import 'package:lms_platform/core/shared_widgets/error_state.dart';
import 'package:lms_platform/features/student/course_forum/domain/entities/forum_entities.dart';
import 'package:lms_platform/features/student/course_forum/presentation/cubit/forum_chat_cubit.dart';
import 'package:lms_platform/features/student/course_forum/presentation/cubit/forum_chat_state.dart';
import 'package:lms_platform/features/student/course_forum/presentation/widgets/message_bubble.dart';
import 'package:lms_platform/features/student/course_forum/presentation/widgets/forum_chat_widgets.dart';

/// Forum Chat Screen - Conversation chat interface
class ForumChatScreen extends StatelessWidget {
  final String conversationId;
  final String conversationTitle;

  const ForumChatScreen({
    super.key,
    required this.conversationId,
    required this.conversationTitle,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ForumChatCubit(
        Supabase.instance.client,
        conversationId,
      )..loadMessages(),
      child: _ForumChatView(
        conversationTitle: conversationTitle,
      ),
    );
  }
}

class _ForumChatView extends StatefulWidget {
  final String conversationTitle;

  const _ForumChatView({
    required this.conversationTitle,
  });

  @override
  State<_ForumChatView> createState() => _ForumChatViewState();
}

class _ForumChatViewState extends State<_ForumChatView> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();
  ConversationMessage? _replyToMessage;
  final Map<String, GlobalKey> _messageKeys = {};
  String? _currentUserId;
  bool _isSearching = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _currentUserId = Supabase.instance.client.auth.currentUser?.id;
  }

  @override
  void dispose() {
    _messageController.dispose();
    _searchController.dispose();
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
      appBar: ForumChatAppBar(
        courseTitle: widget.conversationTitle,
        isDark: isDark,
        isArabic: isArabic,
        isSearching: _isSearching,
        onSearchClose: _closeSearch,
        onSearchTap: () => setState(() => _isSearching = true),
      ),
      body: BlocBuilder<ForumChatCubit, ForumChatState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const SizedBox.shrink();
          }

          if (state.isError) {
            return _buildErrorState(isDark, isArabic, state.errorMessage);
          }

          return Column(
            children: [
              if (_isSearching)
                ForumSearchBar(
                  controller: _searchController,
                  isDark: isDark,
                  isArabic: isArabic,
                  onChanged: (value) => setState(() => _searchQuery = value),
                  onClose: _closeSearch,
                ),
              Expanded(
                child: _buildMessagesList(
                  _filterMessages(state.messages),
                  state.messages,
                  isDark,
                  isArabic,
                ),
              ),
              if (_replyToMessage != null && !_isSearching)
                ReplyPreview(
                  message: _replyToMessage!,
                  isDark: isDark,
                  isArabic: isArabic,
                  onCancel: () => setState(() => _replyToMessage = null),
                ),
              if (!_isSearching)
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

  Widget _buildErrorState(bool isDark, bool isArabic, String? errorMessage) {
    return ErrorState(
      type: ErrorType.generic,
      message: errorMessage,
      onRetry: () => context.read<ForumChatCubit>().loadMessages(),
    );
  }

  void _closeSearch() {
    setState(() {
      _isSearching = false;
      _searchQuery = '';
      _searchController.clear();
    });
  }

  List<ConversationMessage> _filterMessages(
      List<ConversationMessage> messages) {
    if (_searchQuery.isEmpty) return messages;
    return messages.where((m) {
      final text = m.messageText?.toLowerCase() ?? '';
      final name = m.userName.toLowerCase();
      final query = _searchQuery.toLowerCase();
      return text.contains(query) || name.contains(query);
    }).toList();
  }

  Widget _buildMessagesList(
    List<ConversationMessage> filteredMessages,
    List<ConversationMessage> allMessages,
    bool isDark,
    bool isArabic,
  ) {
    if (filteredMessages.isEmpty) {
      return const EmptyState(
        type: EmptyStateType.forum,
        compact: false,
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      itemCount: filteredMessages.length,
      itemBuilder: (context, index) {
        final message = filteredMessages[index];
        final isMe = message.userId == _currentUserId;
        final showDate = index == 0 ||
            !_isSameDay(
                filteredMessages[index - 1].createdAt, message.createdAt);

        return Column(
          children: [
            if (showDate)
              DateDivider(
                date: message.createdAt,
                isDark: isDark,
                isArabic: isArabic,
              ),
            SlideFadeIn.fromBottom(
              delay: Duration(milliseconds: 50 * index),
              child: _ReplySwipeWrapper(
                isDark: isDark,
                isArabic: isArabic,
                onReply: () {
                  HapticFeedback.lightImpact();
                  setState(() => _replyToMessage = message);
                },
                child: MessageBubble(
                  key: _messageKeys[message.id] ??= GlobalKey(),
                  message: message,
                  isMe: isMe,
                  isDark: isDark,
                  isArabic: isArabic,
                  onReplyTap: _scrollToMessage,
                  onReply: () => setState(() => _replyToMessage = message),
                  onDelete: () =>
                      context.read<ForumChatCubit>().deleteMessage(message.id),
                  onReaction: (emoji) => context
                      .read<ForumChatCubit>()
                      .toggleReaction(message.id, emoji),
                  repliedMessage: _findRepliedMessage(message, allMessages),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  ConversationMessage? _findRepliedMessage(
      ConversationMessage message, List<ConversationMessage> allMessages) {
    if (message.replyToMessageId == null) return null;
    try {
      return allMessages.firstWhere((m) => m.id == message.replyToMessageId);
    } catch (_) {
      return message.replyToMessage;
    }
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    context.read<ForumChatCubit>().sendMessage(
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

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
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
    } else {
      final cubit = context.read<ForumChatCubit>();
      final index = cubit.state.messages.indexWhere((m) => m.id == messageId);
      if (index != -1) {
        _scrollController.animateTo(
          index * 100.0,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    }
  }
}

class _ReplySwipeWrapper extends StatefulWidget {
  final Widget child;
  final bool isDark;
  final bool isArabic;
  final VoidCallback onReply;

  const _ReplySwipeWrapper({
    required this.child,
    required this.isDark,
    required this.isArabic,
    required this.onReply,
  });

  @override
  State<_ReplySwipeWrapper> createState() => _ReplySwipeWrapperState();
}

class _ReplySwipeWrapperState extends State<_ReplySwipeWrapper> {
  static const double _maxOffset = 280;
  static const double _triggerOffset = 200;
  double _offsetX = 0;
  bool _didTrigger = false;

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (_didTrigger) return;

    final nextOffset =
        (_offsetX + details.delta.dx).clamp(-_maxOffset, _maxOffset);
    setState(() => _offsetX = nextOffset);

    if (nextOffset.abs() >= _triggerOffset) {
      _didTrigger = true;
      widget.onReply();
      setState(() => _offsetX = 0);
    }
  }

  void _resetDrag() {
    _didTrigger = false;
    if (_offsetX != 0) {
      setState(() => _offsetX = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_offsetX.abs() / _maxOffset).clamp(0.0, 1.0);
    final alignRight = _offsetX < 0;

    return GestureDetector(
      onHorizontalDragUpdate: _onHorizontalDragUpdate,
      onHorizontalDragEnd: (_) => _resetDrag(),
      onHorizontalDragCancel: _resetDrag,
      child: Stack(
        alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Opacity(
              opacity: progress,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.reply, color: AppColors.primary, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    widget.isArabic ? '\u0631\u062f' : 'Reply',
                    style: TextStyle(
                      color: widget.isDark
                          ? AppColors.textMutedDark
                          : AppColors.textMutedLight,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            transform: Matrix4.translationValues(_offsetX, 0, 0),
            child: widget.child,
          ),
        ],
      ),
    );
  }
}
