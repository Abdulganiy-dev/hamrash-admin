import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/academic_calendar/calendar_draft.dart';
import 'package:hamrash_admin/api/services/supabase_services/academic_calendar_service.dart';
import 'package:hamrash_admin/singleton_locator/locator.dart';
import 'package:hamrash_admin/views/academic_calendar/session_draft_model.dart';

/// Creates a session from a suggested calendar: the school's first one from
/// setup step 2, or the next year's from the sessions list.
class CreateSessionViewModel extends SessionDraftModel {
  CreateSessionViewModel({
    required this.organizationId,
    this.startYear,
    DateTime? now,
    AcademicCalendarService? service,
  }) : _service = service ?? locator<AcademicCalendarService>(),
       _now = now ?? DateTime.now() {
    final year = startYear ?? (_now.month >= 9 ? _now.year : _now.year - 1);
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
      // The school's first session needs a current term; a later one only
      // gets one if today falls inside it.
      currentTermIndex: startYear == null ? 0 : null,
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

  /// The year the suggested session starts in, e.g. 2027 for 2027/28.
  /// Null for the school's first session, which follows today's date.
  final int? startYear;

  final AcademicCalendarService _service;
  final DateTime _now;
  @override
  late final CalendarDraft draft;
  bool saving = false;
  String? saveError;

  @override
  void draftChanged() {
    saveError = null;
    super.draftChanged();
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
