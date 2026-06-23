import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../cubit/course_editor_cubit.dart';
import '../../screens/course_edit_step_screen.dart';

/// Edit menu shown when editing an existing course – displays a card grid
/// where the instructor can navigate to each step individually.
class CourseEditMenu extends StatelessWidget {
  const CourseEditMenu({
    super.key,
    required this.state,
    required this.isDark,
  });

  final CourseEditorState state;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCourseHeader(context),
          const SizedBox(height: 32),
          Text(
            isArabic ? 'تعديل أجزاء الكورس' : 'Edit Course Parts',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _buildEditCard(
                    context: context,
                    title: isArabic ? 'المعلومات الأساسية' : 'Basic Info',
                    icon: Icons.info_outline,
                    stepIndex: 0,
                    width: _getCardWidth(constraints.maxWidth),
                  ),
                  _buildEditCard(
                    context: context,
                    title: isArabic
                        ? 'المحتوى والدروس'
                        : 'Curriculum & Lessons',
                    icon: Icons.play_lesson_outlined,
                    stepIndex: 1,
                    width: _getCardWidth(constraints.maxWidth),
                  ),
                  _buildEditCard(
                    context: context,
                    title: isArabic ? 'التسعير' : 'Pricing',
                    icon: Icons.attach_money,
                    stepIndex: 2,
                    width: _getCardWidth(constraints.maxWidth),
                  ),
                  _buildEditCard(
                    context: context,
                    title: isArabic ? 'إعدادات النشر' : 'Publish Settings',
                    icon: Icons.settings_outlined,
                    stepIndex: 3,
                    width: _getCardWidth(constraints.maxWidth),
                  ),
                  _buildEditCard(
                    context: context,
                    title: isArabic ? 'المرفقات' : 'Attachments',
                    icon: Icons.attach_file,
                    stepIndex: 4,
                    width: _getCardWidth(constraints.maxWidth),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCourseHeader(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          if (state.thumbnailUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                state.thumbnailUrl!,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildThumbnailPlaceholder(),
              ),
            )
          else
            _buildThumbnailPlaceholder(),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArabic ? state.titleAr : state.titleEn,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: state.isOriginalPublished
                        ? AppColors.success.withValues(alpha: 0.1)
                        : AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    state.isOriginalPublished
                        ? (isArabic ? 'منشور' : 'Published')
                        : (isArabic ? 'مسودة' : 'Draft'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: state.isOriginalPublished
                          ? AppColors.success
                          : AppColors.warning,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnailPlaceholder() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: isDark ? AppColors.borderDark : AppColors.grey200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.image_outlined,
        color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
      ),
    );
  }

  Widget _buildEditCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required int stepIndex,
    required double width,
  }) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => BlocProvider.value(
              value: context.read<CourseEditorCubit>(),
              child: CourseEditStepScreen(stepIndex: stepIndex),
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: width,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  double _getCardWidth(double parentWidth) {
    if (parentWidth < 400) return parentWidth;
    if (parentWidth < 800) return (parentWidth - 16) / 2;
    return (parentWidth - 32) / 3;
  }
}
