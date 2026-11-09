import 'package:hamrash_admin/api/models/grading/grade_boundary.dart';
import 'package:hamrash_admin/api/models/grading/grading_numbers.dart';
import 'package:hamrash_admin/api/models/grading/score_column.dart';

/// The school's grading setup: the score columns a subject's score is made
/// of and the grade scale a percentage is read against. Only the school's
/// own set (no section's overrides).
///
/// A subject's percentage is its total out of the columns' [totalMarks], and
/// its grade is the highest boundary it reaches. The setup is complete when
/// it has a column and a boundary at 0%, the same two things the database's
/// `grading_problems` reports.
class GradingSetup {
  GradingSetup({
    required List<ScoreColumn> columns,
    required List<GradeBoundary> boundaries,
  }) : columns = List.unmodifiable(
         [...columns]..sort((a, b) {
           final byOrder = a.sortOrder.compareTo(b.sortOrder);
           return byOrder != 0 ? byOrder : a.name.compareTo(b.name);
         }),
       ),
       boundaries = List.unmodifiable(
         [...boundaries]..sort((a, b) => b.minPercent.compareTo(a.minPercent)),
       );

  /// In report-card order.
  final List<ScoreColumn> columns;

  /// Highest first.
  final List<GradeBoundary> boundaries;

  /// Largest mark either field can hold: the database keeps `numeric(6, 2)`.
  static const maxMarks = 9999.99;

  bool get hasColumns => columns.isNotEmpty;
  bool get hasBoundaries => boundaries.isNotEmpty;

  /// Nothing set up at all: the "Grading isn't set up yet" start.
  bool get isEmpty => columns.isEmpty && boundaries.isEmpty;

  /// What every subject's score is out of.
  double get totalMarks =>
      GradingNumbers.round(columns.fold(0.0, (sum, c) => sum + c.maxScore));

  /// A boundary at 0% means every percentage gets a grade.
  bool get hasZeroBoundary => boundaries.any((b) => b.minPercent == 0);

  bool get isComplete => hasColumns && hasZeroBoundary;

  /// Added at the end of the report card.
  int get nextSortOrder => columns.isEmpty
      ? 1
      : columns.map((c) => c.sortOrder).reduce((a, b) => a > b ? a : b) + 1;

  // ── Grade scale ──────────────────────────────────────────────────────

  /// "0 to 39" when nothing starts at 0, or "0 to 100" with no grades at
  /// all. Null when every percentage gets a grade.
  String? get uncoveredRange {
    if (hasZeroBoundary) return null;
    final lowest = boundaries.isEmpty ? null : boundaries.last.minPercent;
    return '0 to ${lowest == null ? '100' : GradingNumbers.format(_endBefore(lowest))}';
  }

  /// The grade above [boundary] on the scale, or null for the top one.
  GradeBoundary? _above(GradeBoundary boundary) {
    final index = boundaries.indexWhere((b) => b.id == boundary.id);
    return index > 0 ? boundaries[index - 1] : null;
  }

  /// "60 to 69": from where the grade starts to just before the next one.
  String rangeOf(GradeBoundary boundary) {
    final above = _above(boundary);
    final end = above == null ? 100.0 : _endBefore(above.minPercent);
    return '${GradingNumbers.format(boundary.minPercent)} to '
        '${GradingNumbers.format(end)}';
  }

  /// "Excellent · Pass", or "Fail · Not a pass".
  String detailsOf(GradeBoundary boundary) {
    final remark = boundary.remark?.trim();
    return [
      if (remark != null && remark.isNotEmpty) remark,
      boundary.isPass ? 'Pass' : 'Not a pass',
    ].join(' · ');
  }

  /// A whole number starts the next grade: the row stops one short of it.
  /// With decimals it stops 0.01 short.
  static double _endBefore(double next) => next == next.roundToDouble()
      ? next - 1
      : GradingNumbers.round(next - 0.01);

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
        ? 'There’s already a column called ${name.trim()}. Use another name.'
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
    if (value <= 0) {
      return 'A column has to be out of more than 0. Enter at least 0.01.';
    }
    if (value > maxMarks) return 'A column can be out of 9,999.99 at most.';
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

  // ── Grade sheets ─────────────────────────────────────────────────────

  /// Why [name] can't be a grade's name, or null.
  String? gradeNameProblem(String name, {GradeBoundary? except}) {
    final wanted = name.trim().toLowerCase();
    if (wanted.isEmpty) return null;
    final taken = boundaries.any(
      (b) => b.id != except?.id && b.grade.trim().toLowerCase() == wanted,
    );
    return taken
        ? 'There’s already a grade called ${name.trim()}. Use another name.'
        : null;
  }

  /// Why [text] can't be where a grade starts, or null (also for blank).
  String? percentProblem(String text, {GradeBoundary? except}) {
    if (text.trim().isEmpty) return null;
    final value = GradingNumbers.parse(text);
    if (value == null) return 'Enter a number, like 70 or 74.5.';
    if (GradingNumbers.hasTooManyDecimals(text)) {
      return 'Use up to 2 decimal places.';
    }
    if (value >= 100) {
      return 'A grade has to start below 100. Enter 99.99 at most.';
    }
    final owner = _startingAt(value, except: except);
    if (owner != null) {
      return '${owner.grade} already starts at '
          '${GradingNumbers.format(value)}. Pick a number no other grade uses.';
    }
    return null;
  }

  /// The percentage in [text], or null when blank or not valid.
  double? percent(String text, {GradeBoundary? except}) =>
      percentProblem(text, except: except) != null
      ? null
      : GradingNumbers.parse(text);

  GradeBoundary? _startingAt(double value, {GradeBoundary? except}) {
    for (final b in boundaries) {
      if (b.id != except?.id && b.minPercent == GradingNumbers.round(value)) {
        return b;
      }
    }
    return null;
  }

  /// "69.99, where A starts", or "100" for the top grade. Null until the
  /// starting point is valid.
  String? goesUpTo(String text, {GradeBoundary? except}) {
    final value = percent(text, except: except);
    if (value == null) return null;
    GradeBoundary? next;
    for (final b in boundaries) {
      if (b.id == except?.id || b.minPercent <= value) continue;
      if (next == null || b.minPercent < next.minPercent) next = b;
    }
    if (next == null) return '100';
    return '${GradingNumbers.format(GradingNumbers.round(next.minPercent - 0.01))}, '
        'where ${next.grade} starts';
  }
}
