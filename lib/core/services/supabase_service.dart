import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lms_platform/core/constants/app_constants.dart';

abstract class SupabaseService {
  SupabaseClient get client;
  GoTrueClient get auth;
  Future<void> initialize();
}

class SupabaseServiceImpl implements SupabaseService {
  static SupabaseServiceImpl? _instance;
  SupabaseClient? _client;
  bool _isInitialized = false;

  SupabaseServiceImpl._();

  static SupabaseServiceImpl get instance {
    _instance ??= SupabaseServiceImpl._();
    return _instance!;
  }

  @override
  SupabaseClient get client {
    if (_client == null) {
      // Try to get from Supabase.instance if available
      try {
        _client = Supabase.instance.client;
        return _client!;
      } catch (e) {
        throw Exception(
          'Supabase not initialized. Please check your internet connection.',
        );
      }
    }
    return _client!;
  }

  @override
  GoTrueClient get auth => client.auth;

  bool get isInitialized => _isInitialized;

  @override
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('⚠️ [SupabaseService] Already initialized');
      return;
    }

    try {
      debugPrint('🔄 [SupabaseService] Initializing...');
      await Supabase.initialize(
        url: AppConstants.supabaseUrl,
        publishableKey: AppConstants.supabaseAnonKey,
        authOptions: const FlutterAuthClientOptions(
          autoRefreshToken: true,
          authFlowType: AuthFlowType.implicit,
        ),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Connection timeout - please check your internet');
        },
      );
      _client = Supabase.instance.client;
      _isInitialized = true;
      debugPrint('✅ [SupabaseService] Initialized successfully');
    } catch (e) {
      debugPrint('❌ [SupabaseService] Initialization failed: $e');
      debugPrint(
          '   App will continue but features requiring internet will not work');
      // Don't rethrow - let the app continue
      _isInitialized = false;
    }
  }
}
