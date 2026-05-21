import 'package:hamrash_admin/api/models/supabase_models/class_model.dart';
import 'package:hamrash_admin/api/models/supabase_models/subject_delete_preflight.dart';
import 'package:hamrash_admin/api/services/supabase_services/class_service.dart';
import 'package:hamrash_admin/singleton_locator/locator.dart';
import 'package:hamrash_admin/viewModel/base_view_model.dart';

enum SubjectDeleteResolutionResult {
  cancelled,
  deleted,
  deactivated,
}

/// Drives SubjectDeleteResolutionView. Same shape as the class flow:
/// preflight → resolve blockers → finalise (delete or deactivate).
class SubjectDeleteResolutionViewModel extends BaseViewModel {
  SubjectDeleteResolutionViewModel({required this.target});

  /// The subject the admin is trying to delete.
  final SubjectModel target;

  final _classService = locator<ClassService>();

  SubjectDeletePreflight? _preflight;
  SubjectDeletePreflight? get preflight => _preflight;

  bool _saving = false;
  bool get saving => _saving;

  bool get canDelete =>
      _preflight != null && !_preflight!.hasBlockers && !busy && !_saving;

  // ─── Loading ──────────────────────────────────────────────────────────

  Future<void> init() async {
    setBusy(true);
    try {
      _preflight = await _classService.preflightSubjectDelete(target.id!);
    } catch (e, st) {
      await handleError(
        e,
        stackTrace: st,
        context: 'SubjectDeleteResolutionViewModel.init',
        userMessage: 'Could not load dependencies. Please try again.',
      );
    } finally {
      setBusy(false);
    }
  }

  Future<void> refreshPreflight() async {
    try {
      _preflight = await _classService.preflightSubjectDelete(target.id!);
      notifyListeners();
    } catch (_) {
      // Best-effort.
    }
  }

  // ─── Curriculum cleanup ──────────────────────────────────────────────

  Future<bool> removeFromAllClasses() {
    return _runAction(() async {
      await _classService.removeSubjectFromAllClasses(target.id!);
      await refreshPreflight();
      return true;
    }, errorMessage: 'Could not remove from classes. Please try again.');
  }

  Future<bool> removeFromOneClass(SubjectDeleteClass entry) {
    return _runAction(() async {
      await _classService.removeClassSubjectLink(entry.classSubjectId);
      await refreshPreflight();
      return true;
    }, errorMessage: 'Could not remove from class. Please try again.');
  }

  // ─── Teacher assignment cleanup ─────────────────────────────────────

  Future<bool> clearAllTeacherAssignments() {
    return _runAction(() async {
      await _classService.clearAllTeacherAssignmentsForSubject(target.id!);
      await refreshPreflight();
      return true;
    }, errorMessage: 'Could not clear teacher assignments. Please try again.');
  }

  Future<bool> removeTeacherAssignment(
    SubjectDeleteTeacherAssignment assignment,
  ) {
    return _runAction(() async {
      await _classService.removeTeacherAssignment(assignment.assignmentId);
      await refreshPreflight();
      return true;
    }, errorMessage: 'Could not unassign teacher. Please try again.');
  }

  // ─── Student enrollment cleanup (bulk only) ─────────────────────────

  Future<bool> unenrollAllStudents() {
    return _runAction(() async {
      await _classService.unenrollAllStudentsFromSubject(target.id!);
      await refreshPreflight();
      return true;
    }, errorMessage: 'Could not unenroll students. Please try again.');
  }

  // ─── Finalisers ──────────────────────────────────────────────────────

  Future<SubjectDeleteResolutionResult> finalizeDelete() async {
    if (!canDelete) return SubjectDeleteResolutionResult.cancelled;
    final ok = await _runAction(() async {
      await _classService.deleteSubject(target.id!);
      return true;
    }, errorMessage: 'Delete failed. Refresh and try again.');
    return ok
        ? SubjectDeleteResolutionResult.deleted
        : SubjectDeleteResolutionResult.cancelled;
  }

  Future<SubjectDeleteResolutionResult> finalizeDeactivate() async {
    final ok = await _runAction(() async {
      await _classService.deactivateSubject(target.id!);
      return true;
    }, errorMessage: 'Could not deactivate. Please try again.');
    return ok
        ? SubjectDeleteResolutionResult.deactivated
        : SubjectDeleteResolutionResult.cancelled;
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
        context: 'SubjectDeleteResolutionViewModel._runAction',
        userMessage: errorMessage,
      );
      await refreshPreflight();
      return false;
    } finally {
      _saving = false;
      setBusy(false);
      notifyListeners();
    }
  }
}
