import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/academic_calendar/calendar_draft.dart';
import 'package:hamrash_admin/viewModel/base_view_model.dart';

/// A session being edited on a page: its draft, the checks it must pass
/// before saving, and the edits the session and term sheets make.
/// Shared by creating a session and a saved session's details page.
abstract class SessionDraftModel extends BaseViewModel {
  CalendarDraft get draft;

  /// Closed sessions, and people who can only view the calendar.
  bool get readOnly => false;

  int get teachingWeeks => draft.terms.fold(
    0,
    (sum, term) => sum + (term.dates.duration.inDays / 7).ceil(),
  );

  /// The first thing stopping a save, or null.
  String? get problem {
    if (draft.name.trim().isEmpty) return 'Add a session name';
    if (!draft.dates.end.isAfter(draft.dates.start)) {
      return 'Session end must be after its start';
    }
    if (draft.terms.isEmpty) return 'Add at least one term';
    if (draft.terms.length > 6) return 'A session can have up to 6 terms';
    final names = <String>{};
    for (var i = 0; i < draft.terms.length; i++) {
      final term = draft.terms[i];
      if (term.name.trim().isEmpty) return 'Name term ${i + 1}';
      if (!names.add(term.name.trim().toLowerCase())) {
        return 'Each term needs a different name';
      }
      if (!term.dates.end.isAfter(term.dates.start)) {
        return '${term.name} needs at least two dates';
      }
      if (term.dates.start.isBefore(draft.dates.start) ||
          term.dates.end.isAfter(draft.dates.end)) {
        return '${term.name} must fit inside the session dates';
      }
      if (i > 0 && !term.dates.start.isAfter(draft.terms[i - 1].dates.end)) {
        return '${term.name} starts before ${draft.terms[i - 1].name} ends';
      }
    }
    return null;
  }

  /// Called after every edit. Pages that track unsaved changes override it.
  @protected
  void draftChanged() => notifyListeners();

  void editSession(String name, DateTimeRange dates) {
    draft.name = name.trim();
    draft.dates = dates;
    draftChanged();
  }

  void editTerm(
    int index,
    String name,
    DateTimeRange dates, {
    required bool isCurrent,
  }) {
    draft.terms[index].name = name.trim();
    draft.terms[index].dates = dates;
    if (isCurrent) draft.currentTermIndex = index;
    draftChanged();
  }

  void addTerm(String name, DateTimeRange dates) {
    draft.terms.add(CalendarTermDraft(name: name.trim(), dates: dates));
    draftChanged();
  }

  /// The current term stays until another term is made current; the
  /// database refuses to remove it too.
  void removeTerm(int index) {
    final current = draft.currentTermIndex;
    if (index == current) return;
    draft.terms.removeAt(index);
    if (current != null && current > index) {
      draft.currentTermIndex = current - 1;
    }
    draftChanged();
  }
}
