import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/constants/radius_containers.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/widgets/app_svg_icon.dart';
import 'package:hamrash_admin/views/team/widgets/icon_label.dart';

/// One of the three quick actions on a staff page: a 44 tall pill that opens
/// the phone, messages or email. Tapping it fills stone-100 instantly — no
/// scale, no tint animation. Without a number or address it stays in the row
/// but greys out and stops taking taps.
class QuickActionPill extends StatefulWidget {
  const QuickActionPill({
    super.key,
    required this.icon,
    required this.label,
    required this.semanticLabel,
    this.onTap,
  });

  final AppSvgIconData icon;
  final String label;

  /// "Call Tunde", "Message Tunde", "Email Tunde".
  final String semanticLabel;

  /// Null when there's nothing to launch.
  final VoidCallback? onTap;

  @override
  State<QuickActionPill> createState() => _QuickActionPillState();
}

class _QuickActionPillState extends State<QuickActionPill> {
  bool _pressed = false;

  bool get _enabled => widget.onTap != null;

  void _pressDown(TapDownDetails _) {
    if (_enabled && !_pressed) setState(() => _pressed = true);
  }

  void _pressUp([TapUpDetails? _]) {
    if (_pressed) setState(() => _pressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final fill = !_enabled || _pressed ? AppPalette.stone100 : AppPalette.white;
    final border = _enabled ? AppPalette.stone300 : AppPalette.stone200;
    final foreground = _enabled
        ? LightColors.textStrong
        : LightColors.textDisabled;
    final iconColor = _enabled
        ? LightColors.primaryPrimaryDefault
        : LightColors.textDisabled;

    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.semanticLabel,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _pressDown,
        onTapUp: _pressUp,
        onTapCancel: _pressUp,
        onTap: _enabled ? widget.onTap : null,
        child: SizedBox(
          height: 44,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.ms),
            decoration: BoxDecoration(
              color: fill,
              borderRadius: AppRadius.brPill,
              border: Border.all(color: border),
            ),
            child: IconLabel(
              icon: widget.icon,
              label: widget.label,
              iconColor: iconColor,
              style: AppTypography.body.copyWith(
                fontSize: 15,
                height: 20 / 15,
                fontWeight: FontWeight.w700,
                color: foreground,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
