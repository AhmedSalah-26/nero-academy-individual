import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lms_platform/features/student/course_forum/data/models/forum_message_model.dart';
import 'package:lms_platform/features/student/course_forum/domain/entities/forum_entities.dart';
import 'package:lms_platform/core/services/user_role_service.dart';
import 'forum_chat_state.dart';

class ForumChatCubit extends Cubit<ForumChatState> {
  final SupabaseClient _supabase;
  final String conversationId;
  RealtimeChannel? _channel;

  ForumChatCubit(this._supabase, this.conversationId)
      : super(const ForumChatState());

  String? get currentUserId => _supabase.auth.currentUser?.id;

  Future<void> loadMessages() async {
    try {
      emit(state.copyWith(isLoading: true, isError: false));

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        emit(state.copyWith(
          isLoading: false,
          isError: true,
          errorMessage: 'User not authenticated',
        ));
        return;
      }

      // Load messages with profile info and reactions
      final response = await _supabase
          .from('messages')
          .select('*, profiles(*), message_reactions(*)')
          .eq('conversation_id', conversationId)
          .eq('is_deleted', false)
          .order('created_at', ascending: true);

      final messages = (response as List).map((json) {
        return ConversationMessageModel.fromJson(json as Map<String, dynamic>);
      }).toList();

      emit(state.copyWith(
        isLoading: false,
        messages: messages,
      ));

      // Subscribe to realtime updates
      if (_channel == null) {
        _subscribeToMessages();
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [ForumChat] Error loading messages: $e');
      debugPrint('Stack trace: $stackTrace');
      emit(state.copyWith(
        isLoading: false,
        isError: true,
        errorMessage: e.toString(),
      ));
    }
  }

