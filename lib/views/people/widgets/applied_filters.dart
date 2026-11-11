import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/constants/radius_containers.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/widgets/app_icons.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/button/bouncy_button.dart';

/// 9.3a / 9.1b · What a People list is narrowed by, each filter with a × to
/// take it off, and how many people that leaves (`countText`, e.g. "12 of
/// 40"). Shared by the Students and Staff sides.
class AppliedFilters extends StatelessWidget {
  const AppliedFilters({
    super.key,
    required this.labels,
    required this.onRemove,
    required this.countText,
  });

  final List<String> labels;

  /// Called with the index of the label whose × was tapped.
  final ValueChanged<int> onRemove;
  final String countText;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.screen,
      AppSpacing.none,
      AppSpacing.screen,
      AppSpacing.md,
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final (index, label) in labels.indexed)
                _AppliedChip(label: label, onRemove: () => onRemove(index)),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        // Lines up with the chips' 32px height.
        SizedBox(
          height: 32,
          child: Center(
            child: AppText(
              countText,
              style: AppTypography.body.copyWith(
                fontSize: 13,
                height: 18 / 13,
                fontWeight: FontWeight.w600,
                color: LightColors.textMuted,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

/// A removable applied filter: 32 tall, tinted, with a small ×.
class _AppliedChip extends StatelessWidget {
  const _AppliedChip({required this.label, required this.onRemove});

  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Remove $label filter',
    excludeSemantics: true,
    child: BouncyButton(
      onPressed: onRemove,
      child: Container(
        height: 32,
        padding: const EdgeInsets.only(left: 12, right: 10),
        decoration: BoxDecoration(
          color: LightColors.primaryPrimaryMute,
          borderRadius: AppRadius.brPill,
          border: Border.all(color: LightColors.primaryPrimaryDefault),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppText(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.body.copyWith(
                fontSize: 13,
                height: 18 / 13,
                fontWeight: FontWeight.w600,
                color: LightColors.primaryPrimaryText,
              ),
            ),
            const SizedBox(width: 6),
            const AppIcon(
              AppIcons.x,
              size: 12,
              color: LightColors.primaryPrimaryDefault,
            ),
          ],
        ),
      ),
    ),
  );
}

