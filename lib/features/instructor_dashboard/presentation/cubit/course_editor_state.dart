part of 'course_editor_cubit.dart';

/// Course Editor Status
enum CourseEditorStatus { initial, loading, success, error }

/// Course Editor State
class CourseEditorState extends Equatable {
  final CourseEditorStatus status;
  final String? courseId;
  final bool isEditing;
  final bool isOriginalPublished; // Track if original course was published
  final int currentStep;

  // Basic Info
  final String titleAr;
  final String titleEn;
  final String subtitleAr;
  final String subtitleEn;
  final String descriptionAr;
  final String descriptionEn;
  final String? thumbnailUrl;
  final String? previewVideoUrl;
  final String? categoryId;
  final String level;

  // Curriculum
  final List<SectionData> sections;

  // Pricing
  final double price;
  final double? discountPrice;
  final String currency;
  final String? badge;
  final bool isFlashSale;
  final DateTime? flashSaleStart;
  final DateTime? flashSaleEnd;
  final DateTime? availableFrom;
  final DateTime? availableUntil;

  // Settings
  final List<String> requirementsAr;
  final List<String> requirementsEn;
  final List<String> objectivesAr;
  final List<String> objectivesEn;

  // Attachments
  final List<CourseAttachmentData> attachments;

  // Categories for dropdown
  final List<CategoryOption> categories;

  final String? errorMessage;

  const CourseEditorState({
    this.status = CourseEditorStatus.initial,
    this.courseId,
    this.isEditing = false,
    this.isOriginalPublished = false,
    this.currentStep = 0,
    this.titleAr = '',
    this.titleEn = '',
    this.subtitleAr = '',
    this.subtitleEn = '',
    this.descriptionAr = '',
    this.descriptionEn = '',
    this.thumbnailUrl,
    this.previewVideoUrl,
    this.categoryId,
    this.level = 'beginner',
    this.sections = const [],
    this.price = 0,
    this.discountPrice,
    this.currency = 'EGP',
    this.badge,
    this.isFlashSale = false,
    this.flashSaleStart,
    this.flashSaleEnd,
    this.availableFrom,
    this.availableUntil,
    this.requirementsAr = const [],
    this.requirementsEn = const [],
    this.objectivesAr = const [],
    this.objectivesEn = const [],
    this.attachments = const [],
    this.categories = const [],
    this.errorMessage,
  });

  bool get isLoading => status == CourseEditorStatus.loading;

  bool get hasValidAvailabilityWindow =>
      availableFrom == null ||
      availableUntil == null ||
      availableUntil!.isAfter(availableFrom!);

  bool get canPublish =>
      titleAr.isNotEmpty &&
      titleEn.isNotEmpty &&
      descriptionAr.isNotEmpty &&
      descriptionEn.isNotEmpty &&
      categoryId != null &&
      hasValidAvailabilityWindow &&
      sections.isNotEmpty &&
      sections.every((s) => s.lessons.isNotEmpty);

  CourseEditorState copyWith({
    CourseEditorStatus? status,
    String? courseId,
    bool? isEditing,
    bool? isOriginalPublished,
    int? currentStep,
    String? titleAr,
    String? titleEn,
    String? subtitleAr,
    String? subtitleEn,
    String? descriptionAr,
    String? descriptionEn,
    String? thumbnailUrl,
    String? previewVideoUrl,
    String? categoryId,
    String? level,
    List<SectionData>? sections,
    double? price,
    double? discountPrice,
    bool clearDiscountPrice = false,
    String? currency,
    String? badge,
    bool clearBadge = false,
    bool? isFlashSale,
    DateTime? flashSaleStart,
    bool clearFlashSaleStart = false,
    DateTime? flashSaleEnd,
    bool clearFlashSaleEnd = false,
    DateTime? availableFrom,
    bool clearAvailableFrom = false,
    DateTime? availableUntil,
    bool clearAvailableUntil = false,
    List<String>? requirementsAr,
    List<String>? requirementsEn,
    List<String>? objectivesAr,
    List<String>? objectivesEn,
    List<CourseAttachmentData>? attachments,
    List<CategoryOption>? categories,
    String? errorMessage,
  }) {
    return CourseEditorState(
      status: status ?? this.status,
      courseId: courseId ?? this.courseId,
      isEditing: isEditing ?? this.isEditing,
      isOriginalPublished: isOriginalPublished ?? this.isOriginalPublished,
      currentStep: currentStep ?? this.currentStep,
      titleAr: titleAr ?? this.titleAr,
      titleEn: titleEn ?? this.titleEn,
      subtitleAr: subtitleAr ?? this.subtitleAr,
      subtitleEn: subtitleEn ?? this.subtitleEn,
      descriptionAr: descriptionAr ?? this.descriptionAr,
      descriptionEn: descriptionEn ?? this.descriptionEn,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      previewVideoUrl: previewVideoUrl ?? this.previewVideoUrl,
      categoryId: categoryId ?? this.categoryId,
      level: level ?? this.level,
      sections: sections ?? this.sections,
      price: price ?? this.price,
      discountPrice:
          clearDiscountPrice ? null : (discountPrice ?? this.discountPrice),
      currency: currency ?? this.currency,
      badge: clearBadge ? null : (badge ?? this.badge),
      isFlashSale: isFlashSale ?? this.isFlashSale,
      flashSaleStart:
          clearFlashSaleStart ? null : (flashSaleStart ?? this.flashSaleStart),
      flashSaleEnd:
          clearFlashSaleEnd ? null : (flashSaleEnd ?? this.flashSaleEnd),
      availableFrom:
          clearAvailableFrom ? null : (availableFrom ?? this.availableFrom),
      availableUntil: clearAvailableUntil
          ? null
          : (availableUntil ?? this.availableUntil),
      requirementsAr: requirementsAr ?? this.requirementsAr,
      requirementsEn: requirementsEn ?? this.requirementsEn,
      objectivesAr: objectivesAr ?? this.objectivesAr,
      objectivesEn: objectivesEn ?? this.objectivesEn,
      attachments: attachments ?? this.attachments,
      categories: categories ?? this.categories,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        courseId,
        isEditing,
        isOriginalPublished,
        currentStep,
        titleAr,
        titleEn,
        subtitleAr,
        subtitleEn,
        descriptionAr,
        descriptionEn,
        thumbnailUrl,
        previewVideoUrl,
        categoryId,
        level,
        sections,
        price,
        discountPrice,
        currency,
        currency,
        badge,
        isFlashSale,
        flashSaleStart,
        flashSaleEnd,
        availableFrom,
        availableUntil,
        requirementsAr,
        requirementsEn,
        objectivesAr,
        objectivesEn,
        attachments,
        categories,
        errorMessage,
      ];
}

/// Section Data
class SectionData extends Equatable {
  final String? id;
  final String titleAr;
  final String titleEn;
  final int order;
  final bool isPublished;
  final List<LessonData> lessons;