  void _subscribeToMessages() {
    if (_channel != null) return;

    final currentUser = _supabase.auth.currentUser?.id;

    _channel = _supabase
        .channel('conversation_$conversationId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: conversationId,
          ),
          callback: (payload) async {
            final messageUserId = payload.newRecord['user_id'];
            if (messageUserId == currentUser) return;

            try {
              final messageId = payload.newRecord['id'];
              if (state.messages.any((m) => m.id == messageId)) return;

              final response = await _supabase
                  .from('messages')
                  .select('*, profiles(*), message_reactions(*)')
                  .eq('id', messageId)
                  .single();

              final newMessage = ConversationMessageModel.fromJson(response);
              final updatedMessages = [...state.messages, newMessage];
              emit(state.copyWith(messages: updatedMessages));
            } catch (e) {
              debugPrint('❌ [ForumChat] Error fetching new message: $e');
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'message_reactions',
          callback: (payload) async {
            final messageId = payload.newRecord['message_id'] as String?;
            if (messageId != null) {
              await _refreshMessageReactions(messageId);
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'message_reactions',
          callback: (payload) async {
            final messageId = payload.oldRecord['message_id'] as String?;
            if (messageId != null) {
              await _refreshMessageReactions(messageId);
            }
          },
        )
        .subscribe();
  }

  Future<void> _refreshMessageReactions(String messageId) async {
    try {
      final response = await _supabase
          .from('message_reactions')
          .select('*')
          .eq('message_id', messageId);

      final reactions = (response as List)
          .map((r) => MessageReactionModel.fromJson(r as Map<String, dynamic>))
          .toList();

      final updatedMessages = List<ConversationMessage>.from(
        state.messages.map((m) {
          if (m.id == messageId) {
            return ConversationMessageModel(
              id: m.id,
              conversationId: m.conversationId,
              userId: m.userId,
              userName: m.userName,
              userAvatar: m.userAvatar,
              messageText: m.messageText,
              messageType: m.messageType,
              mediaUrl: m.mediaUrl,
              fileName: m.fileName,
              fileSize: m.fileSize,
              replyToMessageId: m.replyToMessageId,
              replyToMessage: m.replyToMessage,
              isEdited: m.isEdited,
              isDeleted: m.isDeleted,
              createdAt: m.createdAt,
              updatedAt: m.updatedAt,
              reactions: reactions,
            );
          }
          return m;
        }),
      );

      emit(state.copyWith(messages: updatedMessages));
    } catch (e) {
      debugPrint('❌ [ForumChat] Error refreshing reactions: $e');
    }
  }

  Future<void> sendMessage(String text, {String? replyToId}) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final userProfile = await _supabase
          .from('profiles')
          .select('name, avatar_url')
          .eq('id', userId)
          .single();

      final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
      final optimisticMessage = ConversationMessageModel(
        id: tempId,
        conversationId: conversationId,
        userId: userId,
        userName: userProfile['name'] ?? 'Me',
        userAvatar: userProfile['avatar_url'],
        messageText: text,
        messageType: MessageType.text,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        replyToMessageId: replyToId,
      );

      emit(state.copyWith(messages: [...state.messages, optimisticMessage]));

      final response = await _supabase
          .from('messages')
          .insert({
            'conversation_id': conversationId,
            'user_id': userId,
            'message_text': text,
            'message_type': 'text',
            'reply_to_message_id': replyToId,
          })
          .select('*, profiles(*), message_reactions(*)')
          .single();

      final realMessage = ConversationMessageModel.fromJson(response);
      final updatedMessages = state.messages.map((m) {
        if (m.id == tempId) return realMessage;
        return m;
      }).toList();

      emit(state.copyWith(messages: updatedMessages));
    } catch (e) {
      debugPrint('❌ [ForumChat] Error sending message: $e');
      final updatedMessages =
          state.messages.where((m) => !m.id.startsWith('temp_')).toList();
      emit(state.copyWith(
        messages: updatedMessages,
        isError: true,
        errorMessage: 'Failed to send message: ${e.toString()}',
      ));
    }
  }

  /// Toggle reaction on a message
  Future<void> toggleReaction(String messageId, String emoji) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final messageIndex = state.messages.indexWhere((m) => m.id == messageId);
      if (messageIndex == -1) return;

      final message = state.messages[messageIndex];
      final currentReactions = List<MessageReaction>.from(message.reactions);
      final existingIndex =
          currentReactions.indexWhere((r) => r.userId == userId);

      bool isRemove = false;
      if (existingIndex != -1) {
        final existing = currentReactions[existingIndex];
        if (existing.reaction == emoji) {
          isRemove = true;
        }
      }

      // Optimistic update
      if (existingIndex != -1) {
        if (isRemove) {
          currentReactions.removeAt(existingIndex);
        } else {
          final existing = currentReactions[existingIndex];
          currentReactions[existingIndex] = MessageReaction(
            id: existing.id,
            messageId: messageId,
            userId: userId,
            reaction: emoji,
            createdAt: existing.createdAt,
          );
        }
      } else {
        currentReactions.add(MessageReaction(
          id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
          messageId: messageId,
          userId: userId,
          reaction: emoji,
          createdAt: DateTime.now(),
        ));
      }

      final updatedMessages = List<ConversationMessage>.from(state.messages);
      updatedMessages[messageIndex] = ConversationMessageModel(
        id: message.id,
        conversationId: message.conversationId,
        userId: message.userId,
        userName: message.userName,
        userAvatar: message.userAvatar,
        messageText: message.messageText,
        messageType: message.messageType,
        mediaUrl: message.mediaUrl,
        fileName: message.fileName,
        fileSize: message.fileSize,
        replyToMessageId: message.replyToMessageId,
        replyToMessage: message.replyToMessage,
        isEdited: message.isEdited,
        isDeleted: message.isDeleted,
        createdAt: message.createdAt,
        updatedAt: message.updatedAt,
        reactions: currentReactions,
      );
      emit(state.copyWith(messages: updatedMessages));

      // DB action
      if (isRemove) {
        await _supabase
            .from('message_reactions')
            .delete()
            .eq('message_id', messageId)
            .eq('user_id', userId);
      } else {
        await _supabase
            .from('message_reactions')
            .delete()
            .eq('message_id', messageId)
            .eq('user_id', userId);
        await _supabase.from('message_reactions').insert({
          'message_id': messageId,
          'user_id': userId,
          'reaction': emoji,
        });
      }
    } catch (e) {
      debugPrint('❌ [ForumChat] Error toggling reaction: $e');
      _refreshMessageReactions(messageId);
    }
  }

  /// Delete a message
  Future<void> deleteMessage(String messageId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final isAdmin = UserRoleService.getCachedRole() == 'admin';

      // Soft delete
      final query = _supabase
          .from('messages')
          .update({'is_deleted': true}).eq('id', messageId);

      if (!isAdmin) {
        query.eq('user_id', userId);
      }

      await query;

      final updatedMessages =
          state.messages.where((m) => m.id != messageId).toList();
      emit(state.copyWith(messages: updatedMessages));
    } catch (e) {
      debugPrint('❌ [ForumChat] Error deleting message: $e');
    }
  }

  @override
  Future<void> close() {
    _channel?.unsubscribe();
    return super.close();
  }
}
