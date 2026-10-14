import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/constants/radius_containers.dart';
import 'package:hamrash_admin/core/haptic_helper.dart';
import 'package:hamrash_admin/core/widgets/app_badge.dart';
import 'package:hamrash_admin/core/widgets/app_cards.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/button/bouncy_button.dart';
import 'package:hamrash_admin/core/widgets/selection/app_selection_controls.dart';
import 'package:hamrash_admin/views/classes/classes_view_model.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// 6.1 · A school with no classes picks how to start: the usual Nigerian
/// structure, or its own sections from scratch.
class StructureStartPicker extends StatelessWidget {
  const StructureStartPicker({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final StructureStart value;
  final ValueChanged<StructureStart> onChanged;

  static const _standard = [
    ('Nursery', 'Nursery 1 – 3'),
    ('Primary', 'Primary 1 – 6'),
    ('Secondary', 'JSS 1 – SS 3'),
  ];

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText(
              'How do you want to start?',
              style: AppTypography.h3.copyWith(color: LightColors.textStrong),
            ),
            const SizedBox(height: 6),
            AppText(
              'You can rename, reorder or switch off anything later.',
              style: AppTypography.body.copyWith(color: LightColors.textBody),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      _Option(
        title: 'Standard structure',
        badge: 'Recommended',
        subtitle: '15 classes in 3 sections. You add the arms next.',
        value: StructureStart.standard,
        groupValue: value,
        onChanged: onChanged,
        details: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppPalette.stone50,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  for (final (i, (section, classes)) in _standard.indexed)
                    Container(
                      height: 40,
                      decoration: BoxDecoration(
                        border: i < _standard.length - 1
                            ? const Border(
                                bottom: BorderSide(color: AppPalette.stone100),
                              )
                            : null,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: AppText(
                              section,
                              style: AppTypography.subtitle.copyWith(
                                color: LightColors.textStrong,
                              ),
                            ),
                          ),
                          AppText(
                            classes,
                            style: AppTypography.body.copyWith(
                              color: LightColors.textBody,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  LucideIcons.graduationCap,
                  size: 14,
                  color: LightColors.textMuted,
                ),
                const SizedBox(width: 6),
                AppText(
                  'Students graduate after SS 3',
                  style: AppTypography.caption.copyWith(
                    color: LightColors.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      _Option(
        title: 'Start from scratch',
        subtitle:
            'Add your own sections and classes, e.g. a primary-only school.',
        value: StructureStart.scratch,
        groupValue: value,
        onChanged: onChanged,
      ),
    ],
  );
}

/// A choice card with the radio on the left, like [AppChoiceCard] but with
/// room for a badge and details under the text.
class _Option extends StatelessWidget {
  const _Option({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    this.badge,
    this.details,
  });

  final String title;
  final String subtitle;
  final String? badge;
  final StructureStart value;
  final StructureStart groupValue;
  final ValueChanged<StructureStart> onChanged;
  final Widget? details;

  @override
  Widget build(BuildContext context) {
    final picked = value == groupValue;
    return MergeSemantics(
      child: Semantics(
        selected: picked,
        child: BouncyButton(
          pressedScale: 0.98,
          enableHaptic: false,
          onPressed: picked
              ? null
              : () {
                  HapticHelpers.vibrate(VibrationType.selection);
                  onChanged(value);
                },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            // Keep the content still while the border thickens.
            padding: EdgeInsets.all(picked ? 16 : 16.5),
            decoration: BoxDecoration(
              gradient: AppShadows.cardFill,
              borderRadius: AppRadius.brCard,
              border: Border.all(
                color: picked
                    ? LightColors.primaryPrimaryDefault
                    : LightColors.strokeColourStrokeCard,
                width: picked ? 1.5 : 1,
              ),
              boxShadow: AppShadows.floating,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppRadio<StructureStart>(
                      value: value,
                      groupValue: groupValue,
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
                                  title,
                                  style: AppTypography.title.copyWith(
                                    color: LightColors.textStrong,
                                  ),
                                ),
                              ),
                              if (badge case final label?)
                                AppBadge(label, tone: AppBadgeTone.info),
                            ],
                          ),
                          const SizedBox(height: 2),
                          AppText(
                            subtitle,
                            style: AppTypography.body.copyWith(
                              color: LightColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                ?details,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
