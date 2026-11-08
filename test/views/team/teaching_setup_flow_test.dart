import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hamrash_admin/api/models/academic_calendar/academic_session.dart';
import 'package:hamrash_admin/api/models/class_structure/class_structure.dart';
import 'package:hamrash_admin/api/models/organization_models/member_school.dart';
import 'package:hamrash_admin/api/models/organization_models/organization.dart';
import 'package:hamrash_admin/api/models/organization_models/organization_member.dart';
import 'package:hamrash_admin/api/models/team/staff_member.dart';
import 'package:hamrash_admin/api/models/team/teaching.dart';
import 'package:hamrash_admin/api/services/supabase_services/class_structure_service.dart';
import 'package:hamrash_admin/api/services/supabase_services/subject_service.dart';
import 'package:hamrash_admin/api/services/supabase_services/team_service.dart';
import 'package:hamrash_admin/core/widgets/app_icons.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_variants.dart';
import 'package:hamrash_admin/core/widgets/pickers/app_picker_field.dart';
import 'package:hamrash_admin/singleton_locator/locator.dart';
import 'package:hamrash_admin/views/team/staff_detail/staff_detail_screen.dart';
import 'package:hamrash_admin/views/team/widgets/staff_info_section.dart';

class _FakeTeam implements TeamService {
  _FakeTeam(this.member);

  final StaffMember member;

