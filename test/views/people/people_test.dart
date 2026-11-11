import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hamrash_admin/api/models/class_structure/class_structure.dart'
    show fullArmName;
import 'package:hamrash_admin/api/models/organization_models/member_school.dart';
import 'package:hamrash_admin/api/models/organization_models/organization.dart';
import 'package:hamrash_admin/api/models/organization_models/organization_member.dart';
import 'package:hamrash_admin/api/models/students/student_summary.dart';
import 'package:hamrash_admin/api/models/team/staff_filter.dart';
import 'package:hamrash_admin/api/models/team/staff_member.dart';
import 'package:hamrash_admin/api/models/team/staff_page.dart';
import 'package:hamrash_admin/api/services/supabase_services/class_structure_service.dart';
import 'package:hamrash_admin/api/services/supabase_services/student_service.dart';
import 'package:hamrash_admin/api/services/supabase_services/team_service.dart';
import 'package:hamrash_admin/api/models/academic_calendar/academic_session.dart';
import 'package:hamrash_admin/core/widgets/app_segmented_control.dart';
import 'package:hamrash_admin/views/people/people_screen.dart';
import 'package:hamrash_admin/views/people/people_view_model.dart';
import 'package:hamrash_admin/views/people/students_view_model.dart';
import 'package:hamrash_admin/views/team/team_view_model.dart';

import '../team/staff_page_fake.dart';

class _Students implements StudentService {
  _Students(this.students);

  List<StudentSummary> students;
  Object? failWith;
  String? askedSession;

