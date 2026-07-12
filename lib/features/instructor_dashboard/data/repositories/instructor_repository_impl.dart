import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/instructor_entities.dart';
import '../../domain/repositories/instructor_repository.dart';
import '../datasources/instructor_data_sources.dart';
import '../models/instructor_models.dart';
import '../models/instructor_balance_model.dart';

/// Instructor Repository Implementation
class InstructorRepositoryImpl implements InstructorRepository {
  final SupabaseClient _client;
  final InstructorStatsDataSource _statsDataSource;
  final InstructorCoursesDataSource _coursesDataSource;
  final InstructorStudentsDataSource _studentsDataSource;
  final InstructorEnrollmentsDataSource _enrollmentsDataSource;
  final InstructorEarningsDataSource _earningsDataSource;
  final InstructorQADataSource _qaDataSource;
  final InstructorReviewsDataSource _reviewsDataSource;
  final InstructorCourseEditorDataSource _courseEditorDataSource;
  final InstructorAnnouncementsDataSource _announcementsDataSource;

  InstructorRepositoryImpl({
    required SupabaseClient client,
    required InstructorStatsDataSource statsDataSource,
    required InstructorCoursesDataSource coursesDataSource,
    required InstructorStudentsDataSource studentsDataSource,
    required InstructorEnrollmentsDataSource enrollmentsDataSource,
    required InstructorEarningsDataSource earningsDataSource,
    required InstructorQADataSource qaDataSource,
    required InstructorReviewsDataSource reviewsDataSource,
    required InstructorCourseEditorDataSource courseEditorDataSource,
    required InstructorAnnouncementsDataSource announcementsDataSource,
  })  : _client = client,
        _statsDataSource = statsDataSource,
        _coursesDataSource = coursesDataSource,
        _studentsDataSource = studentsDataSource,
        _enrollmentsDataSource = enrollmentsDataSource,
        _earningsDataSource = earningsDataSource,
        _qaDataSource = qaDataSource,
        _reviewsDataSource = reviewsDataSource,
        _courseEditorDataSource = courseEditorDataSource,
        _announcementsDataSource = announcementsDataSource;

  // Stats
  @override
  Future<InstructorDashboardStats> getDashboardStats() async {
    return await _statsDataSource.getDashboardStats();
  }

  @override
  Future<List<ChartDataPoint>> getRevenueChart(
      DateTime start, DateTime end) async {
    return await _statsDataSource.getRevenueChart(start, end);
  }

  @override
  Future<List<ChartDataPoint>> getEnrollmentsChart(
      DateTime start, DateTime end) async {
    return await _statsDataSource.getEnrollmentsChart(start, end);
  }

  // Courses
  @override
  Future<List<InstructorCourseModel>> getMyCourses({
    InstructorCourseStatus? status,
    int page = 1,
    int limit = 20,
  }) async {
    return await _coursesDataSource.getMyCourses(
        status: status, page: page, limit: limit);
  }

  @override
  Future<bool> publishCourse(String courseId) async {
    return await _coursesDataSource.publishCourse(courseId);
  }

  @override
  Future<bool> unpublishCourse(String courseId) async {
    return await _coursesDataSource.unpublishCourse(courseId);
  }

  // Course Editor
  @override
  Future<List<CategoryOption>> getCategories() async {
    return await _courseEditorDataSource.getCategories();
  }

  @override
  Future<CourseDetails?> getCourseForEdit(String courseId) async {
    return await _courseEditorDataSource.getCourseForEdit(courseId);
  }

  @override
  Future<String> createCourse(CourseCreateDto dto) async {
    return await _courseEditorDataSource.createCourse(dto);
  }

  @override
  Future<bool> updateCourse(String courseId, CourseUpdateDto dto) async {
    return await _courseEditorDataSource.updateCourse(courseId, dto);
  }

  @override
  Future<bool> saveSectionsAndLessons(
      String courseId, List<SectionDto> sections) async {
    return await _courseEditorDataSource.saveSectionsAndLessons(
        courseId, sections);
  }

  @override
  Future<String> addCourseAttachment({
    required String courseId,
    required String fileName,
    required String fileUrl,
    required String fileType,
    required int fileSize,
    required int sortOrder,
  }) async {
    return await _courseEditorDataSource.addCourseAttachment(
      courseId: courseId,
      fileName: fileName,
      fileUrl: fileUrl,
      fileType: fileType,
      fileSize: fileSize,
      sortOrder: sortOrder,
    );
  }

