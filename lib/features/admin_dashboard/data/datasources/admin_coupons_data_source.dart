import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/app_logger.dart';
import '../models/admin_coupon_model.dart';

/// Admin Coupons Data Source - Coupon management
class AdminCouponsDataSource {
  final SupabaseClient _client;
  static const _tag = 'AdminCouponsDS';

  AdminCouponsDataSource(this._client);

  /// Get all coupons with filtering
  Future<List<AdminCouponModel>> getAllCoupons({
    String? status,
    String? scope,
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    AppLogger.d('[$_tag] getAllCoupons: status=$status, scope=$scope');
    try {
      var query =
          _client.from('coupons').select('*, instructor:profiles(name)');

      if (status != null && status != 'all') {
        switch (status) {
          case 'active':
            query = query.eq('is_active', true).eq('is_suspended', false);
            // Filter expired coupons - only show non-expired
            final now = DateTime.now().toIso8601String();
            query = query.or('end_date.is.null,end_date.gte.$now');
            break;
          case 'inactive':
            query = query.eq('is_active', false);
            break;
          case 'suspended':
            query = query.eq('is_suspended', true);
            break;
          case 'expired':
            final now = DateTime.now().toIso8601String();
            query = query.not('end_date', 'is', null).lt('end_date', now);
            break;
        }
      }

      if (scope != null && scope != 'all') {
        if (scope == 'instructors') {
          // Get coupons created by instructors (have instructor_id)
          query = query.not('instructor_id', 'is', null);
        } else if (scope == 'global') {
          // Get platform coupons (no instructor_id)
          query = query.filter('instructor_id', 'is', null);
        } else {
          query = query.eq('scope', scope);
        }
      }

      if (search != null && search.isNotEmpty) {
        query = query.or(
            'code.ilike.%$search%,name_ar.ilike.%$search%,name_en.ilike.%$search%');
      }

      final response = await query
          .order('created_at', ascending: false)
          .range((page - 1) * limit, page * limit - 1);

      final coupons = <AdminCouponModel>[];
      for (final couponData in response as List) {
        final couponMap = couponData as Map<String, dynamic>;
        final couponId = couponMap['id'] as String;

        // Load category IDs if scope is categories
        if (couponMap['scope'] == 'categories') {
          final categoriesResponse = await _client
              .from('coupon_categories')
              .select('category_id')
              .eq('coupon_id', couponId);
          couponMap['category_ids'] = (categoriesResponse as List)
              .map((e) => e['category_id'] as String)
              .toList();
        }

        // Load course IDs if scope is courses
        if (couponMap['scope'] == 'courses') {
          final coursesResponse = await _client
              .from('coupon_courses')
              .select('course_id')
              .eq('coupon_id', couponId);
          couponMap['course_ids'] = (coursesResponse as List)
              .map((e) => e['course_id'] as String)
              .toList();
        }

        coupons.add(AdminCouponModel.fromJson(couponMap));
      }

      AppLogger.success('[$_tag] getAllCoupons: ${coupons.length} coupons');
      return coupons;
    } catch (e, s) {
      AppLogger.e('[$_tag] getAllCoupons error', e, s);
      rethrow;
    }
  }

  /// Get coupon by ID
  Future<AdminCouponModel> getCouponById(String id) async {
    AppLogger.d('[$_tag] getCouponById: $id');
    try {
      final response = await _client
          .from('coupons')
          .select('*, instructor:profiles(name)')
          .eq('id', id)
          .single();

      // Load category IDs if scope is categories
      List<String>? categoryIds;
      if (response['scope'] == 'categories') {
        final categoriesResponse = await _client
            .from('coupon_categories')
            .select('category_id')
            .eq('coupon_id', id);
        categoryIds = (categoriesResponse as List)
            .map((e) => e['category_id'] as String)
            .toList();
      }

      // Load course IDs if scope is courses
      List<String>? courseIds;
      if (response['scope'] == 'courses') {
        final coursesResponse = await _client
            .from('coupon_courses')
            .select('course_id')
            .eq('coupon_id', id);
        courseIds = (coursesResponse as List)
            .map((e) => e['course_id'] as String)
            .toList();
      }

      response['category_ids'] = categoryIds;
      response['course_ids'] = courseIds;

      AppLogger.success('[$_tag] getCouponById success');
      return AdminCouponModel.fromJson(response);
    } catch (e, s) {
      AppLogger.e('[$_tag] getCouponById error', e, s);
      rethrow;
    }
  }

  /// Create coupon
  Future<AdminCouponModel> createCoupon(CreateCouponDto dto) async {
    AppLogger.d('[$_tag] createCoupon: code=${dto.code}');
    try {
      final response =
          await _client.from('coupons').insert(dto.toJson()).select().single();

      final coupon = AdminCouponModel.fromJson(response);

      if (dto.scope == 'categories' && dto.categoryIds != null) {
        for (final categoryId in dto.categoryIds!) {
          await _client.from('coupon_categories').insert({
            'coupon_id': coupon.id,
            'category_id': categoryId,
          });
        }
      }

      if (dto.scope == 'courses' && dto.courseIds != null) {
        for (final courseId in dto.courseIds!) {
          await _client.from('coupon_courses').insert({
            'coupon_id': coupon.id,
            'course_id': courseId,
          });
        }
      }

      AppLogger.success('[$_tag] createCoupon success');
      return coupon;
    } catch (e, s) {
      AppLogger.e('[$_tag] createCoupon error', e, s);
      rethrow;
    }
  }

  /// Update coupon
  Future<AdminCouponModel> updateCoupon(String id, CreateCouponDto dto) async {
    AppLogger.d('[$_tag] updateCoupon: $id');
    try {
      final data = dto.toJson();
      data['updated_at'] = DateTime.now().toIso8601String();

      final response = await _client
          .from('coupons')
          .update(data)
          .eq('id', id)
          .select()
          .single();

      if (dto.scope == 'categories') {
        await _client.from('coupon_categories').delete().eq('coupon_id', id);
        if (dto.categoryIds != null) {
          for (final categoryId in dto.categoryIds!) {
            await _client.from('coupon_categories').insert({
              'coupon_id': id,
              'category_id': categoryId,
            });
          }
        }
      }

      if (dto.scope == 'courses') {
        await _client.from('coupon_courses').delete().eq('coupon_id', id);
        if (dto.courseIds != null) {
          for (final courseId in dto.courseIds!) {
            await _client.from('coupon_courses').insert({
              'coupon_id': id,
              'course_id': courseId,
            });
          }
        }
      }

      AppLogger.success('[$_tag] updateCoupon success');
      return AdminCouponModel.fromJson(response);
    } catch (e, s) {
      AppLogger.e('[$_tag] updateCoupon error', e, s);
      rethrow;
    }
  }

  /// Delete coupon
  Future<bool> deleteCoupon(String id) async {
    AppLogger.d('[$_tag] deleteCoupon: $id');
    try {
      await _client.from('coupons').delete().eq('id', id);
      AppLogger.success('[$_tag] deleteCoupon success');
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] deleteCoupon error', e, s);
      rethrow;
    }
  }

