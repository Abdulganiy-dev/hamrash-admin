import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/grading/grade_systems.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/widgets/app_badge.dart';
import 'package:hamrash_admin/core/widgets/app_icons.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/button/bouncy_button.dart';
import 'package:hamrash_admin/views/grading/widgets/grading_bars.dart';

/// 9.32 · One choice card for a grade system: what it is, a small preview of
/// its bands, and the note that every value stays editable.
class GradeSystemChoiceCard extends StatelessWidget {
  const GradeSystemChoiceCard({
    super.key,
    required this.system,
    required this.selected,
    required this.onTap,
    this.enabled = true,
  });

  final GradeSystem system;
  final bool selected;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    button: true,
    child: BouncyButton(
      pressedScale: 0.98,
      isDisabled: !enabled,
      onPressed: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppPalette.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? LightColors.primaryPrimaryDefault
                : LightColors.strokeColourStrokeCard,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: AppRadioChoice(selected: selected),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: AppText(
                              system.title,
                              style: AppTypography.subtitle.copyWith(
                                fontSize: 16,
                                color: LightColors.textStrong,
                              ),
                            ),
                          ),
                          if (system.badge case final badge?) ...[
                            const SizedBox(width: 8),
                            AppBadge(badge, tone: AppBadgeTone.info),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      AppText(
                        system.blurb,
                        style: AppTypography.body.copyWith(
                          fontSize: 13,
                          height: 18 / 13,
                          color: LightColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppPalette.stone50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _PreviewBar(system: system),
                  const SizedBox(height: 10),
                  for (final row in _rows(system))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 72,
                            child: AppText(
                              row.$1,
                              style: AppTypography.body.copyWith(
                                fontSize: 13,
                                height: 18 / 13,
                                fontWeight: FontWeight.w700,
                                color: row.$3
                                    ? LightColors.errorErrorText
                                    : LightColors.textStrong,
                              ),
                            ),
                          ),
                          Expanded(
                            child: AppText(
                              row.$2,
                              style: AppTypography.body.copyWith(
                                fontSize: 13,
                                height: 18 / 13,
                                color: LightColors.textBody,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: AppIcon(
                    AppIcons.pencil,
                    size: 14,
                    color: LightColors.textMuted,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: AppText(
                    system.footnote,
                    style: AppTypography.caption.copyWith(
                      color: LightColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  static List<(String, String, bool)> _rows(GradeSystem system) =>
      system == GradeSystem.waec
      ? const [
          ('A1', '75 to 100 · Excellent', false),
          ('B2 · B3', '70 to 74 · 65 to 69 · Very Good, Good', false),
          ('C4 to C6', '50 to 64, in 5s · Credit', false),
          ('D7 · E8', '45 to 49 · 40 to 44 · Pass', false),
          ('F9', '0 to 39 · Fail', true),
        ]
      : const [
          ('A', '70 to 100 · Excellent', false),
          ('B · C', '60 to 69 · 50 to 59 · Very Good, Good', false),
          ('D · E', '45 to 49 · 40 to 44 · Fair, Pass', false),
          ('F', '0 to 39 · Fail', true),
        ];
}

/// The selected radio, drawn here so the whole card can take the tap.
class AppRadioChoice extends StatelessWidget {
  const AppRadioChoice({super.key, required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) => Container(
    width: 22,
    height: 22,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: selected ? LightColors.primaryPrimaryDefault : AppPalette.white,
      border: Border.all(
        color: selected
            ? LightColors.primaryPrimaryDefault
            : AppPalette.stone300,
        width: 1.5,
      ),
    ),
    child: selected
        ? Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppPalette.white,
              shape: BoxShape.circle,
            ),
          )
        : null,
  );
}

class _PreviewBar extends StatelessWidget {
  const _PreviewBar({required this.system});

  final GradeSystem system;

  @override
  Widget build(BuildContext context) {
    final ascending = [...system.boundaries]
      ..sort((a, b) => a.minPercent.compareTo(b.minPercent));
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 10,
        child: Row(
          children: [
            for (final (i, grade) in ascending.indexed)
              Expanded(
                flex: grade.maxPercent - grade.minPercent + 1,
                child: ColoredBox(
                  color: gradeBandStyle(grade, i).fill,
                  child: const SizedBox.expand(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
