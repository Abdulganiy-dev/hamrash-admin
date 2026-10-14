import 'package:flutter_test/flutter_test.dart';
import 'package:hamrash_admin/api/models/class_structure/class_structure.dart';
import 'package:hamrash_admin/api/models/organization_models/member_school.dart';
import 'package:hamrash_admin/api/models/organization_models/organization.dart';
import 'package:hamrash_admin/api/models/organization_models/organization_member.dart';
import 'package:hamrash_admin/api/services/supabase_services/class_structure_service.dart';
import 'package:hamrash_admin/api/services/supabase_services/supabase_refusal.dart';
import 'package:hamrash_admin/core/widgets/app_alert_dialog.dart';
import 'package:hamrash_admin/views/classes/classes_view_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

SchoolClass _class(
  String id,
  String section,
  String name,
  int order, {
  List<String> arms = const [],
  bool active = true,
}) => SchoolClass(
  id: id,
  sectionId: section,
  name: name,
  sortOrder: order,
  isGraduating: false,
  isActive: active,
  arms: [
    for (final (i, arm) in arms.indexed)
      ClassArm(
        id: '$id-$arm',
        classId: id,
        name: arm,
        isActive: true,
        createdAt: DateTime(2026, 10, 14, 9, i),
      ),
  ],
);

List<SchoolSection> _structure() => [
  SchoolSection(
    id: 'nursery',
    name: 'Nursery',
    sortOrder: 1,
    isActive: true,
    classes: [
      _class('n1', 'nursery', 'Nursery 1', 1, arms: ['A', 'B']),
      _class('n3', 'nursery', 'Nursery 3', 2),
    ],
  ),
  SchoolSection(
    id: 'primary',
    name: 'Primary',
    sortOrder: 2,
    isActive: true,
    classes: [
      _class('p1', 'primary', 'Primary 1', 1),
      _class('p2', 'primary', 'Primary 2', 2, active: false),
    ],
  ),
  SchoolSection(
    id: 'creche',
    name: 'Creche',
    sortOrder: 3,
    isActive: false,
    classes: [_class('c1', 'creche', 'Creche', 1)],
  ),
];

class _Structure extends ClassStructureService {
  _Structure(this.sections)
    : super(SupabaseClient('https://example.supabase.co', 'test-key'));

  List<SchoolSection> sections;
  Object? failWith;
  List<SchoolClass>? armsAddedTo;
  List<String>? armsAdded;
  int standardCalls = 0;

  @override
  Future<List<SchoolSection>> getStructure(String organizationId) async =>
      sections;

  @override
  Future<int> createStandardStructure(String organizationId) async {
    standardCalls++;
    if (failWith case final error?) throw error;
    sections = _structure();
    return 15;
  }

  @override
  Future<void> saveClass(
    SchoolClass original, {
    required String organizationId,
    required String name,
    required bool isGraduating,
    required List<String> arms,
  }) async {
    if (failWith case final error?) throw error;
  }

  @override
  Future<void> deleteClass(SchoolClass schoolClass) async {
    if (failWith case final error?) throw error;
  }

  @override
  Future<int> addArms({
    required String organizationId,
    required List<SchoolClass> classes,
    required List<String> arms,
  }) async {
    armsAddedTo = classes;
    armsAdded = arms;
    return classes.length * arms.length;
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

Future<(ClassesViewModel, _Structure)> _loaded({
  OrganizationMemberRole role = OrganizationMemberRole.principal,
  List<SchoolSection>? sections,
}) async {
  final service = _Structure(sections ?? _structure());
  final model = ClassesViewModel(school: _school(role), service: service);
  await model.load();
  return (model, service);
}

void main() {
  test('principals change classes; bursars only look', () async {
    final (principal, _) = await _loaded();
    final (bursar, _) = await _loaded(role: OrganizationMemberRole.bursar);

    expect(principal.canChange, isTrue);
    expect(bursar.canChange, isFalse);
  });

  test('counts classes in use that still need arms', () async {
    final (model, _) = await _loaded();

    // Primary 2 is switched off, and so is the Creche section.
    expect(model.classesWithoutArms.map((c) => c.name), [
      'Nursery 3',
      'Primary 1',
    ]);
    expect(model.sectionsNeedingArms.map((entry) => entry.$1.name), [
      'Nursery',
      'Primary',
    ]);
  });

  test('says where a class sits', () async {
    final (model, _) = await _loaded();
    final sections = model.sections;

    expect(model.placeOf(sections[0].classes[0]), 'Nursery · the first class');
    expect(
      model.placeOf(sections[1].classes[0]),
      'Primary · comes after Nursery 3',
    );
    expect(model.placeOfNew(sections[1]), 'Primary · after Primary 2');
  });

  test('spots a class or section name that is taken', () async {
    final (model, _) = await _loaded();
    final primary1 = model.sections[1].classes[0];

    expect(
      model.classNameProblem('primary 1'),
      "There's already a class called Primary 1.",
    );
    expect(model.classNameProblem('Primary 1', except: primary1), isNull);
    expect(model.sectionNameProblem('Nursery'), isNotNull);
    expect(model.removeSectionBlockedReason(model.sections[0]), isNotNull);
  });

  test('starts a new school with the standard structure', () async {
    final (model, service) = await _loaded(sections: []);
    expect(model.isEmpty, isTrue);

    expect(await model.useStandardStructure(), isTrue);

    expect(service.standardCalls, 1);
    expect(model.isEmpty, isFalse);
    expect(model.changed, isTrue);
  });

  test('shows the database reason when the standard structure fails', () async {
    final (model, service) = await _loaded(sections: []);
    service.failWith = const SupabaseRefusal(ClassStructureService.leadersOnly);

    expect(await model.useStandardStructure(), isFalse);
    expect(model.startError, ClassStructureService.leadersOnly);
  });

  test('a refused save keeps the sheet open with the reason', () async {
    final (model, service) = await _loaded();
    final nursery1 = model.sections[0].classes[0];

    service.failWith = const SupabaseRefusal('Nursery 1B has students in it.');
    expect(
      await model.saveClass(
        nursery1,
        name: 'Nursery 1',
        isGraduating: false,
        arms: ['A'],
      ),
      'Nursery 1B has students in it.',
    );

    service.failWith = Exception('offline');
    expect(
      await model.saveClass(
        nursery1,
        name: 'Nursery 1',
        isGraduating: false,
        arms: ['A'],
      ),
      "Couldn't save the class. Try again.",
    );
    expect(model.changed, isFalse);
  });

  test('a refused removal keeps the confirmation open', () async {
    final (model, service) = await _loaded();
    service.failWith = const SupabaseRefusal(ClassStructureService.leadersOnly);

    await expectLater(
      model.deleteClass(model.sections[0].classes[0]),
      throwsA(
        isA<AppAlertError>().having(
          (error) => error.message,
          'message',
          ClassStructureService.leadersOnly,
        ),
      ),
    );
  });

  test('adds arms only to the sections picked', () async {
    final (model, service) = await _loaded();

    expect(await model.addArms(['A', 'B'], {'primary'}), isNull);

    expect(service.armsAddedTo?.map((c) => c.name), ['Primary 1']);
    expect(service.armsAdded, ['A', 'B']);
    expect(model.changed, isTrue);
  });
}
