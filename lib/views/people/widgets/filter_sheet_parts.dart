import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/students/student_filter.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/widgets/app_badge.dart';
import 'package:hamrash_admin/core/widgets/app_icons.dart';
import 'package:hamrash_admin/core/widgets/app_segmented_control.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/button/bouncy_button.dart';
import 'package:hamrash_admin/views/team/widgets/choice_list_sheet.dart';

/// "Reset": aubergine while there is something to reset, stone-400 when not.
class FilterResetAction extends StatelessWidget {
  const FilterResetAction({
    super.key,
    required this.enabled,
    required this.onPressed,
  });

  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: enabled,
    label: 'Reset',
    excludeSemantics: true,
    child: BouncyButton(
      isDisabled: !enabled,
      onPressed: enabled ? onPressed : null,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        alignment: Alignment.center,
        child: AppText(
          'Reset',
          style: AppTypography.subtitle.copyWith(
            color: enabled
                ? LightColors.primaryPrimaryText
                : LightColors.textDisabled,
          ),
        ),
      ),
    ),
  );
}

/// A bold label over its control. The chips bring 4 above and below, so the
/// gaps here are 4 short of the 12 under a label and 24 between sections.
class FilterSection extends StatelessWidget {
  const FilterSection({
    super.key,
    required this.title,
    required this.child,
    this.gapAfter = AppSpacing.ml,
  });

  final String title;
  final Widget child;
  final double gapAfter;

  @override
  Widget build(BuildContext context) {
    final chips = child is! AppSegmentedControl && child is! FilterPickRows;
    return Padding(
      padding: EdgeInsets.only(bottom: gapAfter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppText(
            title,
            style: AppTypography.subtitle.copyWith(
              color: LightColors.textStrong,
            ),
          ),
          SizedBox(height: chips ? AppSpacing.sm : AppSpacing.ms),
          child,
        ],
      ),
    );
  }
}

/// A wrapping group of [AppFilterChip]s, 8 apart.
class FilterChips<T> extends StatelessWidget {
  const FilterChips({
    super.key,
    required this.values,
    required this.labelOf,
    required this.isSelected,
    required this.onTap,
  });

  final List<T> values;
  final String Function(T value) labelOf;
  final bool Function(T value) isSelected;
  final ValueChanged<T> onTap;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: AppSpacing.sm,
    children: [
      for (final value in values)
        AppFilterChip(
          label: labelOf(value),
          selected: isSelected(value),
          onTap: () => onTap(value),
        ),
    ],
  );
}

/// One option row: a label on the left, the picked value (or "Any …") on the
/// right and a chevron. Picked is aubergine on a tint; unpicked is stone.
/// Opens a [ChoiceListSheet] and reports the pick, or null for "Any …".
class FilterPickRow extends StatelessWidget {
  const FilterPickRow({
    super.key,
    required this.label,
    required this.anyLabel,
    required this.sheetTitle,
    required this.searchHint,
    required this.options,
    required this.value,
    required this.onChanged,
    this.sheetSubtitle,
  });

  final String label;

  /// "Any subject".
  final String anyLabel;
  final String sheetTitle;
  final String? sheetSubtitle;
  final String searchHint;
  final List<FilterPick> options;
  final FilterPick? value;

  /// Null when "Any …" was chosen.
  final ValueChanged<FilterPick?> onChanged;

  /// Stands for "Any …" in the list, since a sheet can't return null for a
  /// choice and for a dismissal alike.
  static const _any = FilterPick('', '');

  Future<void> _open(BuildContext context) async {
    final any = FilterPick(_any.id, anyLabel);
    final chosen = await ChoiceListSheet.show<FilterPick>(
      context: context,
      title: sheetTitle,
      subtitle: sheetSubtitle,
      searchHint: searchHint,
      items: [any, ...options],
      labelBuilder: (pick) => pick.label,
      selected: value ?? any,
    );
    if (chosen == null) return;
    onChanged(chosen.id.isEmpty ? null : chosen);
  }

  @override
  Widget build(BuildContext context) {
    final picked = value != null;
    return Semantics(
      button: true,
      label: '$label, ${picked ? value!.label : anyLabel}',
      excludeSemantics: true,
      child: BouncyButton(
        onPressed: () => _open(context),
        pressedScale: 0.98,
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: picked ? LightColors.primaryPrimaryMute : AppPalette.stone50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: picked
                  ? LightColors.primaryPrimaryDefault
                  : AppPalette.stone200,
            ),
          ),
          child: Row(
            children: [
              AppText(
                label,
                style: AppTypography.body.copyWith(
                  fontWeight: FontWeight.w600,
                  color: LightColors.textBody,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AppText(
                  picked ? value!.label : anyLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: AppTypography.body.copyWith(
                    fontSize: 15,
                    fontWeight: picked ? FontWeight.w700 : FontWeight.w600,
                    color: picked
                        ? LightColors.primaryPrimaryText
                        : LightColors.textMuted,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              AppIcon(
                AppIcons.chevronDown,
                size: 18,
                color: picked
                    ? LightColors.primaryPrimaryDefault
                    : AppPalette.stone400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The rows of a picker section, 12 apart, and an optional quiet line under
/// them.
class FilterPickRows extends StatelessWidget {
  const FilterPickRows({super.key, required this.rows, this.hint});

  final List<Widget> rows;
  final String? hint;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final (index, row) in rows.indexed) ...[
        if (index > 0) const SizedBox(height: AppSpacing.ms),
        row,
      ],
      if (hint != null) ...[
        const SizedBox(height: AppSpacing.sm),
        AppText(
          hint!,
          style: AppTypography.caption.copyWith(
            fontWeight: FontWeight.w600,
            color: LightColors.textMuted,
          ),
        ),
      ],
    ],
  );
}
