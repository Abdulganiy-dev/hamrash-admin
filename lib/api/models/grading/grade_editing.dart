import 'package:hamrash_admin/api/models/grading/grade_boundary.dart';

/// One line of what saving a grade changes: "B becomes" / "60 to 70, from
/// 60 to 69".
class GradeChange {
  const GradeChange(this.label, this.value);

  final String label;
  final String value;
}

/// Why a scale can't be saved, or what saving it would do.
class GradeEditOutcome {
  const GradeEditOutcome({this.grades, this.changes = const [], this.error});

  const GradeEditOutcome.pending()
    : grades = null,
      changes = const [],
      error = null;

  /// The whole new scale, or null while there is nothing valid to save.
  final List<GradeBoundary>? grades;
  final List<GradeChange> changes;
  final String? error;

  bool get canSave => grades != null && error == null;
}

/// What removing a grade does to the rest of the scale.
class GradeRemoval {
  const GradeRemoval({
    required this.grades,
    required this.message,
    this.absorbedBy,
  });

  final List<GradeBoundary> grades;

  /// The confirmation line: which neighbour takes the range.
  final String message;

  /// The grade that grew, or null when the set becomes empty.
  final String? absorbedBy;

  bool get isEmpty => grades.isEmpty;
}

/// Whole numbers, ascending, covering 0 to 100 with no gaps and no overlaps.
bool gradeRangesTile(List<GradeBoundary> grades) {
  if (grades.isEmpty) return false;
  final sorted = [...grades]
    ..sort((a, b) => a.minPercent.compareTo(b.minPercent));
  var expected = 0;
  for (final grade in sorted) {
    if (grade.minPercent != expected || grade.maxPercent < grade.minPercent) {
      return false;
    }
    expected = grade.maxPercent + 1;
  }
  return expected == 101;
}

/// Edits one scale as a whole. Every grade change in the app sends the whole
/// new list to `set_grade_scale`, so these helpers build and check that list
/// before the sheet lets it be saved.
class GradeEditor {
  GradeEditor._();

  /// Changes one existing grade. Editing To moves where the grade above
  /// starts; editing From moves where the grade below ends.
  static GradeEditOutcome edit({
    required List<GradeBoundary> grades,
    required GradeBoundary original,
    required String name,
    required int? from,
    required int? to,
    required String? remark,
    required bool isPass,
    required String sectionName,
  }) {
    if (from == null || to == null) return const GradeEditOutcome.pending();
    if (from < 0 || to > 100) {
      return const GradeEditOutcome(
        error:
            'Use a number from 0 to 100. Grades are a percent of the '
            'section’s marks.',
      );
    }

    final trimmed = name.trim();
    final duplicate = _duplicateName(grades, trimmed, exceptId: original.id);
    if (trimmed.isEmpty) {
      return const GradeEditOutcome.pending();
    }
    if (duplicate != null) {
      return GradeEditOutcome(
        error: _duplicateNameMessage(sectionName, trimmed),
      );
    }

    final ascending = [...grades]
      ..sort((a, b) => a.minPercent.compareTo(b.minPercent));
    final index = ascending.indexWhere((g) => g.id == original.id);
    if (index < 0) {
      return const GradeEditOutcome(
        error: 'This grade no longer exists; refresh and try again.',
      );
    }
    final lower = index > 0 ? ascending[index - 1] : null;
    final upper = index < ascending.length - 1 ? ascending[index + 1] : null;

    if (upper == null && to != 100) {
      return const GradeEditOutcome(
        error: 'The top grade always goes up to 100.',
      );
    }
    if (lower == null && from != 0) {
      return const GradeEditOutcome(
        error: 'The lowest grade always starts at 0.',
      );
    }
    if (from > to) {
      return GradeEditOutcome(
        error:
            'From can’t be higher than To. Make From $to or lower, or To '
            '$from or higher.',
      );
    }
    if (lower != null && from <= lower.minPercent) {
      return GradeEditOutcome(error: _coversMessage(lower));
    }
    if (upper != null && to >= upper.maxPercent) {
      return GradeEditOutcome(error: _coversMessage(upper));
    }

    final edited = original.copyWith(
      grade: trimmed,
      minPercent: from,
      maxPercent: to,
      remark: remark,
      clearRemark: true,
      isPass: isPass,
    );
    final next = <GradeBoundary>[
      for (final grade in grades)
        if (grade.id == original.id)
          edited
        else if (lower != null && grade.id == lower.id)
          grade.copyWith(maxPercent: from - 1)
        else if (upper != null && grade.id == upper.id)
          grade.copyWith(minPercent: to + 1)
        else
          grade,
    ];

    if (!gradeRangesTile(next)) {
      return const GradeEditOutcome(
        error: 'Grades have to cover 0 to 100 without gaps or overlaps.',
      );
    }

    final changes = <GradeChange>[];
    if (trimmed != original.grade ||
        from != original.minPercent ||
        to != original.maxPercent) {
      changes.add(
        GradeChange(
          '${trimmed.isEmpty ? original.grade : trimmed} becomes',
          '$from to $to, from ${original.minPercent} to ${original.maxPercent}',
        ),
      );
    }
    if (lower != null && from - 1 != lower.maxPercent) {
      changes.add(
        GradeChange(
          '${lower.grade} will end at',
          '${from - 1}, from ${lower.maxPercent}',
        ),
      );
    }
    if (upper != null && to + 1 != upper.minPercent) {
      changes.add(
        GradeChange(
          '${upper.grade} will start at',
          '${to + 1}, from ${upper.minPercent}',
        ),
      );
    }

    return GradeEditOutcome(grades: next, changes: changes);
  }

