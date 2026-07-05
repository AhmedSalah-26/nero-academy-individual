import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../generated/locale_keys.g.dart';
import 'ai_import_models.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Card rendering each parsed question preview
/// ─────────────────────────────────────────────────────────────────────────────
class AiPreviewQuestionCard extends StatelessWidget {
  final int index;
  final AiPreviewQuestion question;
  final bool isDark;

  const AiPreviewQuestionCard({
    super.key,
    required this.index,
    required this.question,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final typeLabel = _typeLabel(question.type);
    final typeColor = _typeColor(question.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF7C3AED),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border:
                      Border.all(color: typeColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  typeLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: typeColor,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                LocaleKeys.ai_import_points.tr(namedArgs: {'n': '${question.points}'}),
                style: TextStyle(
                  fontSize: 11,
                  color: isDark
                      ? AppColors.textMutedDark
                      : AppColors.textMutedLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (question.questionAr.isNotEmpty)
            Text(
              question.questionAr,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.5,
                color: isDark
                    ? AppColors.textMainDark
                    : AppColors.textMainLight,
              ),
            ),
          if (question.questionEn.isNotEmpty &&
              question.questionEn != question.questionAr) ...[
            const SizedBox(height: 4),
            Text(
              question.questionEn,
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: isDark
                    ? AppColors.textMutedDark
                    : AppColors.textMutedLight,
              ),
            ),
          ],
          if (question.options.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...question.options.map(
              (opt) => Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(
                  children: [
                    Icon(
                      opt.isCorrect
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      size: 16,
                      color: opt.isCorrect
                          ? AppColors.success
                          : (isDark
                              ? AppColors.textMutedDark
                              : AppColors.textMutedLight),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        opt.textAr.isNotEmpty ? opt.textAr : opt.textEn,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: opt.isCorrect
                              ? AppColors.success
                              : (isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondary),
                          fontWeight: opt.isCorrect
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'single':
        return LocaleKeys.ai_import_type_single.tr();
      case 'multiple':
        return LocaleKeys.ai_import_type_multiple.tr();
      case 'true_false':
        return LocaleKeys.ai_import_type_tf.tr();
      case 'text':
        return LocaleKeys.ai_import_type_text.tr();
      default:
        return type;
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'single':
        return const Color(0xFF4F46E5);
      case 'multiple':
        return const Color(0xFF0EA5E9);
      case 'true_false':
        return const Color(0xFF10B981);
      case 'text':
        return const Color(0xFFF59E0B);
      default:
        return AppColors.primary;
    }
  }
}
