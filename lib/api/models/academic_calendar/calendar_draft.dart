import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/academic_calendar/academic_session.dart';

/// Values edited on the session details page before they are saved.
class CalendarTermDraft {
  CalendarTermDraft({required this.name, required this.dates, this.id});

  /// The saved term this edits; null for a term added on the page.
  final String? id;
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

  /// A copy of a saved session to edit.
  factory CalendarDraft.fromSession(AcademicSession session) => CalendarDraft(
    name: session.name,
    dates: session.dates,
    terms: [
      for (final term in session.terms)
        CalendarTermDraft(id: term.id, name: term.name, dates: term.dates),
    ],
    currentTermIndex: session.currentTermIndex,
  );

  String name;
  DateTimeRange dates;
  final List<CalendarTermDraft> terms;

  /// Null when none of this session's terms is current, e.g. next year's
  /// session set up early.
  int? currentTermIndex;
}