  /// Adds a grade inside one band, splitting it. A grade from 0 fills the
  /// uncovered stretch below a legacy scale.
  static GradeEditOutcome add({
    required List<GradeBoundary> grades,
    required String name,
    required int? from,
    required String? remark,
    required bool isPass,
    required String sectionName,
  }) {
    if (from == null) return const GradeEditOutcome.pending();
    if (from < 0 || from > 100) {
      return const GradeEditOutcome(
        error:
            'Use a number from 0 to 100. Grades are a percent of the '
            'section’s marks.',
      );
    }
    final trimmed = name.trim();
    final duplicate = _duplicateName(grades, trimmed);
    if (trimmed.isEmpty) return const GradeEditOutcome.pending();
    if (duplicate != null) {
      return GradeEditOutcome(
        error: _duplicateNameMessage(sectionName, trimmed),
      );
    }

    final ascending = [...grades]
      ..sort((a, b) => a.minPercent.compareTo(b.minPercent));
    final next = [...grades];

    if (ascending.isEmpty) {
      if (from != 0) {
        return const GradeEditOutcome(
          error: 'The first grade has to cover 0 to 100.',
        );
      }
      next.add(
        GradeBoundary(
          id: 'new-0',
          grade: trimmed,
          minPercent: 0,
          maxPercent: 100,
          remark: remark,
          isPass: isPass,
        ),
      );
      return GradeEditOutcome(
        grades: next,
        changes: [GradeChange('$trimmed (new)', '0 to 100')],
      );
    }

    // A legacy scale that starts above 0: a grade from 0 fills the gap.
    final lowest = ascending.first;
    if (from == 0 && lowest.minPercent > 0) {
      final filled = GradeBoundary(
        id: 'new-0',
        grade: trimmed,
        minPercent: 0,
        maxPercent: lowest.minPercent - 1,
        remark: remark,
        isPass: isPass,
      );
      next.add(filled);
      if (!gradeRangesTile(next)) {
        return const GradeEditOutcome(
          error:
              'Grades have to cover 0 to 100 without gaps. Fix the other '
              'gaps first.',
        );
      }
      return GradeEditOutcome(
        grades: next,
        changes: [
          GradeChange('$trimmed (new)', filled.range),
          GradeChange(
            '${lowest.grade} stays',
            '${lowest.minPercent} to ${lowest.maxPercent}',
          ),
        ],
      );
    }

    final band = ascending
        .where((g) => from >= g.minPercent && from <= g.maxPercent)
        .firstOrNull;
    if (band == null) {
      return GradeEditOutcome(
        error: from == 0
            ? 'Add a grade from 0 to start the scale.'
            : 'Choose a percentage inside one of the grades.',
      );
    }
    if (from == band.minPercent) {
      return GradeEditOutcome(
        error:
            '${band.grade} already starts at ${band.minPercent}. Start this '
            'grade higher to split ${band.grade}, or edit ${band.grade} '
            'instead.',
      );
    }

    final added = GradeBoundary(
      id: 'new-$from',
      grade: trimmed,
      minPercent: from,
      maxPercent: band.maxPercent,
      remark: remark,
      isPass: isPass,
    );
    final shortened = band.copyWith(maxPercent: from - 1);
    final list = <GradeBoundary>[
      for (final grade in grades)
        if (grade.id == band.id) shortened else grade,
      added,
    ];
    if (!gradeRangesTile(list)) {
      return const GradeEditOutcome(
        error: 'Grades have to cover 0 to 100 without gaps or overlaps.',
      );
    }

    return GradeEditOutcome(
      grades: list,
      changes: [
        GradeChange('$trimmed (new)', added.range),
        GradeChange(
          '${band.grade} becomes',
          '${shortened.minPercent} to ${shortened.maxPercent}, from '
              '${band.minPercent} to ${band.maxPercent}',
        ),
      ],
    );
  }

