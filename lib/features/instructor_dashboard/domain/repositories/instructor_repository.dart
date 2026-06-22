import '../entities/instructor_entities.dart';
import '../../data/models/instructor_models.dart';
import '../../data/models/instructor_balance_model.dart';

/// Instructor Repository Interface
abstract class InstructorRepository {
  // Dashboard
  Future<InstructorDashboardStats> getDashboardStats();
  Future<List<ChartDataPoint>> getRevenueChart(DateTime start, DateTime end);
  Future<List<ChartDataPoint>> getEnrollmentsChart(
      DateTime start, DateTime end);

  // Courses
  Future<List<InstructorCourseModel>> getMyCourses({
    InstructorCourseStatus? status,
    int page = 1,
    int limit = 20,
  });
  Future<bool> publishCourse(String courseId);
  Future<bool> unpublishCourse(String courseId);

  // Course Editor
  Future<List<CategoryOption>> getCategories();
  Future<CourseDetails?> getCourseForEdit(String courseId);
  Future<String> createCourse(CourseCreateDto dto);
  Future<bool> updateCourse(String courseId, CourseUpdateDto dto);
  Future<bool> saveSectionsAndLessons(
      String courseId, List<SectionDto> sections);

  // Course Attachments Management
  Future<String> addCourseAttachment({
    required String courseId,
    required String fileName,
    required String fileUrl,
    required String fileType,
    required int fileSize,
    required int sortOrder,
  });
  Future<bool> deleteAllCourseAttachments(String courseId);
  Future<List<AttachmentDto>> getCourseAttachments(String courseId);

  // Section Management (Independent CRUD)
  Future<String> createSection(String courseId, SectionCreateDto dto);
  Future<bool> updateSection(String sectionId, SectionUpdateDto dto);
  Future<bool> deleteSection(String sectionId);
  Future<bool> reorderSections(String courseId, List<String> sectionIds);
  Future<bool> toggleSectionPublished(String sectionId);
  Future<void> scheduleSectionPublish(
    String sectionId, {
    DateTime? publishAt,
    DateTime? unpublishAt,
  });

  // Lesson Management (Independent CRUD)
  Future<String> createLesson(
      String sectionId, String courseId, LessonCreateDto dto);
  Future<bool> updateLesson(String lessonId, LessonUpdateDto dto);
  Future<bool> deleteLesson(String lessonId);
  Future<bool> reorderLessons(String sectionId, List<String> lessonIds);
  Future<bool> toggleLessonPublished(String lessonId);
  Future<void> scheduleLessonPublish(
    String lessonId, {
    DateTime? publishAt,
    DateTime? unpublishAt,
  });

  // Students
  Future<List<InstructorStudentModel>> getStudents({
    String? courseId,
    String? search,
    int page = 1,
    int limit = 20,
  });

  // Student Details
  Future<List<StudentEnrollmentDetail>> getStudentEnrollments(String studentId);
  Future<List<StudentCourseProgress>> getStudentProgress(String studentId);
  Future<bool> sendMessageToStudent(
      String studentId, String subject, String message);

  // Enrollment Management
  Future<bool> extendEnrollmentAccess(String enrollmentId, int days);
  Future<bool> resetEnrollmentProgress(String enrollmentId);
  Future<bool> updateEnrollmentStatus(String enrollmentId, String status);
  Future<bool> markAsCompleted(String enrollmentId);
  Future<bool> enrollStudent(String studentId, String courseId);
  Future<bool> unenrollStudent(String enrollmentId);
  Future<List<AvailableCourseForEnrollment>> getAvailableCoursesForStudent(
      String studentId);

  // Enrollments
  Future<List<InstructorEnrollmentModel>> getEnrollments({
    InstructorEnrollmentStatus? status,
    String? courseId,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int limit = 20,
  });

  // Wallet & Earnings (NEW SCHEMA)
  Future<WalletSummaryModel> getWalletSummary();
  Future<List<EarningsTransactionModel>> getTransactions({
    String? courseId,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int limit = 20,
  });
  Future<List<WithdrawRequestModel>> getWithdrawHistory(
      {int page = 1, int limit = 20});
  Future<Map<String, dynamic>> submitWithdrawRequest({
    required double amount,
    required String method,
    required Map<String, String> accountDetails,
  });

