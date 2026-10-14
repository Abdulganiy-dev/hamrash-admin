import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hamrash_admin/api/models/class_structure/class_structure.dart';
import 'package:hamrash_admin/api/models/organization_models/member_school.dart';
import 'package:hamrash_admin/api/models/organization_models/organization.dart';
import 'package:hamrash_admin/api/models/organization_models/organization_member.dart';
import 'package:hamrash_admin/api/models/subjects/curriculum.dart';
import 'package:hamrash_admin/api/models/subjects/subject.dart';
import 'package:hamrash_admin/api/services/supabase_services/class_structure_service.dart';
import 'package:hamrash_admin/api/services/supabase_services/subject_service.dart';
import 'package:hamrash_admin/api/services/supabase_services/supabase_refusal.dart';
import 'package:hamrash_admin/core/widgets/app_alert_dialog.dart';
import 'package:hamrash_admin/views/subjects/class_subjects/class_subjects_view_model.dart';
import 'package:hamrash_admin/views/subjects/subjects_view_model.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

ClassArm _arm(String id, String classId, String name, {int students = 0}) =>
    ClassArm(
      id: id,
      classId: classId,
      name: name,
      isActive: true,
      createdAt: DateTime(2026, 10, 14, 9, id.hashCode % 60),
      students: students,
    );

SchoolClass _class(String id, String name, int order, List<ClassArm> arms) =>
    SchoolClass(
      id: id,
      sectionId: 'sec',
      name: name,
      sortOrder: order,
      isGraduating: false,
      isActive: true,
      arms: arms,
    );

Subject _subject(
  String id,
  String name,
  String code,
  int order, {
  int teachers = 0,
}) => Subject(
  id: id,
  name: name,
  code: code,
  sortOrder: order,
  isActive: true,
  teachers: teachers,
);

final _sections = [
  SchoolSection(
    id: 'sec',
    name: 'Secondary',
    sortOrder: 1,
    isActive: true,
    classes: [
      _class('jss1', 'JSS 1', 1, [
        _arm('jss1a', 'jss1', 'A'),
        _arm('jss1b', 'jss1', 'B'),
      ]),
      _class('ss1', 'SS 1', 2, [
        _arm('sci', 'ss1', 'Science'),
        _arm('art', 'ss1', 'Arts'),
      ]),
      _class('ss2', 'SS 2', 3, [_arm('ss2a', 'ss2', 'A')]),
      _class('ss3', 'SS 3', 4, const []),
    ],
  ),
];

final _subjects = [
  _subject('eng', 'English Language', 'ENG', 1),
  _subject('mth', 'Mathematics', 'MTH', 2, teachers: 2),
  _subject('phy', 'Physics', 'PHY', 3),
  _subject('lit', 'Literature in English', 'LIT', 4),
];

List<ArmSubject> _links() => [
  for (final arm in ['jss1a', 'jss1b'])
    for (final subject in ['eng', 'mth'])
      ArmSubject(armId: arm, subjectId: subject, isCompulsory: true),
  for (final arm in ['sci', 'art'])
    ArmSubject(armId: arm, subjectId: 'eng', isCompulsory: true),
  const ArmSubject(armId: 'sci', subjectId: 'phy', isCompulsory: false),
  const ArmSubject(armId: 'art', subjectId: 'lit', isCompulsory: false),
];

class _Structure extends ClassStructureService {
  _Structure() : super(SupabaseClient('https://example.supabase.co', 'k'));

  @override
  Future<List<SchoolSection>> getStructure(String organizationId) async =>
      _sections;
}

class _Subjects extends SubjectService {
  _Subjects() : super(SupabaseClient('https://example.supabase.co', 'k'));

  List<ArmSubject> links = _links();
  List<String>? lastArms;
  Object? failWith;

  @override
  Future<List<Subject>> listSubjects(String organizationId) async => _subjects;

  @override
  Future<List<ArmSubject>> listArmSubjects(String organizationId) async =>
      links;