  @override
  Future<bool> deleteAllCourseAttachments(String courseId) async {
    return await _courseEditorDataSource.deleteAllCourseAttachments(courseId);
  }

  @override
  Future<List<AttachmentDto>> getCourseAttachments(String courseId) async {
    return await _courseEditorDataSource.getCourseAttachments(courseId);
  }

  @override
  Future<String> createSection(String courseId, SectionCreateDto dto) async {
    return await _courseEditorDataSource.createSection(courseId, dto);
  }

  @override
  Future<bool> updateSection(String sectionId, SectionUpdateDto dto) async {
    return await _courseEditorDataSource.updateSection(sectionId, dto);
  }

  @override
  Future<bool> deleteSection(String sectionId) async {
    return await _courseEditorDataSource.deleteSection(sectionId);
  }

  @override
  Future<bool> reorderSections(String courseId, List<String> sectionIds) async {
    return await _courseEditorDataSource.reorderSections(courseId, sectionIds);
  }

  @override
  Future<String> createLesson(
      String sectionId, String courseId, LessonCreateDto dto) async {
    return await _courseEditorDataSource.createLesson(sectionId, courseId, dto);
  }

  @override
  Future<bool> updateLesson(String lessonId, LessonUpdateDto dto) async {
    return await _courseEditorDataSource.updateLesson(lessonId, dto);
  }

  @override
  Future<bool> deleteLesson(String lessonId) async {
    return await _courseEditorDataSource.deleteLesson(lessonId);
  }

  @override
  Future<bool> reorderLessons(String sectionId, List<String> lessonIds) async {
    return await _courseEditorDataSource.reorderLessons(sectionId, lessonIds);
  }

  @override
  Future<bool> toggleSectionPublished(String sectionId) async {
    return await _courseEditorDataSource.toggleSectionPublished(sectionId);
  }

  @override
  Future<void> scheduleSectionPublish(
    String sectionId, {
    DateTime? publishAt,
    DateTime? unpublishAt,
  }) async {
    return await _courseEditorDataSource.scheduleSectionPublish(
      sectionId,
      publishAt: publishAt,
      unpublishAt: unpublishAt,
    );
  }

  @override
  Future<bool> toggleLessonPublished(String lessonId) async {
    return await _courseEditorDataSource.toggleLessonPublished(lessonId);
  }

  @override
  Future<void> scheduleLessonPublish(
    String lessonId, {
    DateTime? publishAt,
    DateTime? unpublishAt,
  }) async {
    return await _courseEditorDataSource.scheduleLessonPublish(
      lessonId,
      publishAt: publishAt,
      unpublishAt: unpublishAt,
    );
  }

