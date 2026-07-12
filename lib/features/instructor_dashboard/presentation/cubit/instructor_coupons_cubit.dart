import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lms_platform/core/services/app_logger.dart';

part 'instructor_coupons_state.dart';

/// Instructor Coupons Cubit
class InstructorCouponsCubit extends Cubit<InstructorCouponsState> {
  final SupabaseClient _supabase;
  int _currentPage = 1;
  static const int _pageSize = 20;
  static const _tag = 'InstructorCouponsCubit';

  InstructorCouponsCubit(this._supabase)
      : super(const InstructorCouponsState());

  /// Load coupons
  Future<void> loadCoupons({bool refresh = false}) async {
    AppLogger.i('📋 [$_tag] loadCoupons: refresh=$refresh');

    if (refresh) {
      _currentPage = 1;
      emit(state.copyWith(
        status: InstructorCouponsStatus.loading,
        coupons: [],
        hasMore: true,
      ));
    } else if (state.status == InstructorCouponsStatus.initial) {
      emit(state.copyWith(status: InstructorCouponsStatus.loading));
    }

    try {
      final userId = _supabase.auth.currentUser?.id;
      AppLogger.d('[$_tag] loadCoupons: userId=$userId');

      if (userId == null) {
        AppLogger.e('[$_tag] loadCoupons: User not authenticated');
        throw Exception('User not authenticated');
      }

      AppLogger.d(
          '[$_tag] loadCoupons: Querying coupons for instructor $userId');

      final response = await _supabase
          .from('coupons')
          .select('*, coupon_courses(course_id)')
          .eq('instructor_id', userId)
          .order('created_at', ascending: false)
          .range(
            (_currentPage - 1) * _pageSize,
            _currentPage * _pageSize - 1,
          );

      AppLogger.d('[$_tag] loadCoupons: Raw response: $response');
      AppLogger.success(
          '[$_tag] loadCoupons: Received ${(response as List).length} coupons');

      final coupons = response.map((c) {
        AppLogger.d('[$_tag] loadCoupons: Parsing coupon: $c');
        return InstructorCouponModel.fromJson(c);
      }).toList();

      emit(state.copyWith(
        status: InstructorCouponsStatus.success,
        coupons: refresh ? coupons : [...state.coupons, ...coupons],
        hasMore: coupons.length >= _pageSize,
      ));

      AppLogger.success(
          '[$_tag] loadCoupons: State updated with ${coupons.length} coupons');
    } catch (e, s) {
      AppLogger.e('[$_tag] loadCoupons error', e, s);
      emit(state.copyWith(
        status: InstructorCouponsStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Load more coupons
  Future<void> loadMoreCoupons() async {
    if (state.isLoadingMore || !state.hasMore) return;

    emit(state.copyWith(isLoadingMore: true));
    _currentPage++;
    await loadCoupons();
    emit(state.copyWith(isLoadingMore: false));
  }

  /// Set filter
  void setFilter(CouponStatusFilter filter) {
    emit(state.copyWith(filter: filter));
  }

  /// Create coupon
  Future<bool> createCoupon({
    required String code,
    required String nameAr,
    String? nameEn,
    String? descriptionAr,
    String? descriptionEn,
    required String discountType,
    required double discountValue,
    double? maxDiscountAmount,
    double? minOrderAmount,
    int? usageLimit,
    int? usageLimitPerUser,
    DateTime? startDate,
    DateTime? endDate,
    String scope = 'all',
    List<String>? courseIds,
  }) async {
    AppLogger.i(
        '📋 [$_tag] createCoupon: code=$code, nameAr=$nameAr, discountType=$discountType, discountValue=$discountValue');

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        AppLogger.e('[$_tag] createCoupon: User not authenticated');
        throw Exception('User not authenticated');
      }

      final insertData = {
        'instructor_id': userId,
        'code': code.toUpperCase(),
        'name_ar': nameAr,
        'name_en': nameEn,
        'description_ar': descriptionAr,
        'description_en': descriptionEn,
        'discount_type': discountType,
        'discount_value': discountValue,
        'max_discount_amount': maxDiscountAmount,
        'min_order_amount': minOrderAmount ?? 0,
        'usage_limit': usageLimit,
        'usage_limit_per_user': usageLimitPerUser ?? 1,
        if (startDate != null)
          'start_date': startDate.toUtc().toIso8601String(),
        'end_date': _toUtcEndOfDay(endDate),
        'scope': scope,
        'is_active': true,
      };

      AppLogger.d('[$_tag] createCoupon: Inserting: $insertData');

      final created = await _supabase
          .from('coupons')
          .insert(insertData)
          .select('id')
          .single();

      await _syncCouponCourses(
        created['id'] as String,
        scope: scope,
        courseIds: courseIds,
      );

      AppLogger.success('[$_tag] createCoupon: Coupon created successfully');
      await loadCoupons(refresh: true);
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] createCoupon error', e, s);
      emit(state.copyWith(errorMessage: e.toString()));
      return false;
    }
  }

  /// Update coupon
  Future<bool> updateCoupon({
    required String couponId,
    String? code,
    String? nameAr,
    String? nameEn,
    String? descriptionAr,
    String? descriptionEn,
    String? discountType,
    double? discountValue,
    double? maxDiscountAmount,
    double? minOrderAmount,
    int? usageLimit,
    int? usageLimitPerUser,
    DateTime? startDate,
    DateTime? endDate,
    String? scope,
    List<String>? courseIds,
    bool? isActive,
  }) async {
    AppLogger.i('📋 [$_tag] updateCoupon: couponId=$couponId');

    try {
      final updates = <String, dynamic>{};
      if (code != null) updates['code'] = code.toUpperCase();
      if (nameAr != null) updates['name_ar'] = nameAr;
      if (nameEn != null) updates['name_en'] = nameEn;
      if (descriptionAr != null) updates['description_ar'] = descriptionAr;
      if (descriptionEn != null) updates['description_en'] = descriptionEn;
      if (discountType != null) updates['discount_type'] = discountType;
      if (discountValue != null) updates['discount_value'] = discountValue;
      if (maxDiscountAmount != null) {
        updates['max_discount_amount'] = maxDiscountAmount;
      }
      if (minOrderAmount != null) updates['min_order_amount'] = minOrderAmount;
      if (usageLimit != null) updates['usage_limit'] = usageLimit;
      if (usageLimitPerUser != null) {
        updates['usage_limit_per_user'] = usageLimitPerUser;
      }
      if (startDate != null) {
        updates['start_date'] = startDate.toUtc().toIso8601String();
      }
      if (endDate != null) {
        updates['end_date'] = _toUtcEndOfDay(endDate);
      }
      if (scope != null) updates['scope'] = scope;
      if (isActive != null) updates['is_active'] = isActive;

      AppLogger.d('[$_tag] updateCoupon: Updates: $updates');

      await _supabase.from('coupons').update(updates).eq('id', couponId);

      await _syncCouponCourses(
        couponId,
        scope: scope,
        courseIds: courseIds,
      );

      AppLogger.success('[$_tag] updateCoupon: Coupon updated successfully');
      await loadCoupons(refresh: true);
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] updateCoupon error', e, s);
      emit(state.copyWith(errorMessage: e.toString()));
      return false;
    }
  }

