import 'package:equatable/equatable.dart';
import '../../../../core/utils/availability_window.dart';

/// Lesson Type Enum
enum LessonType {
  video,
  article,
  quiz,
  assignment,
  resource,
  live,
  document;

  static LessonType fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'video':
        return LessonType.video;
      case 'article':
        return LessonType.article;
      case 'quiz':
        return LessonType.quiz;
      case 'assignment':
        return LessonType.assignment;
      case 'resource':
        return LessonType.resource;
      case 'live':
        return LessonType.live;
      case 'document':
        return LessonType.document;
      default:
        return LessonType.video;
    }
  }

  String toJson() => name;
}

/// Lesson Entity - Pure Dart Object
class LessonEntity extends Equatable {
  final String id;
  final String sectionId;
  final String? titleAr;
  final String? titleEn;
  final String? descriptionAr;
  final String? descriptionEn;
  final LessonType type;
  final String? videoUrl;
  final String? videoProvider;
  final int videoDuration; // in seconds
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
  final bool isCompleted;
  final int? lastPosition; // video position in seconds

  const LessonEntity({
    required this.id,
    required this.sectionId,
    this.titleAr,
    this.titleEn,
    this.descriptionAr,
    this.descriptionEn,
    this.type = LessonType.video,
    this.videoUrl,
    this.videoProvider,
    this.videoDuration = 0,
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
    this.isCompleted = false,
    this.lastPosition,
  });

  String getTitle(String locale) =>
      locale == 'ar' ? (titleAr ?? titleEn ?? '') : (titleEn ?? titleAr ?? '');

  String getDescription(String locale) => locale == 'ar'
      ? (descriptionAr ?? descriptionEn ?? '')
      : (descriptionEn ?? descriptionAr ?? '');

  /// Format duration as "MM:SS" or "H:MM:SS"
  String get formattedDuration {
    final hours = videoDuration ~/ 3600;
    final minutes = (videoDuration % 3600) ~/ 60;
    final seconds = videoDuration % 60;
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

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
        isCompleted,
      ];
}
