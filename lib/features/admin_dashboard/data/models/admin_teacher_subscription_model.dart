class AdminTeacherSubscriptionModel {
  final String id;
  final String teacherId;
  final String profileId;
  final String displayName;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final bool teacherActive;
  final List<TeacherSubscriptionModel> subscriptions;

  const AdminTeacherSubscriptionModel({
    required this.id,
    required this.teacherId,
    required this.profileId,
    required this.displayName,
    required this.email,
    this.phone,
    this.avatarUrl,
    required this.teacherActive,
    this.subscriptions = const [],
  });

  TeacherSubscriptionModel? get currentSubscription {
    final now = DateTime.now();
    for (final subscription in subscriptions) {
      if (subscription.isActiveAt(now)) {
        return subscription;
      }
    }
    return null;
  }

  TeacherSubscriptionModel? get latestSubscription {
    if (subscriptions.isEmpty) {
      return null;
    }
    return subscriptions.first;
  }

  bool get hasActiveSubscription => currentSubscription != null;

  String get statusLabel {
    if (hasActiveSubscription) {
      return 'Active';
    }
    final latest = latestSubscription;
    if (latest == null) {
      return 'No subscription';
    }
    if (latest.status == TeacherSubscriptionStatus.cancelled) {
      return 'Cancelled';
    }
    return 'Expired';
  }

  factory AdminTeacherSubscriptionModel.fromParts({
    required Map<String, dynamic> profile,
    required Map<String, dynamic> teacher,
    required List<TeacherSubscriptionModel> subscriptions,
  }) {
    final profileName = profile['name'] as String?;
    final teacherName = teacher['display_name'] as String?;
    final email = profile['email'] as String? ?? '';

    return AdminTeacherSubscriptionModel(
      id: teacher['id'] as String,
      teacherId: teacher['id'] as String,
      profileId: profile['id'] as String,
      displayName: (teacherName?.trim().isNotEmpty ?? false)
          ? teacherName!.trim()
          : ((profileName?.trim().isNotEmpty ?? false)
              ? profileName!.trim()
              : email.split('@').first),
      email: email,
      phone: profile['phone'] as String?,
      avatarUrl:
          teacher['avatar_url'] as String? ?? profile['avatar_url'] as String?,
      teacherActive: teacher['is_active'] as bool? ?? true,
      subscriptions: subscriptions,
    );
  }
}

enum TeacherSubscriptionStatus { active, cancelled, expired }

extension TeacherSubscriptionStatusX on TeacherSubscriptionStatus {
  String get value {
    return switch (this) {
      TeacherSubscriptionStatus.active => 'active',
      TeacherSubscriptionStatus.cancelled => 'cancelled',
      TeacherSubscriptionStatus.expired => 'expired',
    };
  }

  String get labelAr {
    return switch (this) {
      TeacherSubscriptionStatus.active => 'ساري',
      TeacherSubscriptionStatus.cancelled => 'ملغي',
      TeacherSubscriptionStatus.expired => 'منتهي',
    };
  }

  static TeacherSubscriptionStatus fromValue(String? value) {
    return switch (value) {
      'cancelled' => TeacherSubscriptionStatus.cancelled,
      'expired' => TeacherSubscriptionStatus.expired,
      _ => TeacherSubscriptionStatus.active,
    };
  }
}

class TeacherSubscriptionModel {
  final String id;
  final String teacherId;
  final DateTime startsAt;
  final DateTime endsAt;
  final TeacherSubscriptionStatus status;
  final String? planName;
  final double? amount;
  final String currency;
  final String? notes;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TeacherSubscriptionModel({
    required this.id,
    required this.teacherId,
    required this.startsAt,
    required this.endsAt,
    required this.status,
    this.planName,
    this.amount,
    this.currency = 'EGP',
    this.notes,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  bool isActiveAt(DateTime date) {
    return status == TeacherSubscriptionStatus.active &&
        !date.isBefore(startsAt) &&
        date.isBefore(endsAt);
  }

  int get remainingDays {
    final diff = endsAt.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  factory TeacherSubscriptionModel.fromJson(Map<String, dynamic> json) {
    return TeacherSubscriptionModel(
      id: json['id'] as String,
      teacherId: json['teacher_id'] as String,
      startsAt: DateTime.parse(json['starts_at'] as String).toLocal(),
      endsAt: DateTime.parse(json['ends_at'] as String).toLocal(),
      status: TeacherSubscriptionStatusX.fromValue(json['status'] as String?),
      planName: json['plan_name'] as String?,
      amount: (json['amount'] as num?)?.toDouble(),
      currency: json['currency'] as String? ?? 'EGP',
      notes: json['notes'] as String?,
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      updatedAt: DateTime.parse(json['updated_at'] as String).toLocal(),
    );
  }
}

class TeacherSubscriptionUpsertDto {
  final String teacherId;
  final DateTime startsAt;
  final DateTime endsAt;
  final String planName;
  final double? amount;
  final String currency;
  final String? notes;

  const TeacherSubscriptionUpsertDto({
    required this.teacherId,
    required this.startsAt,
    required this.endsAt,
    required this.planName,
    this.amount,
    this.currency = 'EGP',
    this.notes,
  });

  Map<String, dynamic> toJson(String? createdBy) {
    return {
      'teacher_id': teacherId,
      'starts_at': startsAt.toUtc().toIso8601String(),
      'ends_at': endsAt.toUtc().toIso8601String(),
      'status': TeacherSubscriptionStatus.active.value,
      'plan_name': planName,
      'amount': amount,
      'currency': currency,
      'notes': notes,
      'created_by': createdBy,
    };
  }
}
