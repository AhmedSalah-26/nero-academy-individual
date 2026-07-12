/// Report Status enum
enum ReportStatusType {
  pending,
  reviewed,
  resolved,
  rejected;

  static ReportStatusType fromString(String value) {
    return ReportStatusType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ReportStatusType.pending,
    );
  }

  /// Valid transitions from this status
  List<ReportStatusType> get validTransitions {
    switch (this) {
      case ReportStatusType.pending:
        return [ReportStatusType.reviewed];
      case ReportStatusType.reviewed:
        return [ReportStatusType.resolved, ReportStatusType.rejected];
      case ReportStatusType.resolved:
      case ReportStatusType.rejected:
        return []; // Terminal states
    }
  }

  /// Check if transition to target status is valid
  bool canTransitionTo(ReportStatusType target) {
    return validTransitions.contains(target);
  }
}

/// Report Type enum
enum ReportType {
  course,
  review;

  static ReportType fromString(String value) {
    return ReportType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ReportType.course,
    );
  }
}

/// Report Action enum - actions that can be taken when resolving
enum ReportAction {
  none,
  hideContent,
  warnUser,
  banUser;

  static ReportAction fromString(String value) {
    switch (value) {
      case 'hide_content':
        return ReportAction.hideContent;
      case 'warn_user':
        return ReportAction.warnUser;
      case 'ban_user':
        return ReportAction.banUser;
      default:
        return ReportAction.none;
    }
  }

  String toJsonValue() {
    switch (this) {
      case ReportAction.hideContent:
        return 'hide_content';
      case ReportAction.warnUser:
        return 'warn_user';
      case ReportAction.banUser:
        return 'ban_user';
      case ReportAction.none:
        return 'none';
    }
  }
}

/// Admin Report Model - Unified model for course and review reports
class AdminReportModel {
  final String id;
  final ReportType type;
  final String? courseId;
  final String? courseTitleAr;
  final String? courseTitleEn;
  final String? reviewId;
  final String reporterId;
  final String? reporterName;
  final String? reporterEmail;
  final String? reporterAvatar;
  final String reason;
  final String? description;
  final ReportStatusType status;
  final String? adminResponse;
  final String? adminId;
  final String? adminName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? resolvedAt;
  // Cached review data (for review reports)
  final String? cachedReviewerId;
  final String? cachedReviewerName;
  final String? cachedReviewComment;
  final int? cachedReviewRating;

  const AdminReportModel({
    required this.id,
    required this.type,
    this.courseId,
    this.courseTitleAr,
    this.courseTitleEn,
    this.reviewId,
    required this.reporterId,
    this.reporterName,
    this.reporterEmail,
    this.reporterAvatar,
    required this.reason,
    this.description,
    required this.status,
    this.adminResponse,
    this.adminId,
    this.adminName,
    required this.createdAt,
    required this.updatedAt,
    this.resolvedAt,
    this.cachedReviewerId,
    this.cachedReviewerName,
    this.cachedReviewComment,
    this.cachedReviewRating,
  });

  /// Create from course_reports table JSON
  factory AdminReportModel.fromCourseReportJson(Map<String, dynamic> json) {
    return AdminReportModel(
      id: json['id'] as String,
      type: ReportType.course,
      courseId: json['course_id'] as String?,
      courseTitleAr: _extractCourseTitleAr(json['course']),
      courseTitleEn: _extractCourseTitleEn(json['course']),
      reviewId: null,
      reporterId: json['user_id'] as String,
      reporterName: _extractUserName(json['user']),
      reporterEmail: _extractUserEmail(json['user']),
      reporterAvatar: _extractUserAvatar(json['user']),
      reason: json['reason'] as String,
      description: json['description'] as String?,
      status:
          ReportStatusType.fromString(json['status'] as String? ?? 'pending'),
      adminResponse: json['admin_response'] as String?,
      adminId: json['admin_id'] as String?,
      adminName: _extractUserName(json['admin']),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(
          json['updated_at'] as String? ?? json['created_at'] as String),
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'] as String)
          : null,
    );
  }

