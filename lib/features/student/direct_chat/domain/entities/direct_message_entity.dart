import 'package:equatable/equatable.dart';

/// Direct Message Entity for 1-on-1 chat
class DirectMessage extends Equatable {
  final String id;
  final String senderId;
  final String receiverId;
  final String senderName;
  final String? senderAvatar;
  final String? messageText;
  final bool isRead;
  final bool isDeleted;
  final bool isEdited;
  final String? replyToMessageId;
  final DirectMessage? replyToMessage;
  final List<DirectMessageReaction> reactions;
  final DateTime createdAt;

  const DirectMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.senderName,
    this.senderAvatar,
    this.messageText,
    this.isRead = false,
    this.isDeleted = false,
    this.isEdited = false,
    this.replyToMessageId,
    this.replyToMessage,
    this.reactions = const [],
    required this.createdAt,
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
        senderId,
        receiverId,
        senderName,
        senderAvatar,
        messageText,
        isRead,
        isDeleted,
        isEdited,
        replyToMessageId,
        reactions.length,
        reactions.map((r) => '${r.userId}_${r.reaction}').join(','),
        createdAt,
      ];
}

/// Direct Message Reaction Entity
class DirectMessageReaction extends Equatable {
  final String id;
  final String messageId;
  final String userId;
  final String reaction;
  final DateTime createdAt;

  const DirectMessageReaction({
    required this.id,
    required this.messageId,
    required this.userId,
    required this.reaction,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, messageId, userId, reaction, createdAt];
}
