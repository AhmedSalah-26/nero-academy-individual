import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/core/shared_widgets/loading_skeleton.dart';

/// Chart Type
enum DashboardChartType { area, bar, line }

/// Chart Data Point
class ChartDataPoint {
  final String label;
  final double value;
  final Color? color;
  final DateTime? date;

  const ChartDataPoint({
    required this.label,
    required this.value,
    this.color,
    this.date,
  });
}

/// Dashboard Chart - Modern chart with consistent styling
class DashboardChart extends StatefulWidget {
  final String title;
  final DashboardChartType type;
  final List<ChartDataPoint> data;
  final bool isLoading;
  final double height;
  final Color? primaryColor;
  final bool showTotal;

  const DashboardChart({
    super.key,
    required this.title,
    required this.type,
    required this.data,
    this.isLoading = false,
    this.height = 220,
    this.primaryColor,
    this.showTotal = false,
  });

  @override
  State<DashboardChart> createState() => _DashboardChartState();
}

class _DashboardChartState extends State<DashboardChart> {
  int? touchedIndex;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chartColor = widget.primaryColor ?? AppColors.primary;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(isDark, chartColor),
          const SizedBox(height: 16),
          SizedBox(
            height: widget.height,
            child: widget.isLoading
                ? _buildSkeleton()
                : _buildChart(isDark, chartColor),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark, Color chartColor) {
    final total = widget.data.fold<double>(0, (sum, d) => sum + d.value);

    return Row(
      children: [
        Expanded(
          child: Text(
            widget.title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
            ),
          ),
        ),
        if (widget.showTotal && widget.data.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: chartColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _formatValue(total),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: chartColor,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildChart(bool isDark, Color chartColor) {
    if (widget.data.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart_rounded,
              size: 48,
              color: isDark ? AppColors.textMutedDark : AppColors.grey300,
            ),
            const SizedBox(height: 8),
            Text(
              'No data available',
              style: TextStyle(
                color:
                    isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              ),
            ),
          ],
        ),
      );
    }

