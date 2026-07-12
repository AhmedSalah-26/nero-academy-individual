import 'dart:ui' as ui;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/core/services/reports_service.dart';
import 'package:lms_platform/core/routing/app_router.dart';

/// Report Dialog - Allows users to report courses or reviews
/// @deprecated Use ReportScreen (full page) instead via AppRouter.goToReport()
class ReportDialog extends StatefulWidget {
  final ReportTargetType targetType;
  final String targetId;
  final String? targetTitle;
  final VoidCallback? onReportSubmitted;
  // For review reports - cache review data
  final String? reviewerId;
  final String? reviewComment;
  final int? reviewRating;

  const ReportDialog({
    super.key,
    required this.targetType,
    required this.targetId,
    this.targetTitle,
    this.onReportSubmitted,
    this.reviewerId,
    this.reviewComment,
    this.reviewRating,
  });

  /// Show the report dialog
  /// @deprecated Use AppRouter.goToReport() to navigate to full screen instead
  static Future<bool?> show(
    BuildContext context, {
    required ReportTargetType targetType,
    required String targetId,
    String? targetTitle,
    VoidCallback? onReportSubmitted,
    String? reviewerId,
    String? reviewComment,
    int? reviewRating,
  }) {
    // Navigate to full screen instead of showing modal
    AppRouter.goToReport(
      context,
      targetType: targetType,
      targetId: targetId,
      targetTitle: targetTitle,
      onReportSubmitted: onReportSubmitted,
      reviewerId: reviewerId,
      reviewComment: reviewComment,
      reviewRating: reviewRating,
    );
    return Future.value(null);
  }

