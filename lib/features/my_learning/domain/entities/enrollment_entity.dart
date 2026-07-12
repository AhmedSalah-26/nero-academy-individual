import 'package:equatable/equatable.dart';
import '../../../../core/utils/availability_window.dart';

/// Enrollment Status
enum EnrollmentStatus { active, completed, expired, refunded }

/// Enrollment Entity - Pure Dart Object
class EnrollmentEntity extends Equatable {
  final String id;
  final String courseId;
  final String userId;
  final String? titleAr;
  final String? titleEn;
  final String? thumbnailUrl;
  final String? instructorId;
  final String? instructorName;
  final String? instructorAvatar;
  final double progressPercentage;
  final int completedLessons;
  final int totalLessons;
  final int totalDurationMinutes;
  final int remainingMinutes;
  final EnrollmentStatus status;
  final DateTime enrolledAt;
  final DateTime? lastAccessedAt;
  final DateTime? completedAt;
  final DateTime? accessExpiresAt;
  final DateTime? availableFrom;
  final DateTime? availableUntil;
  final double rating;
  final int ratingCount;

  const EnrollmentEntity({
    required this.id,
    required this.courseId,
    required this.userId,
    this.titleAr,
    this.titleEn,
    this.thumbnailUrl,
    this.instructorId,
    this.instructorName,
    this.instructorAvatar,
    this.progressPercentage = 0,
    this.completedLessons = 0,
    this.totalLessons = 0,
    this.totalDurationMinutes = 0,
    this.remainingMinutes = 0,
    this.status = EnrollmentStatus.active,
    required this.enrolledAt,
    this.lastAccessedAt,
    this.completedAt,
    this.accessExpiresAt,
    this.availableFrom,
    this.availableUntil,
    this.rating = 0,
    this.ratingCount = 0,
  });

  /// Get title based on locale
  String getTitle(String locale) =>
      locale == 'ar' ? (titleAr ?? titleEn ?? '') : (titleEn ?? titleAr ?? '');

  /// Check if course is completed
  bool get isCompleted => status == EnrollmentStatus.completed;

  /// Check if course is in progress
  bool get isInProgress =>
      status == EnrollmentStatus.active && progressPercentage > 0;

  bool get isCurrentlyAvailable => AvailabilityWindow.isActive(
        availableFrom: availableFrom,
        availableUntil: availableUntil,
      );

  /// Get progress color based on percentage
  String get progressColorHex {
    if (progressPercentage >= 80) return '#10B981'; // emerald
    if (progressPercentage >= 30) return '#6F7A3A'; // primary
    return '#F59E0B'; // amber
  }

  @override
  List<Object?> get props => [
        id,
        courseId,
        userId,
        progressPercentage,
        status,
        completedLessons,
        lastAccessedAt,
        accessExpiresAt,
        availableFrom,
        availableUntil,
      ];
}

