import 'package:hamrash_admin/api/models/class_structure/class_structure.dart';
import 'package:hamrash_admin/api/models/grading/grade_boundary.dart';
import 'package:hamrash_admin/api/models/grading/grading_numbers.dart';
import 'package:hamrash_admin/api/models/grading/grading_setup.dart';
import 'package:hamrash_admin/api/models/grading/score_column.dart';
import 'package:hamrash_admin/api/models/organization_models/member_school.dart';
import 'package:hamrash_admin/api/services/supabase_services/class_structure_service.dart';
import 'package:hamrash_admin/api/services/supabase_services/grading_service.dart';
import 'package:hamrash_admin/api/services/supabase_services/supabase_refusal.dart';
import 'package:hamrash_admin/core/widgets/app_alert_dialog.dart';
import 'package:hamrash_admin/singleton_locator/locator.dart';
import 'package:hamrash_admin/viewModel/base_view_model.dart';

/// 9.1–9.11 · Grading: how to start, then the score columns and the grade
/// scale. School leaders change them; everyone else looks.
///
/// The grade scale is shown for one scope at a time: the school default, or
/// a section that has its own scale ([selectScope]). Adding, editing and
/// removing grades works on the selected scope.
///
/// Sheet saves return an error message (null when it worked); confirmed
/// actions throw [AppAlertError] for [AppConfirmSheet]. The message is the
/// database's reason when it refused, see [SupabaseRefusal].
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

  /// Everything loaded: columns, the school default scale and each section's
  /// own scale.
  GradingSetup? _setup;
  List<SchoolSection> _sections = const [];
  String? _scopeId;
  Object? _error;
  bool _changed = false;
  bool _building = false;

  Object? get error => _error;
  bool get loading => _setup == null && _error == null;
  bool get canChange => school.canRunSetup;

  /// The setup as the selected scale sees it: the columns, and the grades of
  /// the school default or of the selected section.
  GradingSetup get setup => _setup!.scoped(scopeId);

  // ── Scale scopes ─────────────────────────────────────────────────────

  /// The selected section's id, or null for the school default.
  String? get scopeId {
    final id = _scopeId;
    return id != null && (_setup?.hasOwnScale(id) ?? false) ? id : null;
  }

  /// The school has sections, so there are scales to choose between.
  bool get hasSections => _sections.isNotEmpty;

  bool get inSectionScope => scopeId != null;

  SchoolSection? get scopeSection =>
      _sections.where((s) => s.id == scopeId).firstOrNull;

  /// Sections with their own scale, in teaching order: a chip each.
  List<SchoolSection> get ownScaleSections => [
    for (final s in _sections)
      if (_setup!.hasOwnScale(s.id)) s,
  ];

  /// Sections that use the school default.
  List<SchoolSection> get sectionsWithoutOwnScale => [
    for (final s in _sections)
      if (!_setup!.hasOwnScale(s.id)) s,
  ];

  /// "+ New scale": leaders, and only while a section is left to give one.
  bool get canAddScale => canChange && sectionsWithoutOwnScale.isNotEmpty;

  /// Under the chips: who the selected scale is for.
  String get scopeCaption {
    final section = scopeSection;
    if (section != null) {
      return '${section.name}’s own grades. Other sections use the school '
          'default.';
    }
    final names = [for (final s in sectionsWithoutOwnScale) s.name];
    return names.isEmpty
        ? 'Used by every section.'
        : 'Used by ${joinNames(names)}.';
  }

  /// "Nursery", "Nursery and Primary", "Nursery, Primary and Secondary".
  static String joinNames(List<String> names) => switch (names.length) {
    0 => '',
    1 => names.first,
    _ => '${names.sublist(0, names.length - 1).join(', ')} and ${names.last}',
  };

  /// Chips: null is the school default.
  void selectScope(String? sectionId) {
    if (sectionId != null && !(_setup?.hasOwnScale(sectionId) ?? false)) return;
    _scopeId = sectionId;
    notifyListeners();
  }

  /// Something was saved, so the page that opened this one should reload.
  bool get changed => _changed;

  /// There has been something to edit, so an emptied setup stays on the
  /// setup page (with what's missing) instead of going back to the start.
  bool get building => _building;

  /// 9.1 · Nothing set up yet, and this person can start it.
  bool get showStart =>
      _setup != null && _setup!.isEmpty && !_building && canChange;

  /// Nothing set up yet, and this person can only look.
  bool get showNotSetUp => _setup != null && _setup!.isEmpty && !canChange;

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

  /// 9.7 · The standard columns and grades. Returns the reason it didn't
  /// work, or null.
  Future<String?> useStandardSetup() => _save(
    () => _service.createStandardGrading(school.id),
    "Couldn't set up grading. Try again.",
    'Grading.useStandardSetup',
  );

  /// Adds a column at the end of the report card. [marks] is what was typed.
  Future<String?> addColumn(String name, String marks) {
    final max = GradingSetup.marks(marks);
    if (max == null) return Future.value('Enter the marks.');
    return _save(
      () => _service.addScoreColumn(
        organizationId: school.id,
        name: name.trim(),
        maxScore: max,
        sortOrder: setup.nextSortOrder,
      ),
      "Couldn't add the column. Try again.",
      'Grading.addColumn',
    );
  }

  Future<String?> saveColumn(ScoreColumn column, String name, String marks) {
    final max = GradingSetup.marks(marks);
    if (max == null) return Future.value('Enter the marks.');
    return _save(
      () =>
          _service.updateScoreColumn(column, name: name.trim(), maxScore: max),
      "Couldn't save the column. Try again.",
      'Grading.saveColumn',
    );
  }

  /// Moves [column] up ([delta] -1) or down (1) on the report card by
  /// swapping places with its neighbour, then saving the whole new order in
  /// one call. Returns the reason it didn't work, or null (also when it's
  /// already at that end).
  Future<String?> moveColumn(ScoreColumn column, int delta) {
    final ids = [for (final c in setup.columns) c.id];
    final from = ids.indexOf(column.id);
    final to = from + delta;
    if (from < 0 || to < 0 || to >= ids.length) return Future.value();
    ids.insert(to, ids.removeAt(from));
    return _save(
      () => _service.reorderScoreColumns(school.id, ids),
      "Couldn't move the column. Try again.",
      'Grading.moveColumn',
    );
  }

  Future<void> removeColumn(ScoreColumn column) => _act(
    () => _service.deleteScoreColumn(column),
    "Couldn't remove the column. Try again.",
  );

  /// Adds a grade to the selected scale. [percent] is what was typed.
  Future<String?> addGrade({
    required String grade,
    required String percent,
    required String remark,
    required bool isPass,
  }) {
    final min = setup.percent(percent);
    if (min == null) return Future.value('Enter where the grade starts.');
    return _save(
      () => _service.addGradeBoundary(
        organizationId: school.id,
        sectionId: scopeId,
        grade: grade.trim(),
        minPercent: min,
        remark: _remark(remark),
        isPass: isPass,
      ),
      "Couldn't add the grade. Try again.",
      'Grading.addGrade',
    );
  }

  Future<String?> saveGrade(
    GradeBoundary boundary, {
    required String grade,
    required String percent,
    required String remark,
    required bool isPass,
  }) {
    final min = setup.percent(percent, except: boundary);
    if (min == null) return Future.value('Enter where the grade starts.');
    return _save(
      () => _service.updateGradeBoundary(
        boundary,
        grade: grade.trim(),
        minPercent: min,
        remark: _remark(remark),
        isPass: isPass,
      ),
      "Couldn't save the grade. Try again.",
      'Grading.saveGrade',
    );
  }

  Future<void> removeGrade(GradeBoundary boundary) => _act(
    () => _service.deleteGradeBoundary(boundary),
    "Couldn't remove the grade. Try again.",
  );

  /// 9.11 · Gives [sectionId] its own scale, a copy of the school default in
  /// one insert, and selects it. Returns the reason it didn't work, or null.
  Future<String?> createSectionScale(String sectionId) {
    final grades = _setup!.boundaries;
    if (grades.isEmpty) {
      return Future.value(
        'The school default has no grades to copy yet. Add them first.',
      );
    }
    return _save(
      () async {
        await _service.copyScaleToSection(
          organizationId: school.id,
          sectionId: sectionId,
          grades: grades,
        );
        _scopeId = sectionId;
      },
      "Couldn't create the scale. Try again.",
      'Grading.createSectionScale',
    );
  }

  /// "Use the school's scale instead": deletes the selected section's own
  /// grades in one delete and goes back to the school default. Throws
  /// [AppAlertError] for the confirm sheet when it didn't work.
  Future<void> removeSectionScale() {
    final section = scopeId;
    if (section == null) return Future.value();
    return _act(() async {
      await _service.deleteSectionScale(
        organizationId: school.id,
        sectionId: section,
      );
      _scopeId = null;
    }, "Couldn't switch back to the school’s scale. Try again.");
  }

  /// What removing [column] does to the total, for its confirmation.
  String removeColumnMessage(ScoreColumn column) {
    final remaining = GradingNumbers.round(setup.totalMarks - column.maxScore);
    return '${column.name} will be taken out of each subject’s score. '
        '${remaining > 0 ? 'The total becomes ${GradingNumbers.format(remaining)} marks.' : 'No columns will be left.'}';
  }

  static String? _remark(String remark) {
    final value = remark.trim();
    return value.isEmpty ? null : value;
  }

  Future<String?> _save(
    Future<void> Function() action,
    String fallback,
    String context,
  ) async {
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
      notifyListeners();
    }
  }

  Future<void> _act(Future<void> Function() action, String fallback) async {
    final message = await _save(action, fallback, 'Grading.action');
    if (message != null) throw AppAlertError(message);
  }

  Future<void> _fetch() async {
    final (setup, sections) = await (
      _service.getSetup(school.id),
      _structure.getStructure(school.id),
    ).wait;
    _setup = setup;
    _sections = sections;
    // Once there's something to edit, an emptied setup stays on the setup
    // page rather than going back to the start.
    if (!setup.isEmpty) _building = true;
  }

  static String messageFor(Object error, String fallback) =>
      error is SupabaseRefusal ? error.message : fallback;
}
