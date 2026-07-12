import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/shared_widgets/loading_skeleton.dart';
import '../../data/models/admin_course_model.dart';
import '../cubit/admin_courses_cubit.dart';

/// Course Enrollments Screen - Full screen version for viewing course enrollments
class CourseEnrollmentsScreen extends StatefulWidget {
  final AdminCourseModel course;

  const CourseEnrollmentsScreen({
    super.key,
    required this.course,
  });

  @override
  State<CourseEnrollmentsScreen> createState() =>
      _CourseEnrollmentsScreenState();
}

class _CourseEnrollmentsScreenState extends State<CourseEnrollmentsScreen> {
  List<Map<String, dynamic>>? _enrollments;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadEnrollments();
  }

  Future<void> _loadEnrollments() async {
    try {
      final enrollments = await context
          .read<AdminCoursesCubit>()
          .getCourseEnrollments(widget.course.id);
      if (mounted) {
        setState(() {
          _enrollments = enrollments;
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isArabic ? 'المسجلين في الكورس' : 'Course Enrollments',
              style: const TextStyle(fontSize: 18),
            ),
            Text(
              widget.course.getTitle(isArabic),
              style: TextStyle(
                fontSize: 12,
                color:
                    isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              ),
            ),
          ],
        ),
      ),
      body: _buildContent(isDark, isArabic),
    );
  }

  Widget _buildContent(bool isDark, bool isArabic) {
    if (_isLoading) {
      return _buildLoadingSkeleton();
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text(
                isArabic ? 'حدث خطأ' : 'An error occurred',
                style: TextStyle(
                  color:
                      isDark ? AppColors.textMainDark : AppColors.textMainLight,
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _error = null;
                  });
                  _loadEnrollments();
                },
                icon: const Icon(Icons.refresh_rounded),
                label: Text(isArabic ? 'إعادة المحاولة' : 'Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_enrollments == null || _enrollments!.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.people_outline_rounded,
                  size: 64, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text(
                isArabic ? 'لا يوجد مسجلين' : 'No enrollments yet',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          _isLoading = true;
          _error = null;
        });
        await _loadEnrollments();
      },
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _enrollments!.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final enrollment = _enrollments![index];
          return _buildEnrollmentItem(enrollment, isDark, isArabic);
        },
      ),
    );
  }

  Widget _buildEnrollmentItem(
    Map<String, dynamic> enrollment,
    bool isDark,
    bool isArabic,
  ) {
    final user = enrollment['user'] as Map<String, dynamic>?;
    final userName = user?['name'] as String? ?? 'Unknown';
    final userEmail = user?['email'] as String? ?? '';
    final status = enrollment['status'] as String? ?? 'active';
    final progress = (enrollment['progress'] as num?)?.toDouble() ?? 0;
    final enrolledAt = enrollment['enrolled_at'] as String?;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: Text(
                userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.textMainDark
                          : AppColors.textMainLight,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    userEmail,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.textMutedDark
                          : AppColors.textMutedLight,
                    ),
                  ),
                  if (enrolledAt != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      _formatDate(DateTime.parse(enrolledAt), isArabic),
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? AppColors.textMutedDark
                            : AppColors.textMutedLight,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildStatusBadge(status, isArabic),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.trending_up_rounded,
                      size: 14,
                      color: progress >= 100
                          ? AppColors.success
                          : AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${progress.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: progress >= 100
                            ? AppColors.success
                            : AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status, bool isArabic) {
    Color color;
    String label;

    switch (status) {
      case 'completed':
        color = AppColors.success;
        label = isArabic ? 'مكتمل' : 'Completed';
        break;
      case 'refunded':
        color = AppColors.error;
        label = isArabic ? 'مسترد' : 'Refunded';
        break;
      default:
        color = AppColors.info;
        label = isArabic ? 'نشط' : 'Active';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 8,
      itemBuilder: (_, __) => Card(
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              LoadingSkeleton(
                  width: 48,
                  height: 48,
                  borderRadius: BorderRadius.circular(24)),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LoadingSkeleton(height: 15, width: 120),
                    SizedBox(height: 4),
                    LoadingSkeleton(height: 12, width: 180),
                    SizedBox(height: 4),
                    LoadingSkeleton(height: 11, width: 100),
                  ],
                ),
              ),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  LoadingSkeleton(height: 20, width: 60),
                  SizedBox(height: 6),
                  LoadingSkeleton(height: 14, width: 40),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date, bool isArabic) {
    final months = isArabic
        ? [
            'يناير',
            'فبراير',
            'مارس',
            'أبريل',
            'مايو',
            'يونيو',
            'يوليو',
            'أغسطس',
            'سبتمبر',
            'أكتوبر',
            'نوفمبر',
            'ديسمبر'
          ]
        : [
            'Jan',
            'Feb',
            'Mar',
            'Apr',
            'May',
            'Jun',
            'Jul',
            'Aug',
            'Sep',
            'Oct',
            'Nov',
            'Dec'
          ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