  /// Legacy method - shows modal bottom sheet
  /// @deprecated Use show() method which navigates to full screen
  static Future<bool?> showModal(
    BuildContext context, {
    required ReportTargetType targetType,
    required String targetId,
    String? targetTitle,
    VoidCallback? onReportSubmitted,
    String? reviewerId,
    String? reviewComment,
    int? reviewRating,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ReportDialog(
        targetType: targetType,
        targetId: targetId,
        targetTitle: targetTitle,
        onReportSubmitted: onReportSubmitted,
        reviewerId: reviewerId,
        reviewComment: reviewComment,
        reviewRating: reviewRating,
      ),
    );
  }

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  ReportReason? _selectedReason;
  final _descriptionController = TextEditingController();
  bool _isSubmitting = false;
  bool _isCheckingPending = true;
  bool _hasPendingReport = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkPendingReport();
  }

  Future<void> _checkPendingReport() async {
    try {
      final service = ReportsRemoteDataSource(Supabase.instance.client);

      bool hasPending;
      if (widget.targetType == ReportTargetType.course) {
        hasPending = await service.hasReportedCourse(widget.targetId);
      } else {
        hasPending = await service.hasReportedReview(widget.targetId);
      }

      if (mounted) {
        setState(() {
          _hasPendingReport = hasPending;
          _isCheckingPending = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCheckingPending = false);
      }
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (_selectedReason == null) {
      setState(() => _error = context.locale.languageCode == 'ar'
          ? 'الرجاء اختيار سبب البلاغ'
          : 'Please select a reason');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final service = ReportsRemoteDataSource(Supabase.instance.client);

      bool success;
      if (widget.targetType == ReportTargetType.course) {
        success = await service.reportCourse(
          courseId: widget.targetId,
          reason: _selectedReason!,
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
        );
      } else {
        success = await service.reportReview(
          reviewId: widget.targetId,
          reason: _selectedReason!,
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          reviewerId: widget.reviewerId,
          reviewComment: widget.reviewComment,
          reviewRating: widget.reviewRating,
        );
      }

      if (success && mounted) {
        widget.onReportSubmitted?.call();
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.locale.languageCode == 'ar'
                  ? 'تم إرسال البلاغ بنجاح'
                  : 'Report submitted successfully',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
        _error = e.toString().contains('duplicate')
            ? (context.locale.languageCode == 'ar'
                ? 'لقد قمت بالإبلاغ عن هذا المحتوى مسبقاً'
                : 'You have already reported this content')
            : (context.locale.languageCode == 'ar'
                ? 'حدث خطأ أثناء إرسال البلاغ'
                : 'Failed to submit report');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = context.locale.languageCode == 'ar';
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    // Show loading while checking pending
    if (_isCheckingPending) {
      return Container(
        margin: EdgeInsets.only(bottom: bottomPadding),
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Show pending report message
    if (_hasPendingReport) {
      return Container(
        margin: EdgeInsets.only(bottom: bottomPadding),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.grey600 : AppColors.grey300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 32),
                const Icon(
                  Icons.hourglass_empty_rounded,
                  size: 64,
                  color: AppColors.warning,
                ),
                const SizedBox(height: 16),
                Text(
                  isArabic ? 'لديك بلاغ معلق' : 'Pending Report',
                  style: TextStyle(
                    fontFamily: 'Almarai',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.white : AppColors.textMainLight,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isArabic
                      ? 'لديك بلاغ معلق على هذا المحتوى. سيتم الرد عليك قريباً.'
                      : 'You have a pending report for this content. We will respond soon.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Almarai',
                    fontSize: 14,
                    color: isDark ? AppColors.textMutedDark : AppColors.grey600,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.grey600,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      isArabic ? 'حسناً' : 'OK',
                      style: const TextStyle(
                        fontFamily: 'Almarai',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
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

    return Container(
      margin: EdgeInsets.only(bottom: bottomPadding),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.grey600 : AppColors.grey300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Row(
                children: [
                  const Icon(
                    Icons.flag_rounded,
                    color: AppColors.error,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    widget.targetType == ReportTargetType.course
                        ? (isArabic ? 'الإبلاغ عن الكورس' : 'Report Course')
                        : (isArabic ? 'الإبلاغ عن التعليق' : 'Report Review'),
                    style: TextStyle(
                      fontFamily: 'Almarai',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.white : AppColors.textMainLight,
                    ),
                  ),
                ],
              ),

              if (widget.targetTitle != null) ...[
                const SizedBox(height: 8),
                Text(
                  widget.targetTitle!,
                  style: TextStyle(
                    fontFamily: 'Almarai',
                    fontSize: 14,
                    color: isDark
                        ? AppColors.textMutedDark
                        : AppColors.textMutedLight,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: 20),

              // Reason selection
              Text(
                isArabic ? 'سبب البلاغ' : 'Reason for Report',
                style: TextStyle(
                  fontFamily: 'Almarai',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.white : AppColors.textMainLight,
                ),
              ),
              const SizedBox(height: 12),

              // Reason chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ReportReason.values.map((reason) {
                  final isSelected = _selectedReason == reason;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedReason = reason),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark
                                ? AppColors.primary.withValues(alpha: 0.2)
                                : AppColors.primaryLight.withValues(alpha: 0.3))
                            : (isDark
                                ? const Color(0xFF424242) // Neutral Light Grey
                                : AppColors.grey100),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : (isDark
                                  ? const Color(
                                      0xFF616161) // Lighter Grey Border
                                  : AppColors.grey300),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Text(
                        reason.getLabel(isArabic),
                        style: TextStyle(
                          fontFamily: 'Almarai',
                          fontSize: 13,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected
                              ? AppColors.primary
                              : (isDark
                                  ? const Color(0xFFEEEEEE) // White-ish Text
                                  : AppColors.grey600),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              // Description
              Text(
                isArabic
                    ? 'تفاصيل إضافية (اختياري)'
                    : 'Additional Details (Optional)',
                style: TextStyle(
                  fontFamily: 'Almarai',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.white : AppColors.textMainLight,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                maxLength: 500,
                textDirection:
                    isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                decoration: InputDecoration(
                  hintText:
                      isArabic ? 'أضف تفاصيل إضافية...' : 'Add more details...',
                  hintStyle: TextStyle(
                    fontFamily: 'Almarai',
                    color: isDark ? AppColors.textMutedDark : AppColors.grey400,
                  ),
                  filled: true,
                  fillColor: isDark ? AppColors.grey800 : AppColors.grey100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
                style: TextStyle(
                  fontFamily: 'Almarai',
                  fontSize: 14,
                  color: isDark ? AppColors.white : AppColors.textMainLight,
                ),
              ),

              // Error message
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: const TextStyle(
                    fontFamily: 'Almarai',
                    fontSize: 13,
                    color: AppColors.error,
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    disabledBackgroundColor:
                        AppColors.error.withValues(alpha: 0.5),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          isArabic ? 'إرسال البلاغ' : 'Submit Report',
                          style: const TextStyle(
                            fontFamily: 'Almarai',
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 8),

              // Cancel button
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    isArabic ? 'إلغاء' : 'Cancel',
                    style: TextStyle(
                      fontFamily: 'Almarai',
                      fontSize: 14,
                      color:
                          isDark ? AppColors.textMutedDark : AppColors.grey600,
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
