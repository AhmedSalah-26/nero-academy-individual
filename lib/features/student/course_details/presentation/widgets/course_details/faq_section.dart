import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lms_platform/core/animations/widgets/interactive/expandable_card.dart';
import 'package:lms_platform/core/theme/app_colors.dart';

/// FAQ Section with ExpandableCard animations
class FAQSection extends StatelessWidget {
  const FAQSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locale = context.locale.languageCode;

    final faqs = _getFAQs(locale);

    if (faqs.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            locale == 'ar' ? 'الأسئلة الشائعة' : 'Frequently Asked Questions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
            ),
          ),
          const SizedBox(height: 16),
          ...faqs.asMap().entries.map((entry) {
            final index = entry.key;
            final faq = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ExpandableCard(
                header: Text(
                  faq['question']!,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textMainDark
                        : AppColors.textMainLight,
                  ),
                ),
                expandedContent: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    faq['answer']!,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: isDark
                          ? AppColors.textMutedDark
                          : AppColors.textMutedLight,
                    ),
                  ),
                ),
                initiallyExpanded: index == 0,
              ),
            );
          }),
        ],
      ),
    );
  }

  List<Map<String, String>> _getFAQs(String locale) {
    if (locale == 'ar') {
      return [
        {
          'question': 'ما هي متطلبات الدورة؟',
          'answer':
              'لا توجد متطلبات مسبقة لهذه الدورة. كل ما تحتاجه هو الرغبة في التعلم والتطوير من مهاراتك.',
        },
        {
          'question': 'كم مدة الدورة؟',
          'answer':
              'مدة الدورة تختلف حسب المحتوى، ولكن يمكنك إكمالها بالسرعة التي تناسبك. جميع المحتويات متاحة مدى الحياة.',
        },
        {
          'question': 'هل أحصل على شهادة؟',
          'answer':
              'نعم، ستحصل على شهادة إتمام بعد إنهاء جميع دروس الدورة بنجاح.',
        },
        {
          'question': 'هل يمكنني الوصول للدورة من الهاتف؟',
          'answer':
              'نعم، يمكنك الوصول للدورة من أي جهاز - كمبيوتر، تابلت، أو هاتف ذكي.',
        },
      ];
    } else {
      return [
        {
          'question': 'What are the course requirements?',
          'answer':
              'There are no prerequisites for this course. All you need is the desire to learn and develop your skills.',
        },
        {
          'question': 'How long is the course?',
          'answer':
              'The course duration varies by content, but you can complete it at your own pace. All content is available for lifetime access.',
        },
        {
          'question': 'Do I get a certificate?',
          'answer':
              'Yes, you will receive a certificate of completion after successfully finishing all course lessons.',
        },
        {
          'question': 'Can I access the course from my phone?',
          'answer':
              'Yes, you can access the course from any device - computer, tablet, or smartphone.',
        },
      ];
    }
  }
}
