// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/admin_course_model.dart';
import '../widgets/course_details/course_actions_bar.dart';
import '../widgets/course_details/course_info_section.dart';
import '../widgets/course_details/course_stats_section.dart';
import '../widgets/course_details/course_thumbnail.dart';

/// Course Details Screen - Full screen version for viewing course details
class CourseDetailsScreen extends StatefulWidget {
  final AdminCourseModel course;
  final VoidCallback? onPublish;
  final VoidCallback? onUnpublish;
  final VoidCallback? onFeature;
  final VoidCallback? onUnfeature;
  final VoidCallback? onSuspend;
  final VoidCallback? onUnsuspend;
  final VoidCallback? onDelete;
  final VoidCallback? onViewEnrollments;

  const CourseDetailsScreen({
    super.key,
    required this.course,
    this.onPublish,
    this.onUnpublish,
    this.onFeature,
    this.onUnfeature,
    this.onSuspend,
    this.onUnsuspend,
    this.onDelete,
    this.onViewEnrollments,
  });

  @override
  State<CourseDetailsScreen> createState() => _CourseDetailsScreenState();
}

class _CourseDetailsScreenState extends State<CourseDetailsScreen> {
  late AdminCourseModel _currentCourse;

  @override
  void initState() {
    super.initState();
    _currentCourse = widget.course;
  }

  void _updateCourse({
    bool? isPublished,
    bool? isFeatured,
    bool? isSuspended,
    String? suspensionReason,
  }) {
    setState(() {
      _currentCourse = AdminCourseModel(
        id: _currentCourse.id,
        titleAr: _currentCourse.titleAr,
        titleEn: _currentCourse.titleEn,
        thumbnailUrl: _currentCourse.thumbnailUrl,
        instructorId: _currentCourse.instructorId,
        instructorName: _currentCourse.instructorName,
        categoryName: _currentCourse.categoryName,
        price: _currentCourse.price,
        discountPrice: _currentCourse.discountPrice,
        isPublished: isPublished ?? _currentCourse.isPublished,
        isSuspended: isSuspended ?? _currentCourse.isSuspended,
        isFeatured: isFeatured ?? _currentCourse.isFeatured,
        suspensionReason: suspensionReason ?? _currentCourse.suspensionReason,
        enrolledCount: _currentCourse.enrolledCount,
        rating: _currentCourse.rating,
        ratingCount: _currentCourse.ratingCount,
        totalRevenue: _currentCourse.totalRevenue,
        createdAt: _currentCourse.createdAt,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(isArabic ? 'تفاصيل الكورس' : 'Course Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CourseDetailsThumbnail(course: _currentCourse, isDark: isDark),
            const SizedBox(height: 20),
            CourseDetailsInfoSection(
                course: _currentCourse, isDark: isDark, isArabic: isArabic),
            const SizedBox(height: 20),
            CourseDetailsStatsSection(
                course: _currentCourse, isDark: isDark, isArabic: isArabic),
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: CourseActionsBar(
        course: _currentCourse,
        isDark: isDark,
        isArabic: isArabic,
        onPublish: () {
          widget.onPublish?.call();
          _updateCourse(isPublished: true);
          _showSnackBar(
              context,
              isArabic ? 'تم نشر الكورس' : 'Course published',
              AppColors.success);
        },
        onUnpublish: () {
          widget.onUnpublish?.call();
          _updateCourse(isPublished: false);
          _showSnackBar(
              context,
              isArabic ? 'تم إلغاء نشر الكورس' : 'Course unpublished',
              AppColors.success);
        },
        onFeature: () {
          widget.onFeature?.call();
          _updateCourse(isFeatured: true);
          _showSnackBar(
              context,
              isArabic ? 'تم تمييز الكورس' : 'Course featured',
              AppColors.success);
        },
        onUnfeature: () {
          widget.onUnfeature?.call();
          _updateCourse(isFeatured: false);
          _showSnackBar(
              context,
              isArabic ? 'تم إلغاء تمييز الكورس' : 'Course unfeatured',
              AppColors.success);
        },
        onSuspend: (reason) {
          widget.onSuspend?.call();
          _updateCourse(isSuspended: true, suspensionReason: reason);
          _showSnackBar(
              context,
              isArabic ? 'تم إيقاف الكورس' : 'Course suspended',
              AppColors.warning);
        },
        onUnsuspend: () {
          widget.onUnsuspend?.call();
          _updateCourse(isSuspended: false, suspensionReason: null);
          _showSnackBar(
              context,
              isArabic ? 'تم إلغاء إيقاف الكورس' : 'Course unsuspended',
              AppColors.success);
        },
        onDelete: () {
          widget.onDelete?.call();
          _showSnackBar(context, isArabic ? 'تم حذف الكورس' : 'Course deleted',
              AppColors.error);
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              Navigator.pop(context);
            }
          });
        },
        onViewEnrollments: widget.onViewEnrollments,
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
