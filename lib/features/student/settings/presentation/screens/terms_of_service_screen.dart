import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/core/shared_widgets/back_button.dart';

/// Terms of Service Screen
class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locale = context.locale.languageCode;
    final isArabic = locale == 'ar';

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor:
            isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        title: Text(
          'settings.terms_of_service'.tr(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
          ),
        ),
        leading: const AppBackButton(),
        surfaceTintColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              title: isArabic ? 'قبول الشروط' : 'Acceptance of Terms',
              content: isArabic
                  ? 'باستخدام هذا التطبيق، فإنك توافق على الالتزام بهذه الشروط والأحكام. إذا كنت لا توافق على أي جزء من هذه الشروط، يرجى عدم استخدام التطبيق.'
                  : 'By using this application, you agree to be bound by these terms and conditions. If you do not agree to any part of these terms, please do not use the application.',
              isDark: isDark,
            ),
            _buildSection(
              title: isArabic ? 'حساب المستخدم' : 'User Account',
              content: isArabic
                  ? '• يجب أن تكون 13 عامًا أو أكثر لاستخدام التطبيق\n• أنت مسؤول عن الحفاظ على سرية حسابك\n• يجب تقديم معلومات دقيقة وحديثة'
                  : '• You must be 13 years or older to use the app\n• You are responsible for maintaining account confidentiality\n• You must provide accurate and current information',
              isDark: isDark,
            ),
            _buildSection(
              title: isArabic ? 'المحتوى والدورات' : 'Content and Courses',
              content: isArabic
                  ? '• جميع الدورات مرخصة للاستخدام الشخصي فقط\n• لا يجوز مشاركة أو إعادة توزيع المحتوى\n• الشهادات صالحة للتحقق عبر الإنترنت'
                  : '• All courses are licensed for personal use only\n• Content may not be shared or redistributed\n• Certificates are valid for online verification',
              isDark: isDark,
            ),
            _buildSection(
              title: isArabic ? 'المدفوعات والاسترداد' : 'Payments and Refunds',
              content: isArabic
                  ? '• جميع الأسعار بالجنيه المصري\n• يمكن طلب استرداد خلال 30 يومًا من الشراء\n• لا يمكن استرداد الدورات المكتملة بنسبة تزيد عن 30%'
                  : '• All prices are in Egyptian Pounds\n• Refunds can be requested within 30 days of purchase\n• Courses completed more than 30% are non-refundable',
              isDark: isDark,
            ),
            _buildSection(
              title: isArabic ? 'السلوك المحظور' : 'Prohibited Conduct',
              content: isArabic
                  ? '• انتهاك حقوق الملكية الفكرية\n• مشاركة بيانات الدخول مع الآخرين\n• استخدام التطبيق لأغراض غير قانونية\n• محاولة اختراق أو تعطيل الخدمة'
                  : '• Violating intellectual property rights\n• Sharing login credentials with others\n• Using the app for illegal purposes\n• Attempting to hack or disrupt the service',
              isDark: isDark,
            ),
            _buildSection(
              title: isArabic ? 'إنهاء الحساب' : 'Account Termination',
              content: isArabic
                  ? 'نحتفظ بالحق في تعليق أو إنهاء حسابك في حالة انتهاك هذه الشروط. يمكنك أيضًا حذف حسابك في أي وقت من الإعدادات.'
                  : 'We reserve the right to suspend or terminate your account for violation of these terms. You can also delete your account at any time from settings.',
              isDark: isDark,
            ),
            _buildSection(
              title: isArabic ? 'تعديل الشروط' : 'Modification of Terms',
              content: isArabic
                  ? 'قد نقوم بتحديث هذه الشروط من وقت لآخر. سيتم إخطارك بأي تغييرات جوهرية عبر البريد الإلكتروني أو إشعار داخل التطبيق.'
                  : 'We may update these terms from time to time. You will be notified of any material changes via email or in-app notification.',
              isDark: isDark,
            ),
            const SizedBox(height: 20),
            Text(
              isArabic ? 'آخر تحديث: يناير 2026' : 'Last updated: January 2026',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.grey500 : AppColors.grey400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String content,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: isDark ? AppColors.grey300 : AppColors.grey600,
            ),
          ),
        ],
      ),
    );
  }
}
