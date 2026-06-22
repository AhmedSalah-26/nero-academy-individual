import '../../domain/entities/lesson_entity.dart';

/// Lesson Model - Data Model with JSON serialization
class LessonModel extends LessonEntity {
  const LessonModel({
    required super.id,
    required super.sectionId,
    required super.titleAr,
    super.titleEn,
    super.descriptionAr,
    super.descriptionEn,
    required super.type,
    super.videoUrl,
    super.videoProvider,
    super.videoDuration,
    super.articleContentAr,
    super.articleContentEn,
    super.fileUrl,
    super.fileName,
    super.fileSize,
    super.fileType,
    super.isPreview,
    super.isMandatory,
    super.isPublished,
    super.sortOrder,
    super.availableFrom,
    super.availableUntil,
    super.createdAt,
  });

  /// Create from JSON
  factory LessonModel.fromJson(Map<String, dynamic> json) {
    return LessonModel(
      id: json['id'] as String,
      sectionId: json['section_id'] as String,
      titleAr: json['title_ar'] as String,
      titleEn: json['title_en'] as String?,
      descriptionAr: json['description_ar'] as String?,
      descriptionEn: json['description_en'] as String?,
      type: _parseType(json['type'] as String?),
      videoUrl: json['video_url'] as String?,
      videoProvider: _parseProvider(json['video_provider'] as String?),
      videoDuration: json['video_duration'] as int?,
      articleContentAr: json['article_content_ar'] as String?,
      articleContentEn: json['article_content_en'] as String?,
      fileUrl: json['file_url'] as String?,
      fileName: json['file_name'] as String?,
      fileSize: json['file_size'] as int?,
      fileType: json['file_type'] as String?,
      isPreview: json['is_preview'] as bool? ?? false,
      isMandatory: json['is_mandatory'] as bool? ?? true,
      isPublished: json['is_published'] as bool? ?? true,
      sortOrder: json['sort_order'] as int? ?? 0,
      availableFrom: json['available_from'] != null
          ? DateTime.parse(json['available_from'] as String)
          : null,
      availableUntil: json['available_until'] != null
          ? DateTime.parse(json['available_until'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'section_id': sectionId,
      'title_ar': titleAr,
      'title_en': titleEn,
      'description_ar': descriptionAr,
      'description_en': descriptionEn,
      'type': type.name,
      'video_url': videoUrl,
      'video_provider': videoProvider?.name,
      'video_duration': videoDuration,
      'article_content_ar': articleContentAr,
      'article_content_en': articleContentEn,
      'file_url': fileUrl,
      'file_name': fileName,
      'file_size': fileSize,
      'file_type': fileType,
      'is_preview': isPreview,
      'is_mandatory': isMandatory,
      'is_published': isPublished,
      'sort_order': sortOrder,
      'available_from': availableFrom?.toIso8601String(),
      'available_until': availableUntil?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
    };
  }

  static LessonType _parseType(String? type) {
    switch (type) {
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
      case 'file':
        return LessonType.document;
      default:
        return LessonType.video;
    }
  }

  static VideoProvider? _parseProvider(String? provider) {
    switch (provider) {
      case 'supabase':
        return VideoProvider.supabase;
      case 'youtube':
        return VideoProvider.youtube;
      case 'vimeo':
        return VideoProvider.vimeo;
      case 'bunny':
        return VideoProvider.bunny;
      default:
        return null;
    }
  }
}
