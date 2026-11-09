import 'package:hamrash_admin/api/models/class_structure/class_structure.dart';
import 'package:hamrash_admin/api/models/grading/grading_numbers.dart';
import 'package:hamrash_admin/api/models/grading/grading_setup.dart';
import 'package:hamrash_admin/api/models/grading/score_column.dart';
import 'package:hamrash_admin/api/models/grading/section_grading.dart';
import 'package:hamrash_admin/api/models/organization_models/member_school.dart';
import 'package:hamrash_admin/api/services/supabase_services/grading_service.dart';
import 'package:hamrash_admin/api/services/supabase_services/supabase_refusal.dart';
import 'package:hamrash_admin/core/widgets/app_alert_dialog.dart';
import 'package:hamrash_admin/singleton_locator/locator.dart';
import 'package:hamrash_admin/viewModel/base_view_model.dart';

/// 9.26–9.30 · One section's score columns: what a subject's score is made of
/// and how much each part is worth.
class ScoreColumnsViewModel extends BaseViewModel {
  ScoreColumnsViewModel({
    required this.school,
    required this.section,
    required this.sections,
    GradingService? service,
  }) : _service = service ?? locator<GradingService>();

  final MemberSchool school;
  final SchoolSection section;
  final GradingService _service;

  GradingSetup? _setup;

  /// Every section, as the list loaded them; copy sources are picked from it
  /// and it is handed on to the pages opened from here.
  final List<SchoolSection> sections;
  Object? _error;
  bool _changed = false;
  bool _saving = false;

  Object? get error => _error;
  bool get loading => _setup == null && _error == null;
  bool get canChange => school.canRunSetup;
  bool get changed => _changed;

  /// A save is running; buttons that started it show a spinner.
  bool get saving => _saving;

  SectionGrading get grading => _setup!.forSection(section);

  List<ScoreColumn> get columns => grading.columns;

  /// The section follows the school's columns, so it has no own list to edit.
  bool get inheritsColumns => grading.usesSchoolColumns;

  bool get hasColumns => grading.hasColumns;

  /// Active sections to copy columns from.
  List<SchoolSection> get copySources => [
    for (final other in sections)
      if (other.isActive && other.id != section.id) other,
  ];

  SectionGrading sourceGrading(SchoolSection other) =>
      _setup!.forSection(other);

  Future<void> load() async {
    _error = null;
    notifyListeners();
    try {
      await _fetch();
    } catch (error, stackTrace) {
      _error = error;
      await handleError(
        error,
        stackTrace: stackTrace,
        context: 'ScoreColumns.load',
        showErrorModal: false,
      );
    }
    notifyListeners();
  }

