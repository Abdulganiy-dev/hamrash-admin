import 'dart:math' as math;

import 'package:hamrash_admin/api/models/grading/grade_boundary.dart';
import 'package:hamrash_admin/api/models/grading/grading_numbers.dart';
import 'package:hamrash_admin/api/models/grading/score_column.dart';

/// One line of what saving a grade changes: "B becomes" / "60 to 64, from
/// 60 to 69".
class GradeChange {
  const GradeChange(this.label, this.value);

  final String label;
  final String value;
}

/// The school's grading setup: the score columns a subject's score is made
/// of and the grade scale a percentage is read against.
///
/// [boundaries] is the school default scale. A section can have its own
/// scale on top of it ([sectionBoundaries]); [scoped] gives the setup as one
/// scale sees it, which is what the sheets and the list work on.
///
/// A subject's percentage is its total out of the columns' [totalMarks], and
/// its grade is the highest boundary it reaches. The setup is complete when
/// it has a column and a boundary at 0%, the same two things the database's
/// `grading_problems` reports.
class GradingSetup {
  /// [boundaries] holds every grade the school has: the ones with no
  /// [GradeBoundary.sectionId] are the school default, the rest are split by
  /// section.
  factory GradingSetup({
    required List<ScoreColumn> columns,
    required List<GradeBoundary> boundaries,
  }) {
    final school = <GradeBoundary>[];
    final bySection = <String, List<GradeBoundary>>{};
    for (final boundary in boundaries) {
      final section = boundary.sectionId;
      if (section == null) {
        school.add(boundary);
      } else {
        (bySection[section] ??= []).add(boundary);
      }
    }
    return GradingSetup._(
      columns: columns,
      boundaries: school,
      sectionBoundaries: bySection,
    );
  }

  GradingSetup._({
    required List<ScoreColumn> columns,
    required List<GradeBoundary> boundaries,
    Map<String, List<GradeBoundary>> sectionBoundaries = const {},
  }) : columns = List.unmodifiable(
         [...columns]..sort((a, b) {
           final byOrder = a.sortOrder.compareTo(b.sortOrder);
           return byOrder != 0 ? byOrder : a.name.compareTo(b.name);
         }),
       ),
       boundaries = _highestFirst(boundaries),
       sectionBoundaries = Map.unmodifiable({
         for (final entry in sectionBoundaries.entries)
           entry.key: _highestFirst(entry.value),
       });

  static List<GradeBoundary> _highestFirst(List<GradeBoundary> boundaries) =>
      List.unmodifiable(
        [...boundaries]..sort((a, b) => b.minPercent.compareTo(a.minPercent)),
      );

  /// In report-card order.
  final List<ScoreColumn> columns;

  /// The scale this setup is about, highest first: the school default, or a
  /// section's own after [scoped].
  final List<GradeBoundary> boundaries;

  /// Each section's own scale by section id, highest first. Only on the full
  /// setup, not on a [scoped] one.
  final Map<String, List<GradeBoundary>> sectionBoundaries;

  /// Largest mark either field can hold: the database keeps `numeric(6, 2)`.
  static const maxMarks = 9999.99;

  /// The setup as the scale of [sectionId] sees it (null: the school
  /// default). The columns are always the school's.
  GradingSetup scoped(String? sectionId) {
    if (sectionId == null) return this;
    return GradingSetup._(
      columns: columns,
      boundaries: sectionBoundaries[sectionId] ?? const [],
    );
  }

  bool hasOwnScale(String sectionId) =>
      sectionBoundaries.containsKey(sectionId);

  bool get hasColumns => columns.isNotEmpty;
  bool get hasBoundaries => boundaries.isNotEmpty;

  /// Nothing set up at all: the "Grading isn't set up yet" start. A section's
  /// own scale counts as something.
  bool get isEmpty =>
      columns.isEmpty && boundaries.isEmpty && sectionBoundaries.isEmpty;

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

  /// "60 to 69": from where the grade starts to just before the next one.
  String rangeOf(GradeBoundary boundary) => _range(boundaries, boundary);

  /// [boundary]'s range on [sorted] (highest first).
  static String _range(List<GradeBoundary> sorted, GradeBoundary boundary) {
    final index = sorted.indexWhere((b) => b.id == boundary.id);
    final end = index > 0 ? _endBefore(sorted[index - 1].minPercent) : 100.0;
    return '${GradingNumbers.format(boundary.minPercent)} to '
        '${GradingNumbers.format(end)}';
  }

