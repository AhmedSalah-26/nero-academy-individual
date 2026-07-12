import 'package:flutter/material.dart';
import 'package:lms_platform/core/animations/foundation/foundation.dart';

/// Success animation widget
/// Displays an animated checkmark with scale and fade effects
class SuccessAnimation extends StatefulWidget {
  /// Size of the animation
  final double size;

  /// Color of the checkmark
  final Color color;

  /// Callback when animation completes
  final VoidCallback? onComplete;

  /// Animation duration
  final Duration duration;

  const SuccessAnimation({
    super.key,
    this.size = 100.0,
    this.color = Colors.green,
    this.onComplete,
    this.duration = const Duration(milliseconds: 600),
  });

  @override
  State<SuccessAnimation> createState() => _SuccessAnimationState();
}

class _SuccessAnimationState extends State<SuccessAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _checkAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    // Circle scales in first
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
      ),
    );

    // Then checkmark draws
    _checkAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.forward().then((_) {
      if (widget.onComplete != null) {
        widget.onComplete!();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shouldAnimate = AccessibilityManager.instance.shouldAnimate(context);

    if (!shouldAnimate) {
      return _buildCheckmark(1.0, 1.0);
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return _buildCheckmark(_scaleAnimation.value, _checkAnimation.value);
      },
    );
  }

  Widget _buildCheckmark(double scale, double checkProgress) {
    return Transform.scale(
      scale: scale,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
        ),
        child: CustomPaint(
          painter: _CheckmarkPainter(
            progress: checkProgress,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

/// Checkmark painter
class _CheckmarkPainter extends CustomPainter {
  final double progress;
  final Color color;

  _CheckmarkPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.width * 0.08
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();

    // Checkmark path
    final startX = size.width * 0.25;
    final startY = size.height * 0.5;
    final midX = size.width * 0.45;
    final midY = size.height * 0.7;
    final endX = size.width * 0.75;
    final endY = size.height * 0.3;

    // First segment (down-left to middle)
    const segment1Length = 0.4;
    if (progress <= segment1Length) {
      final segmentProgress = progress / segment1Length;
      path.moveTo(startX, startY);
      path.lineTo(
        startX + (midX - startX) * segmentProgress,
        startY + (midY - startY) * segmentProgress,
      );
    } else {
      // Second segment (middle to up-right)
      final segment2Progress =
          (progress - segment1Length) / (1.0 - segment1Length);
      path.moveTo(startX, startY);
      path.lineTo(midX, midY);
      path.lineTo(
        midX + (endX - midX) * segment2Progress,
        midY + (endY - midY) * segment2Progress,
      );
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CheckmarkPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