  @override
  Future<List<StudentSummary>> listStudents({
    required String organizationId,
    String? sessionId,
  }) async {
    askedSession = sessionId;
    if (failWith case final error?) throw error;
    return students;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Structure implements ClassStructureService {
  @override
  Future<AcademicSession?> getCurrentSession(String organizationId) async =>
      AcademicSession(
        id: 'sess',
        organizationId: 'kings',
        name: '2026/27',
        dates: DateTimeRange(start: DateTime(2026, 9), end: DateTime(2027, 7)),
        isCurrent: true,
        terms: const [],
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Team implements TeamService {
  _Team(this.people);

  final List<StaffMember> people;
  int reads = 0;

  @override
  Future<StaffPage> listStaffPage({
    required String organizationId,
    StaffFilter filter = StaffFilter.initial,
    int limit = TeamService.pageSize,
    String? cursor,
  }) async {
    reads++;
    return fakeStaffPage(people, filter: filter, limit: limit, cursor: cursor);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

StudentSummary _student(
  String id,
  String first, {
  String? armId,
  String? arm,
  int order = 1,
}) => StudentSummary(
  id: id,
  firstName: first,
  lastName: 'Okafor',
  admissionNumber: 'KCL/2026/$id',
  armId: armId,
  armLabel: arm,
  classOrder: order,
);

MemberSchool _school(OrganizationMemberRole role) => MemberSchool(
  organization: Organization(
    id: 'kings',
    name: 'Kings College',
    status: OrganizationStatus.trial,
    createdBy: 'platform',
    numberPrefix: 'KCL',
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  ),
  roles: [role],
);

StaffMember _staff() => StaffMember(
  id: 's1',
  firstName: 'Ngozi',
  lastName: 'Eze',
  jobTitle: 'Teacher',
  staffType: 'teaching',
  status: StaffRecordStatus.active,
  createdAt: DateTime(2026, 11, 8),
);

void main() {
  group('StudentsViewModel', () {
    test('groups by class order, then arm, with unplaced students last', () {
      final groups = StudentsViewModel.groupByArm([
        _student('1', 'Zara', armId: 'b', arm: 'JSS 2A', order: 5),
        _student('2', 'Ada', armId: 'a', arm: 'JSS 1B', order: 4),
        _student('3', 'Bayo'),
        _student('4', 'Chi', armId: 'a', arm: 'JSS 1B', order: 4),
        _student('5', 'Dara', armId: 'c', arm: 'JSS 1A', order: 4),
      ]);

      expect(groups.map((g) => g.title), [
        'JSS 1A',
        'JSS 1B',
        'JSS 2A',
        'Not in a class',
      ]);
      expect(groups[1].students.map((s) => s.firstName), ['Ada', 'Chi']);
      expect(groups[1].countLabel, '2 students');
      expect(groups[0].countLabel, '1 student');
    });

    test('loads with the current session and keeps its name', () async {
      final students = _Students([
        _student('1', 'Ada', armId: 'a', arm: 'JSS 1A'),
      ]);
      final model = StudentsViewModel(
        school: _school(OrganizationMemberRole.principal),
        students: students,
        structure: _Structure(),
      );
      await model.load();

      expect(students.askedSession, 'sess');
      expect(model.sessionName, '2026/27');
      expect(model.groups, hasLength(1));
      expect(model.isEmpty, isFalse);
      expect(model.canAdd, isTrue);
    });

    test('no students is the empty state, and a bursar cannot add', () async {
      final model = StudentsViewModel(
        school: _school(OrganizationMemberRole.bursar),
        students: _Students([]),
        structure: _Structure(),
      );
      await model.load();

      expect(model.isEmpty, isTrue);
      expect(model.canAdd, isFalse);
    });

    test('a failed load keeps the error for the retry view', () async {
      final model = StudentsViewModel(
        school: _school(OrganizationMemberRole.principal),
        students: _Students([])..failWith = Exception('offline'),
        structure: _Structure(),
      );
      await model.load();

      expect(model.error, isNotNull);
      expect(model.isEmpty, isFalse);
    });

    test('a student summary reads the placement of the current session', () {
      final json = {
        'id': 'st1',
        'first_name': 'Adaeze',
        'last_name': 'Okonkwo',
        'admission_number': 'KCL/2026/0003',
        'photo_url': null,
        'student_placements': [
          {
            'session_id': 'old',
            'arm_id': 'arm-old',
            'class_arms': {
              'name': 'A',
              'classes': {'name': 'JSS 1', 'sort_order': 4},
            },
          },
          {
            'session_id': 'sess',
            'arm_id': 'arm-new',
            'class_arms': {
              'name': 'A',
              'classes': {'name': 'JSS 2', 'sort_order': 5},
            },
          },
        ],
      };

      final student = StudentSummary.fromJson(json, sessionId: 'sess');

      expect(student.armId, 'arm-new');
      expect(student.armLabel, fullArmName('JSS 2', 'A'));
      expect(student.classOrder, 5);
      expect(student.initials, 'AO');
      expect(StudentSummary.fromJson(json).armId, isNull);
    });
  });

  group('PeopleViewModel', () {
    PeopleViewModel build(OrganizationMemberRole role, {_Team? team}) {
      final school = _school(role);
      return PeopleViewModel(
        school: school,
        students: StudentsViewModel(
          school: school,
          students: _Students([]),
          structure: _Structure(),
        ),
        team: school.canRunSetup
            ? TeamViewModel(school: school, team: team ?? _Team([_staff()]))
            : null,
      );
    }

    test('opens on Students and loads staff when its side is first shown', () {
      final team = _Team([_staff()]);
      final model = build(OrganizationMemberRole.principal, team: team);

      expect(model.side, PeopleSide.students);
      expect(model.showStaffSide, isTrue);
      expect(team.reads, 0);

      model.select(PeopleSide.staff);
      expect(model.side, PeopleSide.staff);
      expect(team.reads, 1);

      model.select(PeopleSide.students);
      model.select(PeopleSide.staff);
      expect(team.reads, 1);
      model.dispose();
    });

    test('a bursar gets Students only', () {
      final model = build(OrganizationMemberRole.bursar);

      expect(model.showStaffSide, isFalse);
      model.select(PeopleSide.staff);
      expect(model.side, PeopleSide.students);
      expect(model.team, isNull);
      model.dispose();
    });
  });

  group('PeopleScreen', () {
    Future<PeopleViewModel> pump(
      WidgetTester tester,
      OrganizationMemberRole role, {
      List<StudentSummary> students = const [],
    }) async {
      final school = _school(role);
      final model = PeopleViewModel(
        school: school,
        students: StudentsViewModel(
          school: school,
          students: _Students([...students]),
          structure: _Structure(),
        ),
        team: school.canRunSetup
            ? TeamViewModel(school: school, team: _Team([_staff()]))
            : null,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: PeopleScreen(school: school, viewModel: model),
        ),
      );
      await tester.pumpAndSettle();
      return model;
    }

    testWidgets('leaders see the Students | Staff switch on Students', (
      tester,
    ) async {
      await pump(
        tester,
        OrganizationMemberRole.principal,
        students: [_student('1', 'Ada', armId: 'a', arm: 'JSS 1A')],
      );

      expect(find.text('People'), findsOneWidget);
      expect(find.text('Kings College · 2026/27'), findsOneWidget);
      expect(find.byType(AppSegmentedControl<PeopleSide>), findsOneWidget);
      expect(find.text('JSS 1A'), findsOneWidget);
      expect(find.text('1 student'), findsOneWidget);
      expect(find.text('Ada Okafor'), findsOneWidget);
    });

    testWidgets('the Staff side shows the staff list with their roles', (
      tester,
    ) async {
      await pump(tester, OrganizationMemberRole.principal);

      await tester.tap(find.text('Staff'));
      await tester.pumpAndSettle();

      expect(find.text('Ngozi Eze'), findsOneWidget);
      expect(find.textContaining('Teacher'), findsWidgets);
    });

    testWidgets('a bursar sees Students with no switch', (tester) async {
      await pump(
        tester,
        OrganizationMemberRole.bursar,
        students: [_student('1', 'Ada', armId: 'a', arm: 'JSS 1A')],
      );

      expect(find.byType(AppSegmentedControl<PeopleSide>), findsNothing);
      expect(find.text('Ada Okafor'), findsOneWidget);
    });

    testWidgets('no students yet reads as the empty state', (tester) async {
      await pump(tester, OrganizationMemberRole.principal);

      expect(find.text('No students yet'), findsOneWidget);
      expect(find.text('Add student'), findsWidgets);
    });
  });
}
