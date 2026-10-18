import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/button/bouncy_button.dart';
import 'package:hamrash_admin/core/widgets/app_svg_icon.dart';

/// Quiet icon-and-text action under a sheet's main button, e.g. "Remove
/// term" or "Switch off this class". When it can't be used, it greys out
/// and [helper] says why.
///
/// ```dart
/// AppSheetLinkAction(
///   icon: AppSvgIcons.trash2,
///   label: 'Remove term',
///   isDestructive: true,
///   helper: isCurrent ? 'Make another term current first.' : null,
///   onPressed: isCurrent ? null : remove,
/// )
/// ```
class AppSheetLinkAction extends StatelessWidget {
  const AppSheetLinkAction({
    super.key,
    required this.label,
    required this.icon,
    this.helper,
    this.onPressed,
    this.isDestructive = false,
  });

  final String label;
  final AppSvgIconData icon;

  /// Shown under the action, usually why it's greyed out.
  final String? helper;
  final VoidCallback? onPressed;

  /// Red, for removing things.
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final color = onPressed == null
        ? AppPalette.stone400
        : isDestructive
        ? LightColors.errorErrorText
        : AppPalette.stone600;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        BouncyButton(
          isDisabled: onPressed == null,
          onPressed: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppSvgIcon(icon, size: 14, color: color),
                const SizedBox(width: 6),
                Flexible(
                  child: AppText(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.button.copyWith(color: color),
                  ),
                ),
              ],
            ),
          ),
        ),
        _AnimatedHelper(
          value: helper ?? '',
          child: helper == null
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: AppText(
                    helper!,
                    textAlign: TextAlign.center,
                    style: AppTypography.caption.copyWith(
                      color: AppPalette.stone500,
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

/// Moves the helper in and out while its height settles.
class _AnimatedHelper extends StatelessWidget {
  const _AnimatedHelper({required this.value, required this.child});

  final String value;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 220);
    return AnimatedSize(
      duration: duration,
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: duration,
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        layoutBuilder: (currentChild, previousChildren) => Stack(
          alignment: Alignment.topCenter,
          children: [
            for (final previous in previousChildren)
              IgnorePointer(child: previous),
            ?currentChild,
          ],
        ),
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.08),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        ),
        child: KeyedSubtree(key: ValueKey(value), child: child),
      ),
    );
  }
}
