import 'package:flutter/material.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/core/shared_widgets/loading_skeleton.dart';
import 'package:lms_platform/core/shared_widgets/empty_state.dart';

/// Dashboard Data Table - Generic data table with search and pagination
class DashboardDataTable<T> extends StatelessWidget {
  final List<T> items;
  final List<DataColumn> columns;
  final DataRow Function(T item) rowBuilder;
  final bool isLoading;
  final bool hasMore;
  final VoidCallback? onLoadMore;
  final String? emptyMessage;
  final String? emptyMessageAr;
  final IconData? emptyIcon;
  final ScrollController? scrollController;

  const DashboardDataTable({
    super.key,
    required this.items,
    required this.columns,
    required this.rowBuilder,
    this.isLoading = false,
    this.hasMore = false,
    this.onLoadMore,
    this.emptyMessage,
    this.emptyMessageAr,
    this.emptyIcon,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    if (isLoading && items.isEmpty) {
      return _buildLoadingSkeleton(isDark);
    }

    if (items.isEmpty) {
      return EmptyState(
        icon: emptyIcon ?? Icons.inbox_rounded,
        title: isArabic
            ? (emptyMessageAr ?? 'لا توجد بيانات')
            : (emptyMessage ?? 'No data available'),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification &&
            notification.metrics.extentAfter < 200 &&
            hasMore &&
            !isLoading &&
            onLoadMore != null) {
          onLoadMore!();
        }
        return false;
      },
      child: SingleChildScrollView(
        controller: scrollController,
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: Column(
            children: [
              DataTable(
                headingRowColor: WidgetStateProperty.all(
                  isDark ? AppColors.surfaceDark : AppColors.grey50,
                ),
                dataRowColor: WidgetStateProperty.all(
                  isDark ? AppColors.cardDark : AppColors.white,
                ),
                columns: columns,
                rows: items.map(rowBuilder).toList(),
              ),
              if (isLoading && items.isNotEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton(bool isDark) {
    return Column(
      children: List.generate(
        5,
        (index) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
          ),
          child: const Row(
            children: [
              LoadingSkeleton(width: 40, height: 40),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LoadingSkeleton(height: 16),
                    SizedBox(height: 4),
                    LoadingSkeleton(width: 100, height: 12),
                  ],
                ),
              ),
              SizedBox(width: 16),
              LoadingSkeleton(width: 80, height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
