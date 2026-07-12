import 'package:lms_platform/features/student/course_forum/domain/entities/forum_entities.dart';

/// Conversation Model — for listing conversations
class ConversationModel extends Conversation {
  const ConversationModel({
    required super.id,
    required super.type,
    super.courseId,
    super.title,
    required super.createdBy,
    required super.createdAt,
    super.lastMessage,
    super.participantsCount,
    super.otherUserName,
    super.otherUserAvatar,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    // Parse last message if exists
    ConversationMessage? lastMessage;
    if (json['last_message_id'] != null && json['last_message_text'] != null) {
      lastMessage = ConversationMessage(
        id: json['last_message_id'] as String,
        conversationId: json['conversation_id'] as String,
        userId: json['last_message_user_id'] as String,
        userName: json['last_message_user_name'] as String? ?? 'Unknown',
        messageText: json['last_message_text'] as String,
        messageType: MessageType.text,
        createdAt: DateTime.parse(json['last_message_created_at'] as String),
        updatedAt: DateTime.parse(json['last_message_created_at'] as String),
      );
    }

    return ConversationModel(
      id: json['conversation_id'] as String,
      type: json['conversation_type'] == 'single'
          ? ConversationType.single
          : ConversationType.multi,
      courseId: json['course_id'] as String?,
      title: json['conversation_title'] as String?,
      createdBy: '', // Not returned by list function
      createdAt: DateTime.parse(json['created_at'] as String),
      lastMessage: lastMessage,
      participantsCount: (json['participants_count'] as num?)?.toInt() ?? 0,
      otherUserName: json['other_user_name'] as String?,
      otherUserAvatar: json['other_user_avatar'] as String?,
    );
  }
}
