import '../../domain/entities/notification_entity.dart';

/// Notification Model - Maps to database table
class NotificationModel extends NotificationEntity {
  const NotificationModel({
    required super.id,
    required super.userId,
    required super.type,
    required super.titleAr,
    super.titleEn,
    super.bodyAr,
    super.bodyEn,
    super.imageUrl,
    super.iconName,
    super.actionType,
    super.actionValue,
    super.data,
    super.isRead,
    super.readAt,
    super.senderId,
    super.courseId,
    required super.createdAt,
    super.updatedAt,
  });

  /// Create from JSON (database row)
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final dataMap = json['data'] != null
        ? Map<String, dynamic>.from(json['data'] as Map)
        : null;
    return NotificationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: NotificationType.fromString(json['type'] as String? ?? 'system'),
      titleAr: json['title_ar'] as String,
      titleEn: json['title_en'] as String?,
      bodyAr: json['body_ar'] as String?,
      bodyEn: json['body_en'] as String?,
      imageUrl: dataMap?['image_url'] as String?,
      iconName: dataMap?['icon_name'] as String?,
      actionType: dataMap?['action_type'] as String?,
      actionValue: dataMap?['action_value'] as String?,
      data: dataMap,
      isRead: json['is_read'] as bool? ?? false,
      readAt: json['read_at'] != null
          ? DateTime.parse(json['read_at'] as String)
          : null,
      senderId: dataMap?['sender_id'] as String?,
      courseId: dataMap?['course_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// Convert to JSON (for insert/update)
  Map<String, dynamic> toJson() {
    final dataMap = Map<String, dynamic>.from(data ?? {});
    if (imageUrl != null) dataMap['image_url'] = imageUrl;
    if (iconName != null) dataMap['icon_name'] = iconName;
    if (actionType != null) dataMap['action_type'] = actionType;
    if (actionValue != null) dataMap['action_value'] = actionValue;
    if (senderId != null) dataMap['sender_id'] = senderId;
    if (courseId != null) dataMap['course_id'] = courseId;
    return {
      'id': id,
      'user_id': userId,
      'type': type.value,
      'title_ar': titleAr,
      'title_en': titleEn,
      'body_ar': bodyAr,
      'body_en': bodyEn,
      'data': dataMap,
      'is_read': isRead,
      'read_at': readAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Create from entity
  factory NotificationModel.fromEntity(NotificationEntity entity) {
    return NotificationModel(
      id: entity.id,
      userId: entity.userId,
      type: entity.type,
      titleAr: entity.titleAr,
      titleEn: entity.titleEn,
      bodyAr: entity.bodyAr,
      bodyEn: entity.bodyEn,
      imageUrl: entity.imageUrl,
      iconName: entity.iconName,
      actionType: entity.actionType,
      actionValue: entity.actionValue,
      data: entity.data,
      isRead: entity.isRead,
      readAt: entity.readAt,
      senderId: entity.senderId,
      courseId: entity.courseId,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
