import 'package:equatable/equatable.dart';

/// Instructor Entity
class InstructorEntity extends Equatable {
  final String id;
  final String name;
  final String? avatarUrl;
  final String? coverImageUrl;
  final String? headline;
  final String? bio;
  final List<String>? expertise;
  final int totalStudents;
  final int totalCourses;
  final double averageRating;
  final int totalReviews;
  final String? website;
  final String? linkedin;
  final String? twitter;
  final String? facebook;
  final String? youtube;
  final DateTime? joinedAt;

  const InstructorEntity({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.coverImageUrl,
    this.headline,
    this.bio,
    this.expertise,
    this.totalStudents = 0,
    this.totalCourses = 0,
    this.averageRating = 0.0,
    this.totalReviews = 0,
    this.website,
    this.linkedin,
    this.twitter,
    this.facebook,
    this.youtube,
    this.joinedAt,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        avatarUrl,
        coverImageUrl,
        headline,
        bio,
        expertise,
        totalStudents,
        totalCourses,
        averageRating,
        totalReviews,
      ];
}
