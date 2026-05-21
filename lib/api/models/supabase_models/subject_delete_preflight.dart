/// Snapshot of what's currently blocking a subject delete. Returned by the
/// `preflight_subject_delete` RPC. Every entry here is a RESTRICT-side FK,
/// so all of them must be cleared before the delete can succeed.
class SubjectDeletePreflight {
  const SubjectDeletePreflight({
    required this.classes,
    required this.teacherAssignments,
    required this.enrolledStudentsCount,
  });

  /// Classes that currently include this subject in their curriculum.
  final List<SubjectDeleteClass> classes;

  /// Teacher × class assignments using this subject.
  final List<SubjectDeleteTeacherAssignment> teacherAssignments;

  /// Total student enrollments. Often large — surfaced as a count + bulk
  /// action rather than an itemised list.
  final int enrolledStudentsCount;

  bool get hasBlockers =>
      classes.isNotEmpty ||
      teacherAssignments.isNotEmpty ||
      enrolledStudentsCount > 0;

  factory SubjectDeletePreflight.fromJson(Map<String, dynamic> json) {
    return SubjectDeletePreflight(
      classes: ((json['classes'] as List<dynamic>?) ?? const [])
          .map(
            (e) => SubjectDeleteClass.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
      teacherAssignments:
          ((json['teacher_assignments'] as List<dynamic>?) ?? const [])
              .map(
                (e) => SubjectDeleteTeacherAssignment.fromJson(
                  Map<String, dynamic>.from(e as Map),
                ),
              )
              .toList(),
      enrolledStudentsCount:
          (json['enrolled_students_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class SubjectDeleteClass {
  const SubjectDeleteClass({
    required this.classSubjectId,
    required this.classId,
    required this.name,
    this.section,
  });

  /// PK of the `class_subjects` row — what we delete to remove from
  /// curriculum.
  final String classSubjectId;
  final String classId;
  final String name;
  final String? section;

  String get displayName => section != null ? '$name $section' : name;

  factory SubjectDeleteClass.fromJson(Map<String, dynamic> json) {
    return SubjectDeleteClass(
      classSubjectId: json['class_subject_id'] as String,
      classId: json['class_id'] as String,
      name: json['name'] as String,
      section: json['section'] as String?,
    );
  }
}

class SubjectDeleteTeacherAssignment {
  const SubjectDeleteTeacherAssignment({
    required this.assignmentId,
    required this.teacherId,
    required this.teacherFirstName,
    required this.teacherLastName,
    required this.classId,
    required this.className,
    this.classSection,
  });

  /// PK of the `teacher_class_subjects` row.
  final String assignmentId;
  final String teacherId;
  final String teacherFirstName;
  final String teacherLastName;
  final String classId;
  final String className;
  final String? classSection;

  String get teacherFullName => '$teacherFirstName $teacherLastName';
  String get classDisplayName =>
      classSection != null ? '$className $classSection' : className;

  factory SubjectDeleteTeacherAssignment.fromJson(Map<String, dynamic> json) {
    return SubjectDeleteTeacherAssignment(
      assignmentId: json['assignment_id'] as String,
      teacherId: json['teacher_id'] as String,
      teacherFirstName: json['teacher_first_name'] as String,
      teacherLastName: json['teacher_last_name'] as String,
      classId: json['class_id'] as String,
      className: json['class_name'] as String,
      classSection: json['class_section'] as String?,
    );
  }
}
