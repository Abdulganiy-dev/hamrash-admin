/// Snapshot of what's currently blocking (or will be auto-removed by) a
/// class delete. Returned by the `preflight_class_delete` RPC.
class ClassDeletePreflight {
  const ClassDeletePreflight({
    required this.students,
    required this.homeroomTeachers,
    required this.autoRemovedCurriculumSubjects,
    required this.autoRemovedTeacherAssignments,
  });

  /// Blocking: students still enrolled in this class. Admin must move or
  /// unassign each before the delete can succeed.
  final List<ClassDeleteStudent> students;

  /// Blocking: teachers currently set as homeroom of this class.
  final List<ClassDeleteHomeroomTeacher> homeroomTeachers;

  /// Informational only — these will CASCADE-delete automatically.
  final int autoRemovedCurriculumSubjects;
  final int autoRemovedTeacherAssignments;

  bool get hasBlockers => students.isNotEmpty || homeroomTeachers.isNotEmpty;

  factory ClassDeletePreflight.fromJson(Map<String, dynamic> json) {
    final auto = json['auto_removed'] as Map<String, dynamic>? ?? const {};
    return ClassDeletePreflight(
      students: ((json['students'] as List<dynamic>?) ?? const [])
          .map(
            (e) => ClassDeleteStudent.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
      homeroomTeachers:
          ((json['homeroom_teachers'] as List<dynamic>?) ?? const [])
              .map(
                (e) => ClassDeleteHomeroomTeacher.fromJson(
                  Map<String, dynamic>.from(e as Map),
                ),
              )
              .toList(),
      autoRemovedCurriculumSubjects:
          (auto['curriculum_subjects'] as num?)?.toInt() ?? 0,
      autoRemovedTeacherAssignments:
          (auto['teacher_assignments'] as num?)?.toInt() ?? 0,
    );
  }
}

class ClassDeleteStudent {
  const ClassDeleteStudent({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.admissionNumber,
    this.avatarUrl,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String? admissionNumber;
  final String? avatarUrl;

  String get fullName => '$firstName $lastName';

  factory ClassDeleteStudent.fromJson(Map<String, dynamic> json) {
    return ClassDeleteStudent(
      id: json['id'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      admissionNumber: json['admission_number'] as String?,
      avatarUrl: json['avatar_url'] as String?,
    );
  }
}

class ClassDeleteHomeroomTeacher {
  const ClassDeleteHomeroomTeacher({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.homeroomRole,
    this.avatarUrl,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String? homeroomRole;
  final String? avatarUrl;

  String get fullName => '$firstName $lastName';

  factory ClassDeleteHomeroomTeacher.fromJson(Map<String, dynamic> json) {
    return ClassDeleteHomeroomTeacher(
      id: json['id'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      homeroomRole: json['homeroom_role'] as String?,
      avatarUrl: json['avatar_url'] as String?,
    );
  }
}
