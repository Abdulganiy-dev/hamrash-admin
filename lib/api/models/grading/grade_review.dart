import 'package:hamrash_admin/api/models/grading/grade_boundary.dart';
import 'package:hamrash_admin/api/models/grading/grading_numbers.dart';
import 'package:hamrash_admin/api/models/grading/section_grading.dart';

/// A score typed into the review screen, worked out locally. Nothing is
/// saved.
class GradeReview {
  const GradeReview({
    required this.totalScore,
    required this.totalMarks,
    required this.percent,
    required this.grade,
  });

  factory GradeReview.calculate({
    required SectionGrading grading,
    required Map<String, String> scores,
  }) {
    var total = 0.0;
    for (final column in grading.columns) {
      final parsed = _score(scores[column.id], column.maxScore);
      total += parsed;
    }
    total = GradingNumbers.round(total);
    final outOf = grading.totalMarks;
    final percent = outOf <= 0 ? 0 : (total / outOf * 100).round();
    return GradeReview(
      totalScore: total,
      totalMarks: outOf,
      percent: percent,
      grade: grading.gradeFor(percent),
    );
  }

  final double totalScore;
  final double totalMarks;

  /// Rounded to a whole number, as the database does before grading.
  final int percent;
  final GradeBoundary? grade;

  /// "86 out of 100 marks".
  String get scoreLine =>
      '${GradingNumbers.format(totalScore)} out of '
      '${GradingNumbers.format(totalMarks)} marks';

  /// "86%".
  String get percentLabel => '$percent%';

  /// "Pass · 70 to 100", or "Fail · 0 to 39".
  String get gradeLine {
    final grade = this.grade;
    if (grade == null) return 'No grade';
    return '${grade.flag} · ${grade.range}';
  }

  /// A score typed into one field, around 0 to the column's mark.
  static double _score(String? text, double max) {
    final value = GradingNumbers.parse(text ?? '');
    if (value == null) return 0;
    if (value < 0) return 0;
    if (value > max) return GradingNumbers.round(max);
    return GradingNumbers.round(value);
  }
}
