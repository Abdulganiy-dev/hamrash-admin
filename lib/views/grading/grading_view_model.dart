import 'package:hamrash_admin/api/models/class_structure/class_structure.dart';
import 'package:hamrash_admin/api/models/grading/grading_setup.dart';
import 'package:hamrash_admin/api/models/grading/section_grading.dart';
import 'package:hamrash_admin/api/models/organization_models/member_school.dart';
import 'package:hamrash_admin/api/services/supabase_services/class_structure_service.dart';
import 'package:hamrash_admin/api/services/supabase_services/grading_service.dart';
import 'package:hamrash_admin/api/services/supabase_services/supabase_refusal.dart';
import 'package:hamrash_admin/singleton_locator/locator.dart';
import 'package:hamrash_admin/viewModel/base_view_model.dart';

/// 9.20–9.22 · The sections list: one row per active section, with how far its
/// grading has got and an entry into its own setup.
///
/// Switched-off sections are hidden and don't count. Leaders change grading;
/// everyone else reads it.
class GradingViewModel extends BaseViewModel {
  GradingViewModel({
    required this.school,
    GradingService? service,
    ClassStructureService? structure,
  }) : _service = service ?? locator<GradingService>(),
       _structure = structure ?? locator<ClassStructureService>();

  final MemberSchool school;
  final GradingService _service;
  final ClassStructureService _structure;

  GradingSetup? _setup;
  List<SchoolSection> _sections = const [];
  Object? _error;
  bool _changed = false;

  Object? get error => _error;
  bool get loading => _setup == null && _error == null;
  bool get canChange => school.canRunSetup;
  bool get changed => _changed;

  /// In teaching order, switched-off sections left out.
  List<SchoolSection> get activeSections => [
    for (final section in _sections)
      if (section.isActive) section,
  ];

  /// One per active section, in the same order.
  List<SectionGrading> get sections => [
    for (final section in activeSections) _setup!.forSection(section),
  ];

  /// "2 of 4".
  int get setUpCount =>
      sections.where((s) => s.status == GradingStatus.setUp).length;

  int get sectionCount => activeSections.length;

  /// No active section to set up: "Create your sections first".
  bool get showEmpty => activeSections.isEmpty;

  /// The school has sections, but every one is switched off.
  bool get hasAnySections => _sections.isNotEmpty;

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
        context: 'Grading.load',
        showErrorModal: false,
      );
    }
    notifyListeners();
  }

  /// Pull to refresh: keeps the page and rethrows for the error toast.
  Future<void> refresh() async {
    try {
      await _fetch();
      _error = null;
    } catch (error, stackTrace) {
      await handleError(
        error,
        stackTrace: stackTrace,
        context: 'Grading.refresh',
        showErrorModal: false,
      );
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  /// A child page changed something.
  Future<void> markChanged() async {
    _changed = true;
    await refresh().catchError((_) {});
  }

  Future<void> _fetch() async {
    final (setup, sections) = await (
      _service.getSetup(school.id),
      _structure.getStructure(school.id),
    ).wait;
    _setup = setup;
    _sections = sections;
  }

  static String messageFor(Object error, String fallback) =>
      error is SupabaseRefusal ? error.message : fallback;
}
