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
    this.sessionName = '',
  });

  final String sessionId;
  final String armId;
  final String staffId;

  /// "2026/27", when the row was read with its session (the staff page).
  final String sessionName;

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

  /// One person's rows in the current session: the same columns plus the
  /// session, joined inside so the read needs no session id first.
  static const currentSessionColumns =
      '$columns,'
      'academic_sessions!class_teachers_session_fkey!inner(name,is_current)';

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
      sessionName: _one(json['academic_sessions'])?['name'] as String? ?? '',
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
    this.sessionName = '',
  });

  final String sessionId;
  final String armId;
  final String subjectId;

  /// "2026/27", when the row was read with its session (the staff page).
  final String sessionName;
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

  /// One person's rows in the current session, with the session joined
  /// inside so the read needs no session id first.
  static const currentSessionColumns =
      '$columns,'
      'academic_sessions!teaching_assignments_session_fkey!inner(name,is_current)';

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
      sessionName: _one(json['academic_sessions'])?['name'] as String? ?? '',
    );
  }
}

/// A subject an arm takes, with its name and whether it is compulsory:
/// what the subject picker offers once an arm is chosen.
class SubjectOffering {
  const SubjectOffering({
    required this.subjectId,
    required this.name,
    required this.isCompulsory,
    required this.sortOrder,
    this.code,
  });

  final String subjectId;
  final String name;
  final bool isCompulsory;

  /// Report-card order.
  final int sortOrder;

  /// Short code, e.g. MTH, when the school set one.
  final String? code;

  static const columns =
      'subject_id,is_compulsory,'
      'subjects!arm_subjects_subject_fkey(name,code,sort_order)';

  factory SubjectOffering.fromJson(Map<String, dynamic> json) {
    final subject = _one(json['subjects']);
    return SubjectOffering(
      subjectId: json['subject_id'] as String,
      name: subject?['name'] as String? ?? '',
      isCompulsory: json['is_compulsory'] as bool,
      sortOrder: subject?['sort_order'] as int? ?? 0,
      code: subject?['code'] as String?,
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
