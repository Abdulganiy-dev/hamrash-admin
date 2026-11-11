import 'package:hamrash_admin/api/models/organization_models/member_school.dart';
import 'package:hamrash_admin/api/models/organization_models/organization.dart';
import 'package:hamrash_admin/api/models/organization_models/organization_member.dart';
import 'package:hamrash_admin/api/models/students/parent_match.dart';
import 'package:hamrash_admin/api/models/students/parent_profile.dart';
import 'package:hamrash_admin/api/models/students/parent_relationship.dart';
import 'package:hamrash_admin/api/models/students/student_details_changes.dart';
import 'package:hamrash_admin/api/models/students/student_filter.dart';
import 'package:hamrash_admin/api/models/students/student_profile.dart';
import 'package:hamrash_admin/api/services/supabase_services/student_service.dart';

MemberSchool schoolFor(OrganizationMemberRole role) => MemberSchool(
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

const _maths = StudentSubjectOffer(
  subjectId: 'maths',
  name: 'Mathematics',
  isCompulsory: true,
);
const _english = StudentSubjectOffer(
  subjectId: 'eng',
  name: 'English Language',
  isCompulsory: true,
);
const _agric = StudentSubjectOffer(
  subjectId: 'agric',
  name: 'Agricultural Science',
  code: 'AGR',
  isCompulsory: false,
);
const _french = StudentSubjectOffer(
  subjectId: 'french',
  name: 'French',
  code: 'FRN',
  isCompulsory: false,
);
const _music = StudentSubjectOffer(
  subjectId: 'music',
  name: 'Music',
  code: 'MUS',
  isCompulsory: false,
);

const mother = StudentParent(
  id: 'p1',
  title: 'Mrs',
  firstName: 'Halima',
  lastName: 'Yusuf',
  phone: '+2348034451290',
  email: 'halima@example.com',
  relationship: ParentRelationship.mother,
  isPrimaryContact: true,
);

const father = StudentParent(
  id: 'p2',
  title: 'Mr',
  firstName: 'Musa',
  lastName: 'Yusuf',
  phone: '+2348031124455',
  relationship: ParentRelationship.father,
  isPrimaryContact: false,
);

/// Abdullahi Yusuf, JSS 1B, taking Agricultural Science and French.
StudentProfile abdullahi({
  StudentStatusFilter status = StudentStatusFilter.active,
  StudentLogin? login,
  bool placed = true,
  List<StudentParent> parents = const [mother, father],
}) => StudentProfile(
  id: 'st1',
  firstName: 'Abdullahi',
  lastName: 'Yusuf',
  admissionNumber: 'KCL/2026/0021',
  gender: StudentGender.male,
  admissionDate: DateTime(2026, 9, 8),
  status: status,
  createdAt: DateTime(2026, 9, 8),
  updatedAt: DateTime(2026, 11, 10),
  memberId: login?.id,
  login: login,
  details: StudentPrivateDetails(
    dateOfBirth: DateTime(2014, 3, 2),
    address: '22 Ahmadu Bello Way, Victoria Island, Lagos',
    stateOfOrigin: 'Kano',
    lga: 'Nassarawa',
    bloodGroup: 'O+',
    genotype: 'AA',
    medicalNotes: 'Asthma. Carries an inhaler in their bag.',
  ),
  placement: placed
      ? const StudentPlacement(
          sessionId: 'sess',
          sessionName: '2026/27',
          armId: 'arm-1b',
          armName: 'B',
          classId: 'jss1',
          className: 'JSS 1',
          leadTeacher: 'Ibrahim Bello',
          offers: [_maths, _english, _agric, _french, _music],
          chosenOptionalIds: {'agric', 'french'},
        )
      : null,
  parents: parents,
);

StudentLogin loginWith(OrganizationMemberStatus status, {String? code}) =>
    StudentLogin(
      id: 'm-st1',
      status: status,
      claimCode: code,
      joinedAt: status == OrganizationMemberStatus.invited
          ? null
          : DateTime(2026, 9, 3),
      createdAt: DateTime(2026, 11, 8),
    );

/// The student calls the page makes. Anything else would be a database call.
class FakeStudents implements StudentService {
  FakeStudents(this.student);

  StudentProfile student;
  Object? failWith;
  final calls = <String>[];

  StudentDetailsChanges? savedChanges;
  StudentStatusFilter? savedStatus;
  String? movedTo;
  int droppedOnMove = 0;
  Set<String>? savedOptional;
  Set<String>? optionalWas;
  String code = 'R4TB8KXW';
  bool? suspended;
  String? removedId;
  ({String parentId, ParentRelationship relationship, bool primary})? linked;
  ({String parentId, String? newPrimary})? unlinked;
  ({
    ParentRelationship relationship,
    String? photoId,
    bool primary,
    String phone,
    String email,
  })?
  newParent;
  ParentRelationship? changedTo;
  List<ParentMatch> matches = const [];

  void _maybeFail() {
    if (failWith case final error?) throw error;
  }

  @override
  Future<StudentProfile> getStudent({
    required String organizationId,
    required String studentId,
  }) async {
    calls.add('getStudent');
    return student;
  }

  @override
  Future<void> updateStudentDetails({
    required StudentProfile student,
    required StudentDetailsChanges changes,
  }) async {
    _maybeFail();
    savedChanges = changes;
  }

  @override
  Future<void> setStudentStatus({
    required StudentProfile student,
    required StudentStatusFilter status,
  }) async {
    _maybeFail();
    savedStatus = status;
  }

  @override
  Future<List<ArmChoice>> listArmChoices({
    required String organizationId,
    required String classId,
    required String className,
    required String sessionId,
  }) async => [
    ArmChoice(
      armId: 'arm-1a',
      name: 'A',
      className: className,
      students: 32,
      isActive: true,
      leadTeacher: 'Oluwaseun Adeyemi',
    ),
    ArmChoice(
      armId: 'arm-1b',
      name: 'B',
      className: className,
      students: 30,
      isActive: true,
      leadTeacher: 'Ibrahim Bello',
    ),
    ArmChoice(
      armId: 'arm-1c',
      name: 'C',
      className: className,
      students: 29,
      isActive: true,
    ),
  ];

  @override
  Future<int> moveToArm({
    required String studentId,
    required String armId,
  }) async {
    _maybeFail();
    movedTo = armId;
    return droppedOnMove;
  }

  @override
  Future<void> setOptionalSubjects({
    required String organizationId,
    required String studentId,
    required String sessionId,
    required Set<String> current,
    required Set<String> subjectIds,
  }) async {
    _maybeFail();
    optionalWas = current;
    savedOptional = subjectIds;
  }

  @override
  Future<String> inviteStudent(String studentId) async {
    _maybeFail();
    return code;
  }

  @override
  Future<void> cancelInvite(String memberId) async => _maybeFail();

  @override
  Future<void> setSuspended({
    required String memberId,
    required bool suspended,
  }) async {
    _maybeFail();
    this.suspended = suspended;
  }

  @override
  Future<void> removeStudent(String studentId) async {
    _maybeFail();
    removedId = studentId;
  }

  @override
  Future<List<ParentMatch>> findParentsByPhone({
    required String organizationId,
    required String phone,
  }) async => matches;

  @override
  Future<void> linkParent({
    required String organizationId,
    required String studentId,
    required String parentId,
    required ParentRelationship relationship,
    required bool primary,
  }) async {
    _maybeFail();
    linked = (parentId: parentId, relationship: relationship, primary: primary);
  }

  @override
  Future<String> createAndLinkParent({
    required String organizationId,
    required String studentId,
    required String? title,
    required String firstName,
    required String lastName,
    required String phone,
    required String email,
    required String occupation,
    required String address,
    required ParentRelationship relationship,
    required bool primary,
    String? photoId,
    String? photoUrl,
  }) async {
    _maybeFail();
    newParent = (
      relationship: relationship,
      photoId: photoId,
      primary: primary,
      phone: phone,
      email: email,
    );
    return 'new-parent';
  }

  ParentProfile parent = parentFixture();
  ParentDetailsChanges? savedParent;
  String? removedParentId;
  String? invitedParentId;

  @override
  Future<ParentProfile> getParent({
    required String organizationId,
    required String parentId,
  }) async {
    calls.add('getParent');
    return parent;
  }

  @override
  Future<void> updateParentDetails({
    required ParentProfile parent,
    required ParentDetailsChanges changes,
  }) async {
    _maybeFail();
    savedParent = changes;
  }

  @override
  Future<String> inviteParent(String parentId) async {
    _maybeFail();
    invitedParentId = parentId;
    return code;
  }

  @override
  Future<void> removeParent(String parentId) async {
    _maybeFail();
    removedParentId = parentId;
  }

  @override
  Future<void> setParentRelationship({
    required String studentId,
    required String parentId,
    required ParentRelationship relationship,
  }) async {
    _maybeFail();
    changedTo = relationship;
  }

  @override
  Future<void> unlinkParent({
    required String studentId,
    required String parentId,
    String? newPrimaryId,
  }) async {
    _maybeFail();
    unlinked = (parentId: parentId, newPrimary: newPrimaryId);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Mrs Halima Yusuf: a pharmacist, mother of Abdullahi (JSS 1B, primary
/// contact) and Aisha (Primary 4A).
ParentProfile parentFixture({StudentLogin? login, bool children = true}) =>
    ParentProfile(
      id: 'p1',
      title: 'Mrs',
      firstName: 'Halima',
      lastName: 'Yusuf',
      phone: '+2348034451290',
      email: 'halima.y@gmail.com',
      occupation: 'Pharmacist',
      address: '22 Ahmadu Bello Way, Victoria Island',
      memberId: login?.id,
      login: login,
      children: children
          ? const [
              ParentChild(
                studentId: 'st1',
                firstName: 'Abdullahi',
                lastName: 'Yusuf',
                relationship: ParentRelationship.mother,
                isPrimaryContact: true,
                armLabel: 'JSS 1B',
              ),
              ParentChild(
                studentId: 'st2',
                firstName: 'Aisha',
                lastName: 'Yusuf',
                relationship: ParentRelationship.mother,
                isPrimaryContact: false,
                armLabel: 'Primary 4A',
              ),
            ]
          : const [],
    );
