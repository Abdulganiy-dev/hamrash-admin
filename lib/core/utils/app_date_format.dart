import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Dates the way people say them, for picker fields and their sheets.
///
/// ```dart
/// AppDateFormat.friendly(DateTime.now());   // Today, Mon 12 Oct
/// AppDateFormat.range(term);                // 5 Jan – 3 Apr 2027
/// AppDateFormat.length(term);               // 13 weeks
/// ```
abstract final class AppDateFormat {
  AppDateFormat._();

  /// [date] at midnight, so days compare cleanly.
  static DateTime dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static bool isSameDay(DateTime? a, DateTime? b) =>
      a != null &&
      b != null &&
      a.year == b.year &&
      a.month == b.month &&
      a.day == b.day;

  /// "Mon 15 Feb", with the year when it isn't this year.
  static String short(DateTime date, {DateTime? now}) {
    final thisYear = (now ?? DateTime.now()).year;
    return date.year == thisYear
        ? DateFormat('EEE d MMM').format(date)
        : DateFormat('EEE d MMM y').format(date);
  }

  /// "Today, Mon 12 Oct", "Yesterday, Sun 11 Oct", "Tomorrow, Tue 13 Oct",
  /// otherwise the same as [short].
  static String friendly(DateTime date, {DateTime? now}) {
    final today = dateOnly(now ?? DateTime.now());
    final days = dateOnly(date).difference(today).inDays;
    final prefix = switch (days) {
      0 => 'Today, ',
      -1 => 'Yesterday, ',
      1 => 'Tomorrow, ',
      _ => '',
    };
    return '$prefix${short(date, now: now)}';
  }

  /// "15 – 19 Feb 2027", "5 Jan – 3 Apr 2027", "15 Dec 2026 – 9 Jan 2027".
  static String range(DateTimeRange range) {
    final start = range.start;
    final end = range.end;
    if (isSameDay(start, end)) return DateFormat('d MMM y').format(start);
    if (start.year != end.year) {
      return '${DateFormat('d MMM y').format(start)} – '
          '${DateFormat('d MMM y').format(end)}';
    }
    if (start.month == end.month) {
      return '${start.day} – ${DateFormat('d MMM y').format(end)}';
    }
    return '${DateFormat('d MMM').format(start)} – '
        '${DateFormat('d MMM y').format(end)}';
  }

  /// How long a range is, counting both ends: "1 day", "5 days", and whole
  /// weeks from two weeks up ("13 weeks").
  static String length(DateTimeRange range) {
    final days =
        dateOnly(range.end).difference(dateOnly(range.start)).inDays + 1;
    if (days < 14) return days == 1 ? '1 day' : '$days days';
    return '${(days / 7).round()} weeks';
  }

  /// "today", "yesterday", "tomorrow", otherwise "3 Sep" (with the year when
  /// it isn't this year). For "added today", "code shared 5 Nov".
  static String relative(DateTime date, {DateTime? now}) {
    final today = dateOnly(now ?? DateTime.now());
    final days = dateOnly(date).difference(today).inDays;
    return switch (days) {
      0 => 'today',
      -1 => 'yesterday',
      1 => 'tomorrow',
      _ =>
        date.year == today.year
            ? DateFormat('d MMM').format(date)
            : DateFormat('d MMM y').format(date),
    };
  }

  /// "3 Sep" without the weekday, for compact headers.
  static String dayMonth(DateTime date) => DateFormat('d MMM').format(date);

  /// "12 Mar 1991", with the year, for dates of birth and similar.
  static String dayMonthYear(DateTime date) =>
      DateFormat('d MMM y').format(date);

  /// "October 2026".
  static String month(DateTime date) => DateFormat('MMMM y').format(date);
}