  // Q&A
  Future<List<InstructorQuestionModel>> getQuestions({
    QAStatus? status,
    String? courseId,
    int page = 1,
    int limit = 20,
  });
  Future<bool> answerQuestion(String questionId, String answer);

  // Reviews
  Future<List<InstructorReviewModel>> getReviews({
    String? courseId,
    int? minRating,
    int? maxRating,
    int page = 1,
    int limit = 20,
  });
  Future<bool> replyToReview(String reviewId, String reply);

  // Course Management (extended)
  Future<bool> deleteCourse(String courseId);

  // Q&A Management (extended)
  Future<bool> updateAnswer(String answerId, String newContent);
  Future<bool> deleteAnswer(String answerId);
  Future<bool> hideQuestion(String questionId);
  Future<bool> pinQuestion(String questionId, bool isPinned);

  // Announcements
  Future<List<Map<String, dynamic>>> getAnnouncements({
    required String courseId,
    int page = 1,
    int limit = 20,
  });
  Future<List<Map<String, dynamic>>> getAnnouncementCourses();
  Future<bool> createAnnouncement({
    required String courseId,
    required String titleAr,
    String? titleEn,
    String? contentAr,
    String? contentEn,
  });
  Future<bool> updateAnnouncement(
      String announcementId, Map<String, dynamic> data);
  Future<bool> deleteAnnouncement(String announcementId);

  // Categories (Merged from Admin)
  Future<List<CategoryModel>> getAdminCategories({bool? isActive});
  Future<CategoryModel> createCategory(CategoryCreateDto dto);
  Future<CategoryModel> updateCategory(String id, CategoryUpdateDto dto);
  Future<bool> toggleCategoryStatus(String id);

  // Banners (Merged from Admin)
  Future<List<BannerModel>> getBanners({BannerType? type, bool? isActive});
  Future<BannerModel> createBanner(BannerCreateDto dto);
  Future<BannerModel> updateBanner(String id, BannerUpdateDto dto);
  Future<bool> deleteBanner(String id);
  Future<bool> toggleBannerStatus(String id);
}

/// Chart Data Point
class ChartDataPoint {
  final String label;
  final double value;

  const ChartDataPoint({required this.label, required this.value});

