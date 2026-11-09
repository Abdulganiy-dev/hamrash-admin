import 'dart:math' as math;

import 'package:hamrash_admin/api/models/grading/grade_boundary.dart';
import 'package:hamrash_admin/api/models/grading/grade_editing.dart';
import 'package:hamrash_admin/api/models/grading/grade_systems.dart';
import 'package:hamrash_admin/api/models/grading/grading_numbers.dart';
import 'package:hamrash_admin/api/models/grading/score_column.dart';

/// How far one section's grading has got.
enum GradingStatus {
  notSetUp('Not set up'),
  partlySetUp('Partly set up'),
  setUp('Set up');

  const GradingStatus(this.label);

  final String label;
}

/// One section's grading as a teacher sees it: its own rows when it has any,
/// otherwise the school-level set, independently for score columns and
/// grades.
class SectionGrading {
  SectionGrading({
    required this.sectionId,
    required this.sectionName,
    required List<ScoreColumn> columns,
    required List<GradeBoundary> grades,
    required this.hasOwnColumns,
    required this.hasOwnGrades,
    required this.usesSchoolColumns,
    required this.usesSchoolGrades,
  }) : columns = List.unmodifiable(
         [...columns]..sort((a, b) {
           final order = a.sortOrder.compareTo(b.sortOrder);
           return order != 0 ? order : a.name.compareTo(b.name);
         }),
       ),
       grades = List.unmodifiable(
         [...grades]..sort((a, b) => b.minPercent.compareTo(a.minPercent)),
       );

  final String? sectionId;
  final String sectionName;

  /// In report-card order.
  final List<ScoreColumn> columns;

  /// Highest first.
  final List<GradeBoundary> grades;

  final bool hasOwnColumns;
  final bool hasOwnGrades;

  /// This section has no own rows of that kind, so it follows the school's.
  final bool usesSchoolColumns;
  final bool usesSchoolGrades;

  /// Largest mark either field can hold: the database keeps `numeric(6, 2)`.
  static const maxMarks = 9999.99;

  bool get hasColumns => columns.isNotEmpty;
  bool get hasGrades => grades.isNotEmpty;

  /// Every percentage gets exactly one grade.
  bool get gradesTile => gradeRangesTile(grades);

  bool get isComplete => hasColumns && gradesTile;

  GradingStatus get status {
    if (hasColumns && gradesTile) return GradingStatus.setUp;
    if (hasColumns || gradesTile) return GradingStatus.partlySetUp;
    return GradingStatus.notSetUp;
  }

  /// Uses the school's setup for both parts, with nothing of its own.
  bool get usesSchoolSetup =>
      usesSchoolColumns && usesSchoolGrades && !hasOwnColumns && !hasOwnGrades;

  /// "3 columns · 100 marks · Standard grades".
  String get summary {
    if (!hasColumns && !hasGrades) return 'No columns or grades yet';
    final columnsPart = hasColumns
        ? '${_count(columns.length, 'column')} · $marksLabel'
        : 'No columns yet';
    final gradesPart = hasGrades
        ? (gradesTile
              ? '${gradeSystem?.label ?? _count(grades.length, 'grade')}'
                    '${gradeSystem == null ? '' : ' grades'}'
              : 'Grades don’t cover 0 to 100')
        : 'No grades yet';
    return '$columnsPart · $gradesPart';
  }

  /// "3 columns · 100 marks" for the section page's Score columns row.
  String get columnsSummary => hasColumns
      ? '${_count(columns.length, 'column')} · $marksLabel'
      : 'No columns yet';

  /// "Standard · 6 grades · covers 0 to 100" for the Grades row.
  String get gradesSummary {
    if (!hasGrades) return 'No grades yet';
    final system = gradeSystem?.label ?? _count(grades.length, 'grade');
    final count = gradeSystem == null
        ? ''
        : ' · ${_count(grades.length, 'grade')}';
    return gradesTile
        ? '$system$count · covers 0 to 100'
        : '$system$count · doesn’t cover 0 to 100 yet';
  }

  /// "Standard", "WAEC", or null for a custom scale.
  GradeSystem? get gradeSystem => GradeSystem.of(grades);

  /// What every subject's score is out of.
  double get totalMarks =>
      GradingNumbers.round(columns.fold(0.0, (sum, c) => sum + c.maxScore));

  /// "100 marks".
  String get marksLabel => '${GradingNumbers.format(totalMarks)} marks';

  /// The percentage [column] contributes to a subject's score, whole.
  int shareOf(ScoreColumn column) {
    final total = totalMarks;
    if (total <= 0) return 0;
    return (column.maxScore / total * 100).round();
  }

  /// 0 to 39 when a legacy scale leaves the bottom uncovered, or the first
  /// gap between two grades.
  String? get uncoveredRange {
    if (!hasGrades || gradesTile) return null;
    final ascending = [...grades]
      ..sort((a, b) => a.minPercent.compareTo(b.minPercent));
    var expected = 0;
    for (final grade in ascending) {
      if (grade.minPercent > expected) {
        return _range(expected, grade.minPercent - 1);
      }
      if (grade.maxPercent < expected) continue;
      expected = grade.maxPercent + 1;
    }
    return expected <= 100 ? _range(expected, 100) : null;
  }

  /// The grade a whole percentage gets, highest start it reaches.
  GradeBoundary? gradeFor(int percent) {
    for (final grade in grades) {
      if (grade.minPercent <= percent) return grade;
    }
    return null;
  }

