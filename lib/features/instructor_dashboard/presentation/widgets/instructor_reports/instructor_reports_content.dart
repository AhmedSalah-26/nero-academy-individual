import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/services/reports_service.dart';
import '../../../../../core/animations/widgets/feedback/animated_snackbar.dart';

/// Instructor Reports Content — shows course & review reports
class InstructorReportsContent extends StatefulWidget {
  const InstructorReportsContent({super.key});

  @override
  State<InstructorReportsContent> createState() =>
      _InstructorReportsContentState();
}

class _InstructorReportsContentState extends State<InstructorReportsContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _courseReports = [];
  List<Map<String, dynamic>> _reviewReports = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadReports();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final service = ReportsRemoteDataSource(Supabase.instance.client);
      final data = await service.getInstructorReports();
      if (mounted) {
        setState(() {
          _courseReports = data['course'] ?? [];
          _reviewReports = data['review'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateStatus(
      String reportId, String status, bool isCourse) async {
    final service = ReportsRemoteDataSource(Supabase.instance.client);
    final success = isCourse
        ? await service.updateCourseReportStatus(reportId, status)
        : await service.updateReviewReportStatus(reportId, status);

    if (mounted) {
      if (success) {
        AnimatedSnackbar.showSuccess(
          context: context,
          message: 'تم تحديث الحالة',
        );
        _loadReports();
      } else {
        AnimatedSnackbar.showError(
          context: context,
          message: 'فشل تحديث الحالة',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Header with stats
        _buildHeader(isDark),

        // Tabs
        Container(
          color: isDark ? AppColors.surfaceDark : AppColors.white,
          child: TabBar(
            controller: _tabController,
            labelColor: AppColors.error,
            unselectedLabelColor:
                isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            indicatorColor: AppColors.error,
            labelStyle: const TextStyle(
              fontFamily: 'Almarai',
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            tabs: [
              Tab(
                text: 'بلاغات الكورسات (${_courseReports.length})',
              ),
              Tab(
                text: 'بلاغات التعليقات (${_reviewReports.length})',
              ),
            ],
          ),
        ),

        // Content
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.error))
              : _error != null
                  ? _buildError(isDark)
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildReportsList(
                            _courseReports, true, isDark),
                        _buildReportsList(
                            _reviewReports, false, isDark),
                      ],
                    ),
        ),
      ],
    );
  }

  Widget _buildHeader(bool isDark) {
    final pending = _courseReports
            .where((r) => r['status'] == 'pending')
            .length +
        _reviewReports.where((r) => r['status'] == 'pending').length;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      color: isDark ? AppColors.surfaceDark : AppColors.white,
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              label: 'إجمالي البلاغات',
              value: (_courseReports.length + _reviewReports.length).toString(),
              icon: Icons.flag_rounded,
              color: AppColors.error,
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              label: 'بانتظار المراجعة',
              value: pending.toString(),
              icon: Icons.hourglass_top_rounded,
              color: AppColors.warning,
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _loadReports,
            icon: const Icon(Icons.refresh_rounded),
            color: AppColors.primary,
            tooltip: 'تحديث',
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.12 : 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'Almarai',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Almarai',
                  fontSize: 11,
                  color: isDark
                      ? AppColors.textMutedDark
                      : AppColors.textMutedLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildError(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.error, size: 48),
          const SizedBox(height: 12),
          Text(
            'حدث خطأ في تحميل البلاغات',
            style: TextStyle(
              fontFamily: 'Almarai',
              color: isDark ? AppColors.white : AppColors.textMainLight,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadReports,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('إعادة المحاولة',
                style: TextStyle(fontFamily: 'Almarai')),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildReportsList(
      List<Map<String, dynamic>> reports, bool isCourse, bool isDark) {
    if (reports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_rounded,
                color: AppColors.success.withValues(alpha: 0.5), size: 64),
            const SizedBox(height: 16),
            Text(
              'لا توجد بلاغات',
              style: TextStyle(
                fontFamily: 'Almarai',
                fontSize: 16,
                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadReports,
      color: AppColors.error,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: reports.length,
        itemBuilder: (_, i) =>
            _buildReportCard(reports[i], isCourse, isDark),
      ),
    );
  }

  Widget _buildReportCard(
      Map<String, dynamic> report, bool isCourse, bool isDark) {
    final status = report['status'] as String? ?? 'pending';
    final reason = report['reason'] as String? ?? '';
    final description = report['description'] as String?;
    final createdAt = report['created_at'] as String?;
    final reporter = report['reporter'] as Map<String, dynamic>?;
    final reporterName = reporter?['full_name'] as String? ?? 'مجهول';

    // Course-specific
    final course = report['course'] as Map<String, dynamic>?;
    final courseTitle =
        course?['title_ar'] as String? ?? course?['title_en'] as String? ?? '';

    // Review-specific
    final reviewComment = report['cached_review_comment'] as String?;
    final reviewRating = report['cached_review_rating'];

    final statusColor = _statusColor(status);
    final statusLabel = _statusLabel(status);
    final reasonLabel = _reasonLabel(reason);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: status == 'pending'
              ? AppColors.warning.withValues(alpha: 0.3)
              : isDark
                  ? AppColors.borderDark
                  : AppColors.borderLight,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                // Type badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isCourse ? AppColors.primary : AppColors.info)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isCourse ? '📚 كورس' : '💬 تعليق',
                    style: TextStyle(
                      fontFamily: 'Almarai',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isCourse ? AppColors.primary : AppColors.info,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Status badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontFamily: 'Almarai',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
                const Spacer(),
                if (createdAt != null)
                  Text(
                    DateFormat('dd/MM/yyyy').format(DateTime.parse(createdAt)),
                    style: TextStyle(
                      fontFamily: 'Almarai',
                      fontSize: 11,
                      color: isDark
                          ? AppColors.textMutedDark
                          : AppColors.textMutedLight,
                    ),
                  ),
              ],
            ),
          ),

          const Divider(height: 1),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Course title
                if (isCourse && courseTitle.isNotEmpty) ...[
                  Row(
                    children: [
                      const Icon(Icons.school_rounded,
                          size: 14, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          courseTitle,
                          style: TextStyle(
                            fontFamily: 'Almarai',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.white
                                : AppColors.textMainLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],

                // Review comment preview
                if (!isCourse && reviewComment != null) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.backgroundDark
                          : AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        if (reviewRating != null) ...[
                          Icon(Icons.star_rounded,
                              color: AppColors.ratingLight, size: 14),
                          Text(
                            ' $reviewRating  •  ',
                            style: const TextStyle(
                                fontFamily: 'Almarai', fontSize: 12),
                          ),
                        ],
                        Expanded(
                          child: Text(
                            reviewComment,
                            style: TextStyle(
                              fontFamily: 'Almarai',
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.textMutedDark
                                  : AppColors.textMutedLight,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                // Reason + Reporter
                Row(
                  children: [
                    Icon(Icons.flag_rounded,
                        size: 14, color: AppColors.error),
                    const SizedBox(width: 4),
                    Text(
                      reasonLabel,
                      style: const TextStyle(
                        fontFamily: 'Almarai',
                        fontSize: 13,
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.person_rounded,
                        size: 14,
                        color: isDark
                            ? AppColors.textMutedDark
                            : AppColors.textMutedLight),
                    const SizedBox(width: 4),
                    Text(
                      reporterName,
                      style: TextStyle(
                        fontFamily: 'Almarai',
                        fontSize: 12,
                        color: isDark
                            ? AppColors.textMutedDark
                            : AppColors.textMutedLight,
                      ),
                    ),
                  ],
                ),

                if (description != null && description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: TextStyle(
                      fontFamily: 'Almarai',
                      fontSize: 12,
                      color: isDark
                          ? AppColors.textMutedDark
                          : AppColors.textMutedLight,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                // Action buttons (only for pending)
                if (status == 'pending') ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _updateStatus(
                              report['id'] as String, 'resolved', isCourse),
                          icon: const Icon(Icons.check_rounded, size: 14),
                          label: const Text('تم الحل',
                              style: TextStyle(
                                  fontFamily: 'Almarai', fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.success,
                            side: const BorderSide(color: AppColors.success),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _updateStatus(
                              report['id'] as String, 'dismissed', isCourse),
                          icon: const Icon(Icons.close_rounded, size: 14),
                          label: const Text('رفض',
                              style: TextStyle(
                                  fontFamily: 'Almarai', fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textMutedLight,
                            side:
                                const BorderSide(color: AppColors.borderLight),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return AppColors.warning;
      case 'resolved':
        return AppColors.success;
      case 'dismissed':
        return AppColors.textMutedLight;
      default:
        return AppColors.info;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return '⏳ معلق';
      case 'resolved':
        return '✅ تم الحل';
      case 'dismissed':
        return '❌ مرفوض';
      default:
        return status;
    }
  }

  String _reasonLabel(String reason) {
    switch (reason) {
      case 'inappropriate':
        return 'محتوى غير لائق';
      case 'spam':
        return 'سبام';
      case 'misleading':
        return 'معلومات مضللة';
      case 'copyright':
        return 'انتهاك حقوق الملكية';
      case 'harassment':
        return 'تحرش أو إساءة';
      case 'other':
        return 'أخرى';
      default:
        return reason;
    }
  }
}
