import 'package:hamrash_admin/api/models/class_structure/class_structure.dart';

/// The subject a student was filtered by, and who teaches it to their class.
class StudentSubject {
  const StudentSubject({
    required this.id,
    required this.name,
    required this.isCompulsory,
    this.teacherFirstName,
    this.teacherLastName,
  });

  final String id;
  final String name;
  final bool isCompulsory;

  /// The teacher assigned to this subject in the student's own arm, or null
  /// when nobody is.
  final String? teacherFirstName;
  final String? teacherLastName;

  bool get hasTeacher => teacherFirstName != null;

  String get teacherName =>
      '${teacherFirstName ?? ''} ${teacherLastName ?? ''}'.trim();

  factory StudentSubject.fromJson(Map<String, dynamic> json) {
    final teacher = json['teacher'];
    return StudentSubject(
      id: json['id'] as String,
      name: json['name'] as String,
      isCompulsory: json['is_compulsory'] as bool? ?? true,
      teacherFirstName: teacher is Map ? teacher['first_name'] as String? : null,
      teacherLastName: teacher is Map ? teacher['last_name'] as String? : null,
    );
  }
}

/// One student as `list_students` returns them: name, admission number, the
/// arm they are in this session, and, when a subject filter is on, that
/// subject with its teacher.
class StudentSummary {
  const StudentSummary({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.admissionNumber,
    this.photoUrl,
    this.armId,
    this.armLabel,
    this.classOrder = 0,
    this.subject,
  });

  final String id;
  final String firstName;
  final String lastName;

  /// e.g. `KCL/2026/0003`.
  final String admissionNumber;
  final String? photoUrl;

  /// The arm they are placed in for the session, null when they have none.
  final String? armId;

  /// "JSS 1A" (the class and the arm).
  final String? armLabel;

  /// The class's own order, so JSS 1 sorts before JSS 2.
  final int classOrder;

  /// Set only while the list is filtered by a subject.
  final StudentSubject? subject;

  String get fullName => '$firstName $lastName'.trim();

  /// "AO" for Adaeze Okonkwo.
  String get initials {
    final first = firstName.trim();
    final last = lastName.trim();
    return '${first.isEmpty ? '' : first[0]}${last.isEmpty ? '' : last[0]}'
        .toUpperCase();
  }

  factory StudentSummary.fromJson(Map<String, dynamic> json) {
    final arm = json['arm'];
    final subject = json['subject'];
    String? armLabel;
    if (arm is Map) {
      final className = arm['class_name'] as String?;
      final armName = arm['name'] as String;
      armLabel = className == null ? armName : fullArmName(className, armName);
    }
    return StudentSummary(
      id: json['id'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      admissionNumber: json['admission_number'] as String,
      photoUrl: json['photo_url'] as String?,
      armId: arm is Map ? arm['id'] as String? : null,
      armLabel: armLabel,
      classOrder: arm is Map
          ? (arm['class_sort_order'] as num?)?.toInt() ?? 0
          : 0,
      subject: subject is Map
          ? StudentSubject.fromJson(Map<String, dynamic>.from(subject))
          : null,
    );
  }
}
