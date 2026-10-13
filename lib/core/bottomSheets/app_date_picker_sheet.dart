import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/bottomSheets/app_sheet.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/haptic_helper.dart';
import 'package:hamrash_admin/core/utils/app_date_format.dart';
import 'package:hamrash_admin/core/widgets/app_badge.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_variants.dart';
import 'package:hamrash_admin/core/widgets/button/bouncy_button.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// A one-tap shortcut shown as a chip above the month, e.g. "Yesterday".
/// Shortcuts that fall outside the sheet's first/last date are left out.
class AppDateQuickPick {
  const AppDateQuickPick(this.label, this.date);

  AppDateQuickPick.today() : label = 'Today', date = _today();

  AppDateQuickPick.yesterday()
    : label = 'Yesterday',
      date = _today().subtract(const Duration(days: 1));

  /// The most recent [weekday] before today, e.g. "Last Friday".
  factory AppDateQuickPick.last(int weekday) {
    final today = _today();
    var back = (today.weekday - weekday) % 7;
    if (back == 0) back = 7;
    final date = DateTime(today.year, today.month, today.day - back);
    return AppDateQuickPick('Last ${DateFormat('EEEE').format(date)}', date);
  }

  final String label;
  final DateTime date;

  static DateTime _today() => AppDateFormat.dateOnly(DateTime.now());
}

/// Floating sheet with one month at a time. Tapping a day picks it and
/// closes the sheet; there is no Done button. Days outside [firstDate] and
/// [lastDate] are greyed out.
///
/// ```dart
/// final date = await AppDatePickerSheet.show(
///   context,
///   title: 'Attendance date',
///   initialDate: model.date,
///   firstDate: term.start,
///   lastDate: DateTime.now(),
///   quickPicks: [AppDateQuickPick.today(), AppDateQuickPick.yesterday()],
/// );
/// ```
abstract final class AppDatePickerSheet {
  AppDatePickerSheet._();

