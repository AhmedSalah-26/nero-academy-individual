import 'package:flutter/material.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/features/instructor_dashboard/presentation/cubit/course_editor_cubit.dart';
import 'dialogs/scheduled_date_time_picker.dart';

/// Card that lets the instructor set a visible-from / visible-until window
/// for the course. Leave both empty to keep the course always available.
class AvailabilityScheduleCard extends StatelessWidget {
  const AvailabilityScheduleCard({
    super.key,
    required this.state,
    required this.cubit,
    required this.isArabic,
    required this.isDark,
  });

  final CourseEditorState state;
  final CourseEditorCubit cubit;
  final bool isArabic;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
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
              color:
                  isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
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
}
