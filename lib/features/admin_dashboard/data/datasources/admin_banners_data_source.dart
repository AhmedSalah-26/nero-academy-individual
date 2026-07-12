import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/app_logger.dart';
import '../models/admin_banner_model.dart';

/// Admin Banners Data Source - Banner management
class AdminBannersDataSource {
  final SupabaseClient _client;
  static const _tag = 'AdminBannersDS';

  AdminBannersDataSource(this._client);

  /// Get all banners with filtering
  Future<List<AdminBannerModel>> getAllBanners({
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    AppLogger.d('[$_tag] getAllBanners: status=$status');
    try {
      var query = _client.from('banners').select();

      if (status != null && status != 'all') {
        final now = DateTime.now().toIso8601String();
        switch (status) {
          case 'active':
            query = query.eq('is_active', true);
            break;
          case 'inactive':
            query = query.eq('is_active', false);
            break;
          case 'scheduled':
            query = query.eq('is_active', true).gt('start_date', now);
            break;
          case 'expired':
            query = query.lt('end_date', now);
            break;
        }
      }

      final response = await query
          .order('sort_order', ascending: true)
          .range((page - 1) * limit, page * limit - 1);

      AppLogger.success('[$_tag] getAllBanners: ${response.length} banners');
      return response.map((e) => AdminBannerModel.fromJson(e)).toList();
    } catch (e, s) {
      AppLogger.e('[$_tag] getAllBanners error', e, s);
      rethrow;
    }
  }

  /// Get banner by ID
  Future<AdminBannerModel> getBannerById(String id) async {
    AppLogger.d('[$_tag] getBannerById: $id');
    try {
      final response =
          await _client.from('banners').select().eq('id', id).single();
      AppLogger.success('[$_tag] getBannerById success');
      return AdminBannerModel.fromJson(response);
    } catch (e, s) {
      AppLogger.e('[$_tag] getBannerById error', e, s);
      rethrow;
    }
  }

  /// Create banner
  Future<AdminBannerModel> createBanner(CreateBannerDto dto) async {
    AppLogger.d('[$_tag] createBanner: title=${dto.titleAr}');
    try {
      final response =
          await _client.from('banners').insert(dto.toJson()).select().single();
      AppLogger.success('[$_tag] createBanner success');
      return AdminBannerModel.fromJson(response);
    } catch (e, s) {
      AppLogger.e('[$_tag] createBanner error', e, s);
      rethrow;
    }
  }

  /// Update banner
  Future<AdminBannerModel> updateBanner(String id, CreateBannerDto dto) async {
    AppLogger.d('[$_tag] updateBanner: $id');
    try {
      final data = dto.toJson();
      data['updated_at'] = DateTime.now().toIso8601String();

      final response = await _client
          .from('banners')
          .update(data)
          .eq('id', id)
          .select()
          .single();
      AppLogger.success('[$_tag] updateBanner success');
      return AdminBannerModel.fromJson(response);
    } catch (e, s) {
      AppLogger.e('[$_tag] updateBanner error', e, s);
      rethrow;
    }
  }

  /// Toggle banner status
  Future<bool> toggleBannerStatus(String id, bool currentStatus) async {
    AppLogger.d('[$_tag] toggleBannerStatus: $id -> ${!currentStatus}');
    try {
      await _client.from('banners').update({
        'is_active': !currentStatus,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', id);
      AppLogger.success('[$_tag] toggleBannerStatus success');
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] toggleBannerStatus error', e, s);
      rethrow;
    }
  }

  /// Delete banner
  Future<bool> deleteBanner(String id) async {
    AppLogger.d('[$_tag] deleteBanner: $id');
    try {
      await _client.from('banners').delete().eq('id', id);
      AppLogger.success('[$_tag] deleteBanner success');
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] deleteBanner error', e, s);
      rethrow;
    }
  }

  /// Reorder banners
  Future<bool> reorderBanners(List<String> bannerIds) async {
    AppLogger.d('[$_tag] reorderBanners: ${bannerIds.length} banners');
    try {
      for (int i = 0; i < bannerIds.length; i++) {
        await _client.from('banners').update({
          'sort_order': i,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', bannerIds[i]);
      }
      AppLogger.success('[$_tag] reorderBanners success');
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] reorderBanners error', e, s);
      rethrow;
    }
  }
}
