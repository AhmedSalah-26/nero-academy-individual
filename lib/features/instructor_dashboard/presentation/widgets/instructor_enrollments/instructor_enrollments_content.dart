// ignore_for_file: use_build_context_synchronously

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/features/instructor_dashboard/presentation/cubit/instructor_enrollments_cubit.dart';
import 'package:lms_platform/features/instructor_dashboard/data/models/instructor_enrollment_model.dart';

/// Instructor Enrollments Content
class InstructorEnrollmentsContent extends StatefulWidget {
  const InstructorEnrollmentsContent({super.key});

  @override
  State<InstructorEnrollmentsContent> createState() =>
      _InstructorEnrollmentsContentState();
}

class _InstructorEnrollmentsContentState
    extends State<InstructorEnrollmentsContent> {
  int _selectedTabIndex = 0;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<InstructorEnrollmentsCubit>().loadEnrollments();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<InstructorEnrollmentsCubit>().loadMore();
    }
  }

  Future<void> _onRefresh() async {
    HapticFeedback.mediumImpact();
    await context.read<InstructorEnrollmentsCubit>().loadEnrollments();
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.locale.languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<InstructorEnrollmentsCubit, InstructorEnrollmentsState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with stats
            _buildStatsHeader(state, isArabic),
            const SizedBox(height: 24),

            // Status Filter Dropdown
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : AppColors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color:
                        isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
                child: DropdownButton<int>(
                  value: _selectedTabIndex,
                  underline: const SizedBox(),
                  isExpanded: true,
                  items: [
                    DropdownMenuItem(
                      value: 0,
                      child: Text(
                          '${isArabic ? 'الكل' : 'All'} (${state.enrollments.length})'),
                    ),
                    DropdownMenuItem(
                      value: 1,
                      child: Text(
                          '${isArabic ? 'نشط' : 'Active'} (${state.enrollments.where((e) => e.status == 'active').length})'),
                    ),
                    DropdownMenuItem(
                      value: 2,
                      child: Text(
                          '${isArabic ? 'مكتمل' : 'Completed'} (${state.enrollments.where((e) => e.status == 'completed').length})'),
                    ),
                    DropdownMenuItem(
                      value: 3,
                      child: Text(
                          '${isArabic ? 'مسترد' : 'Refunded'} (${state.enrollments.where((e) => e.status == 'refunded').length})'),
                    ),
                  ],
                  onChanged: (index) {
                    if (index != null) {
                      setState(() => _selectedTabIndex = index);
                      final filters = [
                        EnrollmentStatusFilter.all,
                        EnrollmentStatusFilter.active,
                        EnrollmentStatusFilter.completed,
                        EnrollmentStatusFilter.refunded,
                      ];
                      context
                          .read<InstructorEnrollmentsCubit>()
                          .setFilter(filters[index]);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Date range filter
            _buildDateFilter(context, state, isArabic),
            const SizedBox(height: 16),

            // Enrollments list
            Expanded(
              child: RefreshIndicator(
                onRefresh: _onRefresh,
                color: AppColors.primary,
                backgroundColor: isDark ? AppColors.cardDark : AppColors.white,
                child: state.isLoading
                    ? const SingleChildScrollView(
                        physics: AlwaysScrollableScrollPhysics(),
                        child: SizedBox(
                          height: 360,
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      )
                    : state.filteredEnrollments.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(
                                height: 360,
                                child: _buildEmptyState(isArabic),
                              ),
                            ],
                          )
                        : _buildEnrollmentsList(state, isArabic),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatsHeader(InstructorEnrollmentsState state, bool isArabic) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.people_rounded,
            label: isArabic ? 'إجمالي التسجيلات' : 'Total Enrollments',
            value: state.totalEnrollments.toString(),
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            icon: Icons.attach_money_rounded,
            label: isArabic ? 'إجمالي الإيرادات' : 'Total Revenue',
            value: '\$${state.totalRevenue.toStringAsFixed(0)}',
            color: Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildDateFilter(
    BuildContext context,
    InstructorEnrollmentsState state,
    bool isArabic,
  ) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _selectDateRange(context),
            icon: const Icon(Icons.date_range_rounded, size: 20),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              minimumSize: const Size.fromHeight(44),
              textStyle: const TextStyle(fontSize: 15),
            ),
            label: Text(
              state.startDate != null && state.endDate != null
                  ? '${DateFormat('MMM d').format(state.startDate!)} - ${DateFormat('MMM d').format(state.endDate!)}'
                  : isArabic
                      ? 'اختر الفترة'
                      : 'Select Date Range',
            ),
          ),
        ),
        if (state.startDate != null) ...[
          const SizedBox(width: 8),
          IconButton(
            onPressed: () {
              context
                  .read<InstructorEnrollmentsCubit>()
                  .setDateRange(null, null);
            },
            icon: const Icon(Icons.clear_rounded),
            tooltip: isArabic ? 'مسح' : 'Clear',
          ),
        ],
      ],
    );
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) {
      if (!mounted) return;
      context
          .read<InstructorEnrollmentsCubit>()
          .setDateRange(picked.start, picked.end);
    }
  }

  Widget _buildEmptyState(bool isArabic) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_ind_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            isArabic ? 'لا توجد تسجيلات' : 'No enrollments found',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnrollmentsList(
      InstructorEnrollmentsState state, bool isArabic) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      controller: _scrollController,
      itemCount:
          state.filteredEnrollments.length + (state.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == state.filteredEnrollments.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }
        return _EnrollmentListItem(
          enrollment: state.filteredEnrollments[index],
          isArabic: isArabic,
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EnrollmentListItem extends StatefulWidget {
  final InstructorEnrollmentModel enrollment;
  final bool isArabic;

  const _EnrollmentListItem({
    required this.enrollment,
    required this.isArabic,
  });

  @override
  State<_EnrollmentListItem> createState() => _EnrollmentListItemState();
}

class _EnrollmentListItemState extends State<_EnrollmentListItem> {
  bool _isProcessing = false;

  Future<void> _showRefundDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.isArabic ? 'تأكيد الاسترداد' : 'Confirm Refund'),
        content: Text(
          widget.isArabic
              ? 'هل أنت متأكد من استرداد المبلغ لـ ${widget.enrollment.studentName}؟\n\nالمبلغ: \$${widget.enrollment.paidAmount?.toStringAsFixed(0)}'
              : 'Are you sure you want to refund ${widget.enrollment.studentName}?\n\nAmount: \$${widget.enrollment.paidAmount?.toStringAsFixed(0)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(widget.isArabic ? 'إلغاء' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(widget.isArabic ? 'استرداد' : 'Refund'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _processRefund();
    }
  }

  Future<void> _processRefund() async {
    setState(() => _isProcessing = true);

    try {
      await Supabase.instance.client.rpc('process_refund', params: {
        'p_enrollment_id': widget.enrollment.id,
        'p_reason': 'Refunded by instructor',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isArabic
                  ? 'تم استرداد المبلغ بنجاح'
                  : 'Refund processed successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Reload enrollments
        context.read<InstructorEnrollmentsCubit>().loadEnrollments();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isArabic
                  ? 'فشل استرداد المبلغ: $e'
                  : 'Failed to process refund: $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                // Student avatar
                CircleAvatar(
                  radius: 24,
                  backgroundImage: widget.enrollment.studentAvatar != null
                      ? NetworkImage(widget.enrollment.studentAvatar!)
                      : null,
                  child: widget.enrollment.studentAvatar == null
                      ? Text(widget.enrollment.studentName[0].toUpperCase())
                      : null,
                ),
                const SizedBox(width: 16),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.enrollment.studentName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.isArabic
                            ? widget.enrollment.courseTitleAr ??
                                widget.enrollment.courseTitle
                            : widget.enrollment.courseTitle,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('MMM d, yyyy')
                            .format(widget.enrollment.enrolledAt),
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                // Status and amount
                Flexible(
                  flex: 0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildStatusChip(widget.enrollment.status),
                      const SizedBox(height: 8),
                      Text(
                        '\$${(widget.enrollment.paidAmount ?? 0).toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Refund button for active enrollments
            if (widget.enrollment.status == 'active' &&
                (widget.enrollment.paidAmount ?? 0) > 0) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isProcessing ? null : _showRefundDialog,
                  icon: _isProcessing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.money_off_rounded, size: 18),
                  label: Text(
                    widget.isArabic ? 'استرداد المبلغ' : 'Process Refund',
                    style: const TextStyle(fontSize: 14),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;

    switch (status) {
      case 'active':
        color = Colors.blue;
        label = widget.isArabic ? 'نشط' : 'Active';
        break;
      case 'completed':
        color = Colors.green;
        label = widget.isArabic ? 'مكتمل' : 'Completed';
        break;
      case 'refunded':
        color = Colors.red;
        label = widget.isArabic ? 'مسترد' : 'Refunded';
        break;
      default:
        color = Colors.grey;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
