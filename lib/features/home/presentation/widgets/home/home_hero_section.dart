import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/services/teacher_context_service.dart';
import '../../../../../core/shared_widgets/glass_search_bar.dart';
import '../../../../../core/theme/app_colors.dart';
import 'home_app_bar.dart';

class HomeSliverAppBar extends StatelessWidget {
  final String? userName;

  const HomeSliverAppBar({super.key, this.userName});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final w = size.width;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final toolbarHeight = (w * 0.24).clamp(92.0, 108.0);
    final expandedHeight =
        (w * 0.58 + toolbarHeight + 54.0).clamp(335.0, 395.0);

    return SliverAppBar(
      pinned: true,
      elevation: 0,
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      expandedHeight: expandedHeight,
      toolbarHeight: toolbarHeight,
      titleSpacing: 0,
      title: HomeAppBar(userName: userName),
      flexibleSpace: FlexibleSpaceBar(
        background: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: toolbarHeight),
              Expanded(
                child: _HeroVisual(isDark: isDark),
              ),
            ],
          ),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(46.0 + (w * 0.038) + 8.0),
        child: Container(
          color: Colors.transparent,
          padding: EdgeInsets.only(
            left: w * 0.04,
            right: w * 0.04,
            bottom: w * 0.038,
            top: 8,
          ),
          child: GlassSearchBar(
            hintText: 'home.search_placeholder'.tr(),
            onTap: () => context.pushNamed('search'),
            readOnly: true,
            height: 46,
            borderRadius: 12,
            iconSize: w * 0.05,
            hintStyle: TextStyle(fontSize: w * 0.033),
          ),
        ),
      ),
    );
  }
}


class _HeroVisual extends StatelessWidget {
  final bool isDark;

  const _HeroVisual({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        ValueListenableBuilder<SelectedTeacher?>(
          valueListenable: TeacherContextService.instance.selectedTeacher,
          builder: (context, teacher, _) {
            final theme = teacher?.theme;
            final hasCustomIdentity = theme?.hasColors == true ||
                ((theme?.logoUrl ?? '').trim().isNotEmpty);

            if (!hasCustomIdentity) {
              return Image.asset(
                'assets/default_identity/default_teacher_cover.png',
                fit: BoxFit.cover,
                alignment: Alignment.center,
                errorBuilder: (context, error, stackTrace) =>
                    _CustomIdentityBackdrop(isDark: isDark),
              );
            }

            return _CustomIdentityBackdrop(isDark: isDark);
          },
        ),
        // Gradient fade top & bottom
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
                  Colors.transparent,
                  Colors.transparent,
                  isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
                ],
                stops: const [0.0, 0.20, 0.70, 1.0],
              ),
            ),
          ),
        ),
        _HeroCopy(isDark: isDark),
      ],
    );
  }
}

class _CustomIdentityBackdrop extends StatelessWidget {
  final bool isDark;

  const _CustomIdentityBackdrop({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0.42, -0.08),
              radius: 0.9,
              colors: [
                (isDark ? AppColors.primaryOnDark : AppColors.primary)
                    .withValues(alpha: isDark ? 0.20 : 0.16),
                isDark ? AppColors.surfaceDark : AppColors.backgroundLight,
                isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
              ],
              stops: const [0.0, 0.48, 1.0],
            ),
          ),
        ),
        CustomPaint(
          painter: _NasaqHeroBackgroundPainter(isDark: isDark),
        ),
        _AnimatedProgrammingShapes(isDark: isDark),
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsetsDirectional.only(end: 28),
            child: _NasaqMark(isDark: isDark),
          ),
        ),
      ],
    );
  }
}

class _NasaqMark extends StatelessWidget {
  final bool isDark;

  const _NasaqMark({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final size = (w * 0.27).clamp(92.0, 128.0);

    return CustomPaint(
      size: Size.square(size),
      painter: _NasaqMarkPainter(isDark: isDark),
    );
  }
}

class _NasaqHeroBackgroundPainter extends CustomPainter {
  final bool isDark;

  const _NasaqHeroBackgroundPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w * 0.70, h * 0.47);
    final accent = isDark ? AppColors.primaryOnDark : AppColors.primary;
    const blue = AppColors.info;

    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          accent.withValues(alpha: 0.34),
          blue.withValues(alpha: 0.16),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: w * 0.46));
    canvas.drawCircle(center, w * 0.46, glowPaint);

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = accent.withValues(alpha: isDark ? 0.26 : 0.18);
    for (var i = 0; i < 4; i++) {
      canvas.drawCircle(center, w * (0.16 + i * 0.075), ringPaint);
    }

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = accent.withValues(alpha: 0.08);
    for (var x = 0.0; x < w; x += 42) {
      canvas.drawLine(Offset(x, 0), Offset(x, h), linePaint);
    }
    for (var y = 0.0; y < h; y += 42) {
      canvas.drawLine(Offset(0, y), Offset(w, y), linePaint);
    }

    final dotPaint = Paint()..color = accent.withValues(alpha: 0.70);
    for (final point in [
      Offset(w * 0.18, h * 0.22),
      Offset(w * 0.78, h * 0.18),
      Offset(w * 0.84, h * 0.62),
      Offset(w * 0.28, h * 0.74),
    ]) {
      canvas.drawCircle(point, 2.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _NasaqHeroBackgroundPainter oldDelegate) {
    return oldDelegate.isDark != isDark;
  }
}

class _NasaqMarkPainter extends CustomPainter {
  final bool isDark;

  const _NasaqMarkPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final rect = Offset.zero & size;
    final accent = isDark ? AppColors.primaryOnDark : AppColors.primary;

    final shadowPaint = Paint()
      ..color = accent.withValues(alpha: 0.32)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(s * 0.13), Radius.circular(s * 0.18)),
      shadowPaint,
    );

    final box = RRect.fromRectAndRadius(
      rect.deflate(s * 0.16),
      Radius.circular(s * 0.18),
    );
    canvas.drawRRect(
      box,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.backgroundDark,
            AppColors.surfaceDark,
            Color(0xFF071D2A),
          ],
        ).createShader(rect),
    );
    canvas.drawRRect(
      box,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..shader = LinearGradient(
          colors: [
            accent.withValues(alpha: 0.85),
            AppColors.info.withValues(alpha: 0.72),
          ],
        ).createShader(rect),
    );

    final nPath = Path()
      ..moveTo(s * 0.32, s * 0.68)
      ..lineTo(s * 0.32, s * 0.34)
      ..cubicTo(s * 0.32, s * 0.26, s * 0.40, s * 0.23, s * 0.46, s * 0.29)
      ..lineTo(s * 0.68, s * 0.51)
      ..lineTo(s * 0.68, s * 0.32);
    final nPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = s * 0.075
      ..shader = const LinearGradient(
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
        colors: [
          Color(0xFF117CFF),
          Color(0xFF00E3CF),
          Color(0xFFE9FEFF),
        ],
      ).createShader(rect);
    canvas.drawPath(nPath, nPaint);

    final sparklePaint = Paint()..color = accent;
    canvas.drawCircle(Offset(s * 0.74, s * 0.25), s * 0.025, sparklePaint);
    canvas.drawLine(Offset(s * 0.74, s * 0.18), Offset(s * 0.74, s * 0.32),
        sparklePaint..strokeWidth = s * 0.012);
    canvas.drawLine(Offset(s * 0.67, s * 0.25), Offset(s * 0.81, s * 0.25),
        sparklePaint);
  }

  @override
  bool shouldRepaint(covariant _NasaqMarkPainter oldDelegate) {
    return oldDelegate.isDark != isDark;
  }
}

class _AnimatedProgrammingShapes extends StatefulWidget {
  final bool isDark;

  const _AnimatedProgrammingShapes({required this.isDark});

