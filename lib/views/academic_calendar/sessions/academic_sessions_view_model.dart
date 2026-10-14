import 'package:hamrash_admin/api/models/academic_calendar/academic_session.dart';
import 'package:hamrash_admin/api/models/organization_models/member_school.dart';
import 'package:hamrash_admin/api/services/supabase_services/academic_calendar_service.dart';
import 'package:hamrash_admin/singleton_locator/locator.dart';
import 'package:hamrash_admin/viewModel/base_view_model.dart';

/// 4.0 · Every session at the school: the current one, then the rest newest
/// first. School leaders can add one; bursars only look.
class AcademicSessionsViewModel extends BaseViewModel {
  AcademicSessionsViewModel({
    required this.school,
    AcademicCalendarService? service,
    DateTime Function()? now,
  }) : _service = service ?? locator<AcademicCalendarService>(),
       _now = now ?? DateTime.now;

  final MemberSchool school;
  final AcademicCalendarService _service;
  final DateTime Function() _now;

  List<AcademicSession>? _sessions;
  Object? _error;

  Object? get error => _error;
  bool get loading => _sessions == null && _error == null;
  bool get isEmpty => _sessions?.isEmpty ?? false;

  bool get canCreate => school.canRunSetup;

  AcademicSession? get current {
    for (final session in _sessions ?? const <AcademicSession>[]) {
      if (session.isCurrent) return session;
    }
    return null;
  }

  /// Everything but the current session, newest first.
  List<AcademicSession> get others => [
    for (final session in _sessions ?? const <AcademicSession>[])
      if (!session.isCurrent) session,
  ];

  SessionStatus statusOf(AcademicSession session) => session.statusOn(_now());

  /// The start year for a new session: the year after the newest one, or
  /// null for the school's first (which follows today's date).
  int? get nextStartYear {
    final sessions = _sessions;
    if (sessions == null || sessions.isEmpty) return null;
    return sessions
            .map((session) => session.dates.start.year)
            .reduce((a, b) => a > b ? a : b) +
        1;
  }

  Future<void> load() async {
    _error = null;
    notifyListeners();
    try {
      _sessions = await _service.listSessions(school.id);
    } catch (error, stackTrace) {
      _error = error;
      await handleError(
        error,
        stackTrace: stackTrace,
        context: 'AcademicSessions.load',
        showErrorModal: false,
      );
    }
    notifyListeners();
  }

  /// Pull to refresh: keeps the list and rethrows for the error toast.
  Future<void> refresh() async {
    try {
      _sessions = await _service.listSessions(school.id);
      _error = null;
    } catch (error, stackTrace) {
      await handleError(
        error,
        stackTrace: stackTrace,
        context: 'AcademicSessions.refresh',
        showErrorModal: false,
      );
      rethrow;
    } finally {
      notifyListeners();
    }
  }
}