  factory ChartDataPoint.fromJson(Map<String, dynamic> json) {
    return ChartDataPoint(
      label: json['label'] as String? ?? '',
      value: (json['value'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// Category Option for course editor
class CategoryOption {
  final String id;
  final String nameAr;
  final String nameEn;

  const CategoryOption({
    required this.id,
    required this.nameAr,
    required this.nameEn,
  });
}

/// Course Details for editing
class CourseDetails {
  final String id;
  final String titleAr;
  final String titleEn;
  final String? subtitleAr;
  final String? subtitleEn;
  final String? descriptionAr;
  final String? descriptionEn;
  final String? thumbnailUrl;
  final String? previewVideoUrl;
  final String? categoryId;
  final String level;
  final double price;
  final double? discountPrice;
  final String currency;
  final bool isPublished;
  final String? badge;
  final bool isFlashSale;
  final DateTime? flashSaleStart;
  final DateTime? flashSaleEnd;
  final DateTime? availableFrom;
  final DateTime? availableUntil;
  final List<SectionDto> sections;

  const CourseDetails({
    required this.id,
    required this.titleAr,
    required this.titleEn,
    this.subtitleAr,
    this.subtitleEn,
    this.descriptionAr,
    this.descriptionEn,
    this.thumbnailUrl,
    this.previewVideoUrl,
    this.categoryId,
    this.level = 'beginner',
    this.price = 0,
    this.discountPrice,
    this.currency = 'EGP',
    this.isPublished = false,
    this.badge,
    this.isFlashSale = false,
    this.flashSaleStart,
    this.flashSaleEnd,
    this.availableFrom,
    this.availableUntil,
    this.sections = const [],
  });
}

/// Course Create DTO
class CourseCreateDto {
  final String titleAr;
  final String titleEn;
  final String? subtitleAr;
  final String? subtitleEn;
  final String? descriptionAr;
  final String? descriptionEn;
  final String? thumbnailUrl;
  final String? previewVideoUrl;
  final String? categoryId;
  final String level;
  final double price;
  final double? discountPrice;
  final String currency;
  final bool isPublished;
  final String? badge;
  final bool isFlashSale;
  final DateTime? flashSaleStart;
  final DateTime? flashSaleEnd;
  final DateTime? availableFrom;
  final DateTime? availableUntil;

  const CourseCreateDto({
    required this.titleAr,
    required this.titleEn,
    this.subtitleAr,
    this.subtitleEn,
    this.descriptionAr,
    this.descriptionEn,
    this.thumbnailUrl,
    this.previewVideoUrl,
    this.categoryId,
    this.level = 'beginner',
    this.price = 0,
    this.discountPrice,
    this.currency = 'EGP',
    this.isPublished = false,
    this.badge,
    this.isFlashSale = false,
    this.flashSaleStart,
    this.flashSaleEnd,
    this.availableFrom,
    this.availableUntil,
  });

  Map<String, dynamic> toJson() => {
        'title_ar': titleAr,
        'title_en': titleEn,
        'subtitle_ar': subtitleAr,
        'subtitle_en': subtitleEn,
        'description_ar': descriptionAr,
        'description_en': descriptionEn,
        'thumbnail_url': thumbnailUrl,
        'preview_video_url': previewVideoUrl,
        'category_id': categoryId,
        'level': level,
        'price': price,
        'discount_price': discountPrice,
        'currency': currency,
        'is_published': isPublished,
        if (badge != null) 'badge': badge,
        'is_flash_sale': isFlashSale,
        if (flashSaleStart != null)
          'flash_sale_start': flashSaleStart!.toIso8601String(),
        if (flashSaleEnd != null)
          'flash_sale_end': flashSaleEnd!.toIso8601String(),
        'available_from': availableFrom?.toIso8601String(),
        'available_until': availableUntil?.toIso8601String(),
      };
}

/// Course Update DTO
class CourseUpdateDto {
  final String? titleAr;
  final String? titleEn;
  final String? subtitleAr;
  final String? subtitleEn;
  final String? descriptionAr;
  final String? descriptionEn;
  final String? thumbnailUrl;
  final String? previewVideoUrl;
  final String? categoryId;
  final String? level;
  final double? price;
  final double? discountPrice;
  final String? currency;
  final bool? isPublished;
  final String? badge;
  final bool? isFlashSale;
  final DateTime? flashSaleStart;
  final DateTime? flashSaleEnd;
  final DateTime? availableFrom;
  final DateTime? availableUntil;
  final bool clearDiscountPrice;
  final bool clearBadge;
  final bool clearFlashSaleData;
  final bool clearAvailabilityWindow;

  const CourseUpdateDto({
    this.titleAr,
    this.titleEn,
    this.subtitleAr,
    this.subtitleEn,
    this.descriptionAr,
    this.descriptionEn,
    this.thumbnailUrl,
    this.previewVideoUrl,
    this.categoryId,
    this.level,
    this.price,
    this.discountPrice,
    this.currency,
    this.isPublished,
    this.badge,
    this.isFlashSale,
    this.flashSaleStart,
    this.flashSaleEnd,
    this.availableFrom,
    this.availableUntil,
    this.clearDiscountPrice = false,
    this.clearBadge = false,
    this.clearFlashSaleData = false,
    this.clearAvailabilityWindow = false,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (titleAr != null) map['title_ar'] = titleAr;
    if (titleEn != null) map['title_en'] = titleEn;
    if (subtitleAr != null) map['subtitle_ar'] = subtitleAr;
    if (subtitleEn != null) map['subtitle_en'] = subtitleEn;
    if (descriptionAr != null) map['description_ar'] = descriptionAr;
    if (descriptionEn != null) map['description_en'] = descriptionEn;
    if (thumbnailUrl != null) map['thumbnail_url'] = thumbnailUrl;
    if (previewVideoUrl != null) map['preview_video_url'] = previewVideoUrl;
    if (categoryId != null) map['category_id'] = categoryId;
    if (level != null) map['level'] = level;
    if (price != null) map['price'] = price;
    if (clearDiscountPrice) {
      map['discount_price'] = null;
    } else if (discountPrice != null) {
      map['discount_price'] = discountPrice;
    }
    if (currency != null) map['currency'] = currency;
    if (isPublished != null) map['is_published'] = isPublished;
    if (clearBadge) {
      map['badge'] = null;
    } else if (badge != null) {
      map['badge'] = badge;
    }
    if (isFlashSale != null) map['is_flash_sale'] = isFlashSale;
    if (clearFlashSaleData) {
      map['flash_sale_start'] = null;
      map['flash_sale_end'] = null;
    } else {
      if (flashSaleStart != null) {
        map['flash_sale_start'] = flashSaleStart!.toIso8601String();
      }
      if (flashSaleEnd != null) {
        map['flash_sale_end'] = flashSaleEnd!.toIso8601String();
      }
    }
    if (clearAvailabilityWindow) {
      map['available_from'] = null;
      map['available_until'] = null;
    } else {
      if (availableFrom != null) {
        map['available_from'] = availableFrom!.toIso8601String();
      }
      if (availableUntil != null) {
        map['available_until'] = availableUntil!.toIso8601String();
      }
    }
    return map;
  }
}

/// Section DTO
class SectionDto {
  final String? id;
  final String titleAr;
  final String titleEn;
  final int order;
  final bool isPublished;
  final List<LessonDto> lessons;

  const SectionDto({
    this.id,
    required this.titleAr,
    required this.titleEn,
    required this.order,
    this.isPublished = true,
    this.lessons = const [],
  });
}

/// Lesson DTO
class LessonDto {
  final String? id;
  final String titleAr;
  final String titleEn;
  final String type;
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

  const LessonDto({
    this.id,
    required this.titleAr,
    required this.titleEn,
    this.type = 'video',
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
  });
}

// ============ INDEPENDENT CRUD DTOs ============

/// Section Create DTO - for creating a single section
class SectionCreateDto {
  final String titleAr;
  final String titleEn;
  final String? descriptionAr;
  final String? descriptionEn;
  final int? sortOrder;

  const SectionCreateDto({
    required this.titleAr,
    required this.titleEn,
    this.descriptionAr,
    this.descriptionEn,
    this.sortOrder,
  });

  Map<String, dynamic> toJson() => {
        'title_ar': titleAr,
        'title_en': titleEn,
        if (descriptionAr != null) 'description_ar': descriptionAr,
        if (descriptionEn != null) 'description_en': descriptionEn,
        if (sortOrder != null) 'sort_order': sortOrder,
      };
}

/// Section Update DTO - for updating a single section
class SectionUpdateDto {
  final String? titleAr;
  final String? titleEn;
  final String? descriptionAr;
  final String? descriptionEn;
  final int? sortOrder;
  final bool? isPublished;

  const SectionUpdateDto({
    this.titleAr,
    this.titleEn,
    this.descriptionAr,
    this.descriptionEn,
    this.sortOrder,
    this.isPublished,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (titleAr != null) map['title_ar'] = titleAr;
    if (titleEn != null) map['title_en'] = titleEn;
    if (descriptionAr != null) map['description_ar'] = descriptionAr;
    if (descriptionEn != null) map['description_en'] = descriptionEn;
    if (sortOrder != null) map['sort_order'] = sortOrder;
    if (isPublished != null) map['is_published'] = isPublished;
    return map;
  }
}

/// Lesson Create DTO - for creating a single lesson
class LessonCreateDto {
  final String titleAr;
  final String titleEn;
  final String? descriptionAr;
  final String? descriptionEn;
  final String type;
  final int? sortOrder;
  final String? videoUrl;
  final String? videoProvider;
  final int? videoDuration;
  final String? articleContentAr;
  final String? articleContentEn;
  final String? fileUrl;
  final String? fileName;
  final int? fileSize;
  final String? fileType;
  final bool isPreview;
  final bool isPublished;
  final DateTime? availableFrom;
  final DateTime? availableUntil;
  final bool isMandatory;

  const LessonCreateDto({
    required this.titleAr,
    required this.titleEn,
    this.descriptionAr,
    this.descriptionEn,
    this.type = 'video',
    this.sortOrder,
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
    this.isPublished = true,
    this.availableFrom,
    this.availableUntil,
    this.isMandatory = true,
  });

  Map<String, dynamic> toJson() => {
        'title_ar': titleAr,
        'title_en': titleEn,
        if (descriptionAr != null) 'description_ar': descriptionAr,
        if (descriptionEn != null) 'description_en': descriptionEn,
        'type': type,
        if (sortOrder != null) 'sort_order': sortOrder,
        if (videoUrl != null) 'video_url': videoUrl,
        if (videoProvider != null) 'video_provider': videoProvider,
        if (videoDuration != null) 'video_duration': videoDuration,
        if (articleContentAr != null) 'article_content_ar': articleContentAr,
        if (articleContentEn != null) 'article_content_en': articleContentEn,
        if (fileUrl != null) 'file_url': fileUrl,
        if (fileName != null) 'file_name': fileName,
        if (fileSize != null) 'file_size': fileSize,
        if (fileType != null) 'file_type': fileType,
        'is_preview': isPreview,
        'is_published': isPublished,
        'available_from': availableFrom?.toIso8601String(),
        'available_until': availableUntil?.toIso8601String(),
        'is_mandatory': isMandatory,
      };
}

/// Lesson Update DTO - for updating a single lesson
class LessonUpdateDto {
  final String? titleAr;
  final String? titleEn;
  final String? descriptionAr;
  final String? descriptionEn;
  final String? type;
  final int? sortOrder;
  final String? videoUrl;
  final String? videoProvider;
  final int? videoDuration;
  final String? articleContentAr;
  final String? articleContentEn;
  final String? fileUrl;
  final String? fileName;
  final int? fileSize;
  final String? fileType;
  final bool? isPreview;
  final bool? isPublished;
  final DateTime? availableFrom;
  final DateTime? availableUntil;
  final bool clearAvailabilityWindow;
  final bool? isMandatory;

  const LessonUpdateDto({
    this.titleAr,
    this.titleEn,
    this.descriptionAr,
    this.descriptionEn,
    this.type,
    this.sortOrder,
    this.videoUrl,
    this.videoProvider,
    this.videoDuration,
    this.articleContentAr,
    this.articleContentEn,
    this.fileUrl,
    this.fileName,
    this.fileSize,
    this.fileType,
    this.isPreview,
    this.isPublished,
    this.availableFrom,
    this.availableUntil,
    this.clearAvailabilityWindow = false,
    this.isMandatory,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (titleAr != null) map['title_ar'] = titleAr;
    if (titleEn != null) map['title_en'] = titleEn;
    if (descriptionAr != null) map['description_ar'] = descriptionAr;
    if (descriptionEn != null) map['description_en'] = descriptionEn;
    if (type != null) map['type'] = type;
    if (sortOrder != null) map['sort_order'] = sortOrder;
    if (videoUrl != null) map['video_url'] = videoUrl;
    if (videoProvider != null) map['video_provider'] = videoProvider;
    if (videoDuration != null) map['video_duration'] = videoDuration;
    if (articleContentAr != null) map['article_content_ar'] = articleContentAr;
    if (articleContentEn != null) map['article_content_en'] = articleContentEn;
    if (fileUrl != null) map['file_url'] = fileUrl;
    if (fileName != null) map['file_name'] = fileName;
    if (fileSize != null) map['file_size'] = fileSize;
    if (fileType != null) map['file_type'] = fileType;
    if (isPreview != null) map['is_preview'] = isPreview;
    if (isPublished != null) map['is_published'] = isPublished;
    if (clearAvailabilityWindow) {
      map['available_from'] = null;
      map['available_until'] = null;
    } else {
      if (availableFrom != null) {
        map['available_from'] = availableFrom!.toIso8601String();
      }
      if (availableUntil != null) {
        map['available_until'] = availableUntil!.toIso8601String();
      }
    }
    if (isMandatory != null) map['is_mandatory'] = isMandatory;
    return map;
  }
}

// ============ STUDENT DETAIL MODELS ============

/// Available Course for Enrollment - courses student is NOT enrolled in
class AvailableCourseForEnrollment {
  final String id;
  final String titleAr;
  final String titleEn;
  final String? thumbnailUrl;

  const AvailableCourseForEnrollment({
    required this.id,
    required this.titleAr,
    required this.titleEn,
    this.thumbnailUrl,
  });

  factory AvailableCourseForEnrollment.fromJson(Map<String, dynamic> json) {
    return AvailableCourseForEnrollment(
      id: json['id'] as String,
      titleAr: json['title_ar'] as String? ?? '',
      titleEn: json['title_en'] as String? ?? '',
      thumbnailUrl: json['thumbnail_url'] as String?,
    );
  }
}

/// Student Enrollment Detail - shows enrollment info for a specific course
class StudentEnrollmentDetail {
  final String enrollmentId;
  final String courseId;
  final String courseTitleAr;
  final String courseTitleEn;
  final String? courseThumbnail;
  final double progressPercentage;
  final int completedLessons;
  final int totalLessons;
  final String status;
  final DateTime enrolledAt;
  final DateTime? lastAccessedAt;
  final DateTime? completedAt;

  const StudentEnrollmentDetail({
    required this.enrollmentId,
    required this.courseId,
    required this.courseTitleAr,
    required this.courseTitleEn,
    this.courseThumbnail,
    required this.progressPercentage,
    required this.completedLessons,
    required this.totalLessons,
    required this.status,
    required this.enrolledAt,
    this.lastAccessedAt,
    this.completedAt,
  });

  factory StudentEnrollmentDetail.fromJson(Map<String, dynamic> json) {
    return StudentEnrollmentDetail(
      enrollmentId: json['id'] as String,
      courseId: json['course_id'] as String,
      courseTitleAr: json['course']?['title_ar'] as String? ?? '',
      courseTitleEn: json['course']?['title_en'] as String? ?? '',
      courseThumbnail: json['course']?['thumbnail_url'] as String?,
      progressPercentage:
          (json['progress_percentage'] as num?)?.toDouble() ?? 0,
      completedLessons: json['completed_lessons'] as int? ?? 0,
      totalLessons: json['course']?['total_lessons'] as int? ?? 0,
      status: json['status'] as String? ?? 'active',
      enrolledAt: DateTime.parse(json['enrolled_at'] as String),
      lastAccessedAt: json['last_accessed_at'] != null
          ? DateTime.parse(json['last_accessed_at'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
    );
  }
}

/// Student Course Progress - detailed progress per lesson
class StudentCourseProgress {
  final String courseId;
  final String courseTitleAr;
  final String courseTitleEn;
  final double overallProgress;
  final List<StudentLessonProgress> lessons;

  const StudentCourseProgress({
    required this.courseId,
    required this.courseTitleAr,
    required this.courseTitleEn,
    required this.overallProgress,
    required this.lessons,
  });

  factory StudentCourseProgress.fromJson(Map<String, dynamic> json) {
    return StudentCourseProgress(
      courseId: json['course_id'] as String,
      courseTitleAr: json['title_ar'] as String? ?? '',
      courseTitleEn: json['title_en'] as String? ?? '',
      overallProgress: (json['progress'] as num?)?.toDouble() ?? 0,
      lessons: (json['lessons'] as List<dynamic>?)
              ?.map((e) =>
                  StudentLessonProgress.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// Student Lesson Progress
class StudentLessonProgress {
  final String lessonId;
  final String titleAr;
  final String titleEn;
  final String type;
  final bool isCompleted;
  final int watchTimeSeconds;
  final DateTime? completedAt;

  const StudentLessonProgress({
    required this.lessonId,
    required this.titleAr,
    required this.titleEn,
    required this.type,
    required this.isCompleted,
    required this.watchTimeSeconds,
    this.completedAt,
  });

  factory StudentLessonProgress.fromJson(Map<String, dynamic> json) {
    return StudentLessonProgress(
      lessonId: json['lesson_id'] as String,
      titleAr: json['title_ar'] as String? ?? '',
      titleEn: json['title_en'] as String? ?? '',
      type: json['type'] as String? ?? 'video',
      isCompleted: json['is_completed'] as bool? ?? false,
      watchTimeSeconds: json['watch_time'] as int? ?? 0,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
    );
  }
}

/// Attachment DTO - for course attachments
class AttachmentDto {
  final String? id;
  final String fileName;
  final String fileUrl;
  final String fileType;
  final int fileSize;
  final int sortOrder;

  const AttachmentDto({
    this.id,
    required this.fileName,
    required this.fileUrl,
    required this.fileType,
    required this.fileSize,
    required this.sortOrder,
  });
}

// ============ QUIZ RESPONSE MODELS ============

/// Quiz Answer Detail - for viewing quiz responses
class QuizAnswerDetail {
  final String questionId;
  final String questionTextAr;
  final String questionTextEn;
  final String? imageUrl;
  final List<QuizOptionDetail> options;
  final String? selectedOptionId;
  final String correctOptionId;
  final bool isCorrect;
  final String? explanation;

  const QuizAnswerDetail({
    required this.questionId,
    required this.questionTextAr,
    required this.questionTextEn,
    this.imageUrl,
    required this.options,
    this.selectedOptionId,
    required this.correctOptionId,
    required this.isCorrect,
    this.explanation,
  });
}

/// Quiz Option Detail - for quiz answer options
class QuizOptionDetail {
  final String id;
  final String textAr;
  final String textEn;
  final bool? isCorrect;

  const QuizOptionDetail({
    required this.id,
    required this.textAr,
    required this.textEn,
    this.isCorrect,
  });
}

// ============ CATEGORIES & BANNERS DTOs ============

class CategoryCreateDto {
  final String nameAr;
  final String? nameEn;
  final String? description;
  final String? icon;
  final String? parentId;

  const CategoryCreateDto({
    required this.nameAr,
    this.nameEn,
    this.description,
    this.icon,
    this.parentId,
  });
}

class CategoryUpdateDto {
  final String? nameAr;
  final String? nameEn;
  final String? description;
  final String? icon;
  final String? parentId;
  final bool? isActive;
  final int? sortOrder;

  const CategoryUpdateDto({
    this.nameAr,
    this.nameEn,
    this.description,
    this.icon,
    this.parentId,
    this.isActive,
    this.sortOrder,
  });
}

class BannerCreateDto {
  final String titleAr;
  final String? titleEn;
  final String? subtitleAr;
  final String? subtitleEn;
  final String imageUrl;
  final String linkType;
  final String? linkValue;
  final int sortOrder;
  final DateTime? startDate;
  final DateTime? endDate;

  const BannerCreateDto({
    required this.titleAr,
    this.titleEn,
    this.subtitleAr,
    this.subtitleEn,
    required this.imageUrl,
    this.linkType = 'none',
    this.linkValue,
    this.sortOrder = 0,
    this.startDate,
    this.endDate,
  });

  Map<String, dynamic> toJson() => {
        'title_ar': titleAr,
        'title_en': titleEn,
        'subtitle_ar': subtitleAr,
        'subtitle_en': subtitleEn,
        'image_url': imageUrl,
        'link_type': linkType,
        'link_value': linkValue,
        'sort_order': sortOrder,
        'start_date': startDate?.toUtc().toIso8601String(),
        'end_date': endDate?.toUtc().toIso8601String(),
      };

  String? validate() {
    if (titleAr.isEmpty) return 'Arabic title is required';
    if (imageUrl.isEmpty) return 'Image URL is required';
    if (linkType != 'none' && (linkValue == null || linkValue!.isEmpty)) {
      return 'Link value is required when link type is set';
    }
    if (endDate != null && startDate != null && endDate!.isBefore(startDate!)) {
      return 'End date must be after start date';
    }
    return null;
  }
}

class BannerUpdateDto {
  final String? titleAr;
  final String? titleEn;
  final String? subtitleAr;
  final String? subtitleEn;
  final String? imageUrl;
  final String? linkType;
  final String? linkValue;
  final int? sortOrder;
  final bool? isActive;
  final DateTime? startDate;
  final DateTime? endDate;

  const BannerUpdateDto({
    this.titleAr,
    this.titleEn,
    this.subtitleAr,
    this.subtitleEn,
    this.imageUrl,
    this.linkType,
    this.linkValue,
    this.sortOrder,
    this.isActive,
    this.startDate,
    this.endDate,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (titleAr != null) map['title_ar'] = titleAr;
    if (titleEn != null) map['title_en'] = titleEn;
    if (subtitleAr != null) map['subtitle_ar'] = subtitleAr;
    if (subtitleEn != null) map['subtitle_en'] = subtitleEn;
    if (imageUrl != null) map['image_url'] = imageUrl;
    if (linkType != null) map['link_type'] = linkType;
    if (linkValue != null) map['link_value'] = linkValue;
    if (sortOrder != null) map['sort_order'] = sortOrder;
    if (isActive != null) map['is_active'] = isActive;
    if (startDate != null) {
      map['start_date'] = startDate!.toUtc().toIso8601String();
    }
    if (endDate != null) {
      map['end_date'] = endDate!.toUtc().toIso8601String();
    }
    return map;
  }
}
