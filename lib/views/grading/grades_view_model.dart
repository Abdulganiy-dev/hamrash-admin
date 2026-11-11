import 'package:hamrash_admin/api/models/class_structure/class_structure.dart';
import 'package:hamrash_admin/api/models/grading/grade_boundary.dart';
import 'package:hamrash_admin/api/models/grading/grade_editing.dart';
import 'package:hamrash_admin/api/models/grading/grade_systems.dart';
import 'package:hamrash_admin/api/models/grading/grading_setup.dart';
import 'package:hamrash_admin/api/models/grading/section_grading.dart';
import 'package:hamrash_admin/api/models/organization_models/member_school.dart';
import 'package:hamrash_admin/api/services/supabase_services/grading_service.dart';
import 'package:hamrash_admin/api/services/supabase_services/supabase_refusal.dart';
import 'package:hamrash_admin/core/widgets/app_alert_dialog.dart';
import 'package:hamrash_admin/singleton_locator/locator.dart';
import 'package:hamrash_admin/viewModel/base_view_model.dart';

/// 8.32–8.34 · One section's grades: choose a system, add/edit/remove ranges,
/// or copy another section's grades. Every save sends the whole new list to
/// `set_grade_scale`.
class GradesViewModel extends BaseViewModel {
  GradesViewModel({
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

  bool get hasOwnGrades => grading.hasOwnGrades;
  bool get inheritsGrades => grading.usesSchoolGrades;
  bool get hasGrades => grading.hasGrades;

  /// The preset this scale matches, or null for a custom one.
  GradeSystem? get system => grading.gradeSystem;

  /// The preset "Change to …" offers, when there is only one obvious other.
  GradeSystem? get changeTarget => system?.other;

  /// Active sections to copy grades from.
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
        context: 'Grades.load',
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
        context: 'Grades.refresh',
        showErrorModal: false,
      );
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  /// "Use Standard grades" / "Replace with WAEC grades".
  Future<String?> applySystem(GradeSystem system) => _save(
    () => _service.applyGradeSystem(
      organizationId: school.id,
      sectionId: section.id,
      system: system.name,
    ),
    "Couldn't change the grades. Try again.",
    'Grades.applySystem',
  );

  /// Every add, edit and remove: the whole new scale for this section.
  Future<String?> saveScale(List<GradeBoundary> grades) => _save(
    () => _service.setGradeScale(
      organizationId: school.id,
      sectionId: section.id,
      grades: grades,
    ),
    "Couldn't save the grades. Try again.",
    'Grades.saveScale',
  );

  /// "Use the school's grades instead", when a section removes its own set.
  Future<String?> removeScale() => _save(
    () => _service.removeSectionGradeScale(
      organizationId: school.id,
      sectionId: section.id,
    ),
    "Couldn't switch to the school’s grades. Try again.",
    'Grades.removeScale',
  );

  /// "Give {Section} its own grades": copy the school-level grades only,
  /// leaving the section's score columns alone.
  Future<String?> giveOwnGrades() => _save(
    () => _service.copySectionGrading(
      organizationId: school.id,
      fromSectionId: null,
      toSectionId: section.id,
      columns: false,
      grades: true,
    ),
    "Couldn't give ${section.name} its own grades. Try again.",
    'Grades.giveOwnGrades',
  );

  /// Copies grades from [source]. A source that follows the school's grades is
  /// copied from the school-level set.
  Future<String?> copyGradesFrom(SchoolSection source) =>
      copyFrom(source, columns: false, grades: true);

  /// Copies the chosen parts from [source], resolving each part to the source
  /// section's own set or the school-level set it follows.
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
      return _save(
        () => _service.copySectionGrading(
          organizationId: school.id,
          fromSectionId: fromColumns,
          toSectionId: section.id,
          columns: true,
          grades: true,
        ),
        "Couldn't copy the setup. Try again.",
        'Grades.copy',
      );
    }
    if (columns) {
      final error = await _save(
        () => _service.copySectionGrading(
          organizationId: school.id,
          fromSectionId: fromColumns,
          toSectionId: section.id,
          columns: true,
          grades: false,
        ),
        "Couldn't copy the columns. Try again.",
        'Grades.copy',
      );
      if (error != null) return error;
    }
    if (grades) {
      return _save(
        () => _service.copySectionGrading(
          organizationId: school.id,
          fromSectionId: fromGrades,
          toSectionId: section.id,
          columns: false,
          grades: true,
        ),
        "Couldn't copy the grades. Try again.",
        'Grades.copy',
      );
    }
    return null;
  }

  /// What removing [grade] does, for the confirmation.
  GradeRemoval removalOf(GradeBoundary grade) => GradeEditor.remove(
    grades: grading.grades,
    target: grade,
    sectionName: section.name,
    sectionOwned: true,
  );

  /// Removes one grade by sending the whole new list. The section's last grade
  /// hands it back to the school's scale.
  Future<void> removeGrade(GradeBoundary grade) async {
    final removal = removalOf(grade);
    final message = removal.isEmpty
        ? await removeScale()
        : await saveScale(removal.grades);
    if (message != null) throw AppAlertError(message);
  }

  /// The 8.40 confirmation copy.
  String systemChangeMessage(GradeSystem to) {
    final current = system;
    final currentCount = grading.grades.length;
    final currentPart = current == null
        ? 'Its $currentCount grades'
        : 'Its $currentCount ${current.label} grades';
    return '$currentPart will be replaced by the ${to.grades.length} '
        '${to.label} grades, ${to.firstToLast}.';
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

  Future<void> _fetch() async {
    _setup = await _service.getSetup(school.id);
  }

  static String messageFor(Object error, String fallback) =>
      error is SupabaseRefusal ? error.message : fallback;
}
