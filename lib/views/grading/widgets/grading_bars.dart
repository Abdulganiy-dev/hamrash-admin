import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/grading/grade_boundary.dart';
import 'package:hamrash_admin/api/models/grading/score_column.dart';
import 'package:hamrash_admin/api/models/grading/section_grading.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';

/// The colour pair for one score column's segment. Reused by the bars and
/// the review screen's dots, so a column always has the same colour.
({Color fill, Color text}) columnSegmentStyle(int index) => switch (index % 8) {
  0 => (fill: LightColors.categoryTealMute, text: LightColors.categoryTealText),
  1 => (
    fill: LightColors.categoryTeal.withValues(alpha: 0.45),
    text: LightColors.categoryTealText,
  ),
  2 => (fill: LightColors.categoryTeal, text: AppPalette.white),
  3 => (
    fill: LightColors.categoryHoneyMute,
    text: LightColors.categoryHoneyText,
  ),
  4 => (fill: LightColors.categoryHoney, text: LightColors.categoryHoneyText),
  5 => (
    fill: LightColors.primaryPrimaryMute,
    text: LightColors.primaryPrimaryText,
  ),
  6 => (
    fill: LightColors.categoryChartreuseMute,
    text: LightColors.categoryChartreuseText,
  ),
  _ => (
    fill: LightColors.categoryChartreuse,
    text: LightColors.categoryChartreuseText,
  ),
};

/// The colour pair for a grade band, counted from the bottom of the scale.
({Color fill, Color text}) gradeBandStyle(
  GradeBoundary grade,
  int indexFromBottom,
) {
  if (!grade.isPass) {
    return (fill: LightColors.errorErrorMute, text: LightColors.errorErrorText);
  }
  return switch (indexFromBottom % 5) {
    0 => (fill: AppPalette.aubergine100, text: AppPalette.aubergine500),
    1 => (fill: AppPalette.aubergine200, text: AppPalette.aubergine500),
    2 => (fill: AppPalette.aubergine300, text: AppPalette.aubergine700),
    3 => (fill: AppPalette.aubergine400, text: AppPalette.white),
    _ => (fill: AppPalette.aubergine500, text: AppPalette.white),
  };
}

/// The bar on the score columns screens: one segment per column, sized by its
/// marks, with the column name and its share of the total underneath.
class ColumnContributionBar extends StatelessWidget {
  const ColumnContributionBar({
    super.key,
    required this.columns,
    required this.totalMarks,
    this.height = 32,
    this.showShares = true,
  });

  final List<ScoreColumn> columns;
  final double totalMarks;
  final double height;
  final bool showShares;

  List<int> get _weights => [
    for (final column in columns) _weight(column.maxScore),
  ];

