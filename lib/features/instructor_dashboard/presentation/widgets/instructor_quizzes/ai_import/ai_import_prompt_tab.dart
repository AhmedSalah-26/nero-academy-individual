import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../generated/locale_keys.g.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Prompt display and copy tab for AI question import
/// ─────────────────────────────────────────────────────────────────────────────
class AiImportPromptTab extends StatefulWidget {
  final bool isDark;

  const AiImportPromptTab({
    super.key,
    required this.isDark,
  });

  @override
  State<AiImportPromptTab> createState() => _AiImportPromptTabState();
}

class _AiImportPromptTabState extends State<AiImportPromptTab> {
  bool _promptCopied = false;

  static const String _promptTemplateAr =
      'أنت مساعد تعليمي. أنشئ أسئلة اختبار للموضوع المطلوب وأرجعها بتنسيق JSON فقط، بدون أي نص إضافي.\n\n'
      'الصيغة المطلوبة بالضبط:\n'
      '[\n'
      '  {\n'
      '    "question_ar": "نص السؤال بالعربية",\n'
      '    "question_en": "Question text in English",\n'
      '    "type": "single",\n'
      '    "points": 1,\n'
      '    "options": [\n'
      '      { "text_ar": "الخيار الأول", "text_en": "Option A", "is_correct": true },\n'
      '      { "text_ar": "الخيار الثاني", "text_en": "Option B", "is_correct": false },\n'
      '      { "text_ar": "الخيار الثالث", "text_en": "Option C", "is_correct": false },\n'
      '      { "text_ar": "الخيار الرابع", "text_en": "Option D", "is_correct": false }\n'
      '    ]\n'
      '  }\n'
      ']\n\n'
      'ملاحظات مهمة:\n'
      '- type يكون: "single" (اختيار واحد) أو "multiple" (متعدد) أو "true_false" (صح/خطأ)\n'
      '- لأسئلة صح/خطأ options تحتوي خيارين فقط: صح وخطأ\n'
      '- لكل سؤال خيار صحيح واحد على الأقل (is_correct: true)\n'
      '- أرجع JSON فقط بدون ``` أو أي نص آخر\n\n'
      'الموضوع: [اكتب موضوع الاختبار هنا]\n'
      'عدد الأسئلة: [اكتب العدد المطلوب]';

  static const String _promptTemplateEn =
      'You are an educational assistant. Create quiz questions for the requested topic and return them in JSON format only, without any additional text.\n\n'
      'Exact required format:\n'
      '[\n'
      '  {\n'
      '    "question_ar": "نص السؤال بالعربية",\n'
      '    "question_en": "Question text in English",\n'
      '    "type": "single",\n'
      '    "points": 1,\n'
      '    "options": [\n'
      '      { "text_ar": "الخيار الأول", "text_en": "Option A", "is_correct": true },\n'
      '      { "text_ar": "الخيار الثاني", "text_en": "Option B", "is_correct": false },\n'
      '      { "text_ar": "الخيار الثالث", "text_en": "Option C", "is_correct": false },\n'
      '      { "text_ar": "الخيار الرابع", "text_en": "Option D", "is_correct": false }\n'
      '    ]\n'
      '  }\n'
      ']\n\n'
      'Important notes:\n'
      '- type must be: "single" (single choice) or "multiple" (multiple choice) or "true_false" (true/false)\n'
      '- For true/false questions, options contain only two choices: True and False\n'
      '- Each question must have at least one correct option (is_correct: true)\n'
      '- Return JSON only without ``` or any other text\n\n'
      'Topic: [Write the quiz topic here]\n'
      'Number of questions: [Write the required count]';

  Future<void> _copyPrompt() async {
    final isArabic = context.locale.languageCode == 'ar';
    final template = isArabic ? _promptTemplateAr : _promptTemplateEn;
    await Clipboard.setData(ClipboardData(text: template));
    setState(() => _promptCopied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _promptCopied = false);
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.locale.languageCode == 'ar';
    final promptTemplate = isArabic ? _promptTemplateAr : _promptTemplateEn;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // How to use
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF4F46E5).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color(0xFF4F46E5).withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: Color(0xFF4F46E5), size: 16),
                    const SizedBox(width: 6),
                    Text(
                      LocaleKeys.course_editor_ai_import_how_title.tr(),
                      style: const TextStyle(
                        color: Color(0xFF4F46E5),
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildStep(isArabic ? '١' : '1', LocaleKeys.course_editor_ai_import_step1.tr()),
                _buildStep(isArabic ? '٢' : '2', LocaleKeys.course_editor_ai_import_step2.tr()),
                _buildStep(isArabic ? '٣' : '3', LocaleKeys.course_editor_ai_import_step3.tr()),
                _buildStep(isArabic ? '٤' : '4', LocaleKeys.course_editor_ai_import_step4.tr()),
                _buildStep(isArabic ? '٥' : '5', LocaleKeys.course_editor_ai_import_step5.tr()),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Prompt box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: widget.isDark
                  ? const Color(0xFF1A1A2E)
                  : const Color(0xFFF8F7FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.isDark
                    ? const Color(0xFF7C3AED).withValues(alpha: 0.3)
                    : const Color(0xFF7C3AED).withValues(alpha: 0.2),
              ),
            ),
            child: SelectableText(
              promptTemplate,
              style: TextStyle(
                fontSize: 11.5,
                height: 1.7,
                fontFamily: 'monospace',
                color: widget.isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _copyPrompt,
              icon: Icon(
                _promptCopied
                    ? Icons.check_circle_outline_rounded
                    : Icons.copy_rounded,
                size: 18,
              ),
              label: Text(
                _promptCopied
                    ? LocaleKeys.course_editor_ai_import_copied.tr()
                    : LocaleKeys.course_editor_ai_import_copy_prompt.tr(),
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _promptCopied
                    ? AppColors.success
                    : const Color(0xFF7C3AED),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              LocaleKeys.course_editor_ai_import_hint.tr(),
              style: TextStyle(
                fontSize: 12,
                color: widget.isDark
                    ? AppColors.textMutedDark
                    : AppColors.textMutedLight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: const Color(0xFF4F46E5).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF4F46E5),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: const TextStyle(fontSize: 12.5, height: 1.5)),
          ),
        ],
      ),
    );
  }
}