  // Students
  @override
  Future<List<InstructorStudentModel>> getStudents({
    String? courseId,
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    return await _studentsDataSource.getStudents(
      courseId: courseId,
      search: search,
      page: page,
      limit: limit,
    );
  }

  @override
  Future<List<StudentEnrollmentDetail>> getStudentEnrollments(
      String studentId) async {
    return await _studentsDataSource.getStudentEnrollments(studentId);
  }

  @override
  Future<List<StudentCourseProgress>> getStudentProgress(
      String studentId) async {
    return await _studentsDataSource.getStudentProgress(studentId);
  }

  @override
  Future<bool> sendMessageToStudent(
      String studentId, String subject, String message) async {
    return await _studentsDataSource.sendMessageToStudent(
        studentId, subject, message);
  }

  // Enrollments
  @override
  Future<List<InstructorEnrollmentModel>> getEnrollments({
    InstructorEnrollmentStatus? status,
    String? courseId,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int limit = 20,
  }) async {
    return await _enrollmentsDataSource.getEnrollments(
      status: status,
      courseId: courseId,
      startDate: startDate,
      endDate: endDate,
      page: page,
      limit: limit,
    );
  }

  @override
  Future<bool> extendEnrollmentAccess(String enrollmentId, int days) async {
    return await _enrollmentsDataSource.extendEnrollmentAccess(
        enrollmentId, days);
  }

  @override
  Future<bool> resetEnrollmentProgress(String enrollmentId) async {
    return await _enrollmentsDataSource.resetEnrollmentProgress(enrollmentId);
  }

  @override
  Future<bool> updateEnrollmentStatus(
      String enrollmentId, String status) async {
    return await _enrollmentsDataSource.updateEnrollmentStatus(
        enrollmentId, status);
  }

  @override
  Future<bool> markAsCompleted(String enrollmentId) async {
    return await _enrollmentsDataSource.markAsCompleted(enrollmentId);
  }

  @override
  Future<bool> enrollStudent(String studentId, String courseId) async {
    return await _enrollmentsDataSource.enrollStudent(studentId, courseId);
  }

  @override
  Future<bool> unenrollStudent(String enrollmentId) async {
    return await _enrollmentsDataSource.unenrollStudent(enrollmentId);
  }

  @override
  Future<List<AvailableCourseForEnrollment>> getAvailableCoursesForStudent(
      String studentId) async {
    return await _enrollmentsDataSource
        .getAvailableCoursesForStudent(studentId);
  }

  // Wallet & Earnings (NEW SCHEMA)
  @override
  Future<WalletSummaryModel> getWalletSummary() async {
    return await _earningsDataSource.getWalletSummary();
  }

  @override
  Future<List<EarningsTransactionModel>> getTransactions({
    String? courseId,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int limit = 20,
  }) async {
    return await _earningsDataSource.getTransactions(
      courseId: courseId,
      status: status,
      startDate: startDate,
      endDate: endDate,
      page: page,
      limit: limit,
    );
  }

  @override
  Future<List<WithdrawRequestModel>> getWithdrawHistory(
      {int page = 1, int limit = 20}) async {
    return await _earningsDataSource.getWithdrawHistory(
        page: page, limit: limit);
  }

  @override
  Future<Map<String, dynamic>> submitWithdrawRequest({
    required double amount,
    required String method,
    required Map<String, String> accountDetails,
  }) async {
    return await _earningsDataSource.submitWithdrawRequest(
      amount: amount,
      method: method,
      accountDetails: accountDetails,
    );
  }

  // Q&A
  @override
  Future<List<InstructorQuestionModel>> getQuestions({
    QAStatus? status,
    String? courseId,
    int page = 1,
    int limit = 20,
  }) async {
    return await _qaDataSource.getQuestions(
      status: status,
      courseId: courseId,
      page: page,
      limit: limit,
    );
  }

  @override
  Future<bool> answerQuestion(String questionId, String answer) async {
    return await _qaDataSource.answerQuestion(questionId, answer);
  }

  // Reviews
  @override
  Future<List<InstructorReviewModel>> getReviews({
    String? courseId,
    int? minRating,
    int? maxRating,
    int page = 1,
    int limit = 20,
  }) async {
    return await _reviewsDataSource.getReviews(
      courseId: courseId,
      minRating: minRating,
      maxRating: maxRating,
      page: page,
      limit: limit,
    );
  }

  @override
  Future<bool> replyToReview(String reviewId, String reply) async {
    return await _reviewsDataSource.replyToReview(reviewId, reply);
  }

  @override
  Future<bool> deleteCourse(String courseId) async {
    return await _coursesDataSource.deleteCourse(courseId);
  }

  @override
  Future<bool> updateAnswer(String answerId, String newContent) async {
    return await _qaDataSource.updateAnswer(answerId, newContent);
  }

  @override
  Future<bool> deleteAnswer(String answerId) async {
    return await _qaDataSource.deleteAnswer(answerId);
  }

  @override
  Future<bool> hideQuestion(String questionId) async {
    return await _qaDataSource.hideQuestion(questionId);
  }

  @override
  Future<bool> pinQuestion(String questionId, bool isPinned) async {
    return await _qaDataSource.pinQuestion(questionId, isPinned);
  }

  // Announcements
  @override
  Future<List<Map<String, dynamic>>> getAnnouncements({
    required String courseId,
    int page = 1,
    int limit = 20,
  }) async {
    return await _announcementsDataSource.getAnnouncements(
      courseId: courseId,
      page: page,
      limit: limit,
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getAnnouncementCourses() async {
    return await _announcementsDataSource.getMyCourses();
  }

  @override
  Future<bool> createAnnouncement({
    required String courseId,
    required String titleAr,
    String? titleEn,
    String? contentAr,
    String? contentEn,
  }) async {
    return await _announcementsDataSource.createAnnouncement(
      courseId: courseId,
      titleAr: titleAr,
      titleEn: titleEn,
      contentAr: contentAr,
      contentEn: contentEn,
    );
  }

  @override
  Future<bool> updateAnnouncement(
      String announcementId, Map<String, dynamic> data) async {
    return await _announcementsDataSource.updateAnnouncement(
        announcementId, data);
  }

  @override
  Future<bool> deleteAnnouncement(String announcementId) async {
    return await _announcementsDataSource.deleteAnnouncement(announcementId);
  }

  // Categories (Merged from Admin)
  @override
  Future<List<CategoryModel>> getAdminCategories({bool? isActive}) async {
    try {
      var query = _client.from('categories').select();
      if (isActive != null) {
        query = query.eq('is_active', isActive);
      }
      final response = await query.order('sort_order', ascending: true);
      return response.map((e) => CategoryModel.fromJson(e)).toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<CategoryModel> createCategory(CategoryCreateDto dto) async {
    try {
      final response = await _client.from('categories').insert({
        'name_ar': dto.nameAr,
        'name_en': dto.nameEn,
        'description_ar': dto.description,
        'icon_name': dto.icon,
        'parent_id': dto.parentId,
      }).select().single();
      return CategoryModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<CategoryModel> updateCategory(String id, CategoryUpdateDto dto) async {
    try {
      final data = <String, dynamic>{};
      if (dto.nameAr != null) data['name_ar'] = dto.nameAr;
      if (dto.nameEn != null) data['name_en'] = dto.nameEn;
      if (dto.description != null) data['description_ar'] = dto.description;
      if (dto.icon != null) data['icon_name'] = dto.icon;
      if (dto.parentId != null) data['parent_id'] = dto.parentId;
      if (dto.isActive != null) data['is_active'] = dto.isActive;
      if (dto.sortOrder != null) data['sort_order'] = dto.sortOrder;

      final response = await _client
          .from('categories')
          .update(data)
          .eq('id', id)
          .select()
          .single();
      return CategoryModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<bool> toggleCategoryStatus(String id) async {
    try {
      final categories = await getAdminCategories();
      final category = categories.firstWhere((c) => c.id == id);
      await _client.from('categories').update({
        'is_active': !category.isActive,
      }).eq('id', id);
      return true;
    } catch (e) {
      rethrow;
    }
  }

  // Banners (Merged from Admin)
  @override
  Future<List<BannerModel>> getBanners({BannerType? type, bool? isActive}) async {
    try {
      var query = _client.from('banners').select();
      if (isActive != null) {
        query = query.eq('is_active', isActive);
      }
      final response = await query.order('sort_order', ascending: true);
      return response.map((e) => BannerModel.fromJson(e)).toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<BannerModel> createBanner(BannerCreateDto dto) async {
    try {
      final response = await _client.from('banners').insert({
        'title_ar': dto.titleAr,
        'title_en': dto.titleEn,
        'subtitle_ar': dto.subtitleAr,
        'subtitle_en': dto.subtitleEn,
        'image_url': dto.imageUrl,
        'link_type': dto.linkType,
        'link_value': dto.linkValue,
        'sort_order': dto.sortOrder,
        'start_date': dto.startDate?.toUtc().toIso8601String(),
        'end_date': dto.endDate?.toUtc().toIso8601String(),
      }).select().single();
      return BannerModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<BannerModel> updateBanner(String id, BannerUpdateDto dto) async {
    try {
      final response = await _client
          .from('banners')
          .update(dto.toJson())
          .eq('id', id)
          .select()
          .single();
      return BannerModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<bool> deleteBanner(String id) async {
    try {
      await _client.from('banners').delete().eq('id', id);
      return true;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<bool> toggleBannerStatus(String id) async {
    try {
      final banner = await _client
          .from('banners')
          .select('is_active')
          .eq('id', id)
          .single();
      final currentStatus = banner['is_active'] as bool? ?? false;
      await _client.from('banners').update({
        'is_active': !currentStatus,
      }).eq('id', id);
      return true;
    } catch (e) {
      rethrow;
    }
  }
}
