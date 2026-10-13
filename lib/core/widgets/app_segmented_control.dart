import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/haptic_helper.dart';

/// A single option inside an [AppSegmentedControl].
///
/// `value` is what the parent receives in `onChanged`. `label` is what the
/// user sees. `icon` is rendered to the left of the label when provided.
class AppSegmentOption<T> {
  const AppSegmentOption({required this.value, required this.label, this.icon});

  final T value;
  final String label;
  final IconData? icon;
}

/// Two to four views of the same thing: a stone-100 track with a white thumb
/// that slides to the picked option.
///
/// ```dart
/// AppSegmentedControl(
///   options: const [
///     AppSegmentOption(value: Range.day, label: 'Day'),
///     AppSegmentOption(value: Range.week, label: 'Week'),
///   ],
///   selected: range,
///   onChanged: (r) => setState(() => range = r),
/// )
/// ```
class AppSegmentedControl<T> extends StatelessWidget {
  const AppSegmentedControl({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.height = 44,
  });

  final List<AppSegmentOption<T>> options;
  final T? selected;
  final ValueChanged<T> onChanged;
  final double height;

  static const _duration = Duration(milliseconds: 220);
  static const _padding = 4.0;

  static const _thumbShadow = [
    BoxShadow(color: Color(0x0F2A1712), offset: Offset(0, 1), blurRadius: 1),
    BoxShadow(color: Color(0x142A1712), offset: Offset(0, 2), blurRadius: 3),
  ];

  @override
  Widget build(BuildContext context) {
    final index = options.indexWhere((o) => o.value == selected);

    return Container(
      height: height,
      padding: const EdgeInsets.all(_padding),
      decoration: BoxDecoration(
        color: AppPalette.stone100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final segmentWidth = constraints.maxWidth / options.length;
          return Stack(
            children: [
              if (index >= 0)
                AnimatedPositioned(
                  duration: _duration,
                  curve: Curves.easeOutCubic,
                  left: segmentWidth * index,
                  top: 0,
                  bottom: 0,
                  width: segmentWidth,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppPalette.white,
                      borderRadius: BorderRadius.circular(9),
                      boxShadow: _thumbShadow,
                    ),
                  ),
                ),
              Positioned.fill(
                child: Row(
                  children: [
                    for (var i = 0; i < options.length; i++)
                      Expanded(
                        child: _Segment(
                          option: options[i],
                          selected: i == index,
                          onTap: () {
                            if (i == index) return;
                            HapticHelpers.vibrate(VibrationType.selection);
                            onChanged(options[i].value);
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Segment<T> extends StatelessWidget {
  const _Segment({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final AppSegmentOption<T> option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? LightColors.textStrong : LightColors.textMuted;

    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (option.icon != null) ...[
              Icon(option.icon, size: 16, color: color),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: AnimatedDefaultTextStyle(
                duration: AppSegmentedControl._duration,
                style: AppTypography.body.copyWith(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  color: color,
                ),
                child: AppText(
                  option.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
