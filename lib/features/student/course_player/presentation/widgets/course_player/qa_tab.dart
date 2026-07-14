import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lms_platform/core/theme/app_colors.dart';

/// Q&A Tab Widget (Placeholder)
class QATab extends StatelessWidget {
  final bool isDark;
  final VoidCallback onAskQuestion;

  const QATab({
    super.key,
    required this.isDark,
    required this.onAskQuestion,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Column(
      children: [
        // Ask question button
        _buildAskQuestionButton(primary),
        // Empty state or questions list
        Expanded(
          child: _buildEmptyState(),
        ),
      ],
    );
  }

  Widget _buildAskQuestionButton(Color primary) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Material(
        color: primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onAskQuestion,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.help_outline,
                    color: primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'course_player.ask_question'.tr(),
                  style: TextStyle(
                    color: primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.question_answer_outlined,
            size: 64,
            color: isDark
                ? AppColors.textMutedDark.withValues(alpha: 0.5)
                : AppColors.textMutedLight.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'course_player.no_questions'.tr(),
            style: TextStyle(
              color:
                  isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'course_player.no_questions_desc'.tr(),
            style: TextStyle(
              color: isDark
                  ? AppColors.textMutedDark.withValues(alpha: 0.7)
                  : AppColors.textMutedLight.withValues(alpha: 0.7),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
