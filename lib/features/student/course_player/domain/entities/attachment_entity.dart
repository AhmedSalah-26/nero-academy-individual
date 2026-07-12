import 'package:equatable/equatable.dart';

/// Attachment Entity - Pure Dart Object
class AttachmentEntity extends Equatable {
  final String id;
  final String? lessonId; // Can be null for course-level attachments
  final String fileName;
  final String? fileNameAr;
  final String fileUrl;
  final String fileType;
  final int fileSize;
  final int sortOrder;
  final DateTime? createdAt;

  const AttachmentEntity({
    required this.id,
    this.lessonId,
    required this.fileName,
    this.fileNameAr,
    required this.fileUrl,
    required this.fileType,
    required this.fileSize,
    this.sortOrder = 0,
    this.createdAt,
  });

  /// Get localized file name
  String getFileName(String locale) {
    if (locale == 'ar' && fileNameAr != null && fileNameAr!.isNotEmpty) {
      return fileNameAr!;
    }
    return fileName;
  }

  /// Get formatted file size (e.g., "2.5 MB")
  String get formattedFileSize {
    if (fileSize < 1024) {
      return '$fileSize B';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  /// Get file type icon
  String get fileIcon {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return 'picture_as_pdf';
      case 'doc':
      case 'docx':
        return 'description';
      case 'xls':
      case 'xlsx':
        return 'table_chart';
      case 'ppt':
      case 'pptx':
        return 'slideshow';
      case 'zip':
      case 'rar':
        return 'folder_zip';
      case 'mp3':
      case 'wav':
        return 'audio_file';
      case 'mp4':
      case 'mov':
        return 'video_file';
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return 'image';
      default:
        return 'insert_drive_file';
    }
  }

  @override
  List<Object?> get props => [
        id,
        lessonId,
        fileName,
        fileUrl,
        fileType,
        fileSize,
        sortOrder,
      ];
}