  const SectionData({
    this.id,
    required this.titleAr,
    required this.titleEn,
    required this.order,
    this.isPublished = true,
    this.lessons = const [],
  });

  SectionData copyWith({
    String? id,
    String? titleAr,
    String? titleEn,
    int? order,
    bool? isPublished,
    List<LessonData>? lessons,
  }) {
    return SectionData(
      id: id ?? this.id,
      titleAr: titleAr ?? this.titleAr,
      titleEn: titleEn ?? this.titleEn,
      order: order ?? this.order,
      isPublished: isPublished ?? this.isPublished,
      lessons: lessons ?? this.lessons,
    );
  }

  @override
  List<Object?> get props =>
      [id, titleAr, titleEn, order, isPublished, lessons];
}

/// Lesson Data
class LessonData extends Equatable {
  final String? id;
  final String titleAr;
  final String titleEn;
  final String type; // video only
  final int order;
  final int durationMinutes;
  final bool isFree;
  final bool isPublished;
  final DateTime? availableFrom;
  final DateTime? availableUntil;
  final String? videoUrl;
  final String? articleContent;
  final String? fileUrl;
  final String? fileName;
  final int? fileSize;
  final String? fileType;
  final String? quizId;

  const LessonData({
    this.id,
    required this.titleAr,
    required this.titleEn,
    required this.type,
    required this.order,
    this.durationMinutes = 0,
    this.isFree = false,
    this.isPublished = true,
    this.availableFrom,
    this.availableUntil,
    this.videoUrl,
    this.articleContent,
    this.fileUrl,
    this.fileName,
    this.fileSize,
    this.fileType,
    this.quizId,
  });

  LessonData copyWith({
    String? id,
    String? titleAr,
    String? titleEn,
    String? type,
    int? order,
    int? durationMinutes,
    bool? isFree,
    bool? isPublished,
    DateTime? availableFrom,
    bool clearAvailableFrom = false,
    DateTime? availableUntil,
    bool clearAvailableUntil = false,
    String? videoUrl,
    String? articleContent,
    String? fileUrl,
    String? fileName,
    int? fileSize,
    String? fileType,
    String? quizId,
  }) {
    return LessonData(
      id: id ?? this.id,
      titleAr: titleAr ?? this.titleAr,
      titleEn: titleEn ?? this.titleEn,
      type: type ?? this.type,
      order: order ?? this.order,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      isFree: isFree ?? this.isFree,
      isPublished: isPublished ?? this.isPublished,
      availableFrom:
          clearAvailableFrom ? null : (availableFrom ?? this.availableFrom),
      availableUntil: clearAvailableUntil
          ? null
          : (availableUntil ?? this.availableUntil),
      videoUrl: videoUrl ?? this.videoUrl,
      articleContent: articleContent ?? this.articleContent,
      fileUrl: fileUrl ?? this.fileUrl,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      fileType: fileType ?? this.fileType,
      quizId: quizId ?? this.quizId,
    );
  }

  @override
  List<Object?> get props => [
        id,
        titleAr,
        titleEn,
        type,
        order,
        durationMinutes,
        isFree,
        isPublished,
        availableFrom,
        availableUntil,
        videoUrl,
        articleContent,
        fileUrl,
        fileName,
        fileSize,
        fileType,
        quizId,
      ];
}

/// Course Attachment Data - for course-level attachments
class CourseAttachmentData extends Equatable {
  final String? id;
  final String fileName;
  final String? fileNameAr;
  final String? fileUrl;
  final String? filePath; // Local path for upload
  final String fileType;
  final int fileSize;
  final int order;

  const CourseAttachmentData({
    this.id,
    required this.fileName,
    this.fileNameAr,
    this.fileUrl,
    this.filePath,
    required this.fileType,
    required this.fileSize,
    this.order = 0,
  });

  CourseAttachmentData copyWith({
    String? id,
    String? fileName,
    String? fileNameAr,
    String? fileUrl,
    String? filePath,
    String? fileType,
    int? fileSize,
    int? order,
  }) {
    return CourseAttachmentData(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      fileNameAr: fileNameAr ?? this.fileNameAr,
      fileUrl: fileUrl ?? this.fileUrl,
      filePath: filePath ?? this.filePath,
      fileType: fileType ?? this.fileType,
      fileSize: fileSize ?? this.fileSize,
      order: order ?? this.order,
    );
  }

  @override
  List<Object?> get props => [
        id,
        fileName,
        fileNameAr,
        fileUrl,
        filePath,
        fileType,
        fileSize,
        order,
      ];
}
