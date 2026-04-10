import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

/// Hugeicons stroke glyph fitted to an outer square (crisp scaling for small sizes).
class AppButtonHugeIcon extends StatelessWidget {
  const AppButtonHugeIcon({
    super.key,
    required this.icon,
    required this.color,
    required this.outerSize,
    this.rasterSize = 24,
    this.strokeWidth,
  });

  final List<List<dynamic>> icon;
  final Color color;
  final double outerSize;
  final double rasterSize;
  final double? strokeWidth;

  @override
  Widget build(BuildContext context) {
    final huge = HugeIcon(
      icon: icon,
      size: rasterSize,
      color: color,
      strokeWidth: strokeWidth,
    );
    if ((outerSize - rasterSize).abs() < 0.001) {
      return huge;
    }
    return huge;
  }
}
