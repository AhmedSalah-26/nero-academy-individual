import 'package:equatable/equatable.dart';

/// Message Type Enum
enum MessageType {
  text,
  image,
  file,
}

/// Conversation Type Enum
enum ConversationType {
  single,
  multi,
}

/// Conversation Entity
class Conversation extends Equatable {
  final String id;
  final ConversationType type;
  final String? courseId;
  final String? title;
  final String createdBy;
  final DateTime createdAt;
  final ConversationMessage? lastMessage;
  final int participantsCount;
  // For single conversations
  final String? otherUserName;
  final String? otherUserAvatar;

  const Conversation({
    required this.id,
    required this.type,
    this.courseId,
    this.title,
    required this.createdBy,
    required this.createdAt,
    this.lastMessage,
    this.participantsCount = 0,
    this.otherUserName,
    this.otherUserAvatar,
  });

  /// Display title: for multi = title, for single = other user's name
  String get displayTitle {
    if (type == ConversationType.single) {
      final safeName = otherUserName?.trim();
      return (safeName == null || safeName.isEmpty) ? 'Unknown' : safeName;
    }
    return title ?? 'Untitled';
  }

  @override
  List<Object?> get props => [
        id,
        type,
        courseId,
        title,
        createdBy,
        createdAt,
        lastMessage,
        participantsCount,
        otherUserName,
        otherUserAvatar,
      ];
}

/// Conversation Message Entity
class ConversationMessage extends Equatable {
  final String id;
  final String conversationId;
  final String userId;
  final String userName;
  final String? userAvatar;
  final String? messageText;
  final MessageType messageType;
  final String? mediaUrl;
  final String? fileName;
  final int? fileSize;
  final String? replyToMessageId;
  final ConversationMessage? replyToMessage;
  final bool isEdited;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<MessageReaction> reactions;

  const ConversationMessage({
    required this.id,
    required this.conversationId,
    required this.userId,
    required this.userName,
    this.userAvatar,
    this.messageText,
    required this.messageType,
    this.mediaUrl,
    this.fileName,
    this.fileSize,
    this.replyToMessageId,
    this.replyToMessage,
    this.isEdited = false,
    this.isDeleted = false,
    required this.createdAt,
    required this.updatedAt,
    this.reactions = const [],
  });

  /// Get grouped reactions with counts
  Map<String, int> get groupedReactions {
    final Map<String, int> grouped = {};
    for (final reaction in reactions) {
      grouped[reaction.reaction] = (grouped[reaction.reaction] ?? 0) + 1;
    }
    return grouped;
  }

  @override
  List<Object?> get props => [
        id,
        conversationId,
        userId,
        userName,
        userAvatar,
        messageText,
        messageType,
        mediaUrl,
        fileName,
        fileSize,
        replyToMessageId,
        isEdited,
        isDeleted,
        createdAt,
        updatedAt,
        reactions.length,
        reactions.map((r) => '${r.userId}_${r.reaction}').join(','),
      ];
}

/// Message Reaction Entity
class MessageReaction extends Equatable {
  final String id;
  final String messageId;
  final String userId;
  final String reaction;
  final DateTime createdAt;

  const MessageReaction({
    required this.id,
    required this.messageId,
    required this.userId,
    required this.reaction,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, messageId, userId, reaction, createdAt];
}