  /// "Excellent · Pass", "Very Good · Fail", or just "Pass" / "Fail" when
  /// there is no remark or the remark already says it.
  String detailsOf(GradeBoundary boundary) {
    final remark = boundary.remark?.trim() ?? '';
    final flag = boundary.isPass ? 'Pass' : 'Fail';
    if (remark.isEmpty) return flag;
    if (remark.toLowerCase() == flag.toLowerCase()) return remark;
    return '$remark · $flag';
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
      final free = _nextFreeWhole(value, except: except);
      return '${owner.grade} already starts at '
          '${GradingNumbers.format(value)}. '
          '${free == null ? 'Edit ${owner.grade}.' : 'Try ${GradingNumbers.format(free)}, or edit ${owner.grade}.'}';
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

  /// The nearest whole number above [value] that no grade starts at, or null
  /// when everything up to 99 is taken.
  double? _nextFreeWhole(double value, {GradeBoundary? except}) {
    for (var n = value.floor() + 1; n < 100; n++) {
      if (_startingAt(n.toDouble(), except: except) == null) {
        return n.toDouble();
      }
    }
    return null;
  }

  /// Whether a new grade starting at [percentText] is a pass by default:
  /// yes, unless it starts below the lowest pass grade (so a grade from 0
  /// is a fail until told otherwise).
  bool defaultIsPass(String percentText) {
    final value = GradingNumbers.parse(percentText);
    if (value == null) return true;
    double? lowestPass;
    for (final b in boundaries) {
      if (b.isPass && (lowestPass == null || b.minPercent < lowestPass)) {
        lowestPass = b.minPercent;
      }
    }
    return lowestPass == null || value >= lowestPass;
  }

  /// The scale as it would be with the grade named [name] starting at
  /// [percentText] (replacing [except] when editing). Null until the start is
  /// valid.
  ({List<GradeBoundary> scale, GradeBoundary grade, String label})? _withGrade(
    String name,
    String percentText, {
    GradeBoundary? except,
  }) {
    final start = percent(percentText, except: except);
    if (start == null) return null;
    final typed = name.trim();
    final label = typed.isNotEmpty ? typed : (except?.grade ?? '');
    final grade = GradeBoundary(
      id: except?.id ?? '_new',
      grade: label,
      minPercent: start,
      remark: null,
      isPass: true,
    );
    final scale = _highestFirst([
      for (final b in boundaries)
        if (b.id != except?.id) b,
      grade,
    ]);
    return (scale: scale, grade: grade, label: label);
  }

  /// What saving changes: the new or edited grade's range and the range of
  /// the grade just below it, in the list's "60 to 69" wording. Empty while
  /// the start isn't valid, and when an edit leaves the start where it was.
  List<GradeChange> gradeChanges({
    required String name,
    required String percentText,
    GradeBoundary? except,
  }) {
    final result = _withGrade(name, percentText, except: except);
    if (result == null) return const [];
    final (:scale, :grade, :label) = result;
    if (except != null && grade.minPercent == except.minPercent) {
      return const [];
    }

    final range = _range(scale, grade);
    final changes = <GradeChange>[
      except == null
          ? GradeChange('New grade', range)
          : GradeChange(
              '${label.isEmpty ? 'This grade' : label} becomes',
              '$range, from ${rangeOf(except)}',
            ),
    ];

    final index = scale.indexWhere((b) => b.id == grade.id);
    if (index < scale.length - 1) {
      final below = scale[index + 1];
      final now = _range(scale, below);
      final before = rangeOf(below);
      if (now != before) {
        changes.add(
          GradeChange('${below.grade} becomes', '$now, from $before'),
        );
      }
    }
    return changes;
  }

  /// A warning when the grade would sit under one whose name comes later in
  /// the alphabet, like A starting below B. Only letter names (A, B2) are
  /// judged; null otherwise.
  String? gradeOrderWarning({
    required String name,
    required String percentText,
    GradeBoundary? except,
  }) {
    final result = _withGrade(name, percentText, except: except);
    if (result == null || result.label.isEmpty) return null;
    final (:scale, :grade, label: _) = result;
    final index = scale.indexWhere((b) => b.id == grade.id);

    final pairs = [
      if (index > 0) (above: scale[index - 1], below: grade),
      if (index < scale.length - 1) (above: grade, below: scale[index + 1]),
    ];
    for (final (:above, :below) in pairs) {
      if (_isOutOfOrder(above.grade, below.grade)) {
        return '${below.grade} will now be below ${above.grade}. '
            'Grades usually go down from A.';
      }
    }
    return null;
  }

  /// [above] (the higher grade) has a later letter than [below], or the same
  /// letter with a bigger number. False unless both look like A or B2.
  static bool _isOutOfOrder(String above, String below) {
    final pattern = RegExp(r'^([A-Za-z])(\d*)$');
    final a = pattern.firstMatch(above.trim());
    final b = pattern.firstMatch(below.trim());
    if (a == null || b == null) return false;
    final letters = a
        .group(1)!
        .toUpperCase()
        .compareTo(b.group(1)!.toUpperCase());
    if (letters != 0) return letters > 0;
    int number(RegExpMatch m) => int.tryParse(m.group(2)!) ?? 0;
    return number(a) > number(b);
  }
}
