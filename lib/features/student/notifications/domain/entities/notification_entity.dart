/// Notification Type Enum
/// Maps to the 'type' column in the notifications table
enum NotificationType {
  instructorMessage('instructor_message'),
  courseUpdate('course_update'),
  newLesson('new_lesson'),
  quizResult('quiz_result'),
  certificateIssued('certificate_issued'),
  enrollmentConfirmed('enrollment_confirmed'),
  paymentConfirmed('payment_confirmed'),
  courseCompleted('course_completed'),
  announcement('announcement'),
  promotion('promotion'),
  reminder('reminder'),
  system('system');

  final String value;
  const NotificationType(this.value);

  static NotificationType fromString(String value) {
    return NotificationType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => NotificationType.system,
    );
  }
}

/// Notification Entity
class NotificationEntity {
  final String id;
  final String userId;
  final NotificationType type;
  final String titleAr;
  final String? titleEn;
  final String? bodyAr;
  final String? bodyEn;
  final String? imageUrl;
  final String? iconName;
  final String? actionType;
  final String? actionValue;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime? readAt;
  final String? senderId;
  final String? courseId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const NotificationEntity({
    required this.id,
    required this.userId,
    required this.type,
    required this.titleAr,
    this.titleEn,
    this.bodyAr,
    this.bodyEn,
    this.imageUrl,
    this.iconName,
    this.actionType,
    this.actionValue,
    this.data,
    this.isRead = false,
    this.readAt,
    this.senderId,
    this.courseId,
    required this.createdAt,
    this.updatedAt,
  });

  /// Get localized title based on language
  String getTitle(String languageCode) {
    if (languageCode == 'en' && titleEn != null && titleEn!.isNotEmpty) {
      return titleEn!;
    }
    return titleAr;
  }

  /// Get localized body based on language
  String? getBody(String languageCode) {
    if (languageCode == 'en' && bodyEn != null && bodyEn!.isNotEmpty) {
      return bodyEn;
    }
    return bodyAr;
  }

  NotificationEntity copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    String? titleAr,
    String? titleEn,
    String? bodyAr,
    String? bodyEn,
    String? imageUrl,
    String? iconName,
    String? actionType,
    String? actionValue,
    Map<String, dynamic>? data,
    bool? isRead,
    DateTime? readAt,
    String? senderId,
    String? courseId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NotificationEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      titleAr: titleAr ?? this.titleAr,
      titleEn: titleEn ?? this.titleEn,
      bodyAr: bodyAr ?? this.bodyAr,
      bodyEn: bodyEn ?? this.bodyEn,
      imageUrl: imageUrl ?? this.imageUrl,
      iconName: iconName ?? this.iconName,
      actionType: actionType ?? this.actionType,
      actionValue: actionValue ?? this.actionValue,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      senderId: senderId ?? this.senderId,
      courseId: courseId ?? this.courseId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
