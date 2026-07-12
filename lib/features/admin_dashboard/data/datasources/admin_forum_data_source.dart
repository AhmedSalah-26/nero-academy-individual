import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/app_logger.dart';

/// Admin Forum Data Source - queries conversations + messages tables
class AdminForumDataSource {
  final SupabaseClient _supabase;
  static const _tag = 'AdminForumDS';

  AdminForumDataSource(this._supabase);

  /// Get all conversations (admin can see all)
  Future<List<Map<String, dynamic>>> getConversations({
    String? search,
    String? typeFilter,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      AppLogger.d(
          '[$_tag] getConversations: search=$search, type=$typeFilter, page=$page');

      var query = _supabase
          .from('conversations')
          .select('*, conversation_participants(count)');

      if (typeFilter != null) {
        query = query.eq('type', typeFilter);
      }

      if (search != null && search.isNotEmpty) {
        query = query.ilike('title', '%$search%');
      }

      final results = await query
          .order('updated_at', ascending: false)
          .range((page - 1) * limit, page * limit - 1);

      AppLogger.success(
          '[$_tag] getConversations: ${(results as List).length} conversations');
      return List<Map<String, dynamic>>.from(results);
    } catch (e, s) {
      AppLogger.e('[$_tag] getConversations error', e, s);
      rethrow;
    }
  }

  /// Get messages for a conversation
  Future<List<Map<String, dynamic>>> getMessages({
    required String conversationId,
    String? search,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      AppLogger.d(
          '[$_tag] getMessages: conversationId=$conversationId, page=$page');

      var query = _supabase
          .from('messages')
          .select('*, profiles(*)')
          .eq('conversation_id', conversationId)
          .eq('is_deleted', false);

      if (search != null && search.isNotEmpty) {
        query = query.ilike('message_text', '%$search%');
      }

      final results = await query
          .order('created_at', ascending: false)
          .range((page - 1) * limit, page * limit - 1);

      AppLogger.success(
          '[$_tag] getMessages: ${(results as List).length} messages');
      return List<Map<String, dynamic>>.from(results);
    } catch (e, s) {
      AppLogger.e('[$_tag] getMessages error', e, s);
      rethrow;
    }
  }

  /// Delete a message (hard delete — admin privilege)
  Future<bool> deleteMessage(String messageId) async {
    try {
      await _supabase
          .from('messages')
          .update({'is_deleted': true}).eq('id', messageId);
      AppLogger.success('[$_tag] deleteMessage: $messageId');
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] deleteMessage error', e, s);
      rethrow;
    }
  }
}
