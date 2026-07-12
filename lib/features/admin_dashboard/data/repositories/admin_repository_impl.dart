import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/admin_entities.dart';
import '../../domain/repositories/admin_repository.dart';
import '../datasources/admin_coupons_data_source.dart';
import '../datasources/admin_courses_data_source.dart';
import '../datasources/admin_forum_data_source.dart';
import '../datasources/admin_payouts_data_source.dart';
import '../datasources/admin_qa_data_source.dart';
import '../datasources/admin_reviews_data_source.dart';
import '../datasources/admin_stats_data_source.dart';
import '../datasources/admin_users_data_source.dart';
import '../models/admin_models.dart';
import '../models/admin_coupon_model.dart';

/// Admin Repository Implementation
class AdminRepositoryImpl implements AdminRepository {
  final AdminStatsDataSource _statsDataSource;
  final AdminUsersDataSource _usersDataSource;
  final AdminCoursesDataSource _coursesDataSource;
  final AdminCouponsDataSource _couponsDataSource;
  final AdminReviewsDataSource _reviewsDataSource;
  final AdminQADataSource _qaDataSource;
  final AdminForumDataSource _forumDataSource;

  AdminRepositoryImpl({
    required AdminStatsDataSource statsDataSource,
    required AdminUsersDataSource usersDataSource,
    required AdminCoursesDataSource coursesDataSource,
    required AdminCouponsDataSource couponsDataSource,
    required AdminPayoutsDataSource payoutsDataSource,
    required AdminReviewsDataSource reviewsDataSource,
    required AdminQADataSource qaDataSource,
    required AdminForumDataSource forumDataSource,
  })  : _statsDataSource = statsDataSource,
        _usersDataSource = usersDataSource,
        _coursesDataSource = coursesDataSource,
        _couponsDataSource = couponsDataSource,
        _reviewsDataSource = reviewsDataSource,
        _qaDataSource = qaDataSource,
        _forumDataSource = forumDataSource;

  @override
  Future<AdminDashboardStats> getDashboardStats() async {
    return await _statsDataSource.getDashboardStats();
  }

  @override
  Future<List<ChartDataPointModel>> getRevenueChart(
      DateTime start, DateTime end) async {
    return await _statsDataSource.getRevenueChart(start, end);
  }

  @override
  Future<List<ChartDataPointModel>> getEnrollmentsChart(
      DateTime start, DateTime end) async {
    return await _statsDataSource.getEnrollmentsChart(start, end);
  }

