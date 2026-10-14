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

/// A big choice card with the radio on the left, like [AppChoiceCard] but
/// with room for a badge and details under the text. For "how do you want
/// to start?" pages.
///
/// ```dart
/// AppOptionCard(
///   title: 'Standard structure',
///   badge: 'Recommended',
///   subtitle: '15 classes in 3 sections.',
///   value: Start.standard,
///   groupValue: start,
///   onChanged: pick,
///   details: AppOptionSummary(rows: [('Nursery', 'Nursery 1 – 3')]),
/// )
/// ```
class AppOptionCard<T> extends StatelessWidget {
  const AppOptionCard({
    super.key,
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
  final T value;
  final T groupValue;
  final ValueChanged<T> onChanged;

  /// Shown under the text, e.g. an [AppOptionSummary].
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
                    AppRadio<T>(value: value, groupValue: groupValue),
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

/// What an [AppOptionCard] gives you: label and value rows on a stone panel,
/// then an optional note with an icon.
class AppOptionSummary extends StatelessWidget {
  const AppOptionSummary({
    super.key,
    required this.rows,
    this.note,
    this.noteIcon,
  });

  final List<(String, String)> rows;
  final String? note;
  final IconData? noteIcon;

  @override
  Widget build(BuildContext context) => Column(
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
            for (final (i, (label, value)) in rows.indexed)
              Container(
                height: 40,
                decoration: BoxDecoration(
                  border: i < rows.length - 1
                      ? const Border(
                          bottom: BorderSide(color: AppPalette.stone100),
                        )
                      : null,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: AppText(
                        label,
                        style: AppTypography.subtitle.copyWith(
                          color: LightColors.textStrong,
                        ),
                      ),
                    ),
                    AppText(
                      value,
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
      if (note case final text?) ...[
        const SizedBox(height: 12),
        Row(
          children: [
            if (noteIcon case final icon?) ...[
              Icon(icon, size: 14, color: LightColors.textMuted),
              const SizedBox(width: 6),
            ],
            Expanded(
              child: AppText(
                text,
                style: AppTypography.caption.copyWith(
                  color: LightColors.textMuted,
                ),
              ),
            ),
          ],
        ),
      ],
    ],
  );
}

/// The heading over a page of [AppOptionCard]s.
class AppOptionsIntro extends StatelessWidget {
  const AppOptionsIntro({super.key, required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          title,
          style: AppTypography.h3.copyWith(color: LightColors.textStrong),
        ),
        const SizedBox(height: 6),
        AppText(
          body,
          style: AppTypography.body.copyWith(color: LightColors.textBody),
        ),
      ],
    ),
  );
}
