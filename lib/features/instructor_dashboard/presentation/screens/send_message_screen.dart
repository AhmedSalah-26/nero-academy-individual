import 'package:flutter/material.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/core/animations/widgets/feedback/animated_snackbar.dart';

/// Send Message Screen - Full page for sending messages to students
class SendMessageScreen extends StatefulWidget {
  final String studentName;
  final String? studentEmail;
  final Function(String subject, String message) onSend;

  const SendMessageScreen({
    super.key,
    required this.studentName,
    this.studentEmail,
    required this.onSend,
  });

  @override
  State<SendMessageScreen> createState() => _SendMessageScreenState();
}

class _SendMessageScreenState extends State<SendMessageScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(isArabic ? 'إرسال رسالة' : 'Send Message'),
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Recipient Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color:
                        isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      child: Text(
                        widget.studentName.isNotEmpty
                            ? widget.studentName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isArabic ? 'المستلم' : 'Recipient',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.textMutedDark
                                  : AppColors.textMutedLight,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.studentName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? AppColors.textMainDark
                                  : AppColors.textMainLight,
                            ),
                          ),
                          if (widget.studentEmail != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              widget.studentEmail!,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? AppColors.textMutedDark
                                    : AppColors.textMutedLight,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const Icon(Icons.message_outlined,
                        color: AppColors.primary, size: 28),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.info.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        color: AppColors.info, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isArabic
                            ? 'سيتم إرسال الرسالة كإشعار للطالب عبر البريد الإلكتروني والتطبيق'
                            : 'Message will be sent as a notification to the student via email and app',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? AppColors.textMainDark
                              : AppColors.textMainLight,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Subject Field
              Text(
                isArabic ? 'الموضوع' : 'Subject',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.white : AppColors.textMainLight,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _subjectController,
                maxLength: 100,
                decoration: InputDecoration(
                  hintText:
                      isArabic ? 'أدخل موضوع الرسالة' : 'Enter message subject',
                  hintStyle: TextStyle(
                    color: isDark ? AppColors.textMutedDark : AppColors.grey400,
                  ),
                  filled: true,
                  fillColor: isDark ? AppColors.surfaceDark : AppColors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color:
                          isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color:
                          isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 2,
                    ),
                  ),
                  prefixIcon: const Icon(Icons.subject),
                  contentPadding: const EdgeInsets.all(16),
                ),
                style: TextStyle(
                  fontSize: 15,
                  color: isDark ? AppColors.white : AppColors.textMainLight,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return isArabic
                        ? 'الرجاء إدخال الموضوع'
                        : 'Please enter subject';
                  }
                  if (value.trim().length < 3) {
                    return isArabic
                        ? 'الموضوع قصير جداً (3 أحرف على الأقل)'
                        : 'Subject is too short (minimum 3 characters)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Message Field
              Text(
                isArabic ? 'الرسالة' : 'Message',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.white : AppColors.textMainLight,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _messageController,
                maxLines: 10,
                maxLength: 1000,
                decoration: InputDecoration(
                  hintText: isArabic
                      ? 'اكتب رسالتك هنا...'
                      : 'Write your message here...',
                  hintStyle: TextStyle(
                    color: isDark ? AppColors.textMutedDark : AppColors.grey400,
                  ),
                  filled: true,
                  fillColor: isDark ? AppColors.surfaceDark : AppColors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color:
                          isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color:
                          isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                  alignLabelWithHint: true,
                ),
                style: TextStyle(
                  fontSize: 15,
                  color: isDark ? AppColors.white : AppColors.textMainLight,
                  height: 1.5,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return isArabic
                        ? 'الرجاء إدخال الرسالة'
                        : 'Please enter message';
                  }
                  if (value.trim().length < 10) {
                    return isArabic
                        ? 'الرسالة قصيرة جداً (10 أحرف على الأقل)'
                        : 'Message is too short (minimum 10 characters)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Send Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSending ? null : _sendMessage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    disabledBackgroundColor:
                        AppColors.primary.withValues(alpha: 0.5),
                  ),
                  icon: _isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.send, size: 20),
                  label: Text(
                    isArabic ? 'إرسال الرسالة' : 'Send Message',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _sendMessage() async {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSending = true);

    try {
      await widget.onSend(
          _subjectController.text.trim(), _messageController.text.trim());

      if (mounted) {
        Navigator.pop(context);
        AnimatedSnackbar.showSuccess(
          context: context,
          message:
              isArabic ? 'تم إرسال الرسالة بنجاح' : 'Message sent successfully',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSending = false);
        AnimatedSnackbar.showError(
          context: context,
          message: isArabic ? 'فشل إرسال الرسالة' : 'Failed to send message',
        );
      }
    }
  }
}
