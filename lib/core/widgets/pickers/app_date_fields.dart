import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/bottomSheets/app_date_picker_sheet.dart';
import 'package:hamrash_admin/core/bottomSheets/app_time_picker_sheet.dart';
import 'package:hamrash_admin/core/utils/app_date_format.dart';
import 'package:hamrash_admin/core/widgets/pickers/app_picker_field.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Pick one day. Reads the way people say it ("Today, Mon 12 Oct") and
/// opens [AppDatePickerSheet]; tapping a day picks it and closes.
///
/// ```dart
/// AppDateField(
///   label: 'Attendance date',
///   value: model.date,
///   firstDate: term.start,
///   lastDate: DateTime.now(),
///   quickPicks: [AppDateQuickPick.today(), AppDateQuickPick.yesterday()],
///   onChanged: model.setDate,
/// )
/// ```
class AppDateField extends StatelessWidget {
  const AppDateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    required this.firstDate,
    required this.lastDate,
    this.quickPicks = const [],
    this.placeholder = 'Pick a date',
    this.sheetTitle,
    this.isOptional = false,
    this.helperText,
    this.errorText,
    this.validator,
    this.enabled = true,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final DateTime firstDate;
  final DateTime lastDate;

  /// Chips above the month, e.g. Today and Yesterday. Any outside the
  /// first/last date are left out.
  final List<AppDateQuickPick> quickPicks;
  final String placeholder;

  /// Defaults to [label].
  final String? sheetTitle;
  final bool isOptional;
  final String? helperText;
  final String? errorText;
  final String? Function(DateTime? value)? validator;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return AppPickerField(
      label: label,
      icon: LucideIcons.calendar,
      valueText: value == null ? null : AppDateFormat.friendly(value!),
      placeholder: placeholder,
      isOptional: isOptional,
      helperText: helperText,
      errorText: errorText,
      validator: validator == null ? null : () => validator!(value),
      enabled: enabled,
      onTap: () async {
        final picked = await AppDatePickerSheet.show(
          context,
          title: sheetTitle ?? label,
          initialDate: value,
          firstDate: firstDate,
          lastDate: lastDate,
          quickPicks: quickPicks,
        );
        if (picked != null) onChanged(picked);
      },
    );
  }
}

/// Pick a start and end day ("5 Jan – 3 Apr 2027"). Unless you pass
/// [helperText], the line under the field says how long the range is.
///
/// ```dart
/// AppDateRangeField(
///   label: 'Term dates',
///   value: model.termDates,
///   firstDate: session.start,
///   lastDate: session.end,
///   onChanged: model.setTermDates,
/// )
/// ```
class AppDateRangeField extends StatelessWidget {
  const AppDateRangeField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    required this.firstDate,
    required this.lastDate,
    this.placeholder = 'Pick dates',
    this.sheetTitle,
    this.saveLabel = 'Save',
    this.isOptional = false,
    this.helperText,
    this.errorText,
    this.validator,
    this.enabled = true,
  });

  final String label;
  final DateTimeRange? value;
  final ValueChanged<DateTimeRange> onChanged;
  final DateTime firstDate;
  final DateTime lastDate;
  final String placeholder;

  /// Defaults to [label].
  final String? sheetTitle;

  /// The sheet's button; the length is added, e.g. "Save · 5 days".
  final String saveLabel;
  final bool isOptional;
  final String? helperText;
  final String? errorText;
  final String? Function(DateTimeRange? value)? validator;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final range = value;
    return AppPickerField(
      label: label,
      icon: LucideIcons.calendar,
      valueText: range == null ? null : AppDateFormat.range(range),
      placeholder: placeholder,
      isOptional: isOptional,
      helperText:
          helperText ?? (range == null ? null : AppDateFormat.length(range)),
      errorText: errorText,
      validator: validator == null ? null : () => validator!(value),
      enabled: enabled,
      onTap: () async {
        final picked = await AppDateRangePickerSheet.show(
          context,
          title: sheetTitle ?? label,
          initialRange: value,
          firstDate: firstDate,
          lastDate: lastDate,
          saveLabel: saveLabel,
        );
        if (picked != null) onChanged(picked);
      },
    );
  }
}

/// Pick a time of day ("7:45 AM") on wheels, in [minuteInterval] steps.
///
/// ```dart
/// AppTimeField(
///   label: 'Assembly starts',
///   value: model.assemblyTime,
///   onChanged: model.setAssemblyTime,
/// )
/// ```
class AppTimeField extends StatelessWidget {
  const AppTimeField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.minuteInterval = 5,
    this.placeholder = 'Pick a time',
    this.sheetTitle,
    this.isOptional = false,
    this.helperText,
    this.errorText,
    this.validator,
    this.enabled = true,
  });

  final String label;
  final TimeOfDay? value;
  final ValueChanged<TimeOfDay> onChanged;
  final int minuteInterval;
  final String placeholder;

  /// Defaults to [label].
  final String? sheetTitle;
  final bool isOptional;
  final String? helperText;
  final String? errorText;
  final String? Function(TimeOfDay? value)? validator;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final time = value;
    return AppPickerField(
      label: label,
      icon: LucideIcons.clock,
      valueText: time == null
          ? null
          : MaterialLocalizations.of(context).formatTimeOfDay(
              time,
              alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(
                context,
              ),
            ),
      placeholder: placeholder,
      isOptional: isOptional,
      helperText: helperText,
      errorText: errorText,
      validator: validator == null ? null : () => validator!(value),
      enabled: enabled,
      onTap: () async {
        final picked = await AppTimePickerSheet.show(
          context,
          title: sheetTitle ?? label,
          initialTime: value,
          minuteInterval: minuteInterval,
        );
        if (picked != null) onChanged(picked);
      },
    );
  }
}
