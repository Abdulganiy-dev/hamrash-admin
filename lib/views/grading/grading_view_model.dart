import 'package:hamrash_admin/api/models/grading/grade_boundary.dart';
import 'package:hamrash_admin/api/models/grading/grading_numbers.dart';
import 'package:hamrash_admin/api/models/grading/grading_setup.dart';
import 'package:hamrash_admin/api/models/grading/score_column.dart';
import 'package:hamrash_admin/api/models/organization_models/member_school.dart';
import 'package:hamrash_admin/api/services/supabase_services/grading_service.dart';
import 'package:hamrash_admin/api/services/supabase_services/supabase_refusal.dart';
import 'package:hamrash_admin/core/widgets/app_alert_dialog.dart';
import 'package:hamrash_admin/singleton_locator/locator.dart';
import 'package:hamrash_admin/viewModel/base_view_model.dart';

/// 9.1–9.9 · Grading: how to start, then the score columns and the grade
/// scale. School leaders change them; everyone else looks.
///
/// Sheet saves return an error message (null when it worked); confirmed
/// actions throw [AppAlertError] for [AppConfirmSheet]. The message is the
/// database's reason when it refused, see [SupabaseRefusal].
class GradingViewModel extends BaseViewModel {
  GradingViewModel({required this.school, GradingService? service})
    : _service = service ?? locator<GradingService>();

  final MemberSchool school;
  final GradingService _service;

  GradingSetup? _setup;
  Object? _error;
  bool _changed = false;
  bool _building = false;

  Object? get error => _error;
  bool get loading => _setup == null && _error == null;
  GradingSetup get setup => _setup!;
  bool get canChange => school.canRunSetup;

  /// Something was saved, so the page that opened this one should reload.
  bool get changed => _changed;

  /// "Build my own" was chosen, or there's already something to edit: the
  /// setup page shows even with nothing in it.
  bool get building => _building;

  /// 9.1 · Nothing set up yet, and this person can start it.
  bool get showStart =>
      _setup != null && setup.isEmpty && !_building && canChange;

  /// Nothing set up yet, and this person can only look.
  bool get showNotSetUp => _setup != null && setup.isEmpty && !canChange;

  /// 9.1 · "Build my own": the setup page with nothing in it.
  void buildOwn() {
    _building = true;
    notifyListeners();
  }

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

  Future<void> removeColumn(ScoreColumn column) => _act(
    () => _service.deleteScoreColumn(column),
    "Couldn't remove the column. Try again.",
  );

  /// Adds a grade. [percent] is what was typed.
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
    _setup = await _service.getSetup(school.id);
    // Once there's something to edit, an emptied setup stays on the setup
    // page rather than going back to the start.
    if (!_setup!.isEmpty) _building = true;
  }

  static String messageFor(Object error, String fallback) =>
      error is SupabaseRefusal ? error.message : fallback;
}
