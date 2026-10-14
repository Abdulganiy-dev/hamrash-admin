import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hamrash_admin/api/models/academic_calendar/academic_session.dart';
import 'package:hamrash_admin/api/models/academic_calendar/calendar_draft.dart';
import 'package:hamrash_admin/api/models/organization_models/member_school.dart';
import 'package:hamrash_admin/api/models/organization_models/organization.dart';
import 'package:hamrash_admin/api/models/organization_models/organization_member.dart';
import 'package:hamrash_admin/api/services/supabase_services/academic_calendar_service.dart';
import 'package:hamrash_admin/views/academic_calendar/create_session/create_session_view_model.dart';
import 'package:hamrash_admin/views/academic_calendar/session_details/session_details_view_model.dart';
import 'package:hamrash_admin/views/academic_calendar/sessions/academic_sessions_view_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

DateTimeRange _range(String start, String end) =>
    DateTimeRange(start: DateTime.parse(start), end: DateTime.parse(end));

AcademicTerm _term(
  String id,
  int sequence,
  String start,
  String end, {
  bool current = false,
}) => AcademicTerm(
  id: id,
  name: ['First term', 'Second term', 'Third term'][sequence - 1],
  sequence: sequence,
  dates: _range(start, end),
  isCurrent: current,
);

AcademicSession _thisYear({bool currentTerm = true}) => AcademicSession(
  id: 'now',
  organizationId: 'kings',
  name: '2026/27',
  dates: _range('2026-09-07', '2027-07-16'),
  isCurrent: currentTerm,
  terms: [
    _term('t1', 1, '2026-09-07', '2026-12-11', current: currentTerm),
    _term('t2', 2, '2027-01-04', '2027-04-01'),
    _term('t3', 3, '2027-04-26', '2027-07-16'),
  ],
);

final _lastYear = AcademicSession(
  id: 'last',
  organizationId: 'kings',
  name: '2025/26',
  dates: _range('2025-09-08', '2026-07-17'),
  isCurrent: false,
  terms: [_term('l1', 1, '2025-09-08', '2025-12-12')],
);

final _closedYear = AcademicSession(
  id: 'closed',
  organizationId: 'kings',
  name: '2024/25',
  dates: _range('2024-09-09', '2025-07-18'),
  isCurrent: false,
  closedAt: DateTime(2025, 7, 20),
  terms: [_term('c1', 1, '2024-09-09', '2024-12-13')],
);

class _Calendar extends AcademicCalendarService {
  _Calendar(this.sessions)
    : super(SupabaseClient('https://example.supabase.co', 'test-key'));

  final List<AcademicSession> sessions;
  SessionUsage usage = const SessionUsage(
    terms: 1,
    placements: 0,
    studentSubjects: 0,
    classTeachers: 0,
    teachingAssignments: 0,
  );
  CalendarDraft? savedDraft;
  String? closedId;

  @override
  Future<List<AcademicSession>> listSessions(String organizationId) async =>
      sessions;

  @override
  Future<AcademicSession> getSession(String sessionId) async =>
      sessions.singleWhere((session) => session.id == sessionId);

  @override
  Future<SessionUsage> getUsage(String sessionId) async => usage;

  @override
  Future<void> saveSession(
    AcademicSession original,
    CalendarDraft draft,
  ) async {
    savedDraft = draft;
  }

  @override
  Future<void> closeSession(String sessionId) async => closedId = sessionId;
}

MemberSchool _school(OrganizationMemberRole role) => MemberSchool(
  organization: Organization(
    id: 'kings',
    code: 'HMR-000001',
    name: 'Kings College',
    status: OrganizationStatus.trial,
    createdBy: 'platform',
    numberPrefix: 'KCL',
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  ),
  roles: [role],
);

DateTime _october() => DateTime(2026, 10, 13);