  static Future<DateTime?> show(
    BuildContext context, {
    required String title,
    required DateTime firstDate,
    required DateTime lastDate,
    DateTime? initialDate,
    List<AppDateQuickPick> quickPicks = const [],
  }) {
    // Date pickers can open over a text form. Close that form's keyboard first.
    FocusManager.instance.primaryFocus?.unfocus();
    final first = AppDateFormat.dateOnly(firstDate);
    final last = AppDateFormat.dateOnly(lastDate);
    final picks = quickPicks
        .where((p) => !p.date.isBefore(first) && !p.date.isAfter(last))
        .toList();

    return Navigator.of(context).push<DateTime>(
      AppSheetRoute<DateTime>(
        size: AppSheetSize.floating,
        child: Builder(
          builder: (context) {
            void pick(DateTime day) => Navigator.of(context).pop(day);
            return AppSheet(
              title: title,
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (picks.isNotEmpty) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final p in picks)
                          AppFilterChip(
                            label: p.label,
                            selected: AppDateFormat.isSameDay(
                              p.date,
                              initialDate,
                            ),
                            onTap: () => pick(p.date),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  AppMonthCalendar(
                    firstDate: first,
                    lastDate: last,
                    initialMonth: _initialMonth(initialDate, first, last),
                    selected: initialDate,
                    onDayTap: pick,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Floating sheet for a start and end date. The first tap sets the start,
/// the second the end; tap "Starts" or "Ends" to change just that one.
/// Saves with a button that says how long the range is.
///
/// ```dart
/// final range = await AppDateRangePickerSheet.show(
///   context,
///   title: 'Mid-term break',
///   initialRange: term.midTerm,
///   firstDate: term.start,
///   lastDate: term.end,
/// );
/// ```
abstract final class AppDateRangePickerSheet {
  AppDateRangePickerSheet._();

  static Future<DateTimeRange?> show(
    BuildContext context, {
    required String title,
    required DateTime firstDate,
    required DateTime lastDate,
    DateTimeRange? initialRange,
    String saveLabel = 'Save',
  }) {
    FocusManager.instance.primaryFocus?.unfocus();
    return Navigator.of(context).push<DateTimeRange>(
      AppSheetRoute<DateTimeRange>(
        size: AppSheetSize.floating,
        child: _RangeSheet(
          title: title,
          firstDate: AppDateFormat.dateOnly(firstDate),
          lastDate: AppDateFormat.dateOnly(lastDate),
          initialRange: initialRange,
          saveLabel: saveLabel,
        ),
      ),
    );
  }
}

DateTime _initialMonth(DateTime? date, DateTime first, DateTime last) {
  var month = date ?? DateTime.now();
  if (month.isBefore(first)) month = first;
  if (month.isAfter(last)) month = last;
  return DateTime(month.year, month.month);
}

class _RangeSheet extends StatefulWidget {
  const _RangeSheet({
    required this.title,
    required this.firstDate,
    required this.lastDate,
    required this.initialRange,
    required this.saveLabel,
  });

  final String title;
  final DateTime firstDate;
  final DateTime lastDate;
  final DateTimeRange? initialRange;
  final String saveLabel;

  @override
  State<_RangeSheet> createState() => _RangeSheetState();
}

class _RangeSheetState extends State<_RangeSheet> {
  late DateTime? _start = widget.initialRange == null
      ? null
      : AppDateFormat.dateOnly(widget.initialRange!.start);
  late DateTime? _end = widget.initialRange == null
      ? null
      : AppDateFormat.dateOnly(widget.initialRange!.end);

  /// Which end the next tap sets.
  bool _settingEnd = false;

  void _onDay(DateTime day) {
    setState(() {
      if (!_settingEnd) {
        _start = day;
        if (_end != null && _end!.isBefore(day)) _end = null;
        _settingEnd = true;
      } else if (_start == null || day.isBefore(_start!)) {
        _start = day;
        _end = null;
      } else {
        _end = day;
        _settingEnd = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final range = _start != null && _end != null
        ? DateTimeRange(start: _start!, end: _end!)
        : null;

    return AppSheet(
      title: widget.title,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _EndBox(
                  label: 'Starts',
                  date: _start,
                  active: !_settingEnd,
                  onTap: () => setState(() => _settingEnd = false),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _EndBox(
                  label: 'Ends',
                  date: _end,
                  active: _settingEnd,
                  onTap: _start == null
                      ? null
                      : () => setState(() => _settingEnd = true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AppMonthCalendar(
            firstDate: widget.firstDate,
            lastDate: widget.lastDate,
            initialMonth: _initialMonth(
              _start,
              widget.firstDate,
              widget.lastDate,
            ),
            selected: _start,
            rangeEnd: _end,
            onDayTap: _onDay,
          ),
        ],
      ),
      footer: AppPrimaryButton(
        width: double.infinity,
        isDisabled: range == null,
        onPressed: range == null
            ? null
            : () => Navigator.of(context).pop(range),
        child: AppText(
          range == null
              ? widget.saveLabel
              : '${widget.saveLabel} · ${AppDateFormat.length(range)}',
        ),
      ),
    );
  }
}

/// "Starts" / "Ends" summary box at the top of the range sheet. The one the
/// next tap sets has a aubergine border.
class _EndBox extends StatelessWidget {
  const _EndBox({
    required this.label,
    required this.date,
    required this.active,
    required this.onTap,
  });

  final String label;
  final DateTime? date;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: active ? AppPalette.white : AppPalette.stone50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active
                ? LightColors.primaryPrimaryDefault
                : AppPalette.stone200,
            width: active ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText(
              label,
              style: AppTypography.label.copyWith(color: LightColors.textMuted),
            ),
            const SizedBox(height: 2),
            AppText(
              date == null ? 'Pick a day' : AppDateFormat.short(date!),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.title.copyWith(
                fontWeight: FontWeight.w800,
                color: date == null
                    ? AppPalette.stone400
                    : LightColors.textStrong,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One month of days, starting on Monday, with buttons (or a sideways
/// swipe) to change month. Used inside [AppDatePickerSheet] and
/// [AppDateRangePickerSheet].
///
/// Shows [selected] as a filled aubergine circle; with [rangeEnd] too, the days
/// between sit on a pale aubergine band. Today is aubergine with a dot under it.
class AppMonthCalendar extends StatefulWidget {
  const AppMonthCalendar({
    super.key,
    required this.firstDate,
    required this.lastDate,
    required this.initialMonth,
    required this.onDayTap,
    this.selected,
    this.rangeEnd,
  });

  final DateTime firstDate;
  final DateTime lastDate;
  final DateTime initialMonth;
  final ValueChanged<DateTime> onDayTap;
  final DateTime? selected;
  final DateTime? rangeEnd;

  @override
  State<AppMonthCalendar> createState() => _AppMonthCalendarState();
}

class _AppMonthCalendarState extends State<AppMonthCalendar> {
  late DateTime _month = DateTime(
    widget.initialMonth.year,
    widget.initialMonth.month,
  );

  /// +1 when moving forward, -1 back: which side the new month slides from.
  int _direction = 1;

  bool get _canGoBack =>
      _month.isAfter(DateTime(widget.firstDate.year, widget.firstDate.month));

  bool get _canGoForward =>
      _month.isBefore(DateTime(widget.lastDate.year, widget.lastDate.month));

  void _go(int step) {
    if (step < 0 ? !_canGoBack : !_canGoForward) return;
    setState(() {
      _direction = step;
      _month = DateTime(_month.year, _month.month + step);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Narrow weekday names, Monday first (1 Jan 2024 was a Monday).
    final weekdays = [
      for (var i = 0; i < 7; i++)
        DateFormat.EEEEE().format(DateTime(2024, 1, 1 + i)),
    ];

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        final v = details.primaryVelocity ?? 0;
        if (v < -200) _go(1);
        if (v > 200) _go(-1);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: AppText(
                  AppDateFormat.month(_month),
                  style: AppTypography.title.copyWith(
                    fontWeight: FontWeight.w800,
                    color: LightColors.textStrong,
                  ),
                ),
              ),
              _MonthButton(
                icon: LucideIcons.chevronLeft,
                enabled: _canGoBack,
                onTap: () => _go(-1),
              ),
              const SizedBox(width: 8),
              _MonthButton(
                icon: LucideIcons.chevronRight,
                enabled: _canGoForward,
                onTap: () => _go(1),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final day in weekdays)
                Expanded(
                  child: AppText(
                    day,
                    textAlign: TextAlign.center,
                    style: AppTypography.label.copyWith(
                      fontWeight: FontWeight.w700,
                      color: LightColors.textMuted,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRect(
            child: AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 240),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                layoutBuilder: (current, previous) => Stack(
                  alignment: Alignment.topCenter,
                  children: [...previous, ?current],
                ),
                transitionBuilder: (child, animation) {
                  // New month slides in from the side you moved toward;
                  // the old one slides out the other way.
                  final entering = child.key == ValueKey(_month);
                  final dx = 0.2 * _direction * (entering ? 1 : -1);
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween(
                        begin: Offset(dx, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: _MonthGrid(
                  key: ValueKey(_month),
                  month: _month,
                  firstDate: widget.firstDate,
                  lastDate: widget.lastDate,
                  selected: widget.selected,
                  rangeEnd: widget.rangeEnd,
                  onDayTap: widget.onDayTap,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthButton extends StatelessWidget {
  const _MonthButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return BouncyButton(
      onPressed: enabled ? onTap : null,
      enableHaptic: false,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: enabled ? AppPalette.stone100 : AppPalette.stone50,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? AppPalette.stone700 : AppPalette.stone300,
        ),
      ),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    super.key,
    required this.month,
    required this.firstDate,
    required this.lastDate,
    required this.selected,
    required this.rangeEnd,
    required this.onDayTap,
  });

  final DateTime month;
  final DateTime firstDate;
  final DateTime lastDate;
  final DateTime? selected;
  final DateTime? rangeEnd;
  final ValueChanged<DateTime> onDayTap;

  @override
  Widget build(BuildContext context) {
    final offset = DateTime(month.year, month.month).weekday - 1;
    final days = DateTime(month.year, month.month + 1, 0).day;
    final rows = ((offset + days) / 7).ceil();
    final today = AppDateFormat.dateOnly(DateTime.now());
    final start = selected == null ? null : AppDateFormat.dateOnly(selected!);
    final end = rangeEnd == null ? null : AppDateFormat.dateOnly(rangeEnd!);
    final isRange = start != null && end != null && end.isAfter(start);

    Widget cell(int row, int col) {
      final dayNumber = row * 7 + col - offset + 1;
      if (dayNumber < 1 || dayNumber > days) {
        return const SizedBox(height: 40);
      }
      final day = DateTime(month.year, month.month, dayNumber);
      final isStart = day == start;
      final isEnd = isRange && day == end;
      final inRange = isRange && day.isAfter(start) && day.isBefore(end);
      return _DayCell(
        day: dayNumber,
        enabled: !day.isBefore(firstDate) && !day.isAfter(lastDate),
        isToday: day == today,
        isEndpoint: isStart || isEnd,
        inRange: inRange,
        bandLeft: inRange || isEnd,
        bandRight: inRange || (isRange && isStart),
        roundLeft: col == 0 || dayNumber == 1,
        roundRight: col == 6 || dayNumber == days,
        onTap: () {
          HapticHelpers.vibrate(VibrationType.selection);
          onDayTap(day);
        },
      );
    }

    return Column(
      children: [
        for (var row = 0; row < rows; row++) ...[
          if (row > 0) const SizedBox(height: 4),
          Row(
            children: [
              for (var col = 0; col < 7; col++) Expanded(child: cell(row, col)),
            ],
          ),
        ],
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.enabled,
    required this.isToday,
    required this.isEndpoint,
    required this.inRange,
    required this.bandLeft,
    required this.bandRight,
    required this.roundLeft,
    required this.roundRight,
    required this.onTap,
  });

  final int day;
  final bool enabled;
  final bool isToday;

  /// The picked day, or either end of a range: a filled aubergine circle.
  final bool isEndpoint;

  /// Strictly between the two ends of a range.
  final bool inRange;

  /// Whether the range band reaches this cell's left / right edge.
  final bool bandLeft;
  final bool bandRight;

  /// Round the band off where a week row (or the month) starts and ends.
  final bool roundLeft;
  final bool roundRight;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const band = AppPalette.aubergine100;
    const radius = Radius.circular(20);

    final Color color;
    var weight = FontWeight.w600;
    if (isEndpoint) {
      color = AppPalette.white;
      weight = FontWeight.w800;
    } else if (!enabled) {
      color = AppPalette.stone300;
    } else if (inRange) {
      color = LightColors.primaryPrimaryText;
      weight = FontWeight.w700;
    } else if (isToday) {
      color = LightColors.primaryPrimaryDefault;
      weight = FontWeight.w800;
    } else {
      color = LightColors.textStrong;
    }

    final label = AppText(
      '$day',
      style: AppTypography.bodyLarge.copyWith(color: color, fontWeight: weight),
    );

    return Semantics(
      button: enabled,
      selected: isEndpoint,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? onTap : null,
        child: SizedBox(
          height: 40,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // The range band, drawn in halves so it can stop at a circle.
              Row(
                children: [
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: bandLeft ? band : null,
                        borderRadius: inRange && roundLeft
                            ? const BorderRadius.horizontal(left: radius)
                            : null,
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: bandRight ? band : null,
                        borderRadius: inRange && roundRight
                            ? const BorderRadius.horizontal(right: radius)
                            : null,
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ],
              ),
              if (isEndpoint)
                const SizedBox.square(
                  dimension: 40,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: LightColors.primaryPrimaryDefault,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              if (isToday && !isEndpoint && !inRange)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    label,
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                )
              else
                label,
            ],
          ),
        ),
      ),
    );
  }
}
