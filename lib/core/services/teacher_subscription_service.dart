import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:lms_platform/core/di/injection_container.dart';
import 'package:lms_platform/core/services/user_role_service.dart';

class TeacherSubscriptionService {
  static final SupabaseClient _client = sl<SupabaseClient>();

  static Future<bool> hasActiveSubscription() async {
    final user = _client.auth.currentUser;
    if (user == null) return false;

    final isAdmin = await UserRoleService.isAdmin();
    if (isAdmin) return true;

    try {
      final teacher = await _client
          .from('teachers')
          .select('id,is_active')
          .eq('profile_id', user.id)
          .maybeSingle();

      if (teacher == null || teacher['is_active'] != true) return false;

      final now = DateTime.now().toUtc().toIso8601String();
      final subscription = await _client
          .from('teacher_subscriptions')
          .select('id')
          .eq('teacher_id', teacher['id'] as String)
          .eq('status', 'active')
          .lte('starts_at', now)
          .gt('ends_at', now)
          .limit(1)
          .maybeSingle();

      return subscription != null;
    } catch (_) {
      return false;
    }
  }
}
