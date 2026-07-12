import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:lms_platform/core/theme/app_colors.dart';

/// Score Circle - Animated circular progress showing quiz score
class ScoreCircle extends StatelessWidget {
  final double percentage;
  final bool passed;
  final bool isDark;

  const ScoreCircle({
    super.key,
    required this.percentage,
    required this.passed,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = passed ? AppColors.success : AppColors.error;

    return SizedBox(
      width: 140,
      height: 140,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Circle
          CustomPaint(
            size: const Size(140, 140),
            painter: _CirclePainter(
              progress: percentage / 100,
              backgroundColor: isDark ? AppColors.grey800 : AppColors.grey100,
              progressColor: color,
              strokeWidth: 10,
            ),
          ),

          // Score Text
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${percentage.toStringAsFixed(0)}%',
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isDark ? 0.3 : 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  passed ? 'نجحت' : 'لم تنجح',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Custom painter for the circular progress
class _CirclePainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Color progressColor;
  final double strokeWidth;

  _CirclePainter({
    required this.progress,
    required this.backgroundColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background circle
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // Start from top
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CirclePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.progressColor != progressColor;
  }
}
