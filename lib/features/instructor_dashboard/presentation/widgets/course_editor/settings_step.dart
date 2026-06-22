import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/services/app_logger.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../domain/repositories/instructor_repository.dart';
import '../../cubit/course_editor_cubit.dart';
import 'dialogs/scheduled_date_time_picker.dart';

/// Settings Step - Requirements, objectives, and publish validation
class SettingsStep extends StatelessWidget {
  const SettingsStep({super.key});

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cubit = context.read<CourseEditorCubit>();

    return BlocBuilder<CourseEditorCubit, CourseEditorState>(
      builder: (context, state) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isArabic ? 'إعدادات الكورس' : 'Course Settings',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color:
                      isDark ? AppColors.textMainDark : AppColors.textMainLight,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isArabic
                    ? 'راجع إعدادات الكورس قبل النشر'
                    : 'Review your course settings before publishing',
                style: TextStyle(
                  color: isDark
                      ? AppColors.textMutedDark
                      : AppColors.textMutedLight,
                ),
              ),
              const SizedBox(height: 32),
              _buildPublishChecklist(context, state, isArabic, isDark),
              const SizedBox(height: 24),
              _buildCourseSummary(state, isArabic, isDark),
              const SizedBox(height: 24),
              _buildAvailabilitySchedule(context, state, cubit, isArabic, isDark),
              const SizedBox(height: 32),
              if (!state.isEditing)
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => cubit.setStep(2),
                      icon: Icon(
                          isArabic ? Icons.arrow_forward : Icons.arrow_back),
                      label: Text(isArabic ? 'السابق' : 'Previous'),
                    ),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        OutlinedButton(
                          onPressed: () async {
                            AppLogger.i('📝 [SettingsStep] Save Draft pressed');
                            final success = await cubit.saveDraft();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(success
                                      ? (isArabic
                                          ? 'تم حفظ المسودة'
                                          : 'Draft saved')
                                      : (isArabic
                                          ? 'فشل في الحفظ'
                                          : 'Failed to save')),
                                  backgroundColor: success
                                      ? AppColors.success
                                      : AppColors.error,
                                ),
                              );
                            }
                          },
                          child:
                              Text(isArabic ? 'حفظ كمسودة' : 'Save as Draft'),
                        ),
                        ElevatedButton.icon(
                          onPressed: () =>
                              cubit.setStep(4), // Go to Attachments
                          icon: Icon(isArabic
                              ? Icons.arrow_back
                              : Icons.arrow_forward),
                          label: Text(isArabic
                              ? 'التالي (المرفقات)'
                              : 'Next (Attachments)'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPublishChecklist(BuildContext context, CourseEditorState state,
      bool isArabic, bool isDark) {
    final checks = [
      _CheckItem(
        title: isArabic ? 'العنوان (عربي)' : 'Title (Arabic)',
        isComplete: state.titleAr.isNotEmpty,
      ),
      _CheckItem(
        title: isArabic ? 'العنوان (إنجليزي)' : 'Title (English)',
        isComplete: state.titleEn.isNotEmpty,
      ),
      _CheckItem(
        title: isArabic ? 'الوصف (عربي)' : 'Description (Arabic)',
        isComplete: state.descriptionAr.isNotEmpty,
      ),
      _CheckItem(
        title: isArabic ? 'الوصف (إنجليزي)' : 'Description (English)',
        isComplete: state.descriptionEn.isNotEmpty,
      ),
      _CheckItem(
        title: isArabic ? 'التصنيف' : 'Category',
        isComplete: state.categoryId != null,
      ),
      _CheckItem(
        title: isArabic ? 'الأقسام' : 'Sections',
        isComplete: state.sections.isNotEmpty,
      ),
      _CheckItem(
        title: isArabic ? 'الدروس' : 'Lessons',
        isComplete: state.sections.any((s) => s.lessons.isNotEmpty),
      ),
    ];

    final completedCount = checks.where((c) => c.isComplete).length;
    final progress = completedCount / checks.length;

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isArabic ? 'قائمة التحقق للنشر' : 'Publish Checklist',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color:
                      isDark ? AppColors.textMainDark : AppColors.textMainLight,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: progress == 1
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '$completedCount/${checks.length}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color:
                        progress == 1 ? AppColors.success : AppColors.warning,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: isDark ? AppColors.borderDark : AppColors.grey200,
            valueColor: AlwaysStoppedAnimation(
              progress == 1 ? AppColors.success : AppColors.warning,
            ),
          ),
          const SizedBox(height: 20),
          ...checks.map((check) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Icon(
                      check.isComplete
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: check.isComplete
                          ? AppColors.success
                          : Colors.grey[400],
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      check.title,
                      style: TextStyle(
                        color: check.isComplete
                            ? (isDark
                                ? AppColors.textMainDark
                                : AppColors.textMainLight)
                            : Colors.grey[500],
                        decoration: check.isComplete
                            ? null
                            : TextDecoration.lineThrough,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildCourseSummary(
      CourseEditorState state, bool isArabic, bool isDark) {
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
            isDark: isDark,
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
            isDark: isDark,
          ),
          _buildSummaryRow(
            icon: Icons.signal_cellular_alt,
            label: isArabic ? 'المستوى' : 'Level',
            value: _getLevelLabel(state.level, isArabic),
            isDark: isDark,
          ),
          _buildSummaryRow(
            icon: Icons.folder_outlined,
            label: isArabic ? 'الأقسام' : 'Sections',
            value: '${state.sections.length}',
            isDark: isDark,
          ),
          _buildSummaryRow(
            icon: Icons.play_lesson_outlined,
            label: isArabic ? 'الدروس' : 'Lessons',
            value: '$totalLessons',
            isDark: isDark,
          ),
          _buildSummaryRow(
            icon: Icons.attach_money,
            label: isArabic ? 'السعر' : 'Price',
            value: state.price > 0
                ? '${state.price.toStringAsFixed(0)} ${state.currency}'
                : (isArabic ? 'مجاني' : 'Free'),
            isDark: isDark,
          ),
          if (state.badge != null && state.badge!.isNotEmpty)
            _buildSummaryRow(
              icon: Icons.local_offer,
              label: isArabic ? 'الشارة' : 'Badge',
              value: state.badge!,
              isDark: isDark,
            ),
        ],
      ),
    );
  }

  Widget _buildAvailabilitySchedule(BuildContext context,
      CourseEditorState state, CourseEditorCubit cubit, bool isArabic, bool isDark) {
    final hasInvalidWindow = state.availableFrom != null &&
        state.availableUntil != null &&
        !state.availableUntil!.isAfter(state.availableFrom!);

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
          Row(
            children: [
              const Icon(Icons.event_available, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isArabic ? 'جدولة ظهور الكورس' : 'Course Availability',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textMainDark
                        : AppColors.textMainLight,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isArabic
                ? 'حدد مدة ظهور الكورس للطلاب. اتركها فارغة ليظل متاحا دائما.'
                : 'Set when students can see this course. Leave empty to keep it always available.',
            style: TextStyle(
              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            ),
          ),
          const SizedBox(height: 16),
          ScheduledDateTimePicker(
            label: isArabic ? 'يظهر من' : 'Visible From',
            selectedDateTime: state.availableFrom,
            isArabic: isArabic,
            onChanged: (value) => cubit.updateAvailabilitySchedule(
              availableFrom: value,
              clearAvailableFrom: value == null,
            ),
          ),
          const SizedBox(height: 12),
          ScheduledDateTimePicker(
            label: isArabic ? 'يختفي في' : 'Visible Until',
            selectedDateTime: state.availableUntil,
            isArabic: isArabic,
            onChanged: (value) => cubit.updateAvailabilitySchedule(
              availableUntil: value,
              clearAvailableUntil: value == null,
            ),
          ),
          if (hasInvalidWindow) ...[
            const SizedBox(height: 12),
            Text(
              isArabic
                  ? 'وقت الاختفاء يجب أن يكون بعد وقت الظهور.'
                  : 'Visible until must be after visible from.',
              style: const TextStyle(color: AppColors.error, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
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

class _CheckItem {
  final String title;
  final bool isComplete;

  const _CheckItem({required this.title, required this.isComplete});
}

extension _Let<T> on T {
  R let<R>(R Function(T) block) => block(this);
}
