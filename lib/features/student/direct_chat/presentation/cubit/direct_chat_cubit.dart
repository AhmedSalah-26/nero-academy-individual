import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lms_platform/features/student/direct_chat/data/models/direct_message_model.dart';
import 'package:lms_platform/core/services/user_role_service.dart';
import 'direct_chat_state.dart';

class DirectChatCubit extends Cubit<DirectChatState> {
  final SupabaseClient _supabase;
  final String otherUserId;
  RealtimeChannel? _channel;

  DirectChatCubit(this._supabase, this.otherUserId)
      : super(const DirectChatState());

  String? get currentUserId => _supabase.auth.currentUser?.id;

  Future<void> loadMessages() async {
    try {
      emit(state.copyWith(isLoading: true, isError: false));

      final userId = currentUserId;
      if (userId == null) {
        emit(state.copyWith(
          isLoading: false,
          isError: true,
          errorMessage: 'User not authenticated',
        ));
        return;
      }

      // Load messages between current user and other user.
      // Try with reactions relation first, then fallback if schema is older.
      dynamic response;
      try {
        response = await _supabase
            .from('direct_messages')
            .select(
                '*, profiles!direct_messages_sender_id_fkey(*), direct_message_reactions(*)')
            .or('and(sender_id.eq.$userId,receiver_id.eq.$otherUserId),and(sender_id.eq.$otherUserId,receiver_id.eq.$userId)')
            .order('created_at', ascending: true);
      } catch (_) {
        response = await _supabase
            .from('direct_messages')
            .select('*, profiles!direct_messages_sender_id_fkey(*)')
            .or('and(sender_id.eq.$userId,receiver_id.eq.$otherUserId),and(sender_id.eq.$otherUserId,receiver_id.eq.$userId)')
            .order('created_at', ascending: true);
      }

      final messages = (response as List)
          .map((json) => DirectMessageModel.fromJson(json))
          .toList();

      emit(state.copyWith(
        isLoading: false,
        messages: messages,
      ));

      // Mark messages as read
      await markAllAsRead();

      // Subscribe to realtime (only once)
      if (_channel == null) {
        _subscribeToMessages();
      }
    } catch (e) {
      debugPrint('❌ [DirectChat] Error loading messages: $e');
      emit(state.copyWith(
        isLoading: false,
        isError: true,
        errorMessage: e.toString(),
      ));
    }
  }

  void _subscribeToMessages() {
    if (_channel != null) return;

    final userId = currentUserId;
    if (userId == null) return;

    _channel = _supabase
        .channel('direct_chat_${userId}_$otherUserId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'direct_messages',
          callback: (payload) {
            final newRecord = payload.newRecord;
            final senderId = newRecord['sender_id'] as String?;
            final receiverId = newRecord['receiver_id'] as String?;

            // Only process messages between us
            final isOurChat =
                (senderId == userId && receiverId == otherUserId) ||
                    (senderId == otherUserId && receiverId == userId);
            if (!isOurChat) return;

            // Reload to get full data with joins
            loadMessages();
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'direct_messages',
          callback: (payload) {
            loadMessages();
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'direct_messages',
          callback: (payload) {
            loadMessages();
          },
        )
        .subscribe();
  }

  Future<void> sendMessage(String text, {String? replyToId}) async {
    try {
      final userId = currentUserId;
      if (userId == null) return;

      final payload = {
        'sender_id': userId,
        'receiver_id': otherUserId,
        'message_text': text.trim(),
      };

      if (replyToId != null) {
        try {
          await _supabase.from('direct_messages').insert({
            ...payload,
            'reply_to_message_id': replyToId,
          });
        } catch (e) {
          // Backward compatibility if migration for reply column is missing.
          if (e is PostgrestException &&
              (e.code == '42703' ||
                  e.message.contains('reply_to_message_id'))) {
            await _supabase.from('direct_messages').insert(payload);
          } else {
            rethrow;
          }
        }
      } else {
        await _supabase.from('direct_messages').insert(payload);
      }

      // Realtime will pick up the new message, but also reload for safety
      await loadMessages();
    } catch (e) {
      debugPrint('❌ [DirectChat] Error sending message: $e');
    }
  }

  Future<void> deleteMessage(String messageId) async {
    try {
      final userId = currentUserId;
      if (userId == null) return;

      final isAdmin = UserRoleService.getCachedRole() == 'admin';

      final query =
          _supabase.from('direct_messages').delete().eq('id', messageId);

      if (!isAdmin) {
        query.eq('sender_id', userId);
      }

      await query;

      final updated = state.messages.where((m) => m.id != messageId).toList();
      emit(state.copyWith(messages: updated, forceUpdate: true));
    } catch (e) {
      debugPrint('❌ [DirectChat] Error deleting message: $e');
    }
  }

  Future<void> toggleReaction(String messageId, String emoji) async {
    try {
      final userId = currentUserId;
      if (userId == null) return;

      // Check if user already reacted with this emoji
      final existing = await _supabase
          .from('direct_message_reactions')
          .select()
          .eq('message_id', messageId)
          .eq('user_id', userId)
          .eq('reaction', emoji);

      if ((existing as List).isNotEmpty) {
        // Remove reaction
        await _supabase
            .from('direct_message_reactions')
            .delete()
            .eq('message_id', messageId)
            .eq('user_id', userId)
            .eq('reaction', emoji);
      } else {
        // Add reaction
        await _supabase.from('direct_message_reactions').insert({
          'message_id': messageId,
          'user_id': userId,
          'reaction': emoji,
        });
      }

      await loadMessages();
    } catch (e) {
      debugPrint('❌ [DirectChat] Error toggling reaction: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final userId = currentUserId;
      if (userId == null) return;

      // Mark all unread messages from the other user as read
      await _supabase
          .from('direct_messages')
          .update({'is_read': true})
          .eq('sender_id', otherUserId)
          .eq('receiver_id', userId)
          .eq('is_read', false);
    } catch (e) {
      debugPrint('❌ [DirectChat] Error marking as read: $e');
    }
  }

  @override
  Future<void> close() {
    _channel?.unsubscribe();
    _channel = null;
    return super.close();
  }
}
