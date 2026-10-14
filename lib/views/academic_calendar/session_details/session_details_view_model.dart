import 'package:hamrash_admin/api/models/academic_calendar/academic_session.dart';
import 'package:hamrash_admin/api/models/academic_calendar/calendar_draft.dart';
import 'package:hamrash_admin/api/models/organization_models/member_school.dart';
import 'package:hamrash_admin/api/services/supabase_services/academic_calendar_service.dart';
import 'package:hamrash_admin/core/widgets/app_alert_dialog.dart';
import 'package:hamrash_admin/singleton_locator/locator.dart';
import 'package:hamrash_admin/views/academic_calendar/session_draft_model.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 4.1–4.8 · One saved session: edit and save it, close last year's session
/// from the current one, and keep closed sessions read-only (only the owner
/// can reopen them). Bursars can look but not change anything.
class SessionDetailsViewModel extends SessionDraftModel {
  SessionDetailsViewModel({
    required this.school,
    required this.sessionId,
    AcademicCalendarService? service,
    DateTime Function()? now,
  }) : _service = service ?? locator<AcademicCalendarService>(),
       _now = now ?? DateTime.now;

  final MemberSchool school;
  final String sessionId;
  final AcademicCalendarService _service;
  final DateTime Function() _now;

  AcademicSession? _session;
  CalendarDraft? _draft;
  SessionUsage? _usage;
  AcademicSession? _toClose;
  Object? _error;
  bool _dirty = false;
  bool _changed = false;
  bool saving = false;
  String? saveError;

  AcademicSession? get session => _session;
  Object? get error => _error;
  bool get loading => _session == null && _error == null;

  @override
  CalendarDraft get draft => _draft!;

  bool get canChange => school.canRunSetup;

  @override
  bool get readOnly => !canChange || (_session?.isClosed ?? true);

  /// Unsaved edits on the page.
  bool get hasChanges => _dirty;

  /// Something was saved, closed or reopened, so the list should reload.
  bool get changed => _changed;

  SessionStatus get status => _session!.statusOn(_now());

  /// "Current session", "Closed session", …
  String get label => switch (status) {
    SessionStatus.current => 'Current session',
    SessionStatus.upcoming => 'Upcoming session',
    SessionStatus.closed => 'Closed session',
    SessionStatus.toClose || SessionStatus.open => 'Past session',
  };

  /// "Closed 20 Jul 2026" for a closed session; otherwise the summary card
  /// shows terms and weeks.
  String? get caption => switch (_session?.closedAt) {
    final DateTime closed => 'Closed ${DateFormat('d MMM y').format(closed)}',
    _ => null,
  };

  /// Only the owner reopens a closed session.
  bool get canReopen => (_session?.isClosed ?? false) && school.canEditSchool;

  /// An ended session still to close, shown on the current session (4.6).
  AcademicSession? get sessionToClose => readOnly ? null : _toClose;

  /// Why "Remove session" is greyed out, or null when it can go. Its terms
  /// go with it, so it only stays while it has the current term or anything
  /// else still uses it.
  String? get removeBlockedReason {
    final saved = _session;
    if (saved == null) return null;
    if (_dirty) return 'Save or undo your changes first.';
    if (saved.isCurrent || saved.currentTermIndex != null) {
      return 'Make another session current before removing this one.';
    }
    return _usage?.blockedReasonBesidesTerms;
  }

  @override
  void draftChanged() {
    _dirty = true;
    saveError = null;
    super.draftChanged();
  }

  Future<void> load() async {
    _error = null;
    notifyListeners();
    try {
      await _fetch();
    } catch (error, stackTrace) {
      _error = error;
      await handleError(
        error,
        stackTrace: stackTrace,
        context: 'SessionDetails.load',
        showErrorModal: false,
      );
    }
    notifyListeners();
  }

  /// Puts the page back to what's saved.
  void discardChanges() {
    final saved = _session;
    if (saved == null) return;
    _draft = CalendarDraft.fromSession(saved);
    _dirty = false;
    saveError = null;
    notifyListeners();
  }

  Future<bool> save() async {
    final saved = _session;
    if (saved == null || readOnly || !_dirty || problem != null || saving) {
      return false;
    }
    saving = true;
    saveError = null;
    notifyListeners();
    try {
      await _service.saveSession(saved, draft);
      _changed = true;
      await _fetch();
      return true;
    } catch (error, stackTrace) {
      saveError = _messageFor(error, 'Could not save the session. Try again.');
      await handleError(
        error,
        stackTrace: stackTrace,
        context: 'SessionDetails.save',
        showErrorModal: false,
      );
      // Some steps may have saved; show what the database now holds.
      await _fetch().catchError((_) {});
      return false;
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  /// For [AppConfirmSheet.onConfirm]: throws [AppAlertError] to keep the
  /// sheet open with the database's reason.
  Future<void> closeSessionToClose() => _act(
    () => _service.closeSession(_toClose!.id),
    'Could not close the session. Try again.',
  );

  Future<void> reopen() => _act(
    () => _service.reopenSession(sessionId),
    'Could not reopen the session. Try again.',
  );

  Future<void> deleteSession() => _act(
    () => _service.deleteSession(_session!),
    'Could not remove the session. Try again.',
    reload: false,
  );

  Future<void> _act(
    Future<void> Function() action,
    String fallback, {
    bool reload = true,
  }) async {
    try {
      await action();
      _changed = true;
      if (reload) await _fetch();
    } catch (error, stackTrace) {
      await handleError(
        error,
        stackTrace: stackTrace,
        context: 'SessionDetails.action',
        showErrorModal: false,
      );
      throw AppAlertError(_messageFor(error, fallback));
    } finally {
      notifyListeners();
    }
  }

  Future<void> _fetch() async {
    final session = await _service.getSession(sessionId);
    _session = session;
    _draft = CalendarDraft.fromSession(session);
    _dirty = false;
    _usage = null;
    _toClose = null;
    if (!canChange || session.isClosed) return;

    final results = await Future.wait<Object?>([
      _optional(_service.getUsage(sessionId)),
      if (session.isCurrent)
        _optional(_service.listSessions(session.organizationId)),
    ]);
    _usage = results[0] as SessionUsage?;
    final all = session.isCurrent ? results[1] as List<AcademicSession>? : null;
    if (all != null) {
      final today = _now();
      for (final other in all) {
        if (other.id != session.id &&
            other.statusOn(today) == SessionStatus.toClose) {
          _toClose = other;
          break;
        }
      }
    }
  }

  /// Our own database rules raise readable messages (P0001, and 23514 for
  /// date checks); anything else gets [fallback].
  static String _messageFor(Object error, String fallback) =>
      error is PostgrestException &&
          (error.code == 'P0001' || error.code == '23514')
      ? error.message
      : fallback;

  static Future<T?> _optional<T>(Future<T?> request) async {
    try {
      return await request;
    } catch (_) {
      return null;
    }
  }
}
