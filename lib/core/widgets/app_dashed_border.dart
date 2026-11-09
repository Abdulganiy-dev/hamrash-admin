import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';

/// A 1.5px dashed stone-300 outline around [child]: the "add another"
/// surfaces (Join another school, Add another parent) and empty slots.
class AppDashedBorder extends StatelessWidget {
  const AppDashedBorder({
    super.key,
    required this.child,
    required this.radius,
    this.color = AppPalette.stone300,
    this.fill,
  });

  final Widget child;
  final double radius;
  final Color color;

  /// Optional fill inside the outline, e.g. white for an empty-state card.
  final Color? fill;

  @override
  Widget build(BuildContext context) {
    final painted = CustomPaint(
      painter: _DashedBorderPainter(color: color, radius: radius),
      child: child,
    );
    if (fill == null) return painted;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: painted,
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  static const _dash = 6.0;
  static const _gap = 4.0;
  static const _width = 1.5;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(_width / 2);
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _width;
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += _dash + _gap) {
        canvas.drawPath(metric.extractPath(d, d + _dash), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) =>
      old.color != color || old.radius != radius;
}