  /// "70 to 100".
  String rangeOf(GradeBoundary grade) => grade.range;

  /// "Excellent · Pass", "Very Good · Fail", or just "Pass" / "Fail" when
  /// there is no remark or the remark already says it.
  String detailsOf(GradeBoundary grade) {
    final remark = grade.remark?.trim() ?? '';
    if (remark.isEmpty) return grade.flag;
    if (remark.toLowerCase() == grade.flag.toLowerCase()) return remark;
    return '$remark · ${grade.flag}';
  }

  /// "A 70 to 100 · B 60 to 69 · F 0 to 39 (Fail)".
  String get gradesLine {
    final ascending = [...grades]
      ..sort((a, b) => a.minPercent.compareTo(b.minPercent));
    return [
      for (final grade in ascending.reversed)
        '${grade.grade} ${grade.range}'
            '${grade.isPass ? '' : ' (Fail)'}',
    ].join(' · ');
  }

  // ── Score column sheets ──────────────────────────────────────────────

  /// Why [name] can't be a column's name, or null. Blank isn't a problem
  /// here: the sheet just won't save it.
  String? columnNameProblem(String name, {ScoreColumn? except}) {
    final wanted = name.trim().toLowerCase();
    if (wanted.isEmpty) return null;
    final taken = columns.any(
      (c) => c.id != except?.id && c.name.trim().toLowerCase() == wanted,
    );
    return taken
        ? '${sectionName.isEmpty ? 'This section' : sectionName} already has '
              'a column called ${name.trim()}. Pick another name.'
        : null;
  }

  /// Why [text] can't be a column's marks, or null (also for blank).
  static String? marksProblem(String text) {
    if (text.trim().isEmpty) return null;
    final value = GradingNumbers.parse(text);
    if (value == null) return 'Enter a number, like 20 or 12.5.';
    if (GradingNumbers.hasTooManyDecimals(text)) {
      return 'Use up to 2 decimal places.';
    }
    if (value <= 0) return 'Enter marks above 0, like 20 or 12.5.';
    if (value > maxMarks) return 'Enter marks under 9,999.99.';
    return null;
  }

  /// The marks in [text], or null when blank or not valid.
  static double? marks(String text) =>
      marksProblem(text) != null ? null : GradingNumbers.parse(text);

  /// The total with a column out of [text] added, or in place of
  /// [replacing]. Null until the marks are valid.
  double? totalWith(String text, {ScoreColumn? replacing}) {
    final value = marks(text);
    if (value == null) return null;
    return GradingNumbers.round(
      totalMarks - (replacing?.maxScore ?? 0) + value,
    );
  }

  /// The total line of a column sheet: "Total stays" / "100 marks" when
  /// nothing changes, "Total becomes" / "120 marks, from 100 now" otherwise,
  /// and a muted prompt until the marks are valid.
  ({String label, String value, bool muted}) totalLine(
    String marksText, {
    ScoreColumn? replacing,
  }) {
    final total = totalWith(marksText, replacing: replacing);
    if (total == null) {
      return (
        label: 'Total becomes',
        value: 'Enter the marks first',
        muted: true,
      );
    }
    if (total == totalMarks) {
      return (
        label: 'Total stays',
        value: '${GradingNumbers.format(total)} marks',
        muted: false,
      );
    }
    return (
      label: 'Total becomes',
      value:
          '${GradingNumbers.format(total)} marks, from '
          '${GradingNumbers.format(totalMarks)} now',
      muted: false,
    );
  }

  /// 100 when the columns add up to 100.
  bool get totalIsHundred => (totalMarks - 100).abs() < 0.005;

  /// Names the add sheet offers as chips, skipping any already used: the
  /// next CA number (CA 3 after CA 1 and CA 2), Test and Assignment.
  List<String> get columnSuggestions {
    final used = {for (final c in columns) c.name.trim().toLowerCase()};
    var nextCa = 1;
    for (final column in columns) {
      final match = RegExp(
        r'^CA\s*(\d+)$',
        caseSensitive: false,
      ).firstMatch(column.name.trim());
      if (match != null) {
        nextCa = math.max(nextCa, int.parse(match.group(1)!) + 1);
      }
    }
    return [
      for (final name in ['CA $nextCa', 'Test', 'Assignment'])
        if (!used.contains(name.toLowerCase())) name,
    ];
  }

  /// Why [name] can't be a grade's name, or null.
  String? gradeNameProblem(String name, {GradeBoundary? except}) {
    final wanted = name.trim().toLowerCase();
    if (wanted.isEmpty) return null;
    final taken = grades.any(
      (g) => g.id != except?.id && g.grade.trim().toLowerCase() == wanted,
    );
    return taken
        ? '${sectionName.isEmpty ? 'This section' : sectionName} already has '
              'a grade called ${name.trim()}.'
        : null;
  }

  /// Whether a new grade from [fromText] is a pass by default: yes, unless
  /// it becomes the lowest grade (so a grade from 0 starts as a fail).
  bool defaultIsPass(String fromText) {
    final value = int.tryParse(fromText.trim());
    if (value == null) return true;
    if (grades.isEmpty) return value > 0;
    final lowest = grades.last.minPercent;
    return value > lowest;
  }

  static String _range(int start, int end) =>
      start == end ? '$start' : '$start to $end';

  static String _count(int count, String noun) =>
      '$count $noun${count == 1 ? '' : 's'}';
}
