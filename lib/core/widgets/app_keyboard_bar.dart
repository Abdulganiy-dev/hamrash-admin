import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/button/app_button.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_types.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_variants.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Bar that rides on top of the keyboard while a field has focus.
///
/// Use it as [Scaffold.bottomNavigationBar] only while the keyboard is open;
/// it lifts itself above the keyboard. Not for bottom sheets: those pin their
/// own button above the keyboard.
///
/// ```dart
/// // One or two fields: a Done button on the right.
/// const AppKeyboardBar()
///
/// // Three or more fields: arrows step between them.
/// AppKeyboardBar(fieldIndex: 1, fieldCount: 4)
///
/// // The screen's main button stays in reach.
/// AppKeyboardBar.action(
///   action: AppPrimaryButton(onPressed: submit, child: Text('Continue')),
/// )
/// ```
class AppKeyboardBar extends StatelessWidget {
  const AppKeyboardBar({
    super.key,
    this.onDone,
    this.fieldIndex,
    this.fieldCount,
    this.onPrevious,
    this.onNext,
  }) : action = null,
       assert(
         (fieldIndex == null) == (fieldCount == null),
         'Pass fieldIndex and fieldCount together.',
       );

  /// The screen's main button on the right, with a dismiss square beside it.
  const AppKeyboardBar.action({
    super.key,
    required Widget this.action,
    this.onDone,
  }) : fieldIndex = null,
       fieldCount = null,
       onPrevious = null,
       onNext = null;

  /// Runs after the keyboard is put away.
  final VoidCallback? onDone;

  /// Zero-based position of the focused field. Arrows show from three fields.
  final int? fieldIndex;

  /// How many fields the form has.
  final int? fieldCount;

  /// Defaults to moving focus to the previous field.
  final VoidCallback? onPrevious;

  /// Defaults to moving focus to the next field.
  final VoidCallback? onNext;

  /// Usually an [AppPrimaryButton]; fills the space beside the dismiss square.
  final Widget? action;

  static const double height = 52;

  /// Whether the keyboard is covering the bottom of the screen.
  static bool isKeyboardOpen(BuildContext context) =>
      MediaQuery.viewInsetsOf(context).bottom > 0;

  void _dismiss() {
    FocusManager.instance.primaryFocus?.unfocus();
    onDone?.call();
  }

  bool get _showStepper =>
      fieldIndex != null && fieldCount != null && fieldCount! >= 3;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: action == null ? _buildDoneBar() : _buildActionBar(),
  );

  Widget _buildDoneBar() => SizedBox(
    height: height,
    child: Padding(
      padding: AppSpacing.horizontalMs,
      child: Row(
        children: [
          if (_showStepper) _buildStepper(),
          const Spacer(),
          AppTertiaryButton(
            size: AppButtonSize.small,
            padding: const EdgeInsets.only(left: 12, right: 14),
            onPressed: _dismiss,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.chevronDown, size: 16),
                SizedBox(width: 6),
                Text('Done'),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildStepper() {
    final index = fieldIndex!;
    final count = fieldCount!;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StepArrow(
          icon: LucideIcons.chevronUp,
          label: 'Previous field',
          onPressed: index > 0
              ? onPrevious ??
                    () => FocusManager.instance.primaryFocus?.previousFocus()
              : null,
        ),
        const SizedBox(width: AppSpacing.xs),
        _StepArrow(
          icon: LucideIcons.chevronDown,
          label: 'Next field',
          onPressed: index < count - 1
              ? onNext ?? () => FocusManager.instance.primaryFocus?.nextFocus()
              : null,
        ),
        const SizedBox(width: 10),
        AppText(
          '${index + 1} of $count',
          variant: AppTextVariant.label,
          fontSize: 13,
          colorType: AppTextColor.textMuted,
        ),
      ],
    );
  }

  Widget _buildActionBar() => Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.ms,
      vertical: AppSpacing.sm,
    ),
    child: Row(
      children: [
        Semantics(
          button: true,
          label: 'Hide keyboard',
          excludeSemantics: true,
          child: AppSecondaryButton(
            width: 48,
            padding: EdgeInsets.zero,
            onPressed: _dismiss,
            child: const Icon(LucideIcons.chevronDown, size: 20),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: action!),
      ],
    ),
  );
}

/// 36px up/down arrow; fades to stone 300 at the ends of the form.
class _StepArrow extends StatelessWidget {
  const _StepArrow({required this.icon, required this.label, this.onPressed});

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: 36,
        child: AppButton(
          type: AppButtonType.icon,
          lucidIcon: icon,
          lucidIconSize: 20,
          isDisabled: !enabled,
          foregroundColor: enabled ? AppPalette.stone700 : AppPalette.stone300,
          onPressed: onPressed,
        ),
      ),
    );
  }
}