  @override
  State<_AnimatedProgrammingShapes> createState() =>
      _AnimatedProgrammingShapesState();
}

class _AnimatedProgrammingShapesState extends State<_AnimatedProgrammingShapes>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          return Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(
                painter: _BrushSashPainter(isDark: widget.isDark, turn: t),
              ),
              _FloatingCodeShape(
                left: 0.80,
                top: 0.12,
                size: 46,
                turn: t,
                depth: 0.45,
                painter: _DotGridPainter(isDark: widget.isDark),
              ),
              _FloatingCodeShape(
                left: 0.90,
                top: 0.33,
                size: 54,
                turn: 1 - t,
                depth: 0.7,
                painter: _CodeBracketsPainter(isDark: widget.isDark),
              ),
              _FloatingCodeShape(
                left: 0.86,
                top: 0.58,
                size: 54,
                turn: t,
                depth: 0.55,
                painter: _TerminalPainter(isDark: widget.isDark),
              ),
              _FloatingCodeShape(
                left: 0.77,
                top: 0.23,
                size: 38,
                turn: 1 - t,
                depth: 0.35,
                painter: _CursorPainter(isDark: widget.isDark),
              ),
              _FloatingCodeShape(
                left: 0.18,
                top: 0.63,
                size: 64,
                turn: t,
                depth: 0.42,
                painter: _TerminalPainter(isDark: widget.isDark, faint: true),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FloatingCodeShape extends StatelessWidget {
  final double left;
  final double top;
  final double size;
  final double turn;
  final double depth;
  final CustomPainter painter;

  const _FloatingCodeShape({
    required this.left,
    required this.top,
    required this.size,
    required this.turn,
    required this.depth,
    required this.painter,
  });

  @override
  Widget build(BuildContext context) {
    final xTilt = (turn - 0.5) * depth;
    final yTilt = (0.5 - turn) * depth * 0.65;
    final floatOffset = (turn - 0.5) * 10;

    return Positioned(
      left: MediaQuery.of(context).size.width * left,
      top: MediaQuery.of(context).size.width * top + floatOffset,
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.0015)
          ..rotateX(xTilt)
          ..rotateY(yTilt)
          ..rotateZ((turn - 0.5) * 0.12),
        child: CustomPaint(
          size: Size.square(size),
          painter: painter,
        ),
      ),
    );
  }
}

class _BrushSashPainter extends CustomPainter {
  final bool isDark;
  final double turn;

  const _BrushSashPainter({required this.isDark, required this.turn});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final lift = (turn - 0.5) * h * 0.025;
    final base = Path()
      ..moveTo(-w * 0.05, h * 0.78 + lift)
      ..cubicTo(
        w * 0.18,
        h * 0.78 + lift,
        w * 0.35,
        h * 0.58 - lift,
        w * 0.52,
        h * 0.55,
      )
      ..cubicTo(
        w * 0.72,
        h * 0.51 + lift,
        w * 0.86,
        h * 0.23 - lift,
        w * 1.08,
        h * 0.24,
      );

