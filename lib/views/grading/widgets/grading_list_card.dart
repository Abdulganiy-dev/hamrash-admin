import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/widgets/app_cards.dart';
import 'package:hamrash_admin/core/widgets/app_dashed_border.dart';
import 'package:hamrash_admin/core/widgets/app_divider.dart';
import 'package:hamrash_admin/core/widgets/app_icons.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/button/bouncy_button.dart';

/// What colours a row's tile.
enum GradingTileTone {
  /// A score column's position.
  column,

  /// A grade that counts as a pass.
  pass,

  /// A grade that doesn't.
  fail,

  /// A range no grade covers yet: dashed, with a warning tint.
  missing,
}

/// One row of a [GradingListCard]: a tile with a letter or number, a title
/// and a line under it. [onTap] null means no chevron and no tap.
class GradingRow {
  const GradingRow({
    required this.tile,
    required this.tone,
    required this.title,
    required this.details,
    this.onTap,
  });

  /// "1", "A", "F"…
  final String tile;
  final GradingTileTone tone;

  /// "CA 1", "70 to 100".
  final String title;

  /// "Out of 20", "Excellent · Pass".
  final String details;
  final VoidCallback? onTap;
}

/// 8.2 · White card with the score columns or the grade scale, one row each.
class GradingListCard extends StatelessWidget {
  const GradingListCard({super.key, required this.rows});

  final List<GradingRow> rows;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Column(
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          _Row(row: rows[i]),
          if (i < rows.length - 1) const AppDivider(),
        ],
      ],
    ),
  );
}

class _Row extends StatelessWidget {
  const _Row({required this.row});

  final GradingRow row;

  bool get _missing => row.tone == GradingTileTone.missing;

  (Color fill, Color text) get _colors => switch (row.tone) {
    GradingTileTone.column => (
      LightColors.categoryTealMute,
      LightColors.categoryTealText,
    ),
    GradingTileTone.pass => (
      LightColors.primaryPrimaryMute,
      LightColors.primaryPrimaryText,
    ),
    GradingTileTone.fail => (
      LightColors.errorErrorMute,
      LightColors.errorErrorText,
    ),
    GradingTileTone.missing => (
      LightColors.warningWarningMute,
      LightColors.warningWarningText,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final (fill, text) = _colors;
    final tile = Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: _missing
          ? null
          : BoxDecoration(color: fill, borderRadius: BorderRadius.circular(10)),
      child: AppText(
        row.tile,
        maxLines: 1,
        overflow: TextOverflow.clip,
        style: AppTypography.heading(16, lineHeight: 20).copyWith(color: text),
      ),
    );
    final content = SizedBox(
      height: 60,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            if (_missing)
              AppDashedBorder(
                radius: 10,
                fill: fill,
                color: LightColors.warningWarningThin,
                child: tile,
              )
            else
              tile,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppText(
                    row.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.subtitle.copyWith(
                      fontSize: 15,
                      color: _missing ? text : LightColors.textStrong,
                    ),
                  ),
                  const SizedBox(height: 2),
                  AppText(
                    row.details,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body.copyWith(
                      fontSize: 13,
                      height: 18 / 13,
                      color: _missing ? text : LightColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (row.onTap != null) ...[
              const SizedBox(width: 12),
              const AppIcon(
                AppIcons.chevronRight,
                size: 18,
                color: AppPalette.stone400,
              ),
            ],
          ],
        ),
      ),
    );
    if (row.onTap == null) return content;
    return BouncyButton(
      pressedScale: 0.98,
      onPressed: row.onTap,
      child: content,
    );
  }
}
