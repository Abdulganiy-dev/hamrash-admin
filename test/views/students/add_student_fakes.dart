import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/academic_calendar/academic_session.dart';
import 'package:hamrash_admin/api/models/class_structure/class_structure.dart';
import 'package:hamrash_admin/api/models/organization_models/member_school.dart';
import 'package:hamrash_admin/api/models/organization_models/organization.dart';
import 'package:hamrash_admin/api/models/organization_models/organization_member.dart';
import 'package:hamrash_admin/api/models/students/parent_match.dart';
import 'package:hamrash_admin/api/models/students/student_registration.dart';
import 'package:hamrash_admin/api/models/team/staff_member.dart';
import 'package:hamrash_admin/api/models/team/teaching.dart';
import 'package:hamrash_admin/api/services/cloudflare_services/image_service.dart';
import 'package:hamrash_admin/api/services/cloudflare_services/media_kind.dart';
import 'package:hamrash_admin/api/services/cloudflare_services/media_upload_service.dart';
import 'package:hamrash_admin/api/services/supabase_services/class_structure_service.dart';
import 'package:hamrash_admin/api/services/supabase_services/student_service.dart';
import 'package:hamrash_admin/api/services/supabase_services/subject_service.dart';
import 'package:hamrash_admin/views/students/add_student/add_student_view_model.dart';

class FakeStudents implements StudentService {
  List<ParentMatch> matches = const [];
  int searches = 0;
  final registrations = <StudentRegistration>[];
  Object? registerError;

  @override
  Future<List<ParentMatch>> findParentsByPhone({
    required String organizationId,
    required String phone,
  }) async {
    searches++;
    return matches;
  }

  @override
  Future<RegisteredStudent> registerStudent(
    StudentRegistration registration,
  ) async {
    registrations.add(registration);
    if (registerError case final error?) throw error;
    return RegisteredStudent(
      id: 'student',
      firstName: registration.firstName,
      lastName: registration.lastName,
      admissionNumber: 'KCL/2026/0042',
      parentIds: [for (var i = 0; i < registration.parents.length; i++) 'p$i'],
      sessionId: registration.sessionId ?? 'session',
      armId: registration.armId,
      subjectIds: registration.optionalSubjectIds,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeSubjects implements SubjectService {
  FakeSubjects(this.offerings);

  final Map<String, List<SubjectOffering>> offerings;
  int reads = 0;

  @override
  Future<List<SubjectOffering>> listArmOfferings({
    required String organizationId,
    required String armId,
  }) async {
    reads++;
    return offerings[armId] ?? const [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeStructure implements ClassStructureService {
  FakeStructure({this.session});

  AcademicSession? session;
  int sessionReads = 0;
  int structureReads = 0;

  @override
  Future<AcademicSession?> getCurrentSession(String organizationId) async {
    sessionReads++;
    return session;
  }

  @override
  Future<List<SchoolSection>> getStructure(String organizationId) async {
    structureReads++;
    return structure();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Uploads finish when [finish] is called (or straight away when [instant]).
class FakeImages implements ImageService {
  bool instant = true;
  bool fail = false;
  int uploads = 0;
  final deleted = <String>[];
  final _waiting = <Completer<UploadedMedia>>[];

  @override
  Future<UploadedMedia> uploadImage(
    Uint8List imageData,
    String filename, {
    required MediaKind kind,
  }) {
    uploads++;
    final id = 'img$uploads';
    if (instant) {
      return fail
          ? Future.error(Exception('offline'))
          : Future.value(UploadedMedia(id: id, url: 'https://img/$id'));
    }
    final completer = Completer<UploadedMedia>();
    _waiting.add(completer);
    return completer.future.then(
      (_) => UploadedMedia(id: id, url: 'https://img/$id'),
    );
  }

  void finishAll() {
    for (final completer in _waiting) {
      completer.complete(const UploadedMedia(id: '', url: ''));
    }
    _waiting.clear();
  }

  @override
  Future<void> deleteImage(String id) async => deleted.add(id);
}

MemberSchool school() => MemberSchool(
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

AcademicSession session({DateTime? closedAt}) => AcademicSession(
  id: 'session',
  organizationId: 'school',
  name: '2026/27',
  dates: DateTimeRange(start: DateTime(2026, 9, 7), end: DateTime(2027, 7, 16)),
  isCurrent: true,
  closedAt: closedAt,
  terms: const [],
);

ClassArm _arm(String id, String classId, String name) => ClassArm(
  id: id,
  classId: classId,
  name: name,
  isActive: true,
  createdAt: DateTime(2026, 9, 1),
);

List<SchoolSection> structure() => [
  SchoolSection(
    id: 'junior',
    name: 'Junior',
    sortOrder: 1,
    isActive: true,
    classes: [
      SchoolClass(
        id: 'jss1',
        sectionId: 'junior',
        name: 'JSS 1',
        sortOrder: 1,
        isGraduating: false,
        isActive: true,
        arms: [_arm('gold', 'jss1', 'Gold'), _arm('blue', 'jss1', 'Blue')],
      ),
    ],
  ),
];

const offerings = <String, List<SubjectOffering>>{
  'gold': [
    SubjectOffering(
      subjectId: 'maths',
      name: 'Maths',
      isCompulsory: true,
      sortOrder: 1,
    ),
    SubjectOffering(
      subjectId: 'french',
      name: 'French',
      isCompulsory: false,
      sortOrder: 2,
      code: 'FRN',
    ),
    SubjectOffering(
      subjectId: 'music',
      name: 'Music',
      isCompulsory: false,
      sortOrder: 3,
    ),
  ],
  'blue': [
    SubjectOffering(
      subjectId: 'maths',
      name: 'Maths',
      isCompulsory: true,
      sortOrder: 1,
    ),
  ],
};

const ngozi = ParentMatch(
  id: 'ngozi',
  title: 'Mrs',
  firstName: 'Ngozi',
  lastName: 'Okafor',
  phone: '08035550142',
  childrenNames: ['Tobenna'],
);

class Fakes {
  Fakes()
    : students = FakeStudents(),
      subjects = FakeSubjects(offerings),
      structure = FakeStructure(session: session()),
      images = FakeImages();

  final FakeStudents students;
  final FakeSubjects subjects;
  final FakeStructure structure;
  final FakeImages images;

  AddStudentViewModel model() => AddStudentViewModel(
    school: school(),
    students: students,
    subjects: subjects,
    structure: structure,
    images: images,
    today: DateTime(2026, 9, 7),
  );
}

/// Fills step 1 with valid answers.
void fillStudent(AddStudentViewModel model) {
  model.firstName.text = 'Chioma';
  model.lastName.text = 'Okafor';
  model.pickGender(StaffGender.female);
  model.pickDateOfBirth(DateTime(2015, 3, 14));
}
