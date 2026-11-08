import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hamrash_admin/api/models/academic_calendar/academic_session.dart';
import 'package:hamrash_admin/api/models/class_structure/class_structure.dart';
import 'package:hamrash_admin/api/models/organization_models/member_school.dart';
import 'package:hamrash_admin/api/models/organization_models/organization.dart';
import 'package:hamrash_admin/api/models/organization_models/organization_member.dart';
import 'package:hamrash_admin/api/models/subjects/subject.dart';
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

  @override
  Future<AcademicSession?> getCurrentSession(String organizationId) async =>
      session;

  @override
  Future<List<SchoolSection>> getStructure(String organizationId) async =>
      sections;

  @override
  Future<List<ClassTeacher>> listClassTeachers({
    required String organizationId,
    required String sessionId,
    String? armId,
  }) async => const [];

  @override
  Future<List<ClassTeacher>> getStaffClassTeachers({
    required String organizationId,
    required String staffId,
    required String sessionId,
  }) async => const [];

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
  @override
  Future<List<Subject>> listSubjects(String organizationId) async => const [];

  @override
  Future<List<ArmSubject>> listArmSubjects(String organizationId) async =>
      const [];

  @override
  Future<List<TeachingAssignment>> listTeachingAssignments({
    required String organizationId,
    required String sessionId,
  }) async => const [];

  @override
  Future<List<TeachingAssignment>> listStaffTeachingAssignments({
    required String organizationId,
    required String staffId,
    required String sessionId,
  }) async => const [];

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

  setUp(() {
    structure = _FakeStructure(_session, _structure());
    locator.registerSingleton<ClassStructureService>(structure);
    locator.registerSingleton<SubjectService>(_FakeSubjects());
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
    expect(find.text('No lead yet'), findsOneWidget);
    await tester.tap(find.text('JSS 1A'));
    await tester.pumpAndSettle();

    expect(find.text('Nothing has been set for JSS 1A yet.'), findsOneWidget);
    await tester.tap(find.widgetWithText(AppPrimaryButton, 'Save homeroom'));
    await tester.pumpAndSettle();

    expect(structure.adds, 1);
    expect(find.text('Teaching setup'), findsNothing);
  });
}
