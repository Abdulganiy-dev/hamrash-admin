import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/bottomSheets/app_sheet.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/haptic_helper.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_variants.dart';

/// Floating sheet with hour, minute (and AM/PM) wheels. The button repeats
/// the time it will set, e.g. "Set 7:45 AM". Follows the phone's 24-hour
/// setting.
///
/// ```dart
/// final time = await AppTimePickerSheet.show(
///   context,
///   title: 'Assembly starts',
///   initialTime: const TimeOfDay(hour: 7, minute: 45),
/// );
/// ```
abstract final class AppTimePickerSheet {
  AppTimePickerSheet._();

  static Future<TimeOfDay?> show(
    BuildContext context, {
    required String title,
    TimeOfDay? initialTime,
    int minuteInterval = 5,
  }) {
    assert(60 % minuteInterval == 0, 'minuteInterval must divide 60');
    return Navigator.of(context).push<TimeOfDay>(
      AppSheetRoute<TimeOfDay>(
        size: AppSheetSize.floating,
        child: _TimeSheet(
          title: title,
          initialTime: initialTime ?? const TimeOfDay(hour: 8, minute: 0),
          minuteInterval: minuteInterval,
        ),
      ),
    );
  }
}

class _TimeSheet extends StatefulWidget {
  const _TimeSheet({
    required this.title,
    required this.initialTime,
    required this.minuteInterval,
  });

  final String title;
  final TimeOfDay initialTime;
  final int minuteInterval;

  @override
  State<_TimeSheet> createState() => _TimeSheetState();
}

class _TimeSheetState extends State<_TimeSheet> {
  late int _hour = widget.initialTime.hour;

  /// Rounded to the nearest step; 60 wraps to 0.
  late int _minute =
      ((widget.initialTime.minute / widget.minuteInterval).round() *
          widget.minuteInterval) %
      60;

  TimeOfDay get _time => TimeOfDay(hour: _hour, minute: _minute);

  @override
  Widget build(BuildContext context) {
    final use24 = MediaQuery.alwaysUse24HourFormatOf(context);
    final localizations = MaterialLocalizations.of(context);
    final minutes = [for (var m = 0; m < 60; m += widget.minuteInterval) m];
    final isPm = _hour >= 12;

    return AppSheet(
      title: widget.title,
      body: SizedBox(
        height: _Wheel.extent * 5,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // The band the chosen row sits on.
            Container(
              height: _Wheel.extent,
              decoration: BoxDecoration(
                color: AppPalette.slate100,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _Wheel(
                  count: use24 ? 24 : 12,
                  initial: use24 ? _hour : (_hour % 12 + 11) % 12,
                  looping: true,
                  label: (i) => use24 ? '$i' : '${i + 1}',
                  onChanged: (i) => setState(() {
                    _hour = use24 ? i : (i + 1) % 12 + (isPm ? 12 : 0);
                  }),
                ),
                AppText(':', style: _Wheel.style(0)),
                _Wheel(
                  count: minutes.length,
                  initial: minutes.indexOf(_minute),
                  looping: true,
                  label: (i) => minutes[i].toString().padLeft(2, '0'),
                  onChanged: (i) => setState(() => _minute = minutes[i]),
                ),
                if (!use24)
                  _Wheel(
                    count: 2,
                    initial: isPm ? 1 : 0,
                    label: (i) => i == 0
                        ? localizations.anteMeridiemAbbreviation
                        : localizations.postMeridiemAbbreviation,
                    onChanged: (i) => setState(() {
                      _hour = _hour % 12 + (i == 1 ? 12 : 0);
                    }),
                  ),
              ],
            ),
          ],
        ),
      ),
      footer: AppPrimaryButton(
        width: double.infinity,
        onPressed: () => Navigator.of(context).pop(_time),
        child: AppText(
          'Set ${localizations.formatTimeOfDay(_time, alwaysUse24HourFormat: use24)}',
        ),
      ),
    );
  }
}

/// One spinning column. The chosen row is large and dark; rows fade and
/// shrink with distance from it.
class _Wheel extends StatefulWidget {
  const _Wheel({
    required this.count,
    required this.initial,
    required this.label,
    required this.onChanged,
    this.looping = false,
  });

  static const double extent = 44;
  static const double width = 64;

  static TextStyle style(int distance) => switch (distance) {
    0 => AppTypography.h2.copyWith(
      fontWeight: FontWeight.w800,
      color: LightColors.textStrong,
    ),
    1 => AppTypography.h3.copyWith(
      fontWeight: FontWeight.w600,
      color: AppPalette.slate400,
    ),
    _ => AppTypography.h4.copyWith(
      fontWeight: FontWeight.w600,
      color: AppPalette.slate300,
    ),
  };

  final int count;
  final int initial;
  final bool looping;
  final String Function(int index) label;
  final ValueChanged<int> onChanged;

  @override
  State<_Wheel> createState() => _WheelState();
}

class _WheelState extends State<_Wheel> {
  late final _controller = FixedExtentScrollController(
    initialItem: widget.initial,
  );

  /// Raw item index under the band (keeps counting past [count] when the
  /// wheel loops).
  late int _selected = widget.initial;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _item(int raw) {
    final distance = (raw - _selected).abs();
    return AnimatedDefaultTextStyle(
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOutCubic,
      style: _Wheel.style(distance),
      child: Center(
        child: AppText(widget.label(raw % widget.count)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _Wheel.width,
      child: ListWheelScrollView.useDelegate(
        controller: _controller,
        itemExtent: _Wheel.extent,
        physics: const FixedExtentScrollPhysics(),
        diameterRatio: 2.4,
        onSelectedItemChanged: (raw) {
          setState(() => _selected = raw);
          HapticHelpers.vibrate(VibrationType.selection);
          widget.onChanged(raw % widget.count);
        },
        childDelegate: widget.looping
            ? ListWheelChildBuilderDelegate(builder: (_, raw) => _item(raw))
            : ListWheelChildBuilderDelegate(
                childCount: widget.count,
                builder: (_, raw) => _item(raw),
              ),
      ),
    );
  }
}
