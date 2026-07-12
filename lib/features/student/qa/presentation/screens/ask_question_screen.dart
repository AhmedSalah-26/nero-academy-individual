import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lms_platform/core/theme/app_colors.dart';

/// Ask Question Screen - Full page replacement for AskQuestionForm bottom sheet
class AskQuestionScreen extends StatefulWidget {
  final String courseId;
  final String? lessonId;
  final VoidCallback? onQuestionPosted;

  const AskQuestionScreen({
    super.key,
    required this.courseId,
    this.lessonId,
    this.onQuestionPosted,
  });

  @override
  State<AskQuestionScreen> createState() => _AskQuestionScreenState();
}

class _AskQuestionScreenState extends State<AskQuestionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submitQuestion() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      // TODO: Implement actual question posting logic
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call

      if (mounted) {
        widget.onQuestionPosted?.call();
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('qa.question_posted'.tr()),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = context.locale.languageCode == 'ar';

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text('qa.ask_question'.tr()),
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
              // Info card
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
                            ? 'اطرح سؤالك بوضوح وسيجيب عليه المدرب أو الطلاب الآخرون'
                            : 'Ask your question clearly and the instructor or other students will answer',
                        style: TextStyle(
                          fontFamily: 'Almarai',
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

              // Question Title
              Text(
                'qa.question_title'.tr(),
                style: TextStyle(
                  fontFamily: 'Almarai',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.white : AppColors.textMainLight,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                maxLength: 200,
                decoration: InputDecoration(
                  hintText: 'qa.question_title_hint'.tr(),
                  hintStyle: TextStyle(
                    fontFamily: 'Almarai',
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
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.error,
                    ),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
                style: TextStyle(
                  fontFamily: 'Almarai',
                  fontSize: 15,
                  color: isDark ? AppColors.white : AppColors.textMainLight,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return isArabic
                        ? 'الرجاء إدخال عنوان السؤال'
                        : 'Please enter a question title';
                  }
                  if (value.trim().length < 10) {
                    return isArabic
                        ? 'العنوان قصير جداً (10 أحرف على الأقل)'
                        : 'Title is too short (minimum 10 characters)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Question Details
              Text(
                'qa.question_details'.tr(),
                style: TextStyle(
                  fontFamily: 'Almarai',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.white : AppColors.textMainLight,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _contentController,
                maxLines: 8,
                maxLength: 1000,
                decoration: InputDecoration(
                  hintText: 'qa.question_details_hint'.tr(),
                  hintStyle: TextStyle(
                    fontFamily: 'Almarai',
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
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.error,
                    ),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
                style: TextStyle(
                  fontFamily: 'Almarai',
                  fontSize: 15,
                  color: isDark ? AppColors.white : AppColors.textMainLight,
                  height: 1.5,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return isArabic
                        ? 'الرجاء إدخال تفاصيل السؤال'
                        : 'Please enter question details';
                  }
                  if (value.trim().length < 20) {
                    return isArabic
                        ? 'التفاصيل قصيرة جداً (20 حرف على الأقل)'
                        : 'Details are too short (minimum 20 characters)';
                  }
                  return null;
                },
              ),

              // Error message
              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppColors.error, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            fontFamily: 'Almarai',
                            fontSize: 13,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitQuestion,
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
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'qa.post_question'.tr(),
                          style: const TextStyle(
                            fontFamily: 'Almarai',
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
}