  @override
  Widget build(BuildContext context) {
    if (columns.isEmpty || totalMarks <= 0) {
      return Container(
        height: height,
        decoration: BoxDecoration(
          color: AppPalette.stone100,
          borderRadius: BorderRadius.circular(10),
        ),
      );
    }
    final weights = _weights;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            height: height,
            child: Row(
              children: [
                for (final (i, column) in columns.indexed)
                  Expanded(
                    flex: weights[i],
                    child: _ColumnSegment(
                      column: column,
                      style: columnSegmentStyle(i),
                      height: height,
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (showShares) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              for (final (i, column) in columns.indexed)
                Expanded(
                  flex: weights[i],
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: AppText(
                      '${(column.maxScore / totalMarks * 100).round()}%',
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                      style: AppTypography.body.copyWith(
                        fontSize: 12,
                        height: 16 / 12,
                        fontWeight: FontWeight.w600,
                        color: LightColors.textMuted,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  static int _weight(double value) => (value * 100).round().clamp(1, 1 << 30);
}

class _ColumnSegment extends StatelessWidget {
  const _ColumnSegment({
    required this.column,
    required this.style,
    required this.height,
  });

  final ScoreColumn column;
  final ({Color fill, Color text}) style;
  final double height;

  @override
  Widget build(BuildContext context) => Container(
    height: height,
    color: style.fill,
    child: LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 30) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Align(
            alignment: Alignment.centerLeft,
            child: AppText(
              column.name,
              maxLines: 1,
              overflow: TextOverflow.clip,
              style: AppTypography.body.copyWith(
                fontSize: 12,
                height: 16 / 12,
                fontWeight: FontWeight.w800,
                color: style.text,
              ),
            ),
          ),
        );
      },
    ),
  );
}

/// The grade scale drawn as a 0 to 100 bar: a warning-hatched stretch when a
/// legacy scale leaves a gap, then one labelled band per grade.
class GradeRangeBar extends StatelessWidget {
  const GradeRangeBar({super.key, required this.grading, this.height = 36});

  final SectionGrading grading;
  final double height;

  @override
  Widget build(BuildContext context) {
    final ascending = [...grading.grades]
      ..sort((a, b) => a.minPercent.compareTo(b.minPercent));
    final gap = grading.uncoveredRange;
    final gapRange = gap == null ? null : _range(gap);
    final bands = <({int start, int end, int index, GradeBoundary? grade})>[
      for (final (i, grade) in ascending.indexed)
        (
          start: grade.minPercent,
          end: grade.maxPercent,
          index: i,
          grade: grade,
        ),
      if (gapRange != null)
        (start: gapRange.$1, end: gapRange.$2, index: -1, grade: null),
    ]..sort((a, b) => a.start.compareTo(b.start));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            height: height,
            child: Row(
              children: [
                for (final band in bands)
                  Expanded(
                    flex: band.end - band.start + 1,
                    child: band.grade == null
                        ? _NoGradeBand(height: height)
                        : _GradeBand(
                            grade: band.grade!,
                            style: gradeBandStyle(band.grade!, band.index),
                            height: height,
                          ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        const _Axis(),
      ],
    );
  }

  static (int, int)? _range(String gap) {
    final parts = gap.split(' to ');
    final start = int.tryParse(parts.first);
    if (start == null) return null;
    final end = parts.length > 1 ? int.tryParse(parts.last) ?? start : start;
    return (start, end);
  }
}

class _GradeBand extends StatelessWidget {
  const _GradeBand({
    required this.grade,
    required this.style,
    required this.height,
  });

  final GradeBoundary grade;
  final ({Color fill, Color text}) style;
  final double height;

  @override
  Widget build(BuildContext context) => Container(
    height: height,
    color: style.fill,
    child: LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 20) return const SizedBox.shrink();
        return Center(
          child: AppText(
            grade.grade,
            maxLines: 1,
            overflow: TextOverflow.clip,
            style: AppTypography.body.copyWith(
              fontSize: 13,
              height: 16 / 13,
              fontWeight: FontWeight.w800,
              color: style.text,
            ),
          ),
        );
      },
    ),
  );
}

class _NoGradeBand extends StatelessWidget {
  const _NoGradeBand({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) => Container(
    height: height,
    color: LightColors.warningWarningMute,
    child: CustomPaint(
      painter: _HatchPainter(color: LightColors.warningWarningThin, spacing: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 54) return const SizedBox.shrink();
          return Center(
            child: AppText(
              'No grade',
              maxLines: 1,
              overflow: TextOverflow.clip,
              style: AppTypography.body.copyWith(
                fontSize: 12,
                height: 16 / 12,
                fontWeight: FontWeight.w800,
                color: LightColors.warningWarningText,
              ),
            ),
          );
        },
      ),
    ),
  );
}

class _HatchPainter extends CustomPainter {
  const _HatchPainter({required this.color, required this.spacing});

  final Color color;
  final double spacing;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    for (var x = -size.height; x < size.width + size.height; x += spacing) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_HatchPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.spacing != spacing;
}

class _Axis extends StatelessWidget {
  const _Axis();

  @override
  Widget build(BuildContext context) {
    final style = AppTypography.body.copyWith(
      fontSize: 12,
      height: 16 / 12,
      fontWeight: FontWeight.w600,
      color: LightColors.textMuted,
    );
    return Row(
      children: [
        Expanded(flex: 40, child: AppText('0', style: style)),
        Expanded(flex: 10, child: AppText('40', style: style)),
        Expanded(flex: 10, child: AppText('50', style: style)),
        Expanded(flex: 10, child: AppText('60', style: style)),
        Expanded(
          flex: 30,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText('70', style: style),
              AppText('100', style: style),
            ],
          ),
        ),
      ],
    );
  }
}
