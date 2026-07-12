import 'package:flutter/material.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/features/instructor_dashboard/domain/repositories/instructor_repository.dart';
import 'package:lms_platform/features/instructor_dashboard/presentation/cubit/course_editor_cubit.dart';

/// Shows a summary card of all key course details (title, category, level, etc.)
class CourseSummaryCard extends StatelessWidget {
  const CourseSummaryCard({
    super.key,
    required this.state,
    required this.isArabic,
    required this.isDark,
  });

  final CourseEditorState state;
  final bool isArabic;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final totalLessons =
        state.sections.fold<int>(0, (sum, s) => sum + s.lessons.length);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isArabic ? 'ملخص الكورس' : 'Course Summary',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
            ),
          ),
          const SizedBox(height: 16),
          _buildSummaryRow(
            icon: Icons.title,
            label: isArabic ? 'العنوان' : 'Title',
            value: isArabic ? state.titleAr : state.titleEn,
          ),
          _buildSummaryRow(
            icon: Icons.category_outlined,
            label: isArabic ? 'التصنيف' : 'Category',
            value: state.categoryId != null
                ? state.categories
                    .firstWhere(
                      (c) => c.id == state.categoryId,
                      orElse: () => const CategoryOption(
                          id: '', nameAr: '-', nameEn: '-'),
                    )
                    .let((c) => isArabic ? c.nameAr : c.nameEn)
                : '-',
          ),
          _buildSummaryRow(
            icon: Icons.signal_cellular_alt,
            label: isArabic ? 'المستوى' : 'Level',
            value: _getLevelLabel(state.level, isArabic),
          ),
          _buildSummaryRow(
            icon: Icons.folder_outlined,
            label: isArabic ? 'الأقسام' : 'Sections',
            value: '${state.sections.length}',
          ),
          _buildSummaryRow(
            icon: Icons.play_lesson_outlined,
            label: isArabic ? 'الدروس' : 'Lessons',
            value: '$totalLessons',
          ),
          _buildSummaryRow(
            icon: Icons.attach_money,
            label: isArabic ? 'السعر' : 'Price',
            value: state.price > 0
                ? '${state.price.toStringAsFixed(0)} ${state.currency}'
                : (isArabic ? 'مجاني' : 'Free'),
          ),
          if (state.badge != null && state.badge!.isNotEmpty)
            _buildSummaryRow(
              icon: Icons.local_offer,
              label: isArabic ? 'الشارة' : 'Badge',
              value: state.badge!,
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
          ),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: TextStyle(
              color:
                  isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color:
                    isDark ? AppColors.textMainDark : AppColors.textMainLight,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _getLevelLabel(String level, bool isArabic) {
    switch (level) {
      case 'beginner':
        return isArabic ? 'مبتدئ' : 'Beginner';
      case 'intermediate':
        return isArabic ? 'متوسط' : 'Intermediate';
      case 'advanced':
        return isArabic ? 'متقدم' : 'Advanced';
      default:
        return level;
    }
  }
}

extension _Let<T> on T {
  R let<R>(R Function(T) block) => block(this);
}
