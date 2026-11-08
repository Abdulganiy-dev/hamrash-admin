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
import 'package:hamrash_admin/views/team/staff_teaching/teaching_catalog.dart';
import 'package:hamrash_admin/views/team/staff_teaching/teaching_setup_view_model.dart';

/// Counts every read, so a test can say what a step did and did not fetch.
class _FakeStructure implements ClassStructureService {
  _FakeStructure({required this.session, required this.sections});

  AcademicSession? session;
  List<SchoolSection> sections;

  /// What the arm's roster read answers.
  List<ClassTeacher> roster = const [];

  bool failNextSession = false;
  int sessionReads = 0;
  int structureReads = 0;
  int rosterReads = 0;
  String? rosterArm;

  int adds = 0;
  int updates = 0;
  bool? addedIsLead;
  bool? updatedIsLead;

  @override
  Future<AcademicSession?> getCurrentSession(String organizationId) async {
    sessionReads++;
    if (failNextSession) {
      failNextSession = false;
      throw Exception('offline');
    }
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
    rosterArm = armId;
    return roster;
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
  List<SubjectOffering> offerings = const [];

  /// Who teaches what in the arm, as the arm's read answers.
  List<TeachingAssignment> assignments = const [];

  int offeringReads = 0;
  int assignmentReads = 0;
  int adds = 0;
  int updates = 0;
  String? changedStaffId;

  @override
  Future<List<SubjectOffering>> listArmOfferings({
    required String organizationId,
    required String armId,
  }) async {
    offeringReads++;
    return offerings;
  }

  @override
  Future<List<TeachingAssignment>> listArmTeachingAssignments({
    required String organizationId,
    required String sessionId,
    required String armId,
  }) async {
    assignmentReads++;
    return assignments;
  }

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

const _maths = SubjectOffering(
  subjectId: 'math',
  name: 'Mathematics',
  isCompulsory: true,
  sortOrder: 1,
);

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
  _FakeSubjects subjects, {
  TeachingCatalog? catalog,
}) => TeachingSetupViewModel(
  school: _school(),
  staff: _staff(),
  catalog:
      catalog ??
      TeachingCatalog(organizationId: 'school', structure: structure),
  structure: structure,
  subjects: subjects,
);

ClassTeacher _row(String staffId, String name, {required bool isLead}) =>
    _classTeacher(staffId: staffId, isLead: isLead, staffName: name);

void main() {
  late _FakeStructure structure;
  late _FakeSubjects subjects;
  late TeachingSetupViewModel model;

  setUp(() async {
    structure = _FakeStructure(session: _session(), sections: _structure());
    subjects = _FakeSubjects()..offerings = [_maths];
    model = _model(structure, subjects);
    await model.loadSession();
    await model.loadStructure();
  });

  group('reads', () {
    test('opening the menu reads only the session', () {
      expect(structure.sessionReads, 1);
      expect(structure.rosterReads, 0);
      expect(subjects.offeringReads, 0);
      expect(subjects.assignmentReads, 0);
    });

    test('the classes are read once and shared by both sheets', () async {
      final other = _model(structure, subjects, catalog: model.catalog);
      await other.loadSession();
      await other.loadStructure();
      await other.loadStructure();

      expect(structure.structureReads, 1);
      expect(structure.sessionReads, 1);
      expect(other.classes.single.name, 'JSS 1');
    });

    test('invalidating the catalog reads the classes again', () async {
      model.catalog.invalidate();
      final other = _model(structure, subjects, catalog: model.catalog);
      await other.loadStructure();

      expect(structure.structureReads, 2);
    });

    test('a failed read is not kept, so asking again tries again', () async {
      final catalog = TeachingCatalog(
        organizationId: 'school',
        structure: structure,
      );
      structure.failNextSession = true;

      await expectLater(catalog.session(), throwsException);
      final session = await catalog.session();

      expect(session?.id, 'session');
      expect(structure.sessionReads, 3);
    });

    test('the roster is read when an arm is chosen, once per arm', () async {
      expect(model.rosterReady('arm'), isFalse);

      await model.loadRoster('arm');
      await model.loadRoster('arm');

      expect(structure.rosterReads, 1);
      expect(structure.rosterArm, 'arm');
      expect(model.rosterReady('arm'), isTrue);
    });

    test('an arm’s subjects and teachers are read together', () async {
      await model.loadArmSubjects('arm');
      await model.loadArmSubjects('arm');

      expect(subjects.offeringReads, 1);
      expect(subjects.assignmentReads, 1);
      expect(model.subjectsOn('arm').single.name, 'Mathematics');
    });
  });

  group('saving', () {
    test('a new homeroom inserts the staff member', () async {
      await model.loadRoster('arm');

      final error = await model.saveHomeroom(armId: 'arm', isLead: true);

      expect(error, isNull);
      expect(structure.adds, 1);
      expect(structure.updates, 0);
      expect(structure.addedIsLead, isTrue);
      expect(model.changed, isTrue);
    });

    test('an existing homeroom switches role with an update', () async {
      structure.roster = [_classTeacher(staffId: 'staff', isLead: true)];
      await model.loadRoster('arm');

      final error = await model.saveHomeroom(armId: 'arm', isLead: false);

      expect(error, isNull);
      expect(structure.adds, 0);
      expect(structure.updates, 1);
      expect(structure.updatedIsLead, isFalse);
      expect(model.changed, isTrue);
    });

    test('already the lead is a no-op', () async {
      structure.roster = [_classTeacher(staffId: 'staff', isLead: true)];
      await model.loadRoster('arm');

      final error = await model.saveHomeroom(armId: 'arm', isLead: true);

      expect(error, isNull);
      expect(structure.adds, 0);
      expect(structure.updates, 0);
      expect(model.changed, isFalse);
    });

    test('a homeroom is not saved before the roster is read', () async {
      final error = await model.saveHomeroom(armId: 'arm', isLead: true);

      expect(error, isNotNull);
      expect(structure.adds, 0);
    });

    test('a subject with no teacher inserts an assignment', () async {
      await model.loadArmSubjects('arm');

      final error = await model.saveSubject(armId: 'arm', subjectId: 'math');

      expect(error, isNull);
      expect(subjects.adds, 1);
      expect(subjects.updates, 0);
      expect(model.changed, isTrue);
    });

    test("another teacher's subject replaces them", () async {
      subjects.assignments = [_assignment(staffId: 'other')];
      await model.loadArmSubjects('arm');

      final error = await model.saveSubject(armId: 'arm', subjectId: 'math');

      expect(error, isNull);
      expect(subjects.adds, 0);
      expect(subjects.updates, 1);
      expect(subjects.changedStaffId, 'staff');
      expect(model.changed, isTrue);
    });

    test('already taught is a no-op', () async {
      subjects.assignments = [
        _assignment(staffId: 'staff', staffName: 'Ngozi Eze'),
      ];
      await model.loadArmSubjects('arm');

      final error = await model.saveSubject(armId: 'arm', subjectId: 'math');

      expect(error, isNull);
      expect(subjects.adds, 0);
      expect(subjects.updates, 0);
      expect(model.changed, isFalse);
    });

    test('a closed session is read-only and refuses the write', () async {
      structure.session = _session(closedAt: DateTime(2027, 7, 17));
      model.catalog.invalidate();
      await model.loadSession();
      await model.loadRoster('arm');

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
  });

  group('notes', () {
    test('the homeroom note waits for the roster', () {
      final waiting = model.homeroomSave(armId: 'arm', isLead: true);

      expect(waiting.canSave, isFalse);
      expect(waiting.note, 'Checking who looks after JSS 1A…');
    });

    test('the homeroom note covers each case', () async {
      structure.roster = [_row('lead', 'Tunde Ade', isLead: true)];
      await model.loadRoster('arm');

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
      structure.roster = [
        _row('lead', 'Tunde Ade', isLead: true),
        _row('staff', 'Ngozi Eze', isLead: false),
      ];
      await model.loadRoster('arm');

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
      structure.roster = [
        _row('a', 'Ada Obi', isLead: false),
        _row('b', 'Bola Ade', isLead: false),
      ];
      await model.loadRoster('arm');

      final save = model.homeroomSave(armId: 'arm', isLead: false);

      expect(save.canSave, isFalse);
      expect(save.tone, TeachingTone.error);
      expect(
        save.note,
        'JSS 1A already has 2 assistants: Ada Obi and Bola Ade. '
        'Save as lead, or free a slot first.',
      );
    });

    test(
      'a subject someone else teaches warns before replacing them',
      () async {
        subjects.assignments = [_assignment(staffId: 'other')];
        await model.loadArmSubjects('arm');

        final save = model.subjectSave(armId: 'arm', subjectId: 'math');

        expect(save.canSave, isTrue);
        expect(
          save.note,
          'Tunde Ade teaches Mathematics in JSS 1A. Saving replaces them.',
        );
      },
    );

    test('an arm with no subjects offers to add some', () async {
      subjects.offerings = const [];
      await model.loadArmSubjects('arm');

      final save = model.subjectSave(armId: 'arm', subjectId: null);

      expect(save.canSave, isFalse);
      expect(save.addSubjects, isTrue);
    });

    test('forgetting arm subjects reads them again', () async {
      await model.loadArmSubjects('arm');
      model.forgetArmSubjects();
      await model.loadArmSubjects('arm');

      expect(subjects.offeringReads, 2);
    });
  });
}