  @override
  Future<List<ArmSubjectUsage>> listArmSubjectUsage(
    String organizationId,
  ) async => const [
    ArmSubjectUsage(
      armId: 'jss1b',
      subjectId: 'mth',
      teacherName: 'Ada Bello',
      choices: 0,
    ),
    ArmSubjectUsage(
      armId: 'sci',
      subjectId: 'phy',
      teacherName: null,
      choices: 3,
    ),
  ];

  @override
  Future<void> addToArms({
    required String organizationId,
    required List<String> armIds,
    required List<String> subjectIds,
    required bool isCompulsory,
  }) async {
    if (failWith case final error?) throw error;
    lastArms = armIds;
    links = [
      ...links,
      for (final arm in armIds)
        for (final subject in subjectIds)
          ArmSubject(
            armId: arm,
            subjectId: subject,
            isCompulsory: isCompulsory,
          ),
    ];
  }

  @override
  Future<void> removeFromArms({
    required List<String> armIds,
    required String subjectId,
  }) async {
    if (failWith case final error?) throw error;
    lastArms = armIds;
  }
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

void main() {
  group('Curriculum', () {
    final curriculum = Curriculum(
      sections: _sections,
      subjects: _subjects,
      links: _links(),
    );

    test('knows when arms take the same subjects', () {
      expect(curriculum.sameInAllArms(_sections[0].classes[0]), isTrue);
      expect(curriculum.sameInAllArms(_sections[0].classes[1]), isFalse);
    });

    test('finds the classes taking a subject', () {
      expect(curriculum.classesTaking(_subjects[0]).map((c) => c.name), [
        'JSS 1',
        'SS 1',
      ]);
      expect(curriculum.onlyOptional(_subjects[2]), isTrue);
      expect(curriculum.onlyOptional(_subjects[0]), isFalse);
    });

    test('checks subject names and codes', () {
      expect(curriculum.subjectNameProblem('mathematics'), isNotNull);
      expect(
        curriculum.subjectNameProblem('Mathematics', except: _subjects[1]),
        isNull,
      );
      expect(curriculum.subjectCodeProblem('eng'), contains('English'));
      expect(curriculum.subjectCodeProblem('E'), contains('2 to 10'));
      expect(curriculum.subjectCodeProblem(''), isNull);
      expect(curriculum.nextSortOrder, 5);
    });
  });

  group('SubjectsViewModel', () {
    Future<SubjectsViewModel> loaded() async {
      final model = SubjectsViewModel(
        school: _school(OrganizationMemberRole.principal),
        subjects: _Subjects(),
        structure: _Structure(),
      );
      await model.load();
      return model;
    }

    test('sums up each class', () async {
      final model = await loaded();
      final classes = _sections[0].classes;

      final jss1 = model.summaryOf(classes[0]);
      expect(jss1.details, '2 compulsory');
      expect(jss1.trailing, '2 subjects');

      final ss1 = model.summaryOf(classes[1]);
      expect(ss1.details, 'Science 2 · Arts 2');
      expect(ss1.trailing, 'Varies by arm');

      final ss2 = model.summaryOf(classes[2]);
      expect(ss2.trailing, 'No subjects yet');
      expect(ss2.needsAttention, isTrue);

      expect(model.summaryOf(classes[3]).trailing, 'Add arms first');
    });

    test('says where a subject is taught', () async {
      final model = await loaded();
      expect(model.usageOf(_subjects[0]), 'JSS 1 – SS 1 · 2 classes');
      expect(model.usageOf(_subjects[2]), 'SS 1 · optional');
      expect(model.removeBlockedReason(_subjects[1]), contains('taught'));
      expect(model.removeBlockedReason(_subjects[2]), isNull);
    });

    test('searches by name or code', () async {
      final model = await loaded();
      model.search('lit');
      expect(model.visibleSubjects.map((s) => s.code), ['LIT']);
    });
  });

  group('ClassSubjectsViewModel', () {
    Future<(ClassSubjectsViewModel, _Subjects)> loaded(String classId) async {
      final service = _Subjects();
      final model = ClassSubjectsViewModel(
        school: _school(OrganizationMemberRole.principal),
        classId: classId,
        subjects: service,
        structure: _Structure(),
      );
      await model.load();
      return (model, service);
    }

    test('edits all arms together while they match', () async {
      final (model, service) = await loaded('jss1');

      expect(model.tabs, [null, 'jss1a', 'jss1b']);
      expect(model.armId, isNull);
      expect(model.note, contains('apply to both'));
      expect(model.compulsory.map((s) => s.code), ['ENG', 'MTH']);

      expect(await model.addSubjects(['phy'], compulsory: false), isNull);
      expect(service.lastArms, ['jss1a', 'jss1b']);
      expect(model.changed, isTrue);
    });

    test('edits one arm at a time when they differ', () async {
      final (model, service) = await loaded('ss1');

      expect(model.tabs, ['sci', 'art']);
      expect(model.armId, 'sci');
      expect(model.note, contains('SS 1 Science only'));
      expect(model.optional.map((s) => s.code), ['PHY']);
      expect(model.copyTargets.map((arm) => arm.name), ['Arts']);

      await model.removeSubject(_subjects[2]);
      expect(service.lastArms, ['sci']);
    });

    test('says why a subject in use can\'t come off', () async {
      final (jss1, _) = await loaded('jss1');
      expect(
        jss1.removeBlockedReason(_subjects[1]),
        'Ada Bello teaches Mathematics in JSS 1B. Unassign them first.',
      );
      expect(jss1.removeBlockedReason(_subjects[0]), isNull);

      // Only the arm being edited counts.
      jss1.pickArm('jss1a');
      expect(jss1.removeBlockedReason(_subjects[1]), isNull);

      final (ss1, _) = await loaded('ss1');
      expect(
        ss1.removeBlockedReason(_subjects[2]),
        '3 students in SS 1 Science chose Physics. Remove their choice first.',
      );
    });

    test('a refused removal keeps the confirmation open', () async {
      final (model, service) = await loaded('jss1');
      service.failWith = const SupabaseRefusal(SubjectService.leadersOnly);

      await expectLater(
        model.removeSubject(_subjects[0]),
        throwsA(isA<AppAlertError>()),
      );
    });
  });

  group('SubjectService', () {
    test('reads how much a subject is used', () async {
      final client = SupabaseClient(
        'https://example.supabase.co',
        'k',
        httpClient: MockClient(
          (request) async => http.Response(
            jsonEncode([
              {
                'id': 'mth',
                'name': 'Mathematics',
                'code': 'MTH',
                'sort_order': 2,
                'is_active': true,
                'teaching_assignments': [
                  {'count': 3},
                ],
                'student_subjects': [
                  {'count': 0},
                ],
              },
            ]),
            200,
            headers: {'content-type': 'application/json'},
            request: request,
          ),
        ),
      );
      addTearDown(client.dispose);

      final subjects = await SubjectService(client).listSubjects('kings');
      expect(subjects.single.teachers, 3);
      expect(subjects.single.inUse, isTrue);
    });

    test('a taught subject stays, with a reason', () async {
      final client = SupabaseClient(
        'https://example.supabase.co',
        'k',
        httpClient: MockClient(
          (request) async => http.Response(
            jsonEncode({'code': '23503', 'message': 'fk', 'details': null}),
            409,
            headers: {'content-type': 'application/json'},
            request: request,
          ),
        ),
      );
      addTearDown(client.dispose);

      await expectLater(
        SubjectService(client).deleteSubject(_subjects[1]),
        throwsA(
          isA<SupabaseRefusal>().having(
            (error) => error.message,
            'message',
            contains("Mathematics is taught or chosen by students"),
          ),
        ),
      );
    });
  });

  test('a class with students or a class teacher in an arm stays', () {
    final busy = _class('p1', 'Primary 1', 1, [
      _arm('p1a', 'p1', 'A'),
      _arm('p1b', 'p1', 'B', students: 12),
    ]);
    expect(busy.busyArm?.name, 'B');
    expect(
      busy.arms[1].removeBlockedReason('Primary 1'),
      contains('Primary 1B has students'),
    );
    expect(busy.arms[0].removeBlockedReason('Primary 1'), isNull);
  });
}