void main() {
  group('AcademicSession', () {
    test('reads a session with its terms in order', () {
      final session = AcademicSession.fromJson({
        'id': 's',
        'organization_id': 'kings',
        'name': '2026/27',
        'starts_on': '2026-09-07',
        'ends_on': '2027-07-16',
        'is_current': true,
        'closed_at': null,
        'terms': [
          {
            'id': 'b',
            'name': 'Second term',
            'sequence': 2,
            'starts_on': '2027-01-04',
            'ends_on': '2027-04-01',
            'is_current': false,
          },
          {
            'id': 'a',
            'name': 'First term',
            'sequence': 1,
            'starts_on': '2026-09-07',
            'ends_on': '2026-12-11',
            'is_current': true,
          },
        ],
      });
      expect(session.terms.map((term) => term.id), ['a', 'b']);
      expect(session.currentTermIndex, 0);
      expect(session.isClosed, isFalse);
    });

    test('works out its status from the date', () {
      expect(_thisYear().statusOn(_october()), SessionStatus.current);
      expect(_lastYear.statusOn(_october()), SessionStatus.toClose);
      expect(_closedYear.statusOn(_october()), SessionStatus.closed);
      expect(
        _thisYear(currentTerm: false).statusOn(DateTime(2026, 8, 1)),
        SessionStatus.upcoming,
      );
    });
  });

  group('CreateSessionViewModel', () {
    test("the school's first session gets a current term", () {
      final model = CreateSessionViewModel(
        organizationId: 'kings',
        now: _october(),
        service: _Calendar(const []),
      );
      expect(model.draft.name, '2026/27');
      expect(model.draft.currentTermIndex, 0);
    });

    test('next year set up early has no current term yet', () {
      final model = CreateSessionViewModel(
        organizationId: 'kings',
        startYear: 2027,
        now: _october(),
        service: _Calendar(const []),
      );
      expect(model.draft.name, '2027/28');
      expect(model.draft.currentTermIndex, isNull);
      expect(model.problem, isNull);
    });
  });

  group('AcademicSessionsViewModel', () {
    test('puts the current session first and suggests the next year', () async {
      final model = AcademicSessionsViewModel(
        school: _school(OrganizationMemberRole.principal),
        service: _Calendar([_thisYear(), _lastYear, _closedYear]),
        now: _october,
      );
      await model.load();
      expect(model.current?.id, 'now');
      expect(model.others.map((s) => s.id), ['last', 'closed']);
      expect(model.nextStartYear, 2027);
      expect(model.canCreate, isTrue);
    });

    test('bursars only look', () async {
      final model = AcademicSessionsViewModel(
        school: _school(OrganizationMemberRole.bursar),
        service: _Calendar(const []),
      );
      await model.load();
      expect(model.isEmpty, isTrue);
      expect(model.canCreate, isFalse);
    });
  });

  group('SessionDetailsViewModel', () {
    SessionDetailsViewModel details(
      String id,
      _Calendar service, {
      OrganizationMemberRole role = OrganizationMemberRole.principal,
    }) => SessionDetailsViewModel(
      school: _school(role),
      sessionId: id,
      service: service,
      now: _october,
    );

    test('edits are tracked and saved, then reloaded', () async {
      final service = _Calendar([_thisYear(), _lastYear]);
      final model = details('now', service);
      await model.load();

      expect(model.label, 'Current session');
      expect(model.readOnly, isFalse);
      expect(model.hasChanges, isFalse);

      model.editTerm(
        1,
        'Second term',
        _range('2027-01-05', '2027-04-01'),
        isCurrent: false,
      );
      expect(model.hasChanges, isTrue);
      expect(model.removeBlockedReason, 'Save or undo your changes first.');

      expect(await model.save(), isTrue);
      expect(service.savedDraft?.terms[1].dates.start, DateTime(2027, 1, 5));
      expect(model.hasChanges, isFalse);
      expect(model.changed, isTrue);
    });

    test('undo puts the saved session back', () async {
      final model = details('now', _Calendar([_thisYear()]));
      await model.load();
      model.editSession('2026/2027', model.draft.dates);
      model.discardChanges();
      expect(model.draft.name, '2026/27');
      expect(model.hasChanges, isFalse);
    });

    test('the current session offers to close last year', () async {
      final service = _Calendar([_thisYear(), _lastYear, _closedYear]);
      final model = details('now', service);
      await model.load();
      expect(model.sessionToClose?.id, 'last');

      await model.closeSessionToClose();
      expect(service.closedId, 'last');
      expect(model.changed, isTrue);
    });

    test("the current session can't be removed", () async {
      final model = details('now', _Calendar([_thisYear()]));
      await model.load();
      expect(
        model.removeBlockedReason,
        'Make another session current before removing this one.',
      );
    });

    test('a session nothing else uses can be removed with its terms', () async {
      final service = _Calendar([_lastYear]);
      final model = details('last', service);
      await model.load();
      expect(model.removeBlockedReason, isNull);

      service.usage = const SessionUsage(
        terms: 1,
        placements: 12,
        studentSubjects: 0,
        classTeachers: 0,
        teachingAssignments: 0,
      );
      await model.load();
      expect(
        model.removeBlockedReason,
        '12 students are placed in classes for it.',
      );
    });

    test('closed sessions are read-only; only the owner reopens', () async {
      final calendar = _Calendar([_closedYear]);
      final principal = details('closed', calendar);
      await principal.load();
      expect(principal.readOnly, isTrue);
      expect(principal.label, 'Closed session');
      expect(principal.caption, 'Closed 20 Jul 2025');
      expect(principal.canReopen, isFalse);

      final owner = details(
        'closed',
        calendar,
        role: OrganizationMemberRole.owner,
      );
      await owner.load();
      expect(owner.canReopen, isTrue);
    });

    test('bursars see an open session read-only', () async {
      final model = details(
        'now',
        _Calendar([_thisYear(), _lastYear]),
        role: OrganizationMemberRole.bursar,
      );
      await model.load();
      expect(model.readOnly, isTrue);
      expect(model.sessionToClose, isNull);
      expect(await model.save(), isFalse);
    });
  });
}