  /// Create from review_reports table JSON
  factory AdminReportModel.fromReviewReportJson(Map<String, dynamic> json) {
    return AdminReportModel(
      id: json['id'] as String,
      type: ReportType.review,
      courseId: null,
      courseTitleAr: null,
      courseTitleEn: null,
      reviewId: json['review_id'] as String?,
      reporterId: json['user_id'] as String,
      reporterName: _extractUserName(json['user']),
      reporterEmail: _extractUserEmail(json['user']),
      reporterAvatar: _extractUserAvatar(json['user']),
      reason: json['reason'] as String,
      description: json['description'] as String?,
      status:
          ReportStatusType.fromString(json['status'] as String? ?? 'pending'),
      adminResponse: json['admin_response'] as String?,
      adminId: json['admin_id'] as String?,
      adminName: _extractUserName(json['admin']),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(
          json['updated_at'] as String? ?? json['created_at'] as String),
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'] as String)
          : null,
      cachedReviewerId: json['cached_reviewer_id'] as String?,
      cachedReviewerName: _extractUserName(json['reviewer']),
      cachedReviewComment: json['cached_review_comment'] as String?,
      cachedReviewRating: json['cached_review_rating'] as int?,
    );
  }

  static String? _extractCourseTitleAr(dynamic course) {
    if (course == null) return null;
    if (course is Map<String, dynamic>) {
      return course['title_ar'] as String?;
    }
    return null;
  }

  static String? _extractCourseTitleEn(dynamic course) {
    if (course == null) return null;
    if (course is Map<String, dynamic>) {
      return course['title_en'] as String?;
    }
    return null;
  }

  static String? _extractUserName(dynamic user) {
    if (user == null) return null;
    if (user is Map<String, dynamic>) {
      return user['name'] as String?;
    }
    return null;
  }

  static String? _extractUserEmail(dynamic user) {
    if (user == null) return null;
    if (user is Map<String, dynamic>) {
      return user['email'] as String?;
    }
    return null;
  }

  static String? _extractUserAvatar(dynamic user) {
    if (user == null) return null;
    if (user is Map<String, dynamic>) {
      return user['avatar_url'] as String?;
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'course_id': courseId,
      'review_id': reviewId,
      'user_id': reporterId,
      'reason': reason,
      'description': description,
      'status': status.name,
      'admin_response': adminResponse,
      'admin_id': adminId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'resolved_at': resolvedAt?.toIso8601String(),
      if (type == ReportType.review) ...{
        'cached_reviewer_id': cachedReviewerId,
        'cached_review_comment': cachedReviewComment,
        'cached_review_rating': cachedReviewRating,
      },
    };
  }

  /// Check if report is pending
  bool get isPending => status == ReportStatusType.pending;

  /// Check if report is resolved
  bool get isResolved => status == ReportStatusType.resolved;

  /// Check if report is rejected
  bool get isRejected => status == ReportStatusType.rejected;

  /// Check if report is in terminal state
  bool get isTerminal => isResolved || isRejected;

  /// Get status label for display
  String get statusLabel => status.name;

  /// Get type label for display
  String get typeLabel => type.name;

  /// Check if can transition to target status
  bool canTransitionTo(ReportStatusType target) {
    return status.canTransitionTo(target);
  }