  @override
  Future<List<AdminUserModel>> getUsers({
    required UserRole role,
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    return await _usersDataSource.getUsers(
        role: role, search: search, page: page, limit: limit);
  }

  @override
  Future<bool> banUser(
      String userId, BanDuration duration, String reason) async {
    return await _usersDataSource.banUser(userId, duration, reason);
  }

  @override
  Future<bool> unbanUser(String userId) async {
    return await _usersDataSource.unbanUser(userId);
  }

  @override
  Future<bool> updateUser(String userId, UserUpdateDto dto) async {
    return await _usersDataSource.updateUser(userId, dto.toJson());
  }

  @override
  Future<List<AdminCourseModel>> getCourses({
    CourseStatus? status,
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    return await _coursesDataSource.getCourses(
        status: status, search: search, page: page, limit: limit);
  }

  @override
  Future<bool> suspendCourse(String courseId, String reason) async {
    return await _coursesDataSource.suspendCourse(courseId, reason);
  }

  @override
  Future<bool> unsuspendCourse(String courseId) async {
    return await _coursesDataSource.unsuspendCourse(courseId);
  }

  @override
  Future<bool> deleteCourse(String courseId) async {
    return await _coursesDataSource.deleteCourse(courseId);
  }

  @override
  Future<List<CategoryModel>> getCategories({bool? isActive}) async {
    return await _coursesDataSource.getCategories(isActive: isActive);
  }

  @override
  Future<CategoryModel> createCategory(CategoryCreateDto dto) async {
    return await _coursesDataSource.createCategory({
      'name_ar': dto.nameAr,
      'name_en': dto.nameEn,
      'description': dto.description,
      'icon': dto.icon,
      'parent_id': dto.parentId,
    });
  }

  @override
  Future<CategoryModel> updateCategory(String id, CategoryUpdateDto dto) async {
    final data = <String, dynamic>{};
    if (dto.nameAr != null) data['name_ar'] = dto.nameAr;
    if (dto.nameEn != null) data['name_en'] = dto.nameEn;
    if (dto.description != null) data['description'] = dto.description;
    if (dto.icon != null) data['icon'] = dto.icon;
    if (dto.parentId != null) data['parent_id'] = dto.parentId;
    if (dto.isActive != null) data['is_active'] = dto.isActive;
    if (dto.sortOrder != null) data['sort_order'] = dto.sortOrder;
    return await _coursesDataSource.updateCategory(id, data);
  }

  @override
  Future<bool> toggleCategoryStatus(String id) async {
    final categories = await _coursesDataSource.getCategories();
    final category = categories.firstWhere((c) => c.id == id);
    await _coursesDataSource
        .updateCategory(id, {'is_active': !category.isActive});
    return true;
  }

  @override
  Future<List<AdminEnrollmentModel>> getEnrollments({
    EnrollmentStatus? status,
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    return await _coursesDataSource.getEnrollments(
        status: status, search: search, page: page, limit: limit);
  }

  @override
  Future<bool> processRefund(String enrollmentId, String reason) async {
    return await _coursesDataSource.processRefund(enrollmentId, reason);
  }

  @override
  Future<List<PayoutModel>> getPayouts({
    PayoutStatus? status,
    int page = 1,
    int limit = 20,
  }) async {
    final client = Supabase.instance.client;
    var query = client.from('withdraw_requests').select(
        '*, instructor:profiles!withdraw_requests_user_id_profiles_fkey(name)');
    if (status != null) query = query.eq('status', status.name);
    final response = await query
        .order('requested_at', ascending: false)
        .range((page - 1) * limit, page * limit - 1);
    return (response as List).map((e) {
      final json = e as Map<String, dynamic>;
      return PayoutModel(
        id: json['id'] as String,
        instructorId: json['user_id'] as String,
        instructorName: json['instructor']?['name'] as String? ?? '',
        amount: (json['amount'] as num).toDouble(),
        status: PayoutStatus.values.firstWhere((s) => s.name == json['status'],
            orElse: () => PayoutStatus.pending),
        requestedAt: DateTime.parse(json['requested_at'] as String),
        processedAt: json['approved_at'] != null
            ? DateTime.parse(json['approved_at'] as String)
            : null,
        payoutMethod: json['method'] as String? ?? 'instapay',
      );
    }).toList();
  }

  @override
  Future<bool> approvePayout(String payoutId) async {
    final adminId = Supabase.instance.client.auth.currentUser?.id ?? '';
    await Supabase.instance.client.rpc('admin_approve_withdraw', params: {
      'p_request_id': payoutId,
      'p_admin_id': adminId,
    });
    return true;
  }

  @override
  Future<bool> completePayout(String payoutId, String transactionId) async {
    final adminId = Supabase.instance.client.auth.currentUser?.id ?? '';
    await Supabase.instance.client.rpc('admin_approve_withdraw', params: {
      'p_request_id': payoutId,
      'p_admin_id': adminId,
    });
    return true;
  }

  @override
  Future<bool> rejectPayout(String payoutId, String reason) async {
    final adminId = Supabase.instance.client.auth.currentUser?.id ?? '';
    await Supabase.instance.client.rpc('admin_reject_withdraw', params: {
      'p_request_id': payoutId,
      'p_admin_id': adminId,
      'p_notes': reason,
    });
    return true;
  }

  @override
  Future<bool> hideReview(String reviewId) async {
    await Supabase.instance.client
        .from('course_reviews')
        .update({'is_hidden': true}).eq('id', reviewId);
    return true;
  }

  @override
  Future<List<CouponModel>> getGlobalCoupons(
      {bool? isActive, int page = 1, int limit = 20}) async {
    final coupons = await _couponsDataSource.getAllCoupons(
        scope: 'global', page: page, limit: limit);
    return coupons
        .map((c) => CouponModel(
              id: c.id,
              code: c.code,
              description: c.nameAr,
              discountType: c.discountType == 'percentage'
                  ? CouponDiscountType.percentage
                  : CouponDiscountType.fixed,
              discountValue: c.discountValue,
              usageLimit: c.usageLimit,
              usedCount: c.usageCount,
              startDate: c.startDate,
              endDate: c.endDate,
              isActive: c.isActive,
              createdAt: c.createdAt,
            ))
        .toList();
  }

  @override
  Future<List<CouponModel>> getInstructorCoupons({
    String? instructorId,
    bool? isActive,
    int page = 1,
    int limit = 20,
  }) async {
    final coupons = await _couponsDataSource.getAllCoupons(
        scope: 'instructors', page: page, limit: limit);
    return coupons
        .map((c) => CouponModel(
              id: c.id,
              code: c.code,
              description: c.nameAr,
              discountType: c.discountType == 'percentage'
                  ? CouponDiscountType.percentage
                  : CouponDiscountType.fixed,
              discountValue: c.discountValue,
              usageLimit: c.usageLimit,
              usedCount: c.usageCount,
              startDate: c.startDate,
              endDate: c.endDate,
              isActive: c.isActive,
              createdAt: c.createdAt,
            ))
        .toList();
  }

  @override
  Future<CouponModel> createGlobalCoupon(CouponCreateDto dto) async {
    final coupon = await _couponsDataSource.createCoupon(CreateCouponDto(
      code: dto.code,
      nameAr: dto.description ?? '',
      discountType: dto.discountType,
      discountValue: dto.discountValue,
      startDate: dto.startDate ?? DateTime.now(),
      scope: 'global',
    ));
    return CouponModel(
      id: coupon.id,
      code: coupon.code,
      description: coupon.nameAr,
      discountType: coupon.discountType == 'percentage'
          ? CouponDiscountType.percentage
          : CouponDiscountType.fixed,
      discountValue: coupon.discountValue,
      usageLimit: coupon.usageLimit,
      usedCount: coupon.usageCount,
      startDate: coupon.startDate,
      endDate: coupon.endDate,
      isActive: coupon.isActive,
      createdAt: coupon.createdAt,
    );
  }

  @override
  Future<CouponModel> updateCoupon(String id, CouponUpdateDto dto) async {
    final existing = await _couponsDataSource.getCouponById(id);
    final coupon = await _couponsDataSource.updateCoupon(
        id,
        CreateCouponDto(
          code: existing.code,
          nameAr: dto.description ?? existing.nameAr,
          discountType: existing.discountType,
          discountValue: dto.discountValue ?? existing.discountValue,
          startDate: dto.startDate ?? existing.startDate,
          endDate: dto.endDate ?? existing.endDate,
          scope: existing.scope,
        ));
    return CouponModel(
      id: coupon.id,
      code: coupon.code,
      description: coupon.nameAr,
      discountType: coupon.discountType == 'percentage'
          ? CouponDiscountType.percentage
          : CouponDiscountType.fixed,
      discountValue: coupon.discountValue,
      usageLimit: coupon.usageLimit,
      usedCount: coupon.usageCount,
      startDate: coupon.startDate,
      endDate: coupon.endDate,
      isActive: coupon.isActive,
      createdAt: coupon.createdAt,
    );
  }

  @override
  Future<bool> deleteCoupon(String id) async {
    return await _couponsDataSource.deleteCoupon(id);
  }

  @override
  Future<bool> toggleCouponStatus(String id) async {
    final coupons = await _couponsDataSource.getAllCoupons();
    final coupon = coupons.firstWhere((c) => c.id == id,
        orElse: () => throw Exception('Coupon not found'));
    return await _couponsDataSource.toggleCouponStatus(id, coupon.isActive);
  }

  @override
  Future<List<TopCourseModel>> getTopCourses({int limit = 10}) async {
    return await _statsDataSource.getTopCourses(limit: limit);
  }

  @override
  Future<List<TopInstructorModel>> getTopInstructors({int limit = 10}) async {
    return await _statsDataSource.getTopInstructors(limit: limit);
  }

  // ==========================================
  // NEW: Missing Permissions Implementations
  // ==========================================

  @override
  Future<bool> deleteUser(String userId) async {
    return await _usersDataSource.deleteUser(userId);
  }

  @override
  Future<bool> changeUserRole(String userId, String newRole) async {
    return await _usersDataSource.changeUserRole(userId, newRole);
  }

  @override
  Future<bool> sendNotification({
    required String userId,
    required String titleAr,
    String? titleEn,
    String? bodyAr,
    String? bodyEn,
    String type = 'system',
  }) async {
    return await _usersDataSource.sendNotification(
      userId: userId,
      titleAr: titleAr,
      titleEn: titleEn,
      bodyAr: bodyAr,
      bodyEn: bodyEn,
      type: type,
    );
  }

  @override
  Future<int> broadcastNotification({
    required String role,
    required String titleAr,
    String? titleEn,
    String? bodyAr,
    String? bodyEn,
    String type = 'announcement',
  }) async {
    return await _usersDataSource.broadcastNotification(
      role: role,
      titleAr: titleAr,
      titleEn: titleEn,
      bodyAr: bodyAr,
      bodyEn: bodyEn,
      type: type,
    );
  }

  @override
  Future<bool> publishCourse(String courseId) async {
    return await _coursesDataSource.publishCourse(courseId);
  }

  @override
  Future<bool> unpublishCourse(String courseId) async {
    return await _coursesDataSource.unpublishCourse(courseId);
  }

  @override
  Future<bool> enrollStudent(String studentId, String courseId) async {
    return await _coursesDataSource.enrollStudent(studentId, courseId);
  }

  @override
  Future<bool> cancelEnrollment(String enrollmentId) async {
    return await _coursesDataSource.cancelEnrollment(enrollmentId);
  }

  @override
  Future<bool> extendEnrollmentAccess(String enrollmentId, int days) async {
    return await _coursesDataSource.extendEnrollmentAccess(enrollmentId, days);
  }

  @override
  Future<List<Map<String, dynamic>>> getAllReviews({
    String? courseId,
    int? minRating,
    int? maxRating,
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    return await _reviewsDataSource.getAllReviews(
      courseId: courseId,
      minRating: minRating,
      maxRating: maxRating,
      search: search,
      page: page,
      limit: limit,
    );
  }

  @override
  Future<bool> deleteReview(String reviewId) async {
    return await _reviewsDataSource.deleteReview(reviewId);
  }

  @override
  Future<bool> unhideReview(String reviewId) async {
    return await _reviewsDataSource.unhideReview(reviewId);
  }

  @override
  Future<List<Map<String, dynamic>>> getAllQuestions({
    String? courseId,
    bool? isAnswered,
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    return await _qaDataSource.getAllQuestions(
      courseId: courseId,
      isAnswered: isAnswered,
      search: search,
      page: page,
      limit: limit,
    );
  }

  @override
  Future<bool> deleteQuestion(String questionId) async {
    return await _qaDataSource.deleteQuestion(questionId);
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
  Future<bool> unhideQuestion(String questionId) async {
    return await _qaDataSource.unhideQuestion(questionId);
  }

  @override
  Future<List<Map<String, dynamic>>> getConversations({
    String? search,
    String? typeFilter,
    int page = 1,
    int limit = 20,
  }) async {
    return await _forumDataSource.getConversations(
      search: search,
      typeFilter: typeFilter,
      page: page,
      limit: limit,
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getMessages({
    required String conversationId,
    String? search,
    int page = 1,
    int limit = 50,
  }) async {
    return await _forumDataSource.getMessages(
      conversationId: conversationId,
      search: search,
      page: page,
      limit: limit,
    );
  }

  @override
  Future<bool> deleteMessage(String messageId) async {
    return await _forumDataSource.deleteMessage(messageId);
  }
}
