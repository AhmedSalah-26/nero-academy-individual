import 'package:flutter/material.dart';
import 'package:lms_platform/core/theme/app_colors.dart';

/// Widget for selecting scheduled date and time
class ScheduledDateTimePicker extends StatelessWidget {
  final String label;
  final DateTime? selectedDateTime;
  final bool isArabic;
  final Function(DateTime?) onChanged;

  const ScheduledDateTimePicker({
    super.key,
    required this.label,
    required this.selectedDateTime,
    required this.isArabic,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: selectedDateTime ?? DateTime.now(),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (date != null) {
              if (!context.mounted) return;
              final time = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(
                  selectedDateTime ?? DateTime.now(),
                ),
              );
              if (time != null) {
                onChanged(DateTime(
                  date.year,
                  date.month,
                  date.day,
                  time.hour,
                  time.minute,
                ));
              }
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 20,
                  color: isDark
                      ? AppColors.textMutedDark
                      : AppColors.textMutedLight,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    selectedDateTime != null
                        ? _formatDateTime(selectedDateTime!)
                        : (isArabic
                            ? 'اختر التاريخ والوقت'
                            : 'Select date and time'),
                    style: TextStyle(
                      fontSize: 14,
                      color: selectedDateTime != null
                          ? (isDark
                              ? AppColors.textMainDark
                              : AppColors.textMainLight)
                          : (isDark
                              ? AppColors.textMutedDark
                              : AppColors.textMutedLight),
                    ),
                  ),
                ),
                if (selectedDateTime != null)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () => onChanged(null),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    color: isDark
                        ? AppColors.textMutedDark
                        : AppColors.textMutedLight,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dt) {
    final date = '${dt.day}/${dt.month}/${dt.year}';
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$date - $hour:$minute';
  }
}