  AdminReportModel copyWith({
    String? id,
    ReportType? type,
    String? courseId,
    String? courseTitleAr,
    String? courseTitleEn,
    String? reviewId,
    String? reporterId,
    String? reporterName,
    String? reporterEmail,
    String? reporterAvatar,
    String? reason,
    String? description,
    ReportStatusType? status,
    String? adminResponse,
    String? adminId,
    String? adminName,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? resolvedAt,
    String? cachedReviewerId,
    String? cachedReviewerName,
    String? cachedReviewComment,
    int? cachedReviewRating,
  }) {
    return AdminReportModel(
      id: id ?? this.id,
      type: type ?? this.type,
      courseId: courseId ?? this.courseId,
      courseTitleAr: courseTitleAr ?? this.courseTitleAr,
      courseTitleEn: courseTitleEn ?? this.courseTitleEn,
      reviewId: reviewId ?? this.reviewId,
      reporterId: reporterId ?? this.reporterId,
      reporterName: reporterName ?? this.reporterName,
      reporterEmail: reporterEmail ?? this.reporterEmail,
      reporterAvatar: reporterAvatar ?? this.reporterAvatar,
      reason: reason ?? this.reason,
      description: description ?? this.description,
      status: status ?? this.status,
      adminResponse: adminResponse ?? this.adminResponse,
      adminId: adminId ?? this.adminId,
      adminName: adminName ?? this.adminName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      cachedReviewerId: cachedReviewerId ?? this.cachedReviewerId,
      cachedReviewerName: cachedReviewerName ?? this.cachedReviewerName,
      cachedReviewComment: cachedReviewComment ?? this.cachedReviewComment,
      cachedReviewRating: cachedReviewRating ?? this.cachedReviewRating,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AdminReportModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// DTO for resolving/rejecting reports
class ResolveReportDto {
  final ReportStatusType status;
  final String? adminResponse;
  final ReportAction action;

  const ResolveReportDto({
    required this.status,
    this.adminResponse,
    this.action = ReportAction.none,
  });

  /// Validate the DTO
  String? validate() {
    if (status != ReportStatusType.resolved &&
        status != ReportStatusType.rejected) {
      return 'Status must be resolved or rejected';
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status.name,
      'admin_response': adminResponse,
      'action': action.toJsonValue(),
      'resolved_at': DateTime.now().toIso8601String(),
    };
  }

  /// Create update data for database
  Map<String, dynamic> toUpdateJson(String adminId) {
    return {
      'status': status.name,
      'admin_response': adminResponse,
      'admin_id': adminId,
      'updated_at': DateTime.now().toIso8601String(),
      if (status == ReportStatusType.resolved ||
          status == ReportStatusType.rejected)
        'resolved_at': DateTime.now().toIso8601String(),
    };
  }
}

/// Model for report statistics
class ReportStatsModel {
  final int totalReports;
  final int pendingReports;
  final int reviewedReports;
  final int resolvedReports;
  final int rejectedReports;
  final int courseReports;
  final int reviewReports;

  const ReportStatsModel({
    this.totalReports = 0,
    this.pendingReports = 0,
    this.reviewedReports = 0,
    this.resolvedReports = 0,
    this.rejectedReports = 0,
    this.courseReports = 0,
    this.reviewReports = 0,
  });

  factory ReportStatsModel.fromJson(Map<String, dynamic> json) {
    return ReportStatsModel(
      totalReports: json['total_reports'] as int? ?? 0,
      pendingReports: json['pending_reports'] as int? ?? 0,
      reviewedReports: json['reviewed_reports'] as int? ?? 0,
      resolvedReports: json['resolved_reports'] as int? ?? 0,
      rejectedReports: json['rejected_reports'] as int? ?? 0,
      courseReports: json['course_reports'] as int? ?? 0,
      reviewReports: json['review_reports'] as int? ?? 0,
    );
  }

  /// Calculate from list of reports
  factory ReportStatsModel.fromReports(List<AdminReportModel> reports) {
    return ReportStatsModel(
      totalReports: reports.length,
      pendingReports:
          reports.where((r) => r.status == ReportStatusType.pending).length,
      reviewedReports:
          reports.where((r) => r.status == ReportStatusType.reviewed).length,
      resolvedReports:
          reports.where((r) => r.status == ReportStatusType.resolved).length,
      rejectedReports:
          reports.where((r) => r.status == ReportStatusType.rejected).length,
      courseReports: reports.where((r) => r.type == ReportType.course).length,
      reviewReports: reports.where((r) => r.type == ReportType.review).length,
    );
  }

  /// Get unresolved count (pending + reviewed)
  int get unresolvedCount => pendingReports + reviewedReports;
}