    final shadowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = h * 0.19
      ..color = Colors.black.withValues(alpha: isDark ? 0.22 : 0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    canvas.drawPath(base.shift(Offset(0, h * 0.025)), shadowPaint);

    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = h * 0.17
      ..shader = LinearGradient(
        colors: isDark
            ? [
                AppColors.primaryOnDark.withValues(alpha: 0.04),
                AppColors.primaryOnDark.withValues(alpha: 0.34),
                AppColors.primary.withValues(alpha: 0.48),
                AppColors.primaryDark.withValues(alpha: 0.16),
              ]
            : [
                AppColors.primaryLight.withValues(alpha: 0.05),
                AppColors.primaryLight.withValues(alpha: 0.55),
                AppColors.primary.withValues(alpha: 0.26),
                AppColors.primaryDark.withValues(alpha: 0.08),
              ],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
    canvas.drawPath(base, glowPaint);

    final ridgePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = h * 0.045
      ..shader = LinearGradient(
        colors: [
          Colors.white.withValues(alpha: isDark ? 0.04 : 0.18),
          AppColors.primaryOnDark.withValues(alpha: isDark ? 0.44 : 0.26),
          AppColors.primaryDark.withValues(alpha: isDark ? 0.20 : 0.12),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    for (var i = 0; i < 7; i++) {
      final offset = (i - 3) * h * 0.018;
      final texturePath = Path()
        ..moveTo(-w * 0.02, h * (0.74 + i * 0.006) + lift + offset)
        ..cubicTo(
          w * 0.22,
          h * (0.78 - i * 0.012) + lift,
          w * 0.43,
          h * (0.57 + i * 0.006) - lift,
          w * 0.57,
          h * (0.56 - i * 0.004),
        )
        ..cubicTo(
          w * 0.73,
          h * (0.52 + i * 0.003) + lift,
          w * 0.86,
          h * (0.26 - i * 0.004) - lift,
          w * 1.06,
          h * (0.24 + i * 0.006),
        );
      ridgePaint.strokeWidth = h * (0.01 + (i % 3) * 0.006);
      ridgePaint.color = ridgePaint.color.withValues(alpha: 0.18);
      canvas.drawPath(texturePath, ridgePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BrushSashPainter oldDelegate) {
    return oldDelegate.isDark != isDark || oldDelegate.turn != turn;
  }
}

abstract class _CodePainter extends CustomPainter {
  final bool isDark;
  final bool faint;

  const _CodePainter({required this.isDark, this.faint = false});

  Color get stroke => (isDark ? AppColors.primaryOnDark : AppColors.primary)
      .withValues(alpha: faint ? 0.28 : 0.72);

  Color get fill => (isDark ? AppColors.primaryOnDark : AppColors.primary)
      .withValues(alpha: faint ? 0.12 : 0.22);

  void drawGlassDisc(Canvas canvas, Size size) {
    final s = size.width;
    final rect = Offset.zero & size;
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: isDark ? 0.28 : 0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(s * 0.52, s * 0.56),
        width: s * 0.78,
        height: s * 0.72,
      ),
      shadowPaint,
    );
    final fillPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.45),
        radius: 0.95,
        colors: [
          Colors.white.withValues(alpha: isDark ? 0.16 : 0.30),
          (isDark ? AppColors.primaryOnDark : AppColors.primary)
              .withValues(alpha: faint ? 0.07 : 0.14),
          Colors.transparent,
        ],
      ).createShader(rect);
    canvas.drawOval(rect.deflate(s * 0.04), fillPaint);
    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.026
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: isDark ? 0.28 : 0.55),
          stroke.withValues(alpha: faint ? 0.28 : 0.82),
          AppColors.primaryDark.withValues(alpha: isDark ? 0.40 : 0.20),
        ],
      ).createShader(rect);
    canvas.drawOval(rect.deflate(s * 0.06), rimPaint);
  }

  @override
  bool shouldRepaint(covariant _CodePainter oldDelegate) {
    return oldDelegate.isDark != isDark || oldDelegate.faint != faint;
  }
}

class _CodeBracketsPainter extends _CodePainter {
  const _CodeBracketsPainter({required super.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    drawGlassDisc(canvas, size);
    final s = size.width;
    final strokePaint = Paint()
      ..color = stroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.045
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final left = Path()
      ..moveTo(s * 0.42, s * 0.26)
      ..lineTo(s * 0.24, s * 0.50)
      ..lineTo(s * 0.42, s * 0.74);
    final right = Path()
      ..moveTo(s * 0.58, s * 0.26)
      ..lineTo(s * 0.76, s * 0.50)
      ..lineTo(s * 0.58, s * 0.74);
    canvas.drawPath(left, strokePaint);
    canvas.drawPath(right, strokePaint);
    canvas.drawLine(
      Offset(s * 0.52, s * 0.72),
      Offset(s * 0.62, s * 0.28),
      strokePaint,
    );
  }
}

class _TerminalPainter extends _CodePainter {
  const _TerminalPainter({required super.isDark, super.faint});

