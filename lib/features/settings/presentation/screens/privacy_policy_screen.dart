import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/shared_widgets/back_button.dart';

/// Privacy Policy Screen
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
          'settings.privacy_policy'.tr(),
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
              title: isArabic ? 'مقدمة' : 'Introduction',
              content: isArabic
                  ? 'نحن نقدر خصوصيتك ونلتزم بحماية بياناتك الشخصية. توضح سياسة الخصوصية هذه كيفية جمع واستخدام وحماية معلوماتك عند استخدام تطبيقنا.'
                  : 'We value your privacy and are committed to protecting your personal data. This privacy policy explains how we collect, use, and protect your information when you use our application.',
              isDark: isDark,
            ),
            _buildSection(
              title: isArabic ? 'البيانات التي نجمعها' : 'Data We Collect',
              content: isArabic
                  ? '• معلومات الحساب: الاسم، البريد الإلكتروني، رقم الهاتف\n• بيانات الاستخدام: الدورات المشتراة، التقدم في التعلم\n• معلومات الجهاز: نوع الجهاز، نظام التشغيل'
                  : '• Account information: Name, email, phone number\n• Usage data: Purchased courses, learning progress\n• Device information: Device type, operating system',
              isDark: isDark,
            ),
            _buildSection(
              title: isArabic ? 'كيف نستخدم بياناتك' : 'How We Use Your Data',
              content: isArabic
                  ? '• تقديم خدماتنا التعليمية\n• تحسين تجربة المستخدم\n• إرسال إشعارات مهمة\n• معالجة المدفوعات'
                  : '• Provide our educational services\n• Improve user experience\n• Send important notifications\n• Process payments',
              isDark: isDark,
            ),
            _buildSection(
              title: isArabic ? 'حماية البيانات' : 'Data Protection',
              content: isArabic
                  ? 'نستخدم تقنيات تشفير متقدمة لحماية بياناتك. لن نشارك معلوماتك الشخصية مع أطراف ثالثة دون موافقتك.'
                  : 'We use advanced encryption technologies to protect your data. We will not share your personal information with third parties without your consent.',
              isDark: isDark,
            ),
            _buildSection(
              title: isArabic ? 'حقوقك' : 'Your Rights',
              content: isArabic
                  ? '• الوصول إلى بياناتك\n• تصحيح البيانات غير الدقيقة\n• حذف حسابك وبياناتك\n• الاعتراض على معالجة البيانات'
                  : '• Access your data\n• Correct inaccurate data\n• Delete your account and data\n• Object to data processing',
              isDark: isDark,
            ),
            _buildSection(
              title: isArabic ? 'تواصل معنا' : 'Contact Us',
              content: isArabic
                  ? 'إذا كان لديك أي أسئلة حول سياسة الخصوصية، يرجى التواصل معنا عبر الهاتف: +2010865017'
                  : 'If you have any questions about this privacy policy, please contact us by phone: +2010865017',
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
