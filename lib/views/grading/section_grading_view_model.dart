import 'package:hamrash_admin/api/models/class_structure/class_structure.dart';
import 'package:hamrash_admin/api/models/grading/grading_setup.dart';
import 'package:hamrash_admin/api/models/grading/section_grading.dart';
import 'package:hamrash_admin/api/models/organization_models/member_school.dart';
import 'package:hamrash_admin/api/services/supabase_services/grading_service.dart';
import 'package:hamrash_admin/api/services/supabase_services/supabase_refusal.dart';
import 'package:hamrash_admin/singleton_locator/locator.dart';
import 'package:hamrash_admin/viewModel/base_view_model.dart';

/// 9.23–9.25 · One section's setup: score columns, grades, copying another
/// section's work, and giving the section its own copy of the school's setup.
class SectionGradingViewModel extends BaseViewModel {
  SectionGradingViewModel({
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
  bool get saving => _saving;

  SectionGrading get grading => _setup!.forSection(section);

  /// Active sections this one can copy from, in teaching order.
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
        context: 'SectionGrading.load',
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
        context: 'SectionGrading.refresh',
        showErrorModal: false,
      );
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  /// A child page or a copy changed something.
  Future<void> markChanged() async {
    _changed = true;
    await refresh().catchError((_) {});
  }

  /// "Give {Section} its own setup": copy the school-level set for the parts
  /// the section follows, leaving any part it already owns alone.
  Future<String?> giveOwnSetup() => copyFrom(
    sourceSectionId: null,
    columns: grading.usesSchoolColumns,
    grades: grading.usesSchoolGrades,
  );

  /// Copies from a source section. A source that itself follows the school's
  /// setup is copied from the school-level set for that part.
  Future<String?> copyFrom({
    required String? sourceSectionId,
    required bool columns,
    required bool grades,
  }) async {
    if (_saving) return null;
    final source = sourceSectionId == null
        ? null
        : sourceGrading(sections.firstWhere((s) => s.id == sourceSectionId));
    final fromColumns = !columns
        ? null
        : sourceSectionId != null && source!.hasOwnColumns
        ? sourceSectionId
        : null;
    final fromGrades = !grades
        ? null
        : sourceSectionId != null && source!.hasOwnGrades
        ? sourceSectionId
        : null;

    _saving = true;
    notifyListeners();
    try {
      if (columns && grades && fromColumns == fromGrades) {
        await _service.copySectionGrading(
          organizationId: school.id,
          fromSectionId: fromColumns,
          toSectionId: section.id,
          columns: true,
          grades: true,
        );
      } else {
        if (columns) {
          await _service.copySectionGrading(
            organizationId: school.id,
            fromSectionId: fromColumns,
            toSectionId: section.id,
            columns: true,
            grades: false,
          );
        }
        if (grades) {
          await _service.copySectionGrading(
            organizationId: school.id,
            fromSectionId: fromGrades,
            toSectionId: section.id,
            columns: false,
            grades: true,
          );
        }
      }
      _changed = true;
      await _fetch().catchError((_) {});
      return null;
    } catch (error, stackTrace) {
      await handleError(
        error,
        stackTrace: stackTrace,
        context: 'SectionGrading.copy',
        showErrorModal: false,
      );
      await _fetch().catchError((_) {});
      return messageFor(error, "Couldn't copy the setup. Try again.");
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
