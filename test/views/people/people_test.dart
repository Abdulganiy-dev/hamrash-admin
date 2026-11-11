import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hamrash_admin/api/models/class_structure/class_structure.dart';
import 'package:hamrash_admin/api/models/organization_models/member_school.dart';
import 'package:hamrash_admin/api/models/organization_models/organization.dart';
import 'package:hamrash_admin/api/models/organization_models/organization_member.dart';
import 'package:hamrash_admin/api/models/students/student_filter.dart';
import 'package:hamrash_admin/api/models/students/student_summary.dart';
import 'package:hamrash_admin/api/models/team/staff_filter.dart';
import 'package:hamrash_admin/api/models/team/staff_member.dart';
import 'package:hamrash_admin/api/models/team/staff_page.dart';
import 'package:hamrash_admin/api/services/supabase_services/class_structure_service.dart';
import 'package:hamrash_admin/api/services/supabase_services/student_service.dart';
import 'package:hamrash_admin/api/services/supabase_services/subject_service.dart';
import 'package:hamrash_admin/api/models/subjects/subject.dart';
import 'package:hamrash_admin/views/people/people_filter_options.dart';
import 'package:hamrash_admin/views/people/widgets/student_filter_sheet.dart';
import 'package:hamrash_admin/views/team/widgets/staff_filter_sheet.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_variants.dart';
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

  /// Every student the fake knows, already in class order.
  List<StudentSummary> students;
  Object? failWith;
  final calls = <({StudentFilter filter, String? cursor, int limit})>[];

  @override
  Future<StudentPage> listStudentsPage({
    required String organizationId,
    StudentFilter filter = StudentFilter.initial,
    int limit = StudentService.pageSize,
    String? cursor,
  }) async {
    calls.add((filter: filter, cursor: cursor, limit: limit));
    if (failWith case final error?) throw error;
    final subject = filter.subject;
    final matching = [
      for (final student in students)
        if ((filter.schoolClass == null ||
                student.armLabel?.startsWith(filter.schoolClass!.label) ==
                    true) &&
            (subject == null || student.subject?.id == subject.id))
          student,
    ];
    final start = cursor == null ? 0 : int.parse(cursor);
    final end = (start + limit).clamp(0, matching.length);
    final counts = <String, int>{};
    for (final student in matching) {
      counts.update(student.armId ?? '', (n) => n + 1, ifAbsent: () => 1);
    }
    return StudentPage(
      rows: matching.sublist(start.clamp(0, matching.length), end),
      nextCursor: end < matching.length ? '$end' : null,
      total: matching.length,
      groupCounts: counts,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Structure implements ClassStructureService {
  @override
  Future<List<SchoolSection>> getStructure(String organizationId) async => [
    SchoolSection(
      id: 'sec',
      name: 'Secondary',
      sortOrder: 1,
      isActive: true,
      classes: [
        SchoolClass(
          id: 'c1',
          sectionId: 'sec',
          name: 'JSS 1',
          sortOrder: 1,
          isGraduating: false,
          isActive: true,
          arms: [
            ClassArm(
              id: 'a1',
              classId: 'c1',
              name: 'A',
              isActive: true,
              createdAt: DateTime(2026),
            ),
            ClassArm(
              id: 'a2',
              classId: 'c1',
              name: 'B',
              isActive: false,
              createdAt: DateTime(2026),
            ),
          ],
        ),
      ],
    ),
  ];

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

class _Subjects implements SubjectService {
  @override
  Future<List<Subject>> listSubjects(String organizationId) async => const [
    Subject(
      id: 'm',
      name: 'Mathematics',
      code: 'MTH',
      sortOrder: 2,
      isActive: true,
    ),
    Subject(id: 'a', name: 'Art', code: 'ART', sortOrder: 1, isActive: true),
    Subject(id: 'x', name: 'Old', code: 'OLD', sortOrder: 3, isActive: false),
  ];

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

extension on StudentSummary {
  StudentSummary copyWithSubject(StudentSubject subject) => StudentSummary(
    id: id,
    firstName: firstName,
    lastName: lastName,
    admissionNumber: admissionNumber,
    armId: armId,
    armLabel: armLabel,
    classOrder: classOrder,
    subject: subject,
  );
}

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
    StudentsViewModel build(
      _Students students, {
      OrganizationMemberRole role = OrganizationMemberRole.principal,
    }) => StudentsViewModel(
      school: _school(role),
      students: students,
      structure: _Structure(),
    );

    final all = [
      _student('1', 'Ada', armId: 'a', arm: 'JSS 1A'),
      _student('2', 'Bayo', armId: 'a', arm: 'JSS 1A'),
      _student('3', 'Chi', armId: 'b', arm: 'JSS 1B', order: 1),
      _student('4', 'Dara', armId: 'c', arm: 'JSS 2A', order: 2),
      _student('5', 'Eze'),
    ];

    test(
      'groups the loaded rows by arm; headers count the whole arm',
      () async {
        final model = build(_Students(all));
        await model.load();

        expect(model.groups.map((g) => g.title), [
          'JSS 1A',
          'JSS 1B',
          'JSS 2A',
          'Not in a class',
        ]);
        expect(model.groups.first.students.map((s) => s.firstName), [
          'Ada',
          'Bayo',
        ]);
        expect(model.groups.first.countLabel, '2 students');
        expect(model.groups[1].countLabel, '1 student');
        expect(model.sessionName, '2026/27');
      },
    );

    test(
      'pages load as you scroll and an arm split across pages stays one group',
      () async {
        final fake = _Students(all);
        final model = build(fake);
        await model.load();
        // page size is 30, so make the next page by hand: two at a time
        expect(fake.calls.single.cursor, isNull);

        fake.students = [
          for (var i = 0; i < 5; i++)
            _student('$i', 'S$i', armId: 'a', arm: 'JSS 1A'),
        ];
        final small = build(fake);
        await small.load();
        expect(small.groups, hasLength(1));
      },
    );

    test('loading more adds under what is there, once each', () async {
      final many = [
        for (var i = 0; i < 70; i++)
          _student('$i', 'S$i', armId: 'a', arm: 'JSS 1A'),
      ];
      final fake = _Students(many);
      final model = build(fake);
      await model.load();

      expect(model.students, hasLength(30));
      expect(model.hasMore, isTrue);
      expect(model.total, 70);
      await model.loadMore();
      await model.loadMore();
      expect(model.students, hasLength(70));
      expect(model.hasMore, isFalse);
      expect(model.groups.single.countLabel, '70 students');
      expect(fake.calls.map((c) => c.cursor), [null, '30', '60']);
      // no more pages: nothing else is asked
      await model.loadMore();
      expect(fake.calls, hasLength(3));
    });

    test('a failed page keeps the rows and offers a retry', () async {
      final many = [
        for (var i = 0; i < 40; i++)
          _student('$i', 'S$i', armId: 'a', arm: 'JSS 1A'),
      ];
      final fake = _Students(many);
      final model = build(fake);
      await model.load();
      fake.failWith = Exception('offline');

      await model.loadMore();

      expect(model.loadMoreError, isNotNull);
      expect(model.students, hasLength(30));
      fake.failWith = null;
      await model.retryLoadMore();
      expect(model.students, hasLength(40));
    });

    test('changing the filter starts again from page 1', () async {
      final fake = _Students(all);
      final model = build(fake);
      await model.load();

      await model.applyFilter(
        model.filter.copyWith(schoolClass: const FilterPick('c1', 'JSS 1')),
      );

      expect(fake.calls.last.cursor, isNull);
      expect(fake.calls.last.filter.schoolClass?.label, 'JSS 1');
      expect(model.students.map((s) => s.firstName), ['Ada', 'Bayo', 'Chi']);
      expect(model.filter.activeCount, 1);
      // the same filter again asks nothing
      final before = fake.calls.length;
      await model.applyFilter(model.filter);
      expect(fake.calls, hasLength(before));
    });

    test(
      'nobody matching is the no-results state, and clearing restores them',
      () async {
        final model = build(_Students(all));
        await model.load();
        await model.applyFilter(
          model.filter.copyWith(subject: const FilterPick('nope', 'Latin')),
        );

        expect(model.showNoResults, isTrue);
        expect(model.isEmpty, isFalse);
        await model.clearFilters();
        expect(model.showNoResults, isFalse);
        expect(model.students, hasLength(5));
      },
    );

    test('a subject filter names the subject and the arm\'s teacher', () async {
      const maths = StudentSubject(
        id: 'maths',
        name: 'Mathematics',
        isCompulsory: true,
        teacherFirstName: 'John',
        teacherLastName: 'Bello',
      );
      const noTeacher = StudentSubject(
        id: 'maths',
        name: 'Mathematics',
        isCompulsory: true,
      );
      final model = build(_Students(const []));

      expect(
        model.subtitleFor(_student('1', 'Ada').copyWithSubject(maths)),
        'Mathematics · Teacher: John Bello',
      );
      expect(
        model.subtitleFor(_student('1', 'Ada').copyWithSubject(noTeacher)),
        'Mathematics · No teacher assigned yet',
      );
      expect(model.subtitleFor(_student('1', 'Ada')), 'KCL/2026/1');
    });

    test(
      'no students at all is the empty state, and a bursar cannot add',
      () async {
        final model = build(_Students([]), role: OrganizationMemberRole.bursar);
        await model.load();

        expect(model.isEmpty, isTrue);
        expect(model.canAdd, isFalse);
      },
    );

    test('a failed load keeps the error for the retry view', () async {
      final model = build(_Students([])..failWith = Exception('offline'));
      await model.load();

      expect(model.error, isNotNull);
      expect(model.isEmpty, isFalse);
    });

    test('the RPC row shape is read: arm, subject and teacher', () {
      final student = StudentSummary.fromJson({
        'id': 'st1',
        'first_name': 'Adaeze',
        'last_name': 'Okonkwo',
        'admission_number': 'KCL/2026/0003',
        'photo_url': null,
        'arm': {
          'id': 'arm-1',
          'name': 'A',
          'class_id': 'c1',
          'class_name': 'JSS 2',
          'section_id': 's1',
          'class_sort_order': 5,
        },
        'subject': {
          'id': 'maths',
          'name': 'Mathematics',
          'is_compulsory': false,
          'teacher': {'id': 't1', 'first_name': 'John', 'last_name': 'Bello'},
        },
      });

      expect(student.armLabel, fullArmName('JSS 2', 'A'));
      expect(student.classOrder, 5);
      expect(student.initials, 'AO');
      expect(student.subject?.teacherName, 'John Bello');
      expect(student.subject?.isCompulsory, isFalse);
      final bare = StudentSummary.fromJson({
        'id': 'st2',
        'first_name': 'Gina',
        'last_name': 'Zubair',
        'admission_number': 'KCL/2026/0009',
        'arm': null,
        'subject': {
          'id': 'maths',
          'name': 'Mathematics',
          'is_compulsory': true,
          'teacher': null,
        },
      });
      expect(bare.armId, isNull);
      expect(bare.subject?.hasTeacher, isFalse);
    });

    test('filter chips read and each takes only itself off', () {
      const filter = StudentFilter(
        search: ' ada ',
        schoolClass: FilterPick('c1', 'JSS 1'),
        arm: FilterPick('a1', 'A'),
        subject: FilterPick('m', 'Mathematics'),
        statuses: {StudentStatusFilter.active, StudentStatusFilter.withdrawn},
        sort: StudentSort.name,
      );

      expect(filter.chips.map((c) => c.label), [
        '“ada”',
        'JSS 1',
        'Arm A',
        'Mathematics',
        'Active',
        'Withdrawn',
        'Name A–Z',
      ]);
      expect(filter.chips[1].without.arm, isNull); // class off drops its arm
      expect(filter.chips[3].without.subject, isNull);
      expect(filter.chips[3].without.schoolClass?.label, 'JSS 1');
      expect(StudentFilter.initial.isDefault, isTrue);
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

  group('filter sheets', () {
    Future<PeopleFilterOptions> options() => PeopleFilterOptionsLoader(
      organizationId: 'kings',
      structure: _Structure(),
      subjects: _Subjects(),
    ).load();

    test(
      'options hold active classes, their active arms and subjects A to Z',
      () async {
        final loaded = await options();

        expect(loaded.classes.map((c) => c.label), ['JSS 1']);
        expect(loaded.armsIn(loaded.classes.first).map((a) => a.label), ['A']);
        expect(loaded.subjects.map((s) => s.label), ['Art', 'Mathematics']);
      },
    );

    testWidgets('students: pick a subject and show results', (tester) async {
      final loaded =
          await tester.runAsync(options) ?? PeopleFilterOptions.empty;
      StudentFilter? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async => result = await StudentFilterSheet.show(
                context,
                initial: StudentFilter.initial,
                options: loaded,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('Filter students'), findsOneWidget);
      expect(find.text('Any subject'), findsOneWidget);
      // Arms only show once a class is picked.
      expect(find.text('All arms'), findsNothing);
      await tester.tap(find.text('JSS 1'));
      await tester.pumpAndSettle();
      expect(find.text('Arm in JSS 1'), findsOneWidget);

      await tester.tap(find.text('Any subject'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mathematics'));
      await tester.pumpAndSettle();
      expect(find.text('Mathematics'), findsOneWidget);

      await tester.tap(find.widgetWithText(AppPrimaryButton, 'Show results'));
      await tester.pumpAndSettle();
      expect(result?.subject, const FilterPick('m', 'Mathematics'));
      expect(result?.schoolClass?.label, 'JSS 1');
    });

    testWidgets('staff: the Teaches section picks a subject and a class', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 2600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final loaded =
          await tester.runAsync(options) ?? PeopleFilterOptions.empty;
      StaffFilter? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async => result = await StaffFilterSheet.show(
                context,
                initial: StaffFilter.initial,
                options: loaded,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('Teaches'), findsOneWidget);
      await tester.tap(find.text('Any subject'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Art'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Any class'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('JSS 1'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(AppPrimaryButton, 'Show results'));
      await tester.pumpAndSettle();

      expect(result?.subject?.label, 'Art');
      expect(result?.schoolClass?.label, 'JSS 1');
      expect(result?.chips.map((c) => c.label), ['Teaches Art', 'In JSS 1']);
      expect(result?.isTeachingFilter, isTrue);
    });

    testWidgets('staff: no Teaches section when the school has no subjects', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () =>
                  StaffFilterSheet.show(context, initial: StaffFilter.initial),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('Teaches'), findsNothing);
      expect(find.text('Login'), findsOneWidget);
    });
  });
}
