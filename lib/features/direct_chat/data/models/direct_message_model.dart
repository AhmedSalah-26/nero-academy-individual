import '../../domain/entities/direct_message_entity.dart';

class DirectMessageModel extends DirectMessage {
  const DirectMessageModel({
    required super.id,
    required super.senderId,
    required super.receiverId,
    required super.senderName,
    super.senderAvatar,
    super.messageText,
    super.isRead,
    super.isDeleted,
    super.isEdited,
    super.replyToMessageId,
    super.replyToMessage,
    super.reactions,
    required super.createdAt,
  });

  factory DirectMessageModel.fromJson(Map<String, dynamic> json) {
    // Parse profile info from joined data
    final profile = json['profiles'] as Map<String, dynamic>?;
    final senderName = profile?['name'] as String? ?? 'Unknown';
    final senderAvatar = profile?['avatar_url'] as String?;

    // Parse reactions - handle if table/relation doesn't exist
    final reactionsJson =
        (json['direct_message_reactions'] as List<dynamic>?) ?? [];
    final reactions = reactionsJson
        .map((r) => DirectMessageReaction(
              id: r['id'] as String,
              messageId: r['message_id'] as String,
              userId: r['user_id'] as String,
              reaction: r['reaction'] as String,
              createdAt: DateTime.parse(r['created_at'] as String),
            ))
        .toList();

    // Parse reply message if exists
    DirectMessageModel? replyTo;
    if (json['reply_to'] != null && json['reply_to'] is Map) {
      replyTo =
          DirectMessageModel.fromJson(json['reply_to'] as Map<String, dynamic>);
    }

    return DirectMessageModel(
      id: json['id'] as String,
      senderId: json['sender_id'] as String,
      receiverId: json['receiver_id'] as String,
      senderName: senderName,
      senderAvatar: senderAvatar,
      messageText: json['message_text'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      isDeleted: false,
      isEdited: false,
      replyToMessageId: null,
      replyToMessage: replyTo,
      reactions: reactions,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
