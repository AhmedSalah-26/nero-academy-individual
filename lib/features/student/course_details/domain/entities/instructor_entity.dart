import 'package:equatable/equatable.dart';

/// Instructor Entity - Pure Dart Object
class InstructorEntity extends Equatable {
  final String id;
  final String? displayName;
  final String? headlineAr;
  final String? headlineEn;
  final String? bioAr;
  final String? bioEn;
  final String? avatarUrl;
  final String? coverImageUrl;
  final int totalStudents;
  final int totalCourses;
  final int totalReviews;
  final double averageRating;
  final bool isVerified;
  final List<String>? expertise;
  final Map<String, String>? socialLinks;

  const InstructorEntity({
    required this.id,
    this.displayName,
    this.headlineAr,
    this.headlineEn,
    this.bioAr,
    this.bioEn,
    this.avatarUrl,
    this.coverImageUrl,
    this.totalStudents = 0,
    this.totalCourses = 0,
    this.totalReviews = 0,
    this.averageRating = 0,
    this.isVerified = false,
    this.expertise,
    this.socialLinks,
  });

  String getHeadline(String locale) => locale == 'ar'
      ? (headlineAr ?? headlineEn ?? '')
      : (headlineEn ?? headlineAr ?? '');

  String getBio(String locale) =>
      locale == 'ar' ? (bioAr ?? bioEn ?? '') : (bioEn ?? bioAr ?? '');

  @override
  List<Object?> get props => [
        id,
        displayName,
        headlineAr,
        headlineEn,
        bioAr,
        bioEn,
        avatarUrl,
        coverImageUrl,
        totalStudents,
        totalCourses,
        totalReviews,
        averageRating,
        isVerified,
        expertise,
        socialLinks,
      ];
}
