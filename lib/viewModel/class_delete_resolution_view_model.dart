import 'package:hamrash_admin/api/models/supabase_models/class_delete_preflight.dart';
import 'package:hamrash_admin/api/models/supabase_models/class_model.dart';
import 'package:hamrash_admin/api/models/supabase_models/teacher_model.dart';
import 'package:hamrash_admin/api/services/supabase_services/class_service.dart';
import 'package:hamrash_admin/api/services/supabase_services/teacher_service.dart';
import 'package:hamrash_admin/resources/app_logger.dart';
import 'package:hamrash_admin/singleton_locator/locator.dart';
import 'package:hamrash_admin/viewModel/base_view_model.dart';

/// Possible terminal outcomes of the resolution flow. The classes list view
/// uses this to refresh / pop appropriately.
enum ClassDeleteResolutionResult {
  /// Admin closed the screen without doing anything.
  cancelled,

  /// Class was hard-deleted after all blockers were cleared.
  deleted,

  /// Class was soft-deleted (is_active = false) instead.
  deactivated,
}

/// Drives the ClassDeleteResolutionView:
/// - loads the dependency snapshot via [ClassService.preflightClassDelete]
/// - exposes the lists for rendering
/// - performs the resolution actions (move/unassign students, clear homeroom)
/// - finalises either by deleting or deactivating the class
class ClassDeleteResolutionViewModel extends BaseViewModel {
  ClassDeleteResolutionViewModel({required this.target});

  /// The class the admin is trying to delete.
  final ClassModel target;

  final _classService = locator<ClassService>();
  final _teacherService = locator<TeacherService>();

  ClassDeletePreflight? _preflight;
  ClassDeletePreflight? get preflight => _preflight;

  /// Other classes (excluding [target]) the admin can move students into.
  List<ClassModel> _moveTargets = const [];
  List<ClassModel> get moveTargets => _moveTargets;

  bool _saving = false;
  bool get saving => _saving;

  bool get canDelete =>
      _preflight != null && !_preflight!.hasBlockers && !busy && !_saving;

  // ─── Loading ──────────────────────────────────────────────────────────

  Future<void> init() async {
    setBusy(true);
    try {
      final results = await Future.wait([
        _classService.preflightClassDelete(target.id!),
        _classService.fetchClasses(),
      ]);
      _preflight = results[0] as ClassDeletePreflight;
      AppLogger.debug('preflight: ${_preflight}');
      _moveTargets = (results[1] as List<ClassModel>)
          .where((c) => c.id != target.id)
          .toList();
    } catch (e, st) {
      await handleError(
        e,
        stackTrace: st,
        context: 'ClassDeleteResolutionViewModel.init',
        userMessage: 'Could not load dependencies. Please try again.',
      );
    } finally {
      setBusy(false);
    }
  }

  /// Re-pull the snapshot — used after each action so the UI reflects the
  /// new blocker counts.
  Future<void> refreshPreflight() async {
    try {
      _preflight = await _classService.preflightClassDelete(target.id!);
      notifyListeners();
    } catch (_) {
      // Best-effort. UI keeps the previous snapshot.
    }
  }

  // ─── Resolution actions ──────────────────────────────────────────────

  Future<bool> moveStudents({
    required List<String> studentIds,
    required String newClassId,
  }) {
    return _runAction(() async {
      await _classService.moveStudentsToClass(
        studentIds: studentIds,
        newClassId: newClassId,
      );
      await refreshPreflight();
      return true;
    }, errorMessage: 'Could not move students. Please try again.');
  }

  Future<bool> unassignStudents(List<String> studentIds) {
    return _runAction(() async {
      await _classService.unassignStudentsFromClass(studentIds);
      await refreshPreflight();
      return true;
    }, errorMessage: 'Could not unassign students. Please try again.');
  }

  /// Clear the homeroom on a single teacher by writing a model with the
  /// homeroom fields nulled. We can't use copyWith here because it
  /// preserves non-null values.
  Future<bool> clearHomeroom(ClassDeleteHomeroomTeacher teacher) {
    return _runAction(() async {
      final cleared = TeacherModel(
        id: teacher.id,
        firstName: teacher.firstName,
        lastName: teacher.lastName,
        isActive: true, // updateTeacher only uses provided fields
        homeroomClassId: null,
        homeroomRole: null,
      );
      await _teacherService.updateTeacher(teacher.id, cleared);
      await refreshPreflight();
      return true;
    }, errorMessage: 'Could not clear homeroom. Please try again.');
  }

  // ─── Finalisers ──────────────────────────────────────────────────────

  Future<ClassDeleteResolutionResult> finalizeDelete() async {
    if (!canDelete) return ClassDeleteResolutionResult.cancelled;
    final ok = await _runAction(() async {
      await _classService.deleteClass(target.id!);
      return true;
    }, errorMessage: 'Delete failed. Refresh and try again.');
    return ok
        ? ClassDeleteResolutionResult.deleted
        : ClassDeleteResolutionResult.cancelled;
  }

  Future<ClassDeleteResolutionResult> finalizeDeactivate() async {
    final ok = await _runAction(() async {
      await _classService.deactivateClass(target.id!);
      return true;
    }, errorMessage: 'Could not deactivate. Please try again.');
    return ok
        ? ClassDeleteResolutionResult.deactivated
        : ClassDeleteResolutionResult.cancelled;
  }

  // ─── Internals ───────────────────────────────────────────────────────

  Future<bool> _runAction(
    Future<bool> Function() op, {
    required String errorMessage,
  }) async {
    if (_saving) return false;
    _saving = true;
    setBusy(true);
    notifyListeners();
    try {
      final ok = await op();
      notifyListeners();
      return ok;
    } catch (e, st) {
      await handleError(
        e,
        stackTrace: st,
        context: 'ClassDeleteResolutionViewModel._runAction',
        userMessage: errorMessage,
      );
      // Refresh in case the action partially completed (e.g. some students
      // moved before a network blip).
      await refreshPreflight();
      return false;
    } finally {
      _saving = false;
      setBusy(false);
      notifyListeners();
    }
  }
}
