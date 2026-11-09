import 'package:hamrash_admin/api/models/grading/grade_boundary.dart';

/// A ready-made grade scale a section can start from. Every value stays
/// editable afterwards.
enum GradeSystem {
  waec(
    label: 'WAEC',
    title: 'WAEC grades',
    blurb:
        'A1 to F9, the 9 grades on WAEC and NECO senior results. Suits '
        'classes preparing for those exams.',
    badge: 'Usual for SS',
    footnote:
        'Usual WAEC values as defaults. Exam bodies and schools differ, so '
        'every value stays editable.',
    grades: [
      (grade: 'A1', min: 75, max: 100, remark: 'Excellent', isPass: true),
      (grade: 'B2', min: 70, max: 74, remark: 'Very Good', isPass: true),
      (grade: 'B3', min: 65, max: 69, remark: 'Good', isPass: true),
      (grade: 'C4', min: 60, max: 64, remark: 'Credit', isPass: true),
      (grade: 'C5', min: 55, max: 59, remark: 'Credit', isPass: true),
      (grade: 'C6', min: 50, max: 54, remark: 'Credit', isPass: true),
      (grade: 'D7', min: 45, max: 49, remark: 'Pass', isPass: true),
      (grade: 'E8', min: 40, max: 44, remark: 'Pass', isPass: true),
      (grade: 'F9', min: 0, max: 39, remark: 'Fail', isPass: false),
    ],
  ),
  standard(
    label: 'Standard',
    title: 'Standard grades',
    blurb: 'A to F, 6 grades. A general scale to adapt to your school.',
    badge: null,
    footnote: 'Default values. Every value stays editable.',
    grades: [
      (grade: 'A', min: 70, max: 100, remark: 'Excellent', isPass: true),
      (grade: 'B', min: 60, max: 69, remark: 'Very Good', isPass: true),
      (grade: 'C', min: 50, max: 59, remark: 'Good', isPass: true),
      (grade: 'D', min: 45, max: 49, remark: 'Fair', isPass: true),
      (grade: 'E', min: 40, max: 44, remark: 'Pass', isPass: true),
      (grade: 'F', min: 0, max: 39, remark: 'Fail', isPass: false),
    ],
  );

  const GradeSystem({
    required this.label,
    required this.title,
    required this.blurb,
    required this.badge,
    required this.footnote,
    required this.grades,
  });

  /// "WAEC" / "Standard".
  final String label;

  /// "WAEC grades" / "Standard grades".
  final String title;
  final String blurb;
  final String? badge;
  final String footnote;

  /// Highest first.
  final List<({String grade, int min, int max, String remark, bool isPass})>
  grades;

  /// The preset as grade rows, with ids the app only uses before saving.
  List<GradeBoundary> get boundaries => [
    for (final (i, row) in grades.indexed)
      GradeBoundary(
        id: 'preset-$name-$i',
        grade: row.grade,
        minPercent: row.min,
        maxPercent: row.max,
        remark: row.remark,
        isPass: row.isPass,
      ),
  ];

  /// "A1 to F9", "A to F".
  String get firstToLast => '${grades.first.grade} to ${grades.last.grade}';

  /// Which preset [boundaries] is, or null for a custom scale.
  static GradeSystem? of(List<GradeBoundary> boundaries) {
    for (final system in values) {
      if (system.matches(boundaries)) return system;
    }
    return null;
  }

  /// Same names and ranges, in any order.
  bool matches(List<GradeBoundary> boundaries) {
    if (boundaries.length != grades.length) return false;
    final byName = {
      for (final row in boundaries) row.grade.trim().toLowerCase(): row,
    };
    if (byName.length != grades.length) return false;
    for (final row in grades) {
      final boundary = byName[row.grade.toLowerCase()];
      if (boundary == null ||
          boundary.minPercent != row.min ||
          boundary.maxPercent != row.max) {
        return false;
      }
    }
    return true;
  }

  /// The other preset, for "Change to …".
  GradeSystem get other => this == waec ? standard : waec;
}