  /// Toggle coupon status
  Future<bool> toggleCouponStatus(String id, bool currentStatus) async {
    AppLogger.d('[$_tag] toggleCouponStatus: $id -> ${!currentStatus}');
    try {
      await _client.from('coupons').update({
        'is_active': !currentStatus,
      }).eq('id', id);
      AppLogger.success('[$_tag] toggleCouponStatus success');
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] toggleCouponStatus error', e, s);
      rethrow;
    }
  }

  /// Toggle coupon suspension
  Future<bool> toggleCouponSuspension(String id, bool currentSuspended) async {
    AppLogger.d('[$_tag] toggleCouponSuspension: $id -> ${!currentSuspended}');
    try {
      await _client.from('coupons').update({
        'is_suspended': !currentSuspended,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', id);
      AppLogger.success('[$_tag] toggleCouponSuspension success');
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] toggleCouponSuspension error', e, s);
      rethrow;
    }
  }

  /// Get coupon usages
  Future<List<CouponUsageModel>> getCouponUsages(
    String couponId, {
    int page = 1,
    int limit = 20,
  }) async {
    AppLogger.d('[$_tag] getCouponUsages: couponId=$couponId');
    try {
      final response = await _client
          .from('coupon_usages')
          .select('*, user:profiles(name, email)')
          .eq('coupon_id', couponId)
          .order('used_at', ascending: false)
          .range((page - 1) * limit, page * limit - 1);

      AppLogger.success('[$_tag] getCouponUsages: ${response.length} usages');
      return response.map((e) => CouponUsageModel.fromJson(e)).toList();
    } catch (e, s) {
      AppLogger.e('[$_tag] getCouponUsages error', e, s);
      rethrow;
    }
  }

  /// Check if coupon code exists
  Future<bool> checkCouponCodeExists(String code, {String? excludeId}) async {
    AppLogger.d('[$_tag] checkCouponCodeExists: code=$code');
    try {
      var query =
          _client.from('coupons').select('id').eq('code', code.toUpperCase());

      if (excludeId != null) {
        query = query.neq('id', excludeId);
      }

      final response = await query.maybeSingle();
      return response != null;
    } catch (e, s) {
      AppLogger.e('[$_tag] checkCouponCodeExists error', e, s);
      rethrow;
    }
  }
}
