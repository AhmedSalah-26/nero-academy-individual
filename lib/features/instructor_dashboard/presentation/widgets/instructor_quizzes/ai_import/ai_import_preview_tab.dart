import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../generated/locale_keys.g.dart';
import 'ai_import_models.dart';
import 'ai_preview_question_card.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Paste and preview tab for AI question import
/// ─────────────────────────────────────────────────────────────────────────────
class AiImportPreviewTab extends StatelessWidget {
  final TextEditingController jsonController;
  final List<AiPreviewQuestion> parsedQuestions;
  final String? parseError;
  final VoidCallback onParseTriggered;
  final bool isDark;
  final ValueChanged<String> onChanged;

  const AiImportPreviewTab({
    super.key,
    required this.jsonController,
    required this.parsedQuestions,
    required this.parseError,
    required this.onParseTriggered,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            LocaleKeys.ai_import_paste_label.tr(),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? AppColors.textMainDark
                  : AppColors.textMainLight,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: jsonController,
            maxLines: 8,
            minLines: 5,
            style: TextStyle(
              fontSize: 11.5,
              fontFamily: 'monospace',
              color: isDark
                  ? AppColors.textMainDark
                  : AppColors.textMainLight,
            ),
            decoration: InputDecoration(
              hintText: LocaleKeys.ai_import_paste_hint.tr(),
              hintStyle: TextStyle(
                color: isDark
                    ? AppColors.textMutedDark
                    : AppColors.textMutedLight,
                fontSize: 11.5,
              ),
              filled: true,
              fillColor: isDark
                  ? AppColors.surfaceDark
                  : const Color(0xFFF8F7FF),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: isDark
                        ? AppColors.borderDark
                        : AppColors.borderLight),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: isDark
                        ? AppColors.borderDark
                        : AppColors.borderLight),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                    color: Color(0xFF7C3AED), width: 1.5),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
            onChanged: onChanged,
          ),
          if (parseError != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      color: AppColors.error, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      parseError!,
                      style: const TextStyle(
                          color: AppColors.error, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onParseTriggered,
              icon: const Icon(Icons.read_more_rounded, size: 18),
              label: Text(
                LocaleKeys.ai_import_preview_btn.tr(),
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF7C3AED),
                side: const BorderSide(color: Color(0xFF7C3AED)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          if (parsedQuestions.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                LocaleKeys.ai_import_ready.tr(namedArgs: {'count': '${parsedQuestions.length}'}),
                style: const TextStyle(
                  color: AppColors.success,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 12),
            ...parsedQuestions.asMap().entries.map(
                  (e) => AiPreviewQuestionCard(
                    index: e.key,
                    question: e.value,
                    isDark: isDark,
                  ),
                ),
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
