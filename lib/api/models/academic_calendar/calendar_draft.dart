import 'package:flutter/material.dart';

/// Values edited on the session details page before they are saved.
class CalendarTermDraft {
  CalendarTermDraft({required this.name, required this.dates});

  String name;
  DateTimeRange dates;
}

class CalendarDraft {
  CalendarDraft({
    required this.name,
    required this.dates,
    required this.terms,
    required this.currentTermIndex,
  });

  String name;
  DateTimeRange dates;
  final List<CalendarTermDraft> terms;
  int currentTermIndex;
}
