import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/academic_calendar/calendar_draft.dart';
import 'package:hamrash_admin/api/services/supabase_services/academic_calendar_service.dart';
import 'package:hamrash_admin/singleton_locator/locator.dart';
import 'package:hamrash_admin/viewModel/base_view_model.dart';

class CreateSessionViewModel extends BaseViewModel {
  CreateSessionViewModel({
    required this.organizationId,
    DateTime? now,
    AcademicCalendarService? service,
  }) : _service = service ?? locator<AcademicCalendarService>(),
       _now = now ?? DateTime.now() {
    final year = _now.month >= 9 ? _now.year : _now.year - 1;
    draft = CalendarDraft(
      name: '$year/${((year + 1) % 100).toString().padLeft(2, '0')}',
      dates: DateTimeRange(
        start: DateTime(year, 9, 7),
        end: DateTime(year + 1, 7, 16),
      ),
      terms: [
        CalendarTermDraft(
          name: 'First term',
          dates: DateTimeRange(
            start: DateTime(year, 9, 7),
            end: DateTime(year, 12, 11),
          ),
        ),
        CalendarTermDraft(
          name: 'Second term',
          dates: DateTimeRange(
            start: DateTime(year + 1, 1, 4),
            end: DateTime(year + 1, 4, 1),
          ),
        ),
        CalendarTermDraft(
          name: 'Third term',
          dates: DateTimeRange(
            start: DateTime(year + 1, 4, 26),
            end: DateTime(year + 1, 7, 16),
          ),
        ),
      ],
      currentTermIndex: 0,
    );
    for (var i = 0; i < draft.terms.length; i++) {
      final dates = draft.terms[i].dates;
      if (!_now.isBefore(dates.start) && !_now.isAfter(dates.end)) {
        draft.currentTermIndex = i;
        break;
      }
    }
  }

  final String organizationId;
  final AcademicCalendarService _service;
  final DateTime _now;
  late final CalendarDraft draft;
  bool saving = false;
  String? saveError;

  int get teachingWeeks => draft.terms.fold(
    0,
    (sum, term) => sum + (term.dates.duration.inDays / 7).ceil(),
  );

  String? get problem {
    if (draft.name.trim().isEmpty) return 'Add a session name';
    if (draft.dates.end.isBefore(draft.dates.start) ||
        draft.dates.end.isAtSameMomentAs(draft.dates.start)) {
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

  void editSession(String name, DateTimeRange dates) {
    draft.name = name.trim();
    draft.dates = dates;
    saveError = null;
    notifyListeners();
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
    saveError = null;
    notifyListeners();
  }

  void addTerm(String name, DateTimeRange dates) {
    draft.terms.add(CalendarTermDraft(name: name.trim(), dates: dates));
    saveError = null;
    notifyListeners();
  }

  void removeTerm(int index) {
    if (index == draft.currentTermIndex) return;
    draft.terms.removeAt(index);
    if (draft.currentTermIndex > index) draft.currentTermIndex--;
    saveError = null;
    notifyListeners();
  }

  Future<bool> save() async {
    if (problem != null || saving) return false;
    saving = true;
    saveError = null;
    notifyListeners();
    try {
      await _service.createCalendar(organizationId, draft);
      return true;
    } catch (error, stackTrace) {
      saveError = error is StateError
          ? error.message
          : 'Could not save the calendar. Try again.';
      await handleError(
        error,
        stackTrace: stackTrace,
        context: 'CreateSession.save',
        showErrorModal: false,
      );
      return false;
    } finally {
      saving = false;
      notifyListeners();
    }
  }
}
