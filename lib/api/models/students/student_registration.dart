import 'package:hamrash_admin/api/models/students/parent_relationship.dart';
import 'package:hamrash_admin/api/models/team/staff_member.dart';
import 'package:intl/intl.dart';

/// A Cloudflare image chosen for a student or a new parent.
class RegistrationPhoto {
  const RegistrationPhoto({required this.id, required this.url});

  final String id;
  final String url;
}

/// One parent in a registration: an existing parent reused by id, or a new
/// one the database creates. Mirrors one item of `register_student`'s
/// `p_parents` (migration 31).
sealed class RegistrationParent {
  const RegistrationParent({
    required this.relationship,
    required this.isPrimaryContact,
  });

  final ParentRelationship relationship;
  final bool isPrimaryContact;

  Map<String, Object?> toJson();
}

/// A parent already in the school, e.g. a sibling's mother.
class ExistingRegistrationParent extends RegistrationParent {
  const ExistingRegistrationParent({
    required this.parentId,
    required super.relationship,
    required super.isPrimaryContact,
  });

  final String parentId;

  @override
  Map<String, Object?> toJson() => {
    'parent_id': parentId,
    'relationship': relationship.value,
    'is_primary_contact': isPrimaryContact,
  };
}

/// A parent the database creates with the student.
class NewRegistrationParent extends RegistrationParent {
  const NewRegistrationParent({
    required this.firstName,
    required this.lastName,
    required this.phone,
    required super.relationship,
    required super.isPrimaryContact,
    this.title,
    this.photo,
  });

  final String? title;
  final String firstName;
  final String lastName;

  /// As the staff forms store it: `+2348035550142`.
  final String phone;
  final RegistrationPhoto? photo;

  @override
  Map<String, Object?> toJson() => {
    'title': title,
    'first_name': firstName,
    'last_name': lastName,
    'phone': phone,
    'photo_id': photo?.id,
    'photo_url': photo?.url,
    'relationship': relationship.value,
    'is_primary_contact': isPrimaryContact,
  };
}

/// Everything the Add student wizard sends to `register_student` in one
/// call.
class StudentRegistration {
  const StudentRegistration({
    required this.organizationId,
    required this.firstName,
    required this.lastName,
    required this.parents,
    required this.armId,
    this.sessionId,
    this.optionalSubjectIds = const [],
    this.middleName,
    this.admissionNumber,
    this.gender,
    this.dateOfBirth,
    this.admissionDate,
    this.photo,
  });

  final String organizationId;
  final String firstName;
  final String? middleName;
  final String lastName;

  /// Null lets the database give the next number.
  final String? admissionNumber;
  final StaffGender? gender;
  final DateTime? dateOfBirth;
  final DateTime? admissionDate;
  final RegistrationPhoto? photo;
  final List<RegistrationParent> parents;
  final String armId;

  /// The session the wizard showed. Null means the school's current one.
  final String? sessionId;
  final List<String> optionalSubjectIds;

  static final _date = DateFormat('yyyy-MM-dd');

  /// The RPC's named arguments, exactly as migration 31 declares them.
  Map<String, Object?> toParams() => {
    'p_organization_id': organizationId,
    'p_first_name': firstName,
    'p_last_name': lastName,
    'p_parents': [for (final parent in parents) parent.toJson()],
    'p_arm_id': armId,
    'p_session_id': sessionId,
    'p_optional_subject_ids': optionalSubjectIds,
    'p_middle_name': middleName,
    'p_admission_number': admissionNumber,
    'p_gender': gender?.value,
    'p_admission_date': admissionDate == null
        ? null
        : _date.format(admissionDate!),
    'p_photo_id': photo?.id,
    'p_photo_url': photo?.url,
    'p_date_of_birth': dateOfBirth == null ? null : _date.format(dateOfBirth!),
  };
}

/// What `register_student` returns: the new student and what was linked.
class RegisteredStudent {
  const RegisteredStudent({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.admissionNumber,
    required this.parentIds,
    required this.sessionId,
    required this.armId,
    required this.subjectIds,
  });

  final String id;
  final String firstName;
  final String lastName;

  /// "KCL/2026/0042", generated when it was left blank.
  final String admissionNumber;
  final List<String> parentIds;
  final String sessionId;
  final String armId;
  final List<String> subjectIds;

  factory RegisteredStudent.fromJson(Map<String, dynamic> json) {
    final student = json['student'] as Map<String, dynamic>;
    final placement = json['placement'] as Map<String, dynamic>;
    return RegisteredStudent(
      id: student['id'] as String,
      firstName: student['first_name'] as String? ?? '',
      lastName: student['last_name'] as String? ?? '',
      admissionNumber: student['admission_number'] as String? ?? '',
      parentIds: _ids(json['parent_ids']),
      sessionId: placement['session_id'] as String,
      armId: placement['arm_id'] as String,
      subjectIds: _ids(json['subject_ids']),
    );
  }

  static List<String> _ids(Object? value) => [
    if (value is List)
      for (final id in value)
        if (id is String) id,
  ];
}
