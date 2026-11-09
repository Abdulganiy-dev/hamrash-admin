import 'package:hamrash_admin/api/models/class_structure/class_structure.dart';
import 'package:hamrash_admin/api/models/grading/grade_boundary.dart';
import 'package:hamrash_admin/api/models/grading/score_column.dart';
import 'package:hamrash_admin/api/models/grading/section_grading.dart';

export 'package:hamrash_admin/api/models/grading/grade_editing.dart'
    show GradeChange;

/// Everything the school has for grading: its school-level score columns and
/// grades, plus each section's own rows.
///
/// The fall-back is per kind: an arm uses its section's own columns if it has
/// any, otherwise the school-level set; independently, its section's own
/// grades if it has any, otherwise the school-level set.
class GradingSetup {
  GradingSetup({
    required List<ScoreColumn> columns,
    required List<GradeBoundary> grades,
  }) : columns = List.unmodifiable(columns),
       grades = List.unmodifiable(grades);

  final List<ScoreColumn> columns;
  final List<GradeBoundary> grades;

  List<ScoreColumn> get schoolColumns => [
    for (final c in columns)
      if (c.sectionId == null) c,
  ];

  List<GradeBoundary> get schoolGrades => [
    for (final g in grades)
      if (g.sectionId == null) g,
  ];

  List<ScoreColumn> ownColumns(String sectionId) => [
    for (final c in columns)
      if (c.sectionId == sectionId) c,
  ];

  List<GradeBoundary> ownGrades(String sectionId) => [
    for (final g in grades)
      if (g.sectionId == sectionId) g,
  ];

  bool hasOwnColumns(String sectionId) => ownColumns(sectionId).isNotEmpty;
  bool hasOwnGrades(String sectionId) => ownGrades(sectionId).isNotEmpty;

  /// Nothing at all, school-level or per section.
  bool get isEmpty => columns.isEmpty && grades.isEmpty;

  SectionGrading forSection(SchoolSection section) =>
      forSectionId(section.id, sectionName: section.name);

  /// One section's resolved grading ([sectionId] null: the school-level set).
  SectionGrading forSectionId(String? sectionId, {String sectionName = ''}) {
    final ownColumns = sectionId == null
        ? schoolColumns
        : this.ownColumns(sectionId);
    final ownGrades = sectionId == null
        ? schoolGrades
        : this.ownGrades(sectionId);
    final fallBackColumns = sectionId != null && ownColumns.isEmpty;
    final fallBackGrades = sectionId != null && ownGrades.isEmpty;
    return SectionGrading(
      sectionId: sectionId,
      sectionName: sectionName.isEmpty && sectionId == null
          ? 'The school'
          : sectionName,
      columns: fallBackColumns ? schoolColumns : ownColumns,
      grades: fallBackGrades ? schoolGrades : ownGrades,
      hasOwnColumns: ownColumns.isNotEmpty,
      hasOwnGrades: ownGrades.isNotEmpty,
      usesSchoolColumns: fallBackColumns && schoolColumns.isNotEmpty,
      usesSchoolGrades: fallBackGrades && schoolGrades.isNotEmpty,
    );
  }
}
