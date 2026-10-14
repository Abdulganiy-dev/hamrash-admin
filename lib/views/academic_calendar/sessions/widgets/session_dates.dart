import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// "7 Sep 2026 – 16 Jul 2027".
String sessionDates(DateTimeRange dates) {
  final format = DateFormat('d MMM y');
  return '${format.format(dates.start)} – ${format.format(dates.end)}';
}