  Future<void> _syncCouponCourses(
    String couponId, {
    String? scope,
    List<String>? courseIds,
  }) async {
    if (scope == null) return;

    await _supabase.from('coupon_courses').delete().eq('coupon_id', couponId);

    if (scope != 'courses' || courseIds == null || courseIds.isEmpty) return;

    await _supabase.from('coupon_courses').insert(
          courseIds
              .map((courseId) => {
                    'coupon_id': couponId,
                    'course_id': courseId,
                  })
              .toList(),
        );
  }

  String? _toUtcEndOfDay(DateTime? value) {
    if (value == null) return null;

    final endOfDay = DateTime(
      value.year,
      value.month,
      value.day,
      23,
      59,
      59,
      999,
      999,
    );
    return endOfDay.toUtc().toIso8601String();
  }

  /// Toggle coupon status
  Future<bool> toggleCouponStatus(String couponId, bool isActive) async {
    AppLogger.i(
        '📋 [$_tag] toggleCouponStatus: couponId=$couponId, isActive=$isActive');

    try {
      await _supabase
          .from('coupons')
          .update({'is_active': isActive}).eq('id', couponId);

      final updatedCoupons = state.coupons.map((c) {
        if (c.id == couponId) {
          return InstructorCouponModel(
            id: c.id,
            code: c.code,
            nameAr: c.nameAr,
            nameEn: c.nameEn,
            descriptionAr: c.descriptionAr,
            descriptionEn: c.descriptionEn,
            discountType: c.discountType,
            discountValue: c.discountValue,
            maxDiscountAmount: c.maxDiscountAmount,
            minOrderAmount: c.minOrderAmount,
            usageLimit: c.usageLimit,
            usageCount: c.usageCount,
            usageLimitPerUser: c.usageLimitPerUser,
            startDate: c.startDate,
            endDate: c.endDate,
            scope: c.scope,
            courseIds: c.courseIds,
            isActive: isActive,
            isSuspended: c.isSuspended,
            createdAt: c.createdAt,
          );
        }
        return c;
      }).toList();

      emit(state.copyWith(coupons: updatedCoupons));
      AppLogger.success(
          '[$_tag] toggleCouponStatus: Status toggled successfully');
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] toggleCouponStatus error', e, s);
      emit(state.copyWith(errorMessage: e.toString()));
      return false;
    }
  }

  /// Delete coupon
  Future<bool> deleteCoupon(String couponId) async {
    AppLogger.i('📋 [$_tag] deleteCoupon: couponId=$couponId');

    try {
      await _supabase.from('coupons').delete().eq('id', couponId);

      final updatedCoupons =
          state.coupons.where((c) => c.id != couponId).toList();
      emit(state.copyWith(coupons: updatedCoupons));

      AppLogger.success('[$_tag] deleteCoupon: Coupon deleted successfully');
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] deleteCoupon error', e, s);
      emit(state.copyWith(errorMessage: e.toString()));
      return false;
    }
  }
}
