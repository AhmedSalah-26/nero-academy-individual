import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:lms_platform/features/admin_dashboard/data/models/admin_teacher_subscription_model.dart';

class AdminTeacherSubscriptionsDataSource {
  final SupabaseClient _client;

  const AdminTeacherSubscriptionsDataSource(this._client);

  Future<List<AdminTeacherSubscriptionModel>> getTeachers({
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    final from = (page - 1) * limit;
    final to = from + limit - 1;

    var query = _client
        .from('profiles')
        .select('id,email,name,phone,avatar_url,role')
        .eq('role', 'instructor');

    final normalizedSearch = search?.trim();
    if (normalizedSearch != null && normalizedSearch.isNotEmpty) {
      query = query.or(
        'name.ilike.%$normalizedSearch%,email.ilike.%$normalizedSearch%,phone.ilike.%$normalizedSearch%',
      );
    }

    final profiles =
        await query.order('created_at', ascending: false).range(from, to);
    final profileRows = List<Map<String, dynamic>>.from(profiles as List);
    if (profileRows.isEmpty) return [];

    final profileIds = profileRows.map((row) => row['id'] as String).toList();
    final teacherRows = List<Map<String, dynamic>>.from(
      await _client
          .from('teachers')
          .select('id,profile_id,display_name,avatar_url,is_active')
          .inFilter('profile_id', profileIds),
    );

    final teachersByProfile = {
      for (final teacher in teacherRows)
        teacher['profile_id'] as String: teacher,
    };
    final teacherIds = teacherRows.map((row) => row['id'] as String).toList();

    final subscriptionsByTeacher = <String, List<TeacherSubscriptionModel>>{};
    if (teacherIds.isNotEmpty) {
      final subscriptionRows = List<Map<String, dynamic>>.from(
        await _client
            .from('teacher_subscriptions')
            .select()
            .inFilter('teacher_id', teacherIds)
            .order('starts_at', ascending: false),
      );

      for (final row in subscriptionRows) {
        final subscription = TeacherSubscriptionModel.fromJson(row);
        subscriptionsByTeacher
            .putIfAbsent(subscription.teacherId, () => [])
            .add(subscription);
      }
    }

    return profileRows
        .where((profile) => teachersByProfile.containsKey(profile['id']))
        .map((profile) {
      final teacher = teachersByProfile[profile['id']]!;
      return AdminTeacherSubscriptionModel.fromParts(
        profile: profile,
        teacher: teacher,
        subscriptions: subscriptionsByTeacher[teacher['id']] ?? const [],
      );
    }).toList();
  }

  Future<List<TeacherSubscriptionModel>> getSubscriptions(
      String teacherId) async {
    final rows = List<Map<String, dynamic>>.from(
      await _client
          .from('teacher_subscriptions')
          .select()
          .eq('teacher_id', teacherId)
          .order('starts_at', ascending: false),
    );

    return rows.map(TeacherSubscriptionModel.fromJson).toList();
  }

  Future<void> createSubscription(TeacherSubscriptionUpsertDto dto) async {
    await _client.from('teacher_subscriptions').insert(
          dto.toJson(_client.auth.currentUser?.id),
        );
  }

  Future<void> extendSubscription({
    required TeacherSubscriptionModel subscription,
    required int days,
    String? notes,
  }) async {
    final baseDate = subscription.endsAt.isAfter(DateTime.now())
        ? subscription.endsAt
        : DateTime.now();
    await _client.from('teacher_subscriptions').update({
      'ends_at': baseDate.add(Duration(days: days)).toUtc().toIso8601String(),
      'status': TeacherSubscriptionStatus.active.value,
      'notes': notes ?? subscription.notes,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', subscription.id);
  }

  Future<void> cancelSubscription(String subscriptionId,
      {String? notes}) async {
    await _client.from('teacher_subscriptions').update({
      'status': TeacherSubscriptionStatus.cancelled.value,
      'notes': notes,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', subscriptionId);
  }

  Future<void> reactivateSubscription(String subscriptionId) async {
    await _client.from('teacher_subscriptions').update({
      'status': TeacherSubscriptionStatus.active.value,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', subscriptionId);
  }
}
