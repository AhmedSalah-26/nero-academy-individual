import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../data/models/admin_course_model.dart';

class CourseDetailsThumbnail extends StatelessWidget {
  final AdminCourseModel course;
  final bool isDark;

  const CourseDetailsThumbnail({
    super.key,
    required this.course,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: course.thumbnailUrl != null
          ? CachedNetworkImage(
              imageUrl: course.thumbnailUrl!,
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
              placeholder: (_, __) => _buildPlaceholder(isDark),
              errorWidget: (_, __, ___) => _buildPlaceholder(isDark),
            )
          : _buildPlaceholder(isDark),
    );
  }

  Widget _buildPlaceholder(bool isDark) {
    return Container(
      width: double.infinity,
      height: 200,
      color: isDark ? AppColors.cardDark : AppColors.grey100,
      child: Icon(
        Icons.school_rounded,
        size: 64,
        color: isDark ? AppColors.textMutedDark : AppColors.grey400,
      ),
    );
  }
}
