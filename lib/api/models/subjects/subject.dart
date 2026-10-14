/// One subject in the school's list, e.g. Mathematics (MTH). Which arms take
/// it is in [ArmSubject].
class Subject {
  const Subject({
    required this.id,
    required this.name,
    required this.code,
    required this.sortOrder,
    required this.isActive,
    this.teachers = 0,
    this.choices = 0,
  });

  final String id;
  final String name;

  /// Short code for timetables and report cards, e.g. MTH.
  final String? code;

  /// Report-card order.
  final int sortOrder;

  /// Switched-off subjects stay on past records but aren't offered.
  final bool isActive;

  /// Teaching assignments for it, in any session.
  final int teachers;

  /// Students who chose it as an optional subject, in any session.
  final int choices;

  /// The subject plus how much it's used, for [SubjectService].
  static const columns =
      'id,name,code,sort_order,is_active,'
      'teaching_assignments(count),student_subjects(count)';

  factory Subject.fromJson(Map<String, dynamic> json) => Subject(
    id: json['id'] as String,
    name: json['name'] as String,
    code: json['code'] as String?,
    sortOrder: json['sort_order'] as int,
    isActive: json['is_active'] as bool,
    teachers: _count(json['teaching_assignments']),
    choices: _count(json['student_subjects']),
  );

  /// The database keeps a subject that's taught or chosen.
  bool get inUse => teachers > 0 || choices > 0;

  /// "MTH", or the first three letters when there's no code.
  String get shortLabel =>
      code ??
      name.replaceAll(RegExp('[^A-Za-z]'), '').padRight(3).substring(0, 3)
          .trim()
          .toUpperCase();

  /// `[{count: 3}]` from an embedded count, or 0 when it's missing.
  static int _count(Object? embedded) => switch (embedded) {
    [{'count': final int count}, ...] => count,
    _ => 0,
  };
}

/// An arm takes a subject, as compulsory (everyone) or optional (only the
/// students who choose it).
class ArmSubject {
  const ArmSubject({
    required this.armId,
    required this.subjectId,
    required this.isCompulsory,
  });

  final String armId;
  final String subjectId;
  final bool isCompulsory;

  static const columns = 'arm_id,subject_id,is_compulsory';

  factory ArmSubject.fromJson(Map<String, dynamic> json) => ArmSubject(
    armId: json['arm_id'] as String,
    subjectId: json['subject_id'] as String,
    isCompulsory: json['is_compulsory'] as bool,
  );
}
