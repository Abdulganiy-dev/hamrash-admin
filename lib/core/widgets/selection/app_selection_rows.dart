import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/haptic_helper.dart';
import 'package:hamrash_admin/core/widgets/app_cards.dart';
import 'package:hamrash_admin/core/widgets/app_surface.dart';
import 'package:hamrash_admin/core/widgets/button/bouncy_button.dart';
import 'package:hamrash_admin/core/widgets/selection/app_selection_controls.dart';

/// One card holding several rows with hairlines between them. Use it for
/// switch, checkbox and radio rows.
///
/// ```dart
/// AppRowGroup(children: [
///   AppSwitchRow(title: 'Absence alerts', value: a, onChanged: setA),
///   AppSwitchRow(title: 'Fee reminders', value: b, onChanged: setB),
/// ])
/// ```
class AppRowGroup extends StatelessWidget {
  /// Floating white card, for rows on the page.
  const AppRowGroup({super.key, required this.children}) : _inset = false;

  /// Flat slate-50 block, for rows inside a white sheet or card.
  const AppRowGroup.inset({super.key, required this.children}) : _inset = true;

  final List<Widget> children;
  final bool _inset;

  @override
  Widget build(BuildContext context) {
    final rows = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0)
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              color: _inset ? AppPalette.slate200 : AppPalette.slate100,
            ),
          children[i],
        ],
      ],
    );

    if (!_inset) {
      return AppCard(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: rows,
      );
    }
    return AppSurfaceScope(
      surface: AppSurface.inset,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ColoredBox(color: AppPalette.slate50, child: rows),
      ),
    );
  }
}

/// Row with a switch on the right. The whole row toggles it.
class AppSwitchRow extends StatelessWidget {
  const AppSwitchRow({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.enabled = true,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final active = enabled && onChanged != null;
    return AppSelectionRow(
      title: title,
      subtitle: subtitle,
      enabled: enabled,
      onTap: active ? () => onChanged!(!value) : null,
      control: AppSwitch(value: value, enabled: enabled),
    );
  }
}

/// Row with a checkbox on the right. The whole row toggles it.
///
/// For a "Select all" row pass [value] null when only some are picked.
class AppCheckboxRow extends StatelessWidget {
  const AppCheckboxRow({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.enabled = true,
  });

  final String title;
  final String? subtitle;
  final bool? value;
  final ValueChanged<bool>? onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final active = enabled && onChanged != null;
    return AppSelectionRow(
      title: title,
      subtitle: subtitle,
      enabled: enabled,
      onTap: active ? () => onChanged!(value != true) : null,
      control: AppCheckbox(value: value, enabled: enabled),
    );
  }
}

/// Row with a radio on the right. The whole row picks it.
class AppRadioRow<T> extends StatelessWidget {
  const AppRadioRow({
    super.key,
    required this.title,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    this.subtitle,
    this.enabled = true,
  });

  final String title;
  final String? subtitle;
  final T value;
  final T? groupValue;
  final ValueChanged<T>? onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final active = enabled && onChanged != null && value != groupValue;
    return AppSelectionRow(
      title: title,
      subtitle: subtitle,
      enabled: enabled,
      onTap: active ? () => onChanged!(value) : null,
      control: AppRadio<T>(
        value: value,
        groupValue: groupValue,
        enabled: enabled,
      ),
    );
  }
}

/// A row with a title, optional subtitle and any [control] on the right.
/// The whole row is the tap target; the control answers the tap (no tint).
///
/// Prefer [AppSwitchRow], [AppCheckboxRow] and [AppRadioRow]. Use this when
/// the tap needs custom handling, e.g. a picker that closes on tap.
class AppSelectionRow extends StatelessWidget {
  const AppSelectionRow({
    super.key,
    required this.title,
    required this.control,
    required this.onTap,
    this.subtitle,
    this.enabled = true,
  });

  final String title;
  final String? subtitle;
  final bool enabled;
  final VoidCallback? onTap;
  final Widget control;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap == null
            ? null
            : () {
                HapticHelpers.vibrate(VibrationType.selection);
                onTap!();
              },
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: subtitle == null ? 12 : 14,
          ),
          child: Row(
            children: [
              Expanded(
                child: _RowText(
                  title: title,
                  subtitle: subtitle,
                  enabled: enabled,
                ),
              ),
              const SizedBox(width: 16),
              control,
            ],
          ),
        ),
      ),
    );
  }
}

class _RowText extends StatelessWidget {
  const _RowText({
    required this.title,
    required this.subtitle,
    required this.enabled,
    this.large = false,
  });

  final String title;
  final String? subtitle;
  final bool enabled;

  /// Choice cards use the bigger title and body subtitle.
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppText(
          title,
          style: (large ? AppTypography.title : AppTypography.subtitle)
              .copyWith(
                color: enabled
                    ? LightColors.textStrong
                    : LightColors.textDisabled,
              ),
        ),
        if (subtitle != null)
          AppText(
            subtitle!,
            style: (large ? AppTypography.body : AppTypography.caption)
                .copyWith(
                  color: enabled
                      ? LightColors.textBody
                      : LightColors.textDisabled,
                ),
          ),
      ],
    );
  }
}

/// A whole card as one option of a single choice. The picked card gets a
/// blue border. Stack them 12 apart.
///
/// ```dart
/// AppChoiceCard(
///   title: 'Full term',
///   subtitle: '₦120,000 now, 5% off',
///   value: Plan.full,
///   groupValue: plan,
///   onChanged: (p) => setState(() => plan = p),
/// )
/// ```
class AppChoiceCard<T> extends StatelessWidget {
  const AppChoiceCard({
    super.key,
    required this.title,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    this.subtitle,
    this.leading,
    this.enabled = true,
  });

  final String title;
  final String? subtitle;
  final T value;
  final T? groupValue;
  final ValueChanged<T>? onChanged;

  /// Optional icon or picture on the left.
  final Widget? leading;

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final picked = enabled && value == groupValue;

    return MergeSemantics(
      child: Semantics(
        selected: picked,
        child: BouncyButton(
          pressedScale: 0.98,
          enableHaptic: false,
          isDisabled: !enabled,
          onPressed: onChanged == null || picked
              ? null
              : () {
                  HapticHelpers.vibrate(VibrationType.selection);
                  onChanged!(value);
                },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            // Keep the content still while the border thickens.
            padding: EdgeInsets.all(picked ? 16 : 16.5),
            decoration: BoxDecoration(
              color: enabled ? AppPalette.white : AppPalette.slate50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: picked
                    ? LightColors.primaryPrimaryDefault
                    : LightColors.strokeColourStrokeSoft,
                width: picked ? 1.5 : 1,
              ),
              boxShadow: enabled ? AppShadows.floating : null,
            ),
            child: Row(
              children: [
                if (leading != null) ...[leading!, const SizedBox(width: 14)],
                Expanded(
                  child: _RowText(
                    title: title,
                    subtitle: subtitle,
                    enabled: enabled,
                    large: true,
                  ),
                ),
                const SizedBox(width: 14),
                AppRadio<T>(
                  value: value,
                  groupValue: groupValue,
                  enabled: enabled,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