  @override
  void paint(Canvas canvas, Size size) {
    drawGlassDisc(canvas, size);
    final s = size.width;
    final strokePaint = Paint()
      ..color = stroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.035
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final rect = Rect.fromLTWH(s * 0.20, s * 0.28, s * 0.60, s * 0.46);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(s * 0.08)),
      Paint()..color = fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(s * 0.08)),
      strokePaint,
    );
    canvas.drawLine(Offset(s * 0.30, s * 0.45), Offset(s * 0.40, s * 0.52),
        strokePaint);
    canvas.drawLine(Offset(s * 0.40, s * 0.52), Offset(s * 0.30, s * 0.59),
        strokePaint);
    canvas.drawLine(Offset(s * 0.48, s * 0.60), Offset(s * 0.66, s * 0.60),
        strokePaint);
  }
}

class _CursorPainter extends _CodePainter {
  const _CursorPainter({required super.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    drawGlassDisc(canvas, size);
    final s = size.width;
    final path = Path()
      ..moveTo(s * 0.30, s * 0.22)
      ..lineTo(s * 0.70, s * 0.52)
      ..lineTo(s * 0.52, s * 0.56)
      ..lineTo(s * 0.64, s * 0.78)
      ..lineTo(s * 0.54, s * 0.84)
      ..lineTo(s * 0.42, s * 0.62)
      ..lineTo(s * 0.30, s * 0.74)
      ..close();
    final paint = Paint()
      ..color = fill
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = stroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.035
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, paint);
    path.close();
    canvas.drawPath(path, strokePaint);
  }
}

class _DotGridPainter extends _CodePainter {
  const _DotGridPainter({required super.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final paint = Paint()
      ..color = stroke.withValues(alpha: 0.48)
      ..style = PaintingStyle.fill;
    for (var row = 0; row < 5; row++) {
      for (var col = 0; col < 5; col++) {
        canvas.drawCircle(
          Offset(s * (0.16 + col * 0.17), s * (0.16 + row * 0.17)),
          s * 0.035,
          paint,
        );
      }
    }
  }
}

class _HeroCopy extends StatelessWidget {
  final bool isDark;

  const _HeroCopy({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: EdgeInsets.only(
            left: w * 0.05,
            right: w * 0.50,
            bottom: w * 0.02,
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'مرحبا بك في',
                  style: TextStyle(
                    color: isDark
                        ? AppColors.textMainDark
                        : AppColors.primaryDark,
                    fontSize: (w * 0.03).clamp(11.0, 14.0),
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
                SizedBox(height: w * 0.012),
                ValueListenableBuilder<SelectedTeacher?>(
                  valueListenable:
                      TeacherContextService.instance.selectedTeacher,
                  builder: (context, teacher, _) {
                    final name = teacher?.name ?? 'نسق';
                    return Text(
                      name,
                      style: TextStyle(
                        color: isDark
                            ? AppColors.primaryOnDark
                            : AppColors.primaryDark,
                        fontSize: (w * 0.078).clamp(27.0, 39.0),
                        fontWeight: FontWeight.w900,
                        height: 1.08,
                      ),
                    );
                  },
                ),
                SizedBox(height: w * 0.018),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: w * 0.022,
                    vertical: w * 0.008,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.primary : AppColors.primaryDark,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    'كيمياء بشكل مختلف',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: (w * 0.021).clamp(8.5, 11.0),
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                    ),
                  ),
                ),
                SizedBox(height: w * 0.014),
                Text(
                  'تجارب، شرح، وتدريب لحد الامتحان',
                  style: TextStyle(
                    color: isDark
                        ? AppColors.textMutedDark
                        : AppColors.primaryDark,
                    fontSize: (w * 0.019).clamp(8.0, 10.0),
                    fontWeight: FontWeight.w700,
                    height: 1.3,
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
