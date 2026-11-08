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
import 'package:hamrash_admin/views/team/staff_teaching/teaching_setup_view_model.dart';

/// The reads the view model loads, plus the two writes each sheet makes.
/// The roster and the single assignment are what the write's fresh read
/// answers, so a test can put the row in place first.
class _FakeStructure implements ClassStructureService {
  _FakeStructure({required this.session, required this.sections});

  AcademicSession? session;
  List<SchoolSection> sections;
  List<ClassTeacher> roster = const [];

  int adds = 0;
  int updates = 0;
  bool? addedIsLead;
  bool? updatedIsLead;

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
  }) async => roster;

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
    addedIsLead = isLead;
  }

  @override
  Future<void> updateClassTeacherRole(
    ClassTeacher row, {
    required bool isLead,
  }) async {
    updates++;
    updatedIsLead = isLead;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSubjects implements SubjectService {
  _FakeSubjects({this.subjects = const [], this.links = const []});

  List<Subject> subjects;
  List<ArmSubject> links;
  List<TeachingAssignment> assignments = const [];

  /// What the save's fresh read answers; null means nobody has it yet.
  TeachingAssignment? single;

  int adds = 0;
  int updates = 0;
  String? changedStaffId;

  @override
  Future<List<Subject>> listSubjects(String organizationId) async => subjects;

  @override
  Future<List<ArmSubject>> listArmSubjects(String organizationId) async =>
      links;

  @override
  Future<List<TeachingAssignment>> listTeachingAssignments({
    required String organizationId,
    required String sessionId,
  }) async => assignments;

  @override
  Future<List<TeachingAssignment>> listStaffTeachingAssignments({
    required String organizationId,
    required String staffId,
    required String sessionId,
  }) async => const [];

  @override
  Future<TeachingAssignment?> getTeachingAssignment({
    required String organizationId,
    required String sessionId,
    required String armId,
    required String subjectId,
  }) async => single;

  @override
  Future<void> addTeachingAssignment({
    required String organizationId,
    required String sessionId,
    required String armId,
    required String subjectId,
    required String staffId,
  }) async {
    adds++;
  }

  @override
  Future<void> changeTeachingAssignmentTeacher(
    TeachingAssignment row, {
    required String staffId,
  }) async {
    updates++;
    changedStaffId = staffId;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

AcademicSession _session({DateTime? closedAt}) => AcademicSession(
  id: 'session',
  organizationId: 'school',
  name: '2026/27',
  dates: DateTimeRange(start: DateTime(2026, 9, 7), end: DateTime(2027, 7, 16)),
  isCurrent: true,
  closedAt: closedAt,
  terms: const [],
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

final _subject = Subject(
  id: 'math',
  name: 'Mathematics',
  code: 'MTH',
  sortOrder: 1,
  isActive: true,
);

final _link = ArmSubject(armId: 'arm', subjectId: 'math', isCompulsory: true);

ClassTeacher _classTeacher({
  required String staffId,
  required bool isLead,
  String staffName = 'Ngozi Eze',
}) => ClassTeacher(
  sessionId: 'session',
  armId: 'arm',
  staffId: staffId,
  isLead: isLead,
  staffName: staffName,
  className: 'JSS 1',
  armName: 'A',
);

TeachingAssignment _assignment({
  required String staffId,
  String staffName = 'Tunde Ade',
}) => TeachingAssignment(
  sessionId: 'session',
  armId: 'arm',
  subjectId: 'math',
  staffId: staffId,
  staffName: staffName,
  subjectName: 'Mathematics',
  className: 'JSS 1',
  armName: 'A',
);

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

StaffMember _staff() => StaffMember(
  id: 'staff',
  firstName: 'Ngozi',
  lastName: 'Eze',
  staffType: 'teaching',
  status: StaffRecordStatus.active,
  createdAt: DateTime(2026, 9, 1),
);

TeachingSetupViewModel _model(
  _FakeStructure structure,
  _FakeSubjects subjects,
) => TeachingSetupViewModel(
  school: _school(),
  staff: _staff(),
  structure: structure,
  subjects: subjects,
);

void main() {
  late _FakeStructure structure;
  late _FakeSubjects subjects;
  late TeachingSetupViewModel model;

  setUp(() async {
    structure = _FakeStructure(session: _session(), sections: _structure());
    subjects = _FakeSubjects(subjects: [_subject], links: [_link]);
    model = _model(structure, subjects);
    await model.load();
  });

  test('a new homeroom inserts the staff member', () async {
    structure.roster = const [];

    final error = await model.saveHomeroom(armId: 'arm', isLead: true);

    expect(error, isNull);
    expect(structure.adds, 1);
    expect(structure.updates, 0);
    expect(structure.addedIsLead, isTrue);
    expect(model.changed, isTrue);
  });

  test('an existing homeroom switches role with an update', () async {
    structure.roster = [_classTeacher(staffId: 'staff', isLead: true)];

    final error = await model.saveHomeroom(armId: 'arm', isLead: false);

    expect(error, isNull);
    expect(structure.adds, 0);
    expect(structure.updates, 1);
    expect(structure.updatedIsLead, isFalse);
    expect(model.changed, isTrue);
  });

  test('already the lead is a no-op', () async {
    structure.roster = [_classTeacher(staffId: 'staff', isLead: true)];

    final error = await model.saveHomeroom(armId: 'arm', isLead: true);

    expect(error, isNull);
    expect(structure.adds, 0);
    expect(structure.updates, 0);
    expect(model.changed, isFalse);
  });

  test('a subject with no teacher inserts an assignment', () async {
    subjects.single = null;

    final error = await model.saveSubject(armId: 'arm', subjectId: 'math');

    expect(error, isNull);
    expect(subjects.adds, 1);
    expect(subjects.updates, 0);
    expect(model.changed, isTrue);
  });

  test("another teacher's subject replaces them", () async {
    subjects.single = _assignment(staffId: 'other');

    final error = await model.saveSubject(armId: 'arm', subjectId: 'math');

    expect(error, isNull);
    expect(subjects.adds, 0);
    expect(subjects.updates, 1);
    expect(subjects.changedStaffId, 'staff');
    expect(model.changed, isTrue);
  });

  test('already taught is a no-op', () async {
    subjects.single = _assignment(staffId: 'staff', staffName: 'Ngozi Eze');

    final error = await model.saveSubject(armId: 'arm', subjectId: 'math');

    expect(error, isNull);
    expect(subjects.adds, 0);
    expect(subjects.updates, 0);
    expect(model.changed, isFalse);
  });

  test('the homeroom note covers each case', () async {
    structure.roster = const [
      ClassTeacher(
        sessionId: 'session',
        armId: 'arm',
        staffId: 'lead',
        isLead: true,
        staffName: 'Tunde Ade',
        className: 'JSS 1',
        armName: 'A',
      ),
    ];
    await model.refresh();

    final warning = model.homeroomSave(armId: 'arm', isLead: true);
    expect(warning.tone, TeachingTone.warning);
    expect(
      warning.note,
      'Tunde Ade is the lead of JSS 1A. Saving makes them an assistant.',
    );
    expect(warning.canSave, isTrue);

    final empty = model.homeroomSave(armId: null, isLead: true);
    expect(empty.canSave, isFalse);
  });

  test('promoting an assistant names the lead it displaces', () async {
    structure.roster = const [
      ClassTeacher(
        sessionId: 'session',
        armId: 'arm',
        staffId: 'lead',
        isLead: true,
        staffName: 'Tunde Ade',
        className: 'JSS 1',
        armName: 'A',
      ),
      ClassTeacher(
        sessionId: 'session',
        armId: 'arm',
        staffId: 'staff',
        isLead: false,
        staffName: 'Ngozi Eze',
        className: 'JSS 1',
        armName: 'A',
      ),
    ];
    await model.refresh();

    final save = model.homeroomSave(armId: 'arm', isLead: true);

    expect(save.canSave, isTrue);
    expect(save.tone, TeachingTone.warning);
    expect(
      save.note,
      'Ngozi Eze is an assistant of JSS 1A. Saving makes them the lead and '
      'moves Tunde Ade to assistant.',
    );
    expect(save.buttonLabel, 'Switch to lead');
  });

  test('two assistants stop a third', () async {
    structure.roster = const [
      ClassTeacher(
        sessionId: 'session',
        armId: 'arm',
        staffId: 'a',
        isLead: false,
        staffName: 'Ada Obi',
        className: 'JSS 1',
        armName: 'A',
      ),
      ClassTeacher(
        sessionId: 'session',
        armId: 'arm',
        staffId: 'b',
        isLead: false,
        staffName: 'Bola Ade',
        className: 'JSS 1',
        armName: 'A',
      ),
    ];
    await model.refresh();

    final save = model.homeroomSave(armId: 'arm', isLead: false);

    expect(save.canSave, isFalse);
    expect(save.tone, TeachingTone.error);
    expect(
      save.note,
      'JSS 1A already has 2 assistants: Ada Obi and Bola Ade. '
      'Save as lead, or free a slot first.',
    );
  });

  test('a closed session is read-only and refuses the write', () async {
    structure.session = _session(closedAt: DateTime(2027, 7, 17));
    await model.refresh();

    final save = model.homeroomSave(armId: 'arm', isLead: true);
    expect(save.readOnly, isTrue);
    expect(save.canSave, isFalse);

    final error = await model.saveHomeroom(armId: 'arm', isLead: true);
    expect(
      error,
      'This session is closed. Reopen it to change who teaches where.',
    );
    expect(structure.adds, 0);
    expect(model.changed, isFalse);
  });
}
