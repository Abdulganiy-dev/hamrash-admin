import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/haptic_helper.dart';
import 'package:hamrash_admin/core/widgets/app_badge.dart';

/// Compact one-letter segments coloured by meaning. Built for taking
/// attendance: the picked segment takes its status's badge colours.
///
/// [value] null means nothing picked yet (e.g. attendance not taken).
///
/// ```dart
/// AppStatusPicker(
///   options: const [AttendanceStatus.present, AttendanceStatus.late, AttendanceStatus.absent],
///   value: student.attendance,
///   onChanged: (s) => model.mark(student, s),
/// )
/// ```
class AppStatusPicker<T extends BadgeStatus> extends StatelessWidget {
  const AppStatusPicker({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.shortLabel,
  });

  final List<T> options;
  final T? value;
  final ValueChanged<T>? onChanged;

  /// Text in each segment. Defaults to the first letter of the label.
  final String Function(T status)? shortLabel;

  static const _duration = Duration(milliseconds: 140);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppPalette.slate100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < options.length; i++) ...[
            if (i > 0) const SizedBox(width: 2),
            _segment(options[i]),
          ],
        ],
      ),
    );
  }

  Widget _segment(T status) {
    final picked = status == value;
    final tone = status.tone;
    final text = shortLabel?.call(status) ?? status.label.characters.first;

    return Semantics(
      button: true,
      selected: picked,
      label: status.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onChanged == null || picked
            ? null
            : () {
                HapticHelpers.vibrate(VibrationType.selection);
                onChanged!(status);
              },
        child: AnimatedContainer(
          duration: _duration,
          width: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: picked ? tone.mute : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: picked ? tone.thin : Colors.transparent),
          ),
          child: AnimatedDefaultTextStyle(
            duration: _duration,
            style: AppTypography.body.copyWith(
              fontWeight: picked ? FontWeight.w800 : FontWeight.w700,
              color: picked
                  ? tone.strong
                  // Brighter letters while nothing is picked, so the row
                  // reads as "to do".
                  : (value == null ? AppPalette.slate500 : AppPalette.slate400),
            ),
            child: Text(text),
          ),
        ),
      ),
    );
  }
}
