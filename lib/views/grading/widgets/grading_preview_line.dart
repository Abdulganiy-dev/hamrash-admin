import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/grading/grading_setup.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/widgets/app_icons.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';

TextStyle _label() => AppTypography.body.copyWith(
  fontSize: 13,
  height: 18 / 13,
  color: LightColors.textMuted,
);

TextStyle _value({bool muted = false}) => muted
    ? AppTypography.body.copyWith(color: LightColors.textMuted)
    : AppTypography.subtitle.copyWith(color: LightColors.textStrong);

BoxDecoration _box() => BoxDecoration(
  color: AppPalette.stone50,
  borderRadius: BorderRadius.circular(12),
);

/// 9.3, 9.4 · The quiet line in a column sheet that shows what saving will
/// do: "Total becomes 120 marks, from 100 now", "Total stays 100 marks".
/// [muted] is for the prompt before there is anything to show.
class GradingPreviewLine extends StatelessWidget {
  const GradingPreviewLine({
    super.key,
    required this.label,
    required this.value,
    this.muted = false,
  });

  final String label;
  final String value;
  final bool muted;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: _box(),
    child: Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      children: [
        AppText(label, style: _label()),
        AppText(value, style: _value(muted: muted)),
      ],
    ),
  );
}

/// 9.5, 9.6a · What saving a grade changes, one line each: "New grade 65 to
/// 69", "B becomes 60 to 64, from 60 to 69".
class GradingChangesBlock extends StatelessWidget {
  const GradingChangesBlock({super.key, required this.changes});

  final List<GradeChange> changes;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: _box(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (i, change) in changes.indexed) ...[
          if (i > 0) const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 84),
                child: AppText(change.label, style: _label()),
              ),
              const SizedBox(width: 8),
              Expanded(child: AppText(change.value, style: _value())),
            ],
          ),
        ],
      ],
    ),
  );
}

/// A warning-tone line under a sheet's preview, e.g. "A will now be below B.
/// Grades usually go down from A.".
class GradingWarningLine extends StatelessWidget {
  const GradingWarningLine({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Padding(
        padding: EdgeInsets.only(top: 1),
        child: AppIcon(
          AppIcons.triangleAlert,
          size: 14,
          color: LightColors.warningWarningDefault,
        ),
      ),
      const SizedBox(width: 6),
      Expanded(
        child: AppText(
          message,
          style: AppTypography.caption.copyWith(
            fontWeight: FontWeight.w600,
            color: LightColors.warningWarningText,
          ),
        ),
      ),
    ],
  );
}
