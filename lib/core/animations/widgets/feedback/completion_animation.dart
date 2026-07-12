import 'package:flutter/material.dart';
import 'package:lms_platform/core/animations/foundation/animation_config.dart';
import 'package:lms_platform/core/animations/foundation/accessibility_manager.dart';

/// Type of completion animation to display
enum CompletionType {
  /// Simple checkmark animation
  checkmark,

  /// Confetti celebration animation
  confetti,

  /// Trophy/achievement animation
  trophy,
}

/// A widget that displays a completion animation
///
/// Shows different types of completion animations (checkmark, confetti, trophy)
/// based on the completion type. Useful for quiz completions, course completions,
/// and achievement unlocks.
///
/// Respects accessibility settings:
/// - If reduce motion is enabled, shows instant completion without animation
/// - If animations are disabled, shows static completion icon
///
/// Example:
/// ```dart
/// CompletionAnimation(
///   type: CompletionType.trophy,
///   size: 120.0,
///   color: Colors.amber,
///   onComplete: () {
///     print('Animation completed');
///   },
/// )
/// ```
class CompletionAnimation extends StatefulWidget {
  /// Size of the completion animation
  final double size;

  /// Primary color for the animation
  final Color color;

  /// Callback when animation completes
  final VoidCallback? onComplete;

  /// Type of completion animation
  final CompletionType type;

  /// Duration of the animation
  final Duration duration;

  const CompletionAnimation({
    super.key,
    this.size = 100.0,
    this.color = Colors.green,
    this.onComplete,
    this.type = CompletionType.checkmark,
    Duration? duration,
  }) : duration = duration ?? const Duration(milliseconds: 800);

  @override
  State<CompletionAnimation> createState() => _CompletionAnimationState();
}

class _CompletionAnimationState extends State<CompletionAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _rotationAnimation;
  bool _shouldAnimate = true;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initAnimation();
  }

  void _initAnimation() {
    final config = AnimationConfig.instance;

    // Initialize controller immediately with default duration
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    // Initialize animations
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.2)
            .chain(CurveTween(curve: config.emphasizedCurve)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
    ]).animate(_controller);

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
    ));

    _rotationAnimation = Tween<double>(
      begin: -0.1,
      end: 0.1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    // Check accessibility settings after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final accessibilityManager = AccessibilityManager.instance;
      _shouldAnimate = accessibilityManager.shouldAnimate(context);

      // Get adjusted duration based on accessibility settings
      final adjustedDuration = accessibilityManager.getSimplifiedDuration(
        context,
        widget.duration,
      );

      // Update controller duration if needed
      if (adjustedDuration != widget.duration) {
        _controller.duration = adjustedDuration;
      }

      _initialized = true;

      if (_shouldAnimate) {
        _controller.forward().then((_) {
          if (mounted && widget.onComplete != null) {
            widget.onComplete!();
          }
        });
      } else {
        // If animations are disabled, show completion immediately
        if (mounted) {
          setState(() {});
          // Call onComplete after a brief delay to ensure UI is rendered
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted && widget.onComplete != null) {
              widget.onComplete!();
            }
          });
        }
      }
    });
  }

  @override
  void dispose() {
    if (_controller.isAnimating) {
      _controller.stop();
    }
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If not initialized yet or animations are disabled, show static completion icon
    if (!_initialized || !_shouldAnimate) {
      return _buildCompletionWidget();
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: _buildCompletionWidget(),
          ),
        );
      },
    );
  }

  Widget _buildCompletionWidget() {
    switch (widget.type) {
      case CompletionType.checkmark:
        return _buildCheckmark();
      case CompletionType.confetti:
        return _buildConfetti();
      case CompletionType.trophy:
        return _buildTrophy();
    }
  }

  Widget _buildCheckmark() {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: widget.color,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.check,
        color: Colors.white,
        size: widget.size * 0.6,
      ),
    );
  }

  Widget _buildConfetti() {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Center checkmark
          Container(
            width: widget.size * 0.6,
            height: widget.size * 0.6,
            decoration: BoxDecoration(
              color: widget.color,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check,
              color: Colors.white,
              size: widget.size * 0.36,
            ),
          ),
          // Confetti particles
          ..._buildConfettiParticles(),
        ],
      ),
    );
  }

  List<Widget> _buildConfettiParticles() {
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.yellow,
      Colors.green,
      Colors.blueAccent,
      Colors.orange,
    ];

    return List.generate(12, (index) {
      final angle = (index * 30.0) * (3.14159 / 180.0);
      final distance = widget.size * 0.4 * _scaleAnimation.value;
      final x = distance * (index % 2 == 0 ? 1 : -1) * (index / 12);
      final y = distance * (index % 3 == 0 ? 1 : -1) * (index / 12);

      return Positioned(
        left: widget.size / 2 + x,
        top: widget.size / 2 + y,
        child: Transform.rotate(
          angle: angle,
          child: Container(
            width: 6,
            height: 12,
            decoration: BoxDecoration(
              color: colors[index % colors.length],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildTrophy() {
    return Transform.rotate(
      angle: _rotationAnimation.value,
      child: Icon(
        Icons.emoji_events,
        color: widget.color,
        size: widget.size,
      ),
    );
  }
}
