import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/widgets/app_icon_label.dart';
import 'package:hamrash_admin/core/widgets/button/bouncy_button.dart';

/// The compact action beside a section title, e.g. "Change" over Details.
///
/// It looks like a small tinted pill but keeps a 44 tall, 44 wide tap box.
/// Pressing gives the app's bouncy spring ([BouncyButton]); with no
/// [onPressed] it greys out and stops taking taps.
class AppSectionAction extends StatelessWidget {
  const AppSectionAction({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.semanticLabel,
    this.addBackground = false,
  });

  final String label;
  final IconData icon;

  /// Null disables the action.
  final VoidCallback? onPressed;

  /// Defaults to [label].
  final String? semanticLabel;
  final bool addBackground;

  bool get _enabled => onPressed != null;

  @override
  Widget build(BuildContext context) {
    final fill =
        _enabled ? LightColors.primaryPrimaryMute : AppPalette.stone100;
    final border =
        _enabled ? LightColors.primaryPrimaryThin : AppPalette.stone200;
    final foreground =
        _enabled ? LightColors.primaryPrimaryText : LightColors.textDisabled;

    return Semantics(
      button: true,
      enabled: _enabled,
      label: semanticLabel ?? label,
      excludeSemantics: true,
      child: BouncyButton(
        onPressed: onPressed,
        isDisabled: !_enabled,
        child: SizedBox(
          height: 44,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 44),
            child: Center(
              widthFactor: 1,
              child: Container(
                height: 32,
                padding: const EdgeInsets.only(left: 10, right: 12),
                decoration:addBackground ? BoxDecoration(
                  color: fill,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: border),
                ) : null,
                child: Center(
                  child: AppIconLabel(
                    icon: icon,
                    label: label,
                    iconColor: foreground,
                    iconSize: 16,
                    gap: 6,
                    hugContent: true,
                    style: AppTypography.body.copyWith(
                      fontSize: 14,
                      height: 20 / 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                      color: foreground,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