    switch (widget.type) {
      case DashboardChartType.area:
        return _buildAreaChart(isDark, chartColor);
      case DashboardChartType.bar:
        return _buildBarChart(isDark, chartColor);
      case DashboardChartType.line:
        return _buildLineChart(isDark, chartColor);
    }
  }

  Widget _buildAreaChart(bool isDark, Color chartColor) {
    final maxY = _getMaxY();

    return LineChart(
      LineChartData(
        gridData: _gridData(isDark, maxY),
        titlesData: _titlesData(isDark, maxY),
        borderData: FlBorderData(show: false),
        minY: 0,
        maxY: maxY,
        lineTouchData: LineTouchData(
          touchTooltipData: _tooltipData(isDark, chartColor),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: widget.data.asMap().entries.map((e) {
              return FlSpot(e.key.toDouble(), e.value.value);
            }).toList(),
            isCurved: true,
            curveSmoothness: 0.3,
            color: chartColor,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  chartColor.withValues(alpha: 0.3),
                  chartColor.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(bool isDark, Color chartColor) {
    final maxY = _getMaxY();

    return BarChart(
      BarChartData(
        gridData: _gridData(isDark, maxY),
        titlesData: _titlesData(isDark, maxY),
        borderData: FlBorderData(show: false),
        minY: 0,
        maxY: maxY,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) =>
                isDark ? AppColors.surfaceDark : AppColors.grey800,
            tooltipRoundedRadius: 8,
            tooltipPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final dataPoint = widget.data[group.x];
              return BarTooltipItem(
                '${dataPoint.label}\n',
                TextStyle(
                  color: isDark ? AppColors.textMutedDark : AppColors.grey400,
                  fontSize: 12,
                ),
                children: [
                  TextSpan(
                    text: _formatValue(dataPoint.value),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              );
            },
          ),
          touchCallback: (event, response) {
            setState(() {
              if (response?.spot != null &&
                  event is! FlPointerExitEvent &&
                  event is! FlLongPressEnd) {
                touchedIndex = response!.spot!.touchedBarGroupIndex;
              } else {
                touchedIndex = null;
              }
            });
          },
        ),
        barGroups: widget.data.asMap().entries.map((e) {
          final isTouched = touchedIndex == e.key;
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: e.value.value,
                width: _getBarWidth(),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(6)),
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: isTouched
                      ? [
                          chartColor,
                          chartColor.withValues(alpha: 0.8),
                        ]
                      : [
                          chartColor.withValues(alpha: 0.7),
                          chartColor,
                        ],
                ),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: maxY,
                  color: isDark ? AppColors.surfaceDark : AppColors.grey100,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLineChart(bool isDark, Color chartColor) {
    final maxY = _getMaxY();

    return LineChart(
      LineChartData(
        gridData: _gridData(isDark, maxY),
        titlesData: _titlesData(isDark, maxY),
        borderData: FlBorderData(show: false),
        minY: 0,
        maxY: maxY,
        lineTouchData: LineTouchData(
          touchTooltipData: _tooltipData(isDark, chartColor),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: widget.data.asMap().entries.map((e) {
              return FlSpot(e.key.toDouble(), e.value.value);
            }).toList(),
            isCurved: true,
            curveSmoothness: 0.3,
            color: chartColor,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 5,
                  color: chartColor,
                  strokeWidth: 2,
                  strokeColor: isDark ? AppColors.cardDark : AppColors.white,
                );
              },
            ),
            shadow: Shadow(
              color: chartColor.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ),
        ],
      ),
    );
  }

  double _getMaxY() {
    if (widget.data.isEmpty) return 5;
    final maxValue =
        widget.data.map((d) => d.value).reduce((a, b) => a > b ? a : b);
    if (maxValue <= 0) return 5;
    // Add 20% padding and round up
    final padded = maxValue * 1.2;
    if (padded <= 5) return 5;
    if (padded <= 10) return 10;
    if (padded <= 20) return 20;
    if (padded <= 50) return 50;
    if (padded <= 100) return 100;
    return (padded / 10).ceil() * 10.0;
  }

  double _getBarWidth() {
    final count = widget.data.length;
    if (count <= 7) return 24;
    if (count <= 14) return 16;
    if (count <= 21) return 12;
    return 8;
  }

  FlGridData _gridData(bool isDark, double maxY) {
    final interval = _calculateInterval(maxY);
    return FlGridData(
      show: true,
      drawVerticalLine: false,
      horizontalInterval: interval,
      getDrawingHorizontalLine: (value) {
        return FlLine(
          color: isDark
              ? AppColors.borderDark.withValues(alpha: 0.3)
              : AppColors.grey200,
          strokeWidth: 1,
          dashArray: [5, 5],
        );
      },
    );
  }

  double _calculateInterval(double maxValue) {
    if (maxValue <= 5) return 1;
    if (maxValue <= 10) return 2;
    if (maxValue <= 20) return 5;
    if (maxValue <= 50) return 10;
    if (maxValue <= 100) return 20;
    return (maxValue / 5).ceilToDouble();
  }

  LineTouchTooltipData _tooltipData(bool isDark, Color chartColor) {
    return LineTouchTooltipData(
      getTooltipColor: (_) =>
          isDark ? AppColors.surfaceDark : AppColors.grey800,
      tooltipRoundedRadius: 8,
      tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      getTooltipItems: (spots) {
        return spots.map((spot) {
          final dataPoint = widget.data[spot.x.toInt()];
          return LineTooltipItem(
            '${dataPoint.label}\n',
            TextStyle(
              color: isDark ? AppColors.textMutedDark : AppColors.grey400,
              fontSize: 12,
            ),
            children: [
              TextSpan(
                text: _formatValue(dataPoint.value),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          );
        }).toList();
      },
    );
  }

  FlTitlesData _titlesData(bool isDark, double maxY) {
    final textColor =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    final yInterval = _calculateInterval(maxY);

    // Show fewer X-axis labels when there are many data points
    final count = widget.data.length;
    int showEveryNth;
    if (count <= 5) {
      showEveryNth = 1;
    } else if (count <= 10) {
      showEveryNth = 2;
    } else if (count <= 15) {
      showEveryNth = 3;
    } else if (count <= 20) {
      showEveryNth = 4;
    } else {
      showEveryNth = (count / 5).ceil();
    }

    return FlTitlesData(
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 40,
          interval: 1,
          getTitlesWidget: (value, meta) {
            final index = value.toInt();
            if (index < 0 || index >= widget.data.length) {
              return const SizedBox();
            }

            // Only show every Nth label
            if (index % showEveryNth != 0) {
              return const SizedBox();
            }

            final dataPoint = widget.data[index];
            String label;

            // Format as day/month
            if (dataPoint.date != null) {
              label = '${dataPoint.date!.day}/${dataPoint.date!.month}';
            } else {
              // Try to parse label as date
              try {
                final date = DateTime.parse(dataPoint.label);
                label = '${date.day}/${date.month}';
              } catch (_) {
                // Not a date, truncate
                label = dataPoint.label;
                if (label.length > 6) {
                  label = label.substring(0, 5);
                }
              }
            }

            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: textColor,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
              ),
            );
          },
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 40,
          interval: yInterval,
          getTitlesWidget: (value, meta) {
            if (value < 0) return const SizedBox();
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                _formatValue(value),
                style: TextStyle(
                  fontSize: 11,
                  color: textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String _formatValue(double value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(1);
  }

  Widget _buildSkeleton() {
    return const Center(
      child: LoadingSkeleton(width: double.infinity, height: 180),
    );
  }
}
