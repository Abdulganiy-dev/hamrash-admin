import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';

/// The app's one loading spinner: a faint ring with a running arc on top.
///
/// Leave [value] null to spin. Give it 0–1 to draw that much of the ring
/// instead, e.g. while a list is being pulled to refresh.
///
/// ```dart
/// const AppSpinner()                          // 20px, aubergine
/// AppSpinner(size: 24, color: Colors.white)
/// AppSpinner(value: pullProgress)             // partly drawn, still
/// ```
class AppSpinner extends StatefulWidget {
  const AppSpinner({
    super.key,
    this.size = 20,
    this.strokeWidth,
    this.color = LightColors.primaryPrimaryDefault,
    this.value,
  });

  final double size;

  /// Defaults to about an eighth of [size] (2.5 at 20px).
  final double? strokeWidth;

  /// The arc. The ring under it is the same colour at 25%.
  final Color color;

  /// How much of the ring to draw, 0–1. Null spins.
  final double? value;

  @override
  State<AppSpinner> createState() => _AppSpinnerState();
}

class _AppSpinnerState extends State<AppSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _turns = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(AppSpinner oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  /// Only tick while spinning.
  void _sync() {
    if (widget.value == null) {
      if (!_turns.isAnimating) _turns.repeat();
    } else {
      _turns.stop();
    }
  }

  @override
  void dispose() {
    _turns.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stroke = widget.strokeWidth ?? (widget.size / 8).clamp(2.0, 3.0);
    return Semantics(
      label: 'Loading',
      child: SizedBox.square(
        dimension: widget.size,
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _turns,
            builder: (context, _) => CustomPaint(
              painter: _SpinnerPainter(
                color: widget.color,
                stroke: stroke,
                value: widget.value,
                turn: _turns.value,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SpinnerPainter extends CustomPainter {
  _SpinnerPainter({
    required this.color,
    required this.stroke,
    required this.value,
    required this.turn,
  });

  final Color color;
  final double stroke;
  final double? value;
  final double turn;

  /// Length of the running arc, a little over a quarter turn.
  static const _arc = 0.28 * 2 * math.pi;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(stroke / 2);
    final track = Paint()
      ..color = color.withValues(alpha: color.a * 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    final arc = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawOval(rect, track);
    final v = value;
    if (v == null) {
      canvas.drawArc(rect, -math.pi / 2 + turn * 2 * math.pi, _arc, false, arc);
    } else if (v >= 1) {
      canvas.drawOval(rect, arc..strokeCap = StrokeCap.butt);
    } else if (v > 0) {
      canvas.drawArc(rect, -math.pi / 2, v * 2 * math.pi, false, arc);
    }
  }

  @override
  bool shouldRepaint(_SpinnerPainter old) =>
      old.turn != turn ||
      old.value != value ||
      old.color != color ||
      old.stroke != stroke;
}
