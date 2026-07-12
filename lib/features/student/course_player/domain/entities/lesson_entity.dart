import 'package:equatable/equatable.dart';
import 'package:lms_platform/core/utils/availability_window.dart';

/// Lesson Entity - Pure Dart Object
class LessonEntity extends Equatable {
  final String id;
  final String sectionId;
  final String titleAr;
  final String? titleEn;
  final String? descriptionAr;
  final String? descriptionEn;
  final LessonType type;
  final String? videoUrl;
  final VideoProvider? videoProvider;
  final int? videoDuration;
  final String? articleContentAr;
  final String? articleContentEn;
  final String? fileUrl;
  final String? fileName;
  final int? fileSize;
  final String? fileType;
  final bool isPreview;
  final bool isMandatory;
  final bool isPublished;
  final int sortOrder;
  final DateTime? availableFrom;
  final DateTime? availableUntil;
  final DateTime? createdAt;

  const LessonEntity({
    required this.id,
    required this.sectionId,
    required this.titleAr,
    this.titleEn,
    this.descriptionAr,
    this.descriptionEn,
    required this.type,
    this.videoUrl,
    this.videoProvider,
    this.videoDuration,
    this.articleContentAr,
    this.articleContentEn,
    this.fileUrl,
    this.fileName,
    this.fileSize,
    this.fileType,
    this.isPreview = false,
    this.isMandatory = true,
    this.isPublished = true,
    this.sortOrder = 0,
    this.availableFrom,
    this.availableUntil,
    this.createdAt,
  });

  /// Get localized title
  String getTitle(String locale) {
    if (locale == 'en' && titleEn != null && titleEn!.isNotEmpty) {
      return titleEn!;
    }
    return titleAr;
  }

  /// Get localized description
  String? getDescription(String locale) {
    if (locale == 'en' && descriptionEn != null && descriptionEn!.isNotEmpty) {
      return descriptionEn;
    }
    return descriptionAr;
  }

  /// Get localized article content
  String? getArticleContent(String locale) {
    if (locale == 'en' &&
        articleContentEn != null &&
        articleContentEn!.isNotEmpty) {
      return articleContentEn;
    }
    return articleContentAr;
  }

  /// Format video duration as string (e.g., "12:45")
  String get formattedDuration {
    if (videoDuration == null) return '';
    final minutes = videoDuration! ~/ 60;
    final seconds = videoDuration! % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Get duration in minutes
  int get durationInMinutes => (videoDuration ?? 0) ~/ 60;

  bool get isCurrentlyAvailable => AvailabilityWindow.isActive(
        availableFrom: availableFrom,
        availableUntil: availableUntil,
      );

  @override
  List<Object?> get props => [
        id,
        sectionId,
        titleAr,
        titleEn,
        type,
        videoUrl,
        videoDuration,
        fileUrl,
        fileName,
        fileSize,
        fileType,
        isPreview,
        isMandatory,
        isPublished,
        sortOrder,
        availableFrom,
        availableUntil,
      ];
}

/// Lesson Type Enum
enum LessonType {
  video,
  article,
  quiz,
  assignment,
  resource,
  live,
  document;

  String get icon {
    switch (this) {
      case LessonType.video:
        return 'play_circle';
      case LessonType.article:
        return 'description';
      case LessonType.quiz:
        return 'quiz';
      case LessonType.assignment:
        return 'assignment';
      case LessonType.resource:
        return 'folder';
      case LessonType.live:
        return 'live_tv';
      case LessonType.document:
        return 'insert_drive_file';
    }
  }
}

/// Video Provider Enum
enum VideoProvider {
  supabase,
  youtube,
  vimeo,
  bunny;
}
