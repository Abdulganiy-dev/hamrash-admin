import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/haptic_helper.dart';
import 'package:hamrash_admin/core/widgets/button/bouncy_button.dart';
import 'package:hamrash_admin/core/widgets/app_svg_icon.dart';

const _duration = Duration(milliseconds: 140);

/// Square checkbox for picking any number of things.
///
/// [value] null shows the "some" dash, for a "Select all" row when only part
/// of the list is picked; tapping it then picks everything.
///
/// Leave [onChanged] null when a row around it handles the tap
/// ([AppCheckboxRow] does). Set [enabled] false for the disabled look.
///
/// ```dart
/// AppCheckbox(value: isPicked, onChanged: (v) => setState(() => isPicked = v))
/// ```
class AppCheckbox extends StatelessWidget {
  const AppCheckbox({
    super.key,
    required this.value,
    this.onChanged,
    this.enabled = true,
  });

  final bool? value;
  final ValueChanged<bool>? onChanged;
  final bool enabled;

  static const double size = 22;

  @override
  Widget build(BuildContext context) {
    final on = value != false;

    final Color fill;
    final Color border;
    if (!enabled) {
      fill = AppPalette.stone100;
      border = AppPalette.stone200;
    } else if (on) {
      fill = LightColors.primaryPrimaryDefault;
      border = LightColors.primaryPrimaryDefault;
    } else {
      fill = AppPalette.white;
      border = AppPalette.stone300;
    }

    final box = AnimatedContainer(
      duration: _duration,
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border, width: 1.5),
      ),
      child: AnimatedSwitcher(
        duration: _duration,
        transitionBuilder: (child, animation) =>
            ScaleTransition(scale: animation, child: child),
        child: !on
            ? const SizedBox.shrink(key: ValueKey('off'))
            : AppSvgIcon(
                value == null ? AppSvgIcons.minus600 : AppSvgIcons.check600,
                key: ValueKey(value),
                size: 16,
                color: enabled ? AppPalette.white : AppPalette.stone400,
              ),
      ),
    );

    return _TapTarget(
      onTap: enabled && onChanged != null
          ? () => onChanged!(value != true)
          : null,
      child: box,
    );
  }
}

/// 44 tap area around a small control, with a press bounce and a selection
/// haptic. Passes the child through untouched when [onTap] is null.
class _TapTarget extends StatelessWidget {
  const _TapTarget({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (onTap == null) return child;
    return BouncyButton(
      enableHaptic: false,
      pressedScale: 0.9,
      onPressed: () {
        HapticHelpers.vibrate(VibrationType.selection);
        onTap!();
      },
      child: SizedBox.square(dimension: 44, child: Center(child: child)),
    );
  }
}

/// Round radio for picking exactly one of [groupValue]'s options.
///
/// Leave [onChanged] null when a row or card around it handles the tap
/// ([AppRadioRow], [AppChoiceCard]).
///
/// ```dart
/// AppRadio(value: Plan.full, groupValue: plan, onChanged: (p) => setState(() => plan = p))
/// ```
class AppRadio<T> extends StatelessWidget {
  const AppRadio({
    super.key,
    required this.value,
    required this.groupValue,
    this.onChanged,
    this.enabled = true,
  });

  final T value;
  final T? groupValue;
  final ValueChanged<T>? onChanged;
  final bool enabled;

  bool get selected => value == groupValue;

  @override
  Widget build(BuildContext context) {
    final on = selected && enabled;

    final circle = AnimatedContainer(
      duration: _duration,
      width: AppCheckbox.size,
      height: AppCheckbox.size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: !enabled
            ? AppPalette.stone100
            : (on ? LightColors.primaryPrimaryDefault : AppPalette.white),
        border: Border.all(
          color: !enabled
              ? AppPalette.stone200
              : (on ? LightColors.primaryPrimaryDefault : AppPalette.stone300),
          width: 1.5,
        ),
      ),
      child: AnimatedScale(
        duration: _duration,
        curve: Curves.easeOutBack,
        scale: on ? 1 : 0,
        child: Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: AppPalette.white,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );

    return _TapTarget(
      onTap: enabled && onChanged != null ? () => onChanged!(value) : null,
      child: circle,
    );
  }
}

/// On/off switch for a setting that applies straight away.
///
/// Leave [onChanged] null when a row around it handles the tap
/// ([AppSwitchRow] does).
///
/// ```dart
/// AppSwitch(value: alertsOn, onChanged: (v) => setState(() => alertsOn = v))
/// ```
class AppSwitch extends StatelessWidget {
  const AppSwitch({
    super.key,
    required this.value,
    this.onChanged,
    this.enabled = true,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool enabled;

  static const _thumbShadow = [
    BoxShadow(color: Color(0x1F2A1712), offset: Offset(0, 1), blurRadius: 1.5),
    BoxShadow(color: Color(0x0F2A1712), offset: Offset(0, 2), blurRadius: 3),
  ];

  @override
  Widget build(BuildContext context) {
    final Color track;
    if (!enabled) {
      track = AppPalette.stone100;
    } else {
      track = value ? LightColors.primaryPrimaryDefault : AppPalette.stone200;
    }

    final control = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      width: 48,
      height: 28,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: track,
        borderRadius: BorderRadius.circular(14),
      ),
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: enabled ? AppPalette.white : AppPalette.stone50,
            shape: BoxShape.circle,
            boxShadow: enabled ? _thumbShadow : null,
          ),
        ),
      ),
    );

    return Semantics(
      toggled: value,
      enabled: enabled,
      child: _TapTarget(
        onTap: enabled && onChanged != null ? () => onChanged!(!value) : null,
        child: control,
      ),
    );
  }
}