  Future<void> refresh() async {
    try {
      await _fetch();
      _error = null;
    } catch (error, stackTrace) {
      await handleError(
        error,
        stackTrace: stackTrace,
        context: 'ScoreColumns.refresh',
        showErrorModal: false,
      );
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  /// Adds a column and puts it at [position] (1 first) with
  /// `reorder_score_columns`, so the new order is written in one call.
  Future<String?> addColumn(
    String name,
    String marksText, {
    required int position,
  }) async {
    final problem =
        grading.columnNameProblem(name) ??
        (name.trim().isEmpty ? 'Give the column a name.' : null) ??
        SectionGrading.marksProblem(marksText);
    if (problem != null) return problem;
    final marks = SectionGrading.marks(marksText);
    if (marks == null) return 'Enter the marks.';

    return _save(
      () async {
        final existing = [for (final c in grading.columns) c.id];
        final id = await _service.addScoreColumn(
          organizationId: school.id,
          sectionId: section.id,
          name: name.trim(),
          maxScore: marks,
          sortOrder: existing.length + 1,
        );
        if (existing.isNotEmpty) {
          final ordered = [...existing];
          final index = (position - 1).clamp(0, ordered.length);
          ordered.insert(index, id);
          await _service.reorderScoreColumns(school.id, ordered);
        }
      },
      "Couldn't add the column. Try again.",
      'ScoreColumns.add',
    );
  }

  Future<String?> saveColumn(
    ScoreColumn column,
    String name,
    String marksText,
  ) async {
    final problem =
        grading.columnNameProblem(name, except: column) ??
        SectionGrading.marksProblem(marksText);
    if (problem != null) return problem;
    final marks = SectionGrading.marks(marksText);
    if (marks == null) return 'Enter the marks.';
    return _save(
      () => _service.updateScoreColumn(
        column,
        name: name.trim(),
        maxScore: marks,
      ),
      "Couldn't save the column. Try again.",
      'ScoreColumns.save',
    );
  }

  /// Moves [column] up (-1) or down (1), then saves the whole new order in
  /// one call. Returns the reason it didn't work, or null (also at the ends).
  Future<String?> moveColumn(ScoreColumn column, int delta) {
    final ids = [for (final c in columns) c.id];
    final from = ids.indexOf(column.id);
    final to = from + delta;
    if (from < 0 || to < 0 || to >= ids.length) return Future.value();
    ids.insert(to, ids.removeAt(from));
    return _save(
      () => _service.reorderScoreColumns(school.id, ids),
      "Couldn't move the column. Try again.",
      'ScoreColumns.move',
    );
  }

  Future<void> removeColumn(ScoreColumn column) => _act(
    () => _service.deleteScoreColumn(column),
    "Couldn't remove the column. Try again.",
  );

  /// "Give {Section} its own setup": copy the part the section still follows
  /// from the school, leaving any part it already owns alone.
  Future<String?> giveOwnSetup() => _serviceCopy(
    fromSectionId: null,
    columns: grading.usesSchoolColumns,
    grades: grading.usesSchoolGrades,
    fallback: "Couldn't give ${section.name} its own setup. Try again.",
  );

  /// Copies columns (and, when asked, grades) from [source]. A source that
  /// follows the school's setup is copied from the school-level set for that
  /// part.
  Future<String?> copyFrom(
    SchoolSection source, {
    required bool columns,
    required bool grades,
  }) async {
    final sourceGrading = this.sourceGrading(source);
    final fromColumns = !columns
        ? null
        : sourceGrading.hasOwnColumns
        ? source.id
        : null;
    final fromGrades = !grades
        ? null
        : sourceGrading.hasOwnGrades
        ? source.id
        : null;
    if (columns && grades && fromColumns == fromGrades) {
      return _serviceCopy(
        fromSectionId: fromColumns,
        columns: true,
        grades: true,
        fallback: "Couldn't copy the setup. Try again.",
      );
    }
    if (columns) {
      final error = await _serviceCopy(
        fromSectionId: fromColumns,
        columns: true,
        grades: false,
        fallback: "Couldn't copy the columns. Try again.",
      );
      if (error != null) return error;
    }
    if (grades) {
      return _serviceCopy(
        fromSectionId: fromGrades,
        columns: false,
        grades: true,
        fallback: "Couldn't copy the grades. Try again.",
      );
    }
    return null;
  }

  Future<String?> _serviceCopy({
    required String? fromSectionId,
    required bool columns,
    required bool grades,
    required String fallback,
  }) => _save(
    () => _service.copySectionGrading(
      organizationId: school.id,
      fromSectionId: fromSectionId,
      toSectionId: section.id,
      columns: columns,
      grades: grades,
    ),
    fallback,
    'ScoreColumns.copy',
  );

  /// What removing [column] does to the total, for its confirmation.
  String removeColumnMessage(ScoreColumn column) {
    final remaining = GradingNumbers.round(
      grading.totalMarks - column.maxScore,
    );
    return '${column.name} will be taken out of each subject’s score. '
        '${remaining > 0 ? 'The total becomes ${GradingNumbers.format(remaining)} marks.' : 'No columns will be left.'}';
  }

  Future<String?> _save(
    Future<void> Function() action,
    String fallback,
    String context,
  ) async {
    if (_saving) return null;
    _saving = true;
    notifyListeners();
    try {
      await action();
      _changed = true;
      await _fetch().catchError((_) {});
      return null;
    } catch (error, stackTrace) {
      await handleError(
        error,
        stackTrace: stackTrace,
        context: context,
        showErrorModal: false,
      );
      await _fetch().catchError((_) {});
      return messageFor(error, fallback);
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  Future<void> _act(Future<void> Function() action, String fallback) async {
    final message = await _save(action, fallback, 'ScoreColumns.action');
    if (message != null) throw AppAlertError(message);
  }

  Future<void> _fetch() async {
    _setup = await _service.getSetup(school.id);
  }

  static String messageFor(Object error, String fallback) =>
      error is SupabaseRefusal ? error.message : fallback;
}