  /// Removes [target]. The grade below takes its range, or the grade above
  /// when there is no grade below.
  static GradeRemoval remove({
    required List<GradeBoundary> grades,
    required GradeBoundary target,
    required String sectionName,
    required bool sectionOwned,
  }) {
    final ascending = [...grades]
      ..sort((a, b) => a.minPercent.compareTo(b.minPercent));
    final index = ascending.indexWhere((g) => g.id == target.id);
    if (index < 0) {
      return GradeRemoval(
        grades: grades,
        message: 'This grade no longer exists; refresh and try again.',
      );
    }
    final lower = index > 0 ? ascending[index - 1] : null;
    final upper = index < ascending.length - 1 ? ascending[index + 1] : null;

    if (lower == null && upper == null) {
      return GradeRemoval(
        grades: const [],
        message: sectionOwned
            ? '${target.grade} is the last grade. $sectionName will use the '
                  'school’s grades again.'
            : 'The school needs at least one grade.',
      );
    }

    final next = <GradeBoundary>[];
    for (final grade in grades) {
      if (grade.id == target.id) continue;
      if (lower != null && grade.id == lower.id) {
        next.add(grade.copyWith(maxPercent: target.maxPercent));
      } else if (lower == null && upper != null && grade.id == upper.id) {
        next.add(grade.copyWith(minPercent: target.minPercent));
      } else {
        next.add(grade);
      }
    }

    final grown = lower ?? upper!;
    return GradeRemoval(
      grades: next,
      absorbedBy: grown.grade,
      message:
          '${target.grade} (${target.minPercent} to ${target.maxPercent}) is '
          'removed. ${grown.grade} now covers ${next.where((g) => g.id == grown.id).first.minPercent} '
          'to ${next.where((g) => g.id == grown.id).first.maxPercent}.',
    );
  }

  static GradeBoundary? _duplicateName(
    List<GradeBoundary> grades,
    String name, {
    String? exceptId,
  }) {
    final wanted = name.trim().toLowerCase();
    if (wanted.isEmpty) return null;
    for (final grade in grades) {
      if (grade.id == exceptId) continue;
      if (grade.grade.trim().toLowerCase() == wanted) return grade;
    }
    return null;
  }

  static String _duplicateNameMessage(String sectionName, String name) =>
      '${sectionName.isEmpty ? 'This section' : sectionName} already has a '
      'grade called ${name.trim()}.';

  static String _coversMessage(GradeBoundary neighbour) =>
      'This would cover all of ${neighbour.grade} '
      '(${neighbour.minPercent} to ${neighbour.maxPercent}). Change or '
      'remove ${neighbour.grade} first.';
}
