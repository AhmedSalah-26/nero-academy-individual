import 'dart:ui' as ui;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_colors.dart';
import '../services/reports_service.dart';

/// Report Screen - Full page replacement for ReportDialog
class ReportScreen extends StatefulWidget {
  final ReportTargetType targetType;
  final String targetId;
  final String? targetTitle;
  final VoidCallback? onReportSubmitted;
  final String? reviewerId;
  final String? reviewComment;
  final int? reviewRating;

  const ReportScreen({
    super.key,
    required this.targetType,
    required this.targetId,
    this.targetTitle,
    this.onReportSubmitted,
    this.reviewerId,
    this.reviewComment,
    this.reviewRating,
  });

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen>
    with SingleTickerProviderStateMixin {
  ReportReason? _selectedReason;
  final _descriptionController = TextEditingController();
  bool _isSubmitting = false;
  bool _isCheckingPending = true;
  bool _hasPendingReport = false;
  String? _error;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  // Icon and accent color per reason
  static const Map<ReportReason, IconData> _reasonIcons = {
    ReportReason.inappropriate: Icons.block_rounded,
    ReportReason.spam: Icons.mark_email_unread_rounded,
    ReportReason.misleading: Icons.info_outline_rounded,
    ReportReason.copyright: Icons.copyright_rounded,
    ReportReason.harassment: Icons.report_gmailerrorred_rounded,
    ReportReason.other: Icons.more_horiz_rounded,
  };

  static const Map<ReportReason, Color> _reasonColors = {
    ReportReason.inappropriate: Color(0xFFEF4444),
    ReportReason.spam: Color(0xFFF97316),
    ReportReason.misleading: Color(0xFFF59E0B),
    ReportReason.copyright: Color(0xFF8B5CF6),
    ReportReason.harassment: Color(0xFFEC4899),
    ReportReason.other: Color(0xFF64748B),
  };

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
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
        _animController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCheckingPending = false);
        _animController.forward();
      }
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _animController.dispose();
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
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  context.locale.languageCode == 'ar'
                      ? 'تم إرسال البلاغ بنجاح'
                      : 'Report submitted successfully',
                  style: const TextStyle(fontFamily: 'Almarai'),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFF),
      appBar: _buildAppBar(isDark, isArabic),
      body: _isCheckingPending
          ? _buildLoadingView(isDark)
          : _hasPendingReport
              ? _buildPendingReportView(isDark, isArabic)
              : FadeTransition(
                  opacity: _fadeAnim,
                  child: _buildReportForm(isDark, isArabic),
                ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark, bool isArabic) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          child: Icon(
            isArabic
                ? Icons.arrow_forward_ios_rounded
                : Icons.arrow_back_ios_rounded,
            size: 16,
            color: isDark ? AppColors.white : AppColors.textMainLight,
          ),
        ),
      ),
      title: Text(
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
    );
  }

  Widget _buildLoadingView(bool isDark) {
    return const Center(
      child: CircularProgressIndicator(
        color: AppColors.error,
        strokeWidth: 2.5,
      ),
    );
  }

  Widget _buildPendingReportView(bool isDark, bool isArabic) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon with gradient background
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.warning.withValues(alpha: 0.15),
                    AppColors.warning.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.hourglass_top_rounded,
                size: 48,
                color: AppColors.warning,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              isArabic ? 'لديك بلاغ معلق' : 'Pending Report',
              style: TextStyle(
                fontFamily: 'Almarai',
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.white : AppColors.textMainLight,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isArabic
                  ? 'تم استلام بلاغك وهو قيد المراجعة.\nسنرد عليك في أقرب وقت.'
                  : 'Your report has been received\nand is under review.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Almarai',
                fontSize: 15,
                height: 1.7,
                color:
                    isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              ),
            ),
            const SizedBox(height: 36),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  backgroundColor:
                      isDark ? AppColors.surfaceDark : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color:
                          isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                  ),
                ),
                child: Text(
                  isArabic ? 'حسناً، فهمت' : 'Got it',
                  style: TextStyle(
                    fontFamily: 'Almarai',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.white : AppColors.textMainLight,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportForm(bool isDark, bool isArabic) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero Header
          _buildHeroHeader(isDark, isArabic),
          const SizedBox(height: 28),

          // Target title card
          if (widget.targetTitle != null) ...[
            _buildTargetCard(isDark),
            const SizedBox(height: 24),
          ],

          // Section: Reason
          _buildSectionTitle(
            isArabic ? 'سبب البلاغ' : 'Reason for Report',
            Icons.flag_rounded,
            isDark,
          ),
          const SizedBox(height: 14),

          // Reason grid
          _buildReasonGrid(isDark, isArabic),
          const SizedBox(height: 28),

          // Section: Description
          _buildSectionTitle(
            isArabic
                ? 'تفاصيل إضافية (اختياري)'
                : 'Additional Details (Optional)',
            Icons.edit_note_rounded,
            isDark,
          ),
          const SizedBox(height: 14),

          // Text field
          _buildDescriptionField(isDark, isArabic),

          // Error
          if (_error != null) ...[
            const SizedBox(height: 16),
            _buildErrorCard(_error!, isDark),
          ],

          const SizedBox(height: 32),

          // Submit button
          _buildSubmitButton(isDark, isArabic),
        ],
      ),
    );
  }

  Widget _buildHeroHeader(bool isDark, bool isArabic) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.error.withValues(alpha: isDark ? 0.18 : 0.08),
            AppColors.error.withValues(alpha: isDark ? 0.06 : 0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.error.withValues(alpha: isDark ? 0.25 : 0.12),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.flag_rounded,
              color: AppColors.error,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArabic ? 'إرسال بلاغ' : 'Submit a Report',
                  style: TextStyle(
                    fontFamily: 'Almarai',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.white : AppColors.textMainLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isArabic
                      ? 'ساعدنا في الحفاظ على المجتمع آمناً'
                      : 'Help us keep the community safe',
                  style: TextStyle(
                    fontFamily: 'Almarai',
                    fontSize: 13,
                    color: isDark
                        ? AppColors.textMutedDark
                        : AppColors.textMutedLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.info_outline_rounded,
                color: AppColors.error, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.targetTitle!,
              style: TextStyle(
                fontFamily: 'Almarai',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.white : AppColors.textMainLight,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.error),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontFamily: 'Almarai',
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.white : AppColors.textMainLight,
          ),
        ),
      ],
    );
  }

  Widget _buildReasonGrid(bool isDark, bool isArabic) {
    const reasons = ReportReason.values;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: reasons.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.5,
      ),
      itemBuilder: (_, i) => _buildReasonTile(reasons[i], isDark, isArabic),
    );
  }

  Widget _buildReasonTile(ReportReason reason, bool isDark, bool isArabic) {
    final isSelected = _selectedReason == reason;
    final color = _reasonColors[reason] ?? AppColors.error;
    final icon = _reasonIcons[reason] ?? Icons.flag_rounded;

    return GestureDetector(
      onTap: () => setState(() => _selectedReason = reason),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: isDark ? 0.18 : 0.08)
              : (isDark ? AppColors.surfaceDark : Colors.white),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? color.withValues(alpha: 0.7)
                : (isDark ? AppColors.borderDark : AppColors.borderLight),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected || isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: color.withValues(alpha: isSelected ? 0.15 : 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                reason.getLabel(isArabic),
                style: TextStyle(
                  fontFamily: 'Almarai',
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? color
                      : (isDark
                          ? AppColors.textMutedDark
                          : AppColors.textMutedLight),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: color, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionField(bool isDark, bool isArabic) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: TextField(
        controller: _descriptionController,
        maxLines: 5,
        maxLength: 500,
        textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
        decoration: InputDecoration(
          hintText: isArabic
              ? 'أضف تفاصيل إضافية تساعدنا على فهم المشكلة...'
              : 'Add details that help us understand the issue...',
          hintStyle: TextStyle(
            fontFamily: 'Almarai',
            fontSize: 13,
            color: isDark ? AppColors.textHintDark : AppColors.textHintLight,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
          counterStyle: TextStyle(
            fontFamily: 'Almarai',
            fontSize: 12,
            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
          ),
        ),
        style: TextStyle(
          fontFamily: 'Almarai',
          fontSize: 14,
          color: isDark ? AppColors.white : AppColors.textMainLight,
        ),
      ),
    );
  }

  Widget _buildErrorCard(String error, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.error, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(
                fontFamily: 'Almarai',
                fontSize: 13,
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(bool isDark, bool isArabic) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitReport,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: EdgeInsets.zero,
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: _isSubmitting
                ? LinearGradient(
                    colors: [
                      AppColors.error.withValues(alpha: 0.5),
                      AppColors.error.withValues(alpha: 0.4),
                    ],
                  )
                : const LinearGradient(
                    colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: _isSubmitting
                ? null
                : [
                    BoxShadow(
                      color: AppColors.error.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: Container(
            alignment: Alignment.center,
            child: _isSubmitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.send_rounded,
                          color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        isArabic ? 'إرسال البلاغ' : 'Submit Report',
                        style: const TextStyle(
                          fontFamily: 'Almarai',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
