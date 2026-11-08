import 'package:hamrash_admin/api/models/class_structure/class_structure.dart';

/// One person on an arm's teaching team for a session, read with the staff
/// name and the class and arm it belongs to. An arm has one lead and up to
/// two assistants; the database keeps it that way.
class ClassTeacher {
  const ClassTeacher({
    required this.sessionId,
    required this.armId,
    required this.staffId,
    required this.isLead,
    required this.staffName,
    required this.className,
    required this.armName,
  });

  final String sessionId;
  final String armId;
  final String staffId;

  /// True for the lead, false for an assistant.
  final bool isLead;

  /// "Ngozi Eze".
  final String staffName;

  final String className;
  final String armName;

  /// "JSS 1 Gold".
  String get armLabel => fullArmName(className, armName);

  /// The row plus the names the sheets show, for ClassStructureService.
  static const columns =
      'session_id,arm_id,staff_id,is_lead,'
      'staff!class_teachers_staff_fkey(first_name,last_name),'
      'class_arms!class_teachers_arm_fkey(name,'
      'classes!class_arms_class_fkey(name))';

  factory ClassTeacher.fromJson(Map<String, dynamic> json) {
    final staff = _one(json['staff']);
    final arm = _one(json['class_arms']);
    final schoolClass = _one(arm?['classes']);
    final firstName = staff?['first_name'] as String? ?? '';
    final lastName = staff?['last_name'] as String? ?? '';
    return ClassTeacher(
      sessionId: json['session_id'] as String,
      armId: json['arm_id'] as String,
      staffId: json['staff_id'] as String,
      isLead: json['is_lead'] as bool,
      staffName: '$firstName $lastName'.trim(),
      className: schoolClass?['name'] as String? ?? '',
      armName: arm?['name'] as String? ?? '',
    );
  }
}

/// Who teaches one subject in one arm for a session, read with the teacher,
/// subject, class and arm names. The database keeps one teacher per subject
/// per arm per session.
class TeachingAssignment {
  const TeachingAssignment({
    required this.sessionId,
    required this.armId,
    required this.subjectId,
    required this.staffId,
    required this.staffName,
    required this.subjectName,
    required this.className,
    required this.armName,
  });

  final String sessionId;
  final String armId;
  final String subjectId;
  final String staffId;

  /// "Ngozi Eze".
  final String staffName;

  /// "Mathematics".
  final String subjectName;

  final String className;
  final String armName;

  /// "JSS 1 Gold".
  String get armLabel => fullArmName(className, armName);

  /// The row plus the names the sheets show, for SubjectService.
  static const columns =
      'session_id,arm_id,subject_id,staff_id,'
      'staff!teaching_assignments_staff_fkey(first_name,last_name),'
      'subjects!teaching_assignments_subject_fkey(name),'
      'class_arms!teaching_assignments_arm_fkey(name,'
      'classes!class_arms_class_fkey(name))';

  factory TeachingAssignment.fromJson(Map<String, dynamic> json) {
    final staff = _one(json['staff']);
    final subject = _one(json['subjects']);
    final arm = _one(json['class_arms']);
    final schoolClass = _one(arm?['classes']);
    final firstName = staff?['first_name'] as String? ?? '';
    final lastName = staff?['last_name'] as String? ?? '';
    return TeachingAssignment(
      sessionId: json['session_id'] as String,
      armId: json['arm_id'] as String,
      subjectId: json['subject_id'] as String,
      staffId: json['staff_id'] as String,
      staffName: '$firstName $lastName'.trim(),
      subjectName: subject?['name'] as String? ?? '',
      className: schoolClass?['name'] as String? ?? '',
      armName: arm?['name'] as String? ?? '',
    );
  }
}

/// PostgREST gives a many-to-one embed as an object, but a list when the
/// relationship is ambiguous. Take the first either way.
Map<String, dynamic>? _one(Object? embedded) => switch (embedded) {
  final Map value => Map<String, dynamic>.from(value),
  [final Map value, ...] => Map<String, dynamic>.from(value),
  _ => null,
};