  @override
  Future<StaffMember> getStaff(String staffId) async => member;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeStructure implements ClassStructureService {
  _FakeStructure(this.session, this.sections);

  final AcademicSession session;
  final List<SchoolSection> sections;
  int adds = 0;
  int homeroomReads = 0;
  int sessionReads = 0;
  int structureReads = 0;
  int rosterReads = 0;
  List<ClassTeacher> staffRows = const [];

  @override
  Future<AcademicSession?> getCurrentSession(String organizationId) async {
    sessionReads++;
    return session;
  }

  @override
  Future<List<SchoolSection>> getStructure(String organizationId) async {
    structureReads++;
    return sections;
  }

  @override
  Future<List<ClassTeacher>> listArmClassTeachers({
    required String organizationId,
    required String sessionId,
    required String armId,
  }) async {
    rosterReads++;
    return const [];
  }

  @override
  Future<List<ClassTeacher>> getStaffHomerooms({
    required String organizationId,
    required String staffId,
  }) async {
    homeroomReads++;
    return staffRows;
  }

  @override
  Future<void> addClassTeacher({
    required String organizationId,
    required String sessionId,
    required String armId,
    required String staffId,
    required bool isLead,
  }) async {
    adds++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSubjects implements SubjectService {
  List<TeachingAssignment> staffAssignments = const [];
  int subjectReads = 0;
  int offeringReads = 0;
  int assignmentReads = 0;

  @override
  Future<List<TeachingAssignment>> getStaffSubjects({
    required String organizationId,
    required String staffId,
  }) async {
    subjectReads++;
    return staffAssignments;
  }

  @override
  Future<List<SubjectOffering>> listArmOfferings({
    required String organizationId,
    required String armId,
  }) async {
    offeringReads++;
    return const [
      SubjectOffering(
        subjectId: 'maths',
        name: 'Mathematics',
        isCompulsory: true,
        sortOrder: 1,
      ),
    ];
  }

  @override
  Future<List<TeachingAssignment>> listArmTeachingAssignments({
    required String organizationId,
    required String sessionId,
    required String armId,
  }) async {
    assignmentReads++;
    return const [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

MemberSchool _school() => MemberSchool(
  organization: Organization(
    id: 'school',
    name: 'Kings College',
    status: OrganizationStatus.trial,
    createdBy: 'platform',
    numberPrefix: 'KCL',
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  ),
  roles: const [OrganizationMemberRole.admin],
);

StaffMember _staff({String staffType = 'teaching'}) => StaffMember(
  id: 'staff',
  firstName: 'Ngozi',
  lastName: 'Eze',
  staffType: staffType,
  status: StaffRecordStatus.active,
  createdAt: DateTime(2026, 9, 1),
);

List<SchoolSection> _structure() => [
  SchoolSection(
    id: 'section',
    name: 'Junior',
    sortOrder: 1,
    isActive: true,
    classes: [
      SchoolClass(
        id: 'class',
        sectionId: 'section',
        name: 'JSS 1',
        sortOrder: 1,
        isGraduating: false,
        isActive: true,
        arms: [
          ClassArm(
            id: 'arm',
            classId: 'class',
            name: 'A',
            isActive: true,
            createdAt: DateTime(2026, 9, 1),
          ),
        ],
      ),
    ],
  ),
];

final _session = AcademicSession(
  id: 'session',
  organizationId: 'school',
  name: '2026/27',
  dates: DateTimeRange(start: DateTime(2026, 9, 7), end: DateTime(2027, 7, 16)),
  isCurrent: true,
  terms: const [],
);

void main() {
  late _FakeStructure structure;
  late _FakeSubjects subjects;

  setUp(() {
    structure = _FakeStructure(_session, _structure());
    subjects = _FakeSubjects();
    locator.registerSingleton<ClassStructureService>(structure);
    locator.registerSingleton<SubjectService>(subjects);
  });

  tearDown(locator.reset);

  Future<void> pump(WidgetTester tester, StaffMember member) async {
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    locator.registerSingleton<TeamService>(_FakeTeam(member));
    await tester.pumpWidget(
      MaterialApp(
        home: StaffDetailScreen(school: _school(), staffId: member.id),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('teaching staff open the setup sheet', (tester) async {
    await pump(tester, _staff());

    expect(find.byIcon(AppIcons.graduationCap), findsOneWidget);
    await tester.tap(find.byIcon(AppIcons.graduationCap));
    await tester.pumpAndSettle();

    expect(find.text('Teaching setup'), findsOneWidget);
    expect(find.text('2026/27 · current session'), findsOneWidget);
    expect(find.text('Set homeroom'), findsOneWidget);
    expect(find.text('Not set'), findsOneWidget);
    expect(find.text('Set subject'), findsOneWidget);
    expect(find.text('None this session'), findsOneWidget);
  });

  testWidgets('the staff page lists the class and subjects they teach', (
    tester,
  ) async {
    structure.staffRows = const [
      ClassTeacher(
        sessionId: 'session',
        armId: 'arm',
        staffId: 'staff',
        isLead: true,
        staffName: 'Ngozi Eze',
        className: 'JSS 1',
        armName: 'A',
        sessionName: '2026/27',
      ),
    ];
    subjects.staffAssignments = const [
      TeachingAssignment(
        sessionId: 'session',
        armId: 'arm',
        subjectId: 'maths',
        staffId: 'staff',
        staffName: 'Ngozi Eze',
        subjectName: 'Mathematics',
        className: 'JSS 1',
        armName: 'A',
      ),
    ];
    await pump(tester, _staff());

    expect(find.widgetWithText(StaffSectionTitle, 'Teaching'), findsOneWidget);
    expect(find.text('2026/27'), findsOneWidget);
    expect(find.text('Lead teacher'), findsOneWidget);
    expect(find.text('Mathematics'), findsOneWidget);
    expect(find.text('JSS 1A'), findsNWidgets(2));
  });

  testWidgets('a non-teaching record has no Teaching card', (tester) async {
    await pump(tester, _staff(staffType: 'non_teaching'));
    expect(find.widgetWithText(StaffSectionTitle, 'Teaching'), findsNothing);
  });

  testWidgets('a non-teaching record has no teaching action', (tester) async {
    await pump(tester, _staff(staffType: 'non_teaching'));

    expect(find.byIcon(AppIcons.graduationCap), findsNothing);
  });

  testWidgets('the homeroom sheet inserts a new lead', (tester) async {
    await pump(tester, _staff());
    await tester.tap(find.byIcon(AppIcons.graduationCap));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Set homeroom'));
    await tester.pumpAndSettle();

    expect(
      find.text('Choose a class and arm to set a homeroom.'),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(AppPickerField, 'Class'));
    await tester.pumpAndSettle();
    expect(find.text('1 arms'), findsOneWidget);
    await tester.tap(find.text('JSS 1'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(AppPickerField, 'Arm'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('JSS 1A'));
    await tester.pumpAndSettle();

    expect(find.text('Nothing has been set for JSS 1A yet.'), findsOneWidget);
    await tester.tap(find.widgetWithText(AppPrimaryButton, 'Save homeroom'));
    await tester.pumpAndSettle();

    expect(structure.adds, 1);
    expect(find.text('Teaching setup'), findsNothing);
  });

  testWidgets('each step reads only what it needs', (tester) async {
    await pump(tester, _staff());

    // The page: two reads, nothing else.
    expect(structure.homeroomReads, 1);
    expect(subjects.subjectReads, 1);
    expect(structure.sessionReads, 0);
    expect(structure.structureReads, 0);

    // The menu: the session.
    await tester.tap(find.byIcon(AppIcons.graduationCap));
    await tester.pumpAndSettle();
    expect(structure.sessionReads, 1);
    expect(structure.structureReads, 0);

    // The homeroom sheet: the classes, then the roster once an arm is chosen.
    await tester.tap(find.text('Set homeroom'));
    await tester.pumpAndSettle();
    expect(structure.structureReads, 1);
    expect(structure.rosterReads, 0);
    await tester.tap(find.widgetWithText(AppPickerField, 'Class'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('JSS 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(AppPickerField, 'Arm'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('JSS 1A'));
    await tester.pumpAndSettle();
    expect(structure.rosterReads, 1);
    expect(subjects.offeringReads, 0);

    // Back out; the subject sheet reuses the classes already read.
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Set subject'));
    await tester.pumpAndSettle();
    expect(structure.structureReads, 1);
    expect(subjects.offeringReads, 0);
    await tester.tap(find.widgetWithText(AppPickerField, 'Class'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('JSS 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(AppPickerField, 'Arm'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('JSS 1A'));
    await tester.pumpAndSettle();
    expect(subjects.offeringReads, 1);
    expect(subjects.assignmentReads, 1);
    expect(structure.structureReads, 1);
  });
}
