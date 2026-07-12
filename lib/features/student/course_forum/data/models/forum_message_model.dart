import 'package:lms_platform/features/student/course_forum/domain/entities/forum_entities.dart';

/// Conversation Message Model
class ConversationMessageModel extends ConversationMessage {
  const ConversationMessageModel({
    required super.id,
    required super.conversationId,
    required super.userId,
    required super.userName,
    super.userAvatar,
    super.messageText,
    required super.messageType,
    super.mediaUrl,
    super.fileName,
    super.fileSize,
    super.replyToMessageId,
    super.replyToMessage,
    super.isEdited,
    super.isDeleted,
    required super.createdAt,
    required super.updatedAt,
    super.reactions,
  });

  factory ConversationMessageModel.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'];

    // Parse reactions
    final reactionsJson = json['message_reactions'] as List?;
    final reactions = reactionsJson
            ?.map(
                (r) => MessageReactionModel.fromJson(r as Map<String, dynamic>))
            .toList() ??
        [];

    return ConversationMessageModel(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      userId: json['user_id'] as String,
      userName: profile != null
          ? (profile['name'] as String? ?? 'Unknown')
          : (json['user_name'] as String? ?? 'Unknown'),
      userAvatar: profile?['avatar_url'] as String?,
      messageText: json['message_text'] as String?,
      messageType: _parseMessageType(json['message_type'] as String?),
      mediaUrl: json['media_url'] as String?,
      fileName: json['file_name'] as String?,
      fileSize: json['file_size'] as int?,
      replyToMessageId: json['reply_to_message_id'] as String?,
      replyToMessage: json['reply_to_message'] != null
          ? ConversationMessageModel.fromJson(
              json['reply_to_message'] as Map<String, dynamic>)
          : null,
      isEdited: json['is_edited'] as bool? ?? false,
      isDeleted: json['is_deleted'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      reactions: reactions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'user_id': userId,
      'message_text': messageText,
      'message_type': messageType.name,
      'media_url': mediaUrl,
      'file_name': fileName,
      'file_size': fileSize,
      'reply_to_message_id': replyToMessageId,
      'is_edited': isEdited,
      'is_deleted': isDeleted,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  static MessageType _parseMessageType(String? type) {
    switch (type) {
      case 'image':
        return MessageType.image;
      case 'file':
        return MessageType.file;
      default:
        return MessageType.text;
    }
  }
}

/// Message Reaction Model
class MessageReactionModel extends MessageReaction {
  const MessageReactionModel({
    required super.id,
    required super.messageId,
    required super.userId,
    required super.reaction,
    required super.createdAt,
  });

  factory MessageReactionModel.fromJson(Map<String, dynamic> json) {
    return MessageReactionModel(
      id: json['id'] as String,
      messageId: json['message_id'] as String,
      userId: json['user_id'] as String,
      reaction: json['reaction'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message_id': messageId,
      'user_id': userId,
      'reaction': reaction,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
