import 'package:hamrash_admin/api/models/supabase_models/class_model.dart';
import 'package:hamrash_admin/api/models/supabase_models/teacher_model.dart';
import 'package:hamrash_admin/api/services/supabase_services/class_service.dart';
import 'package:hamrash_admin/api/services/supabase_services/teacher_service.dart';
import 'package:hamrash_admin/singleton_locator/locator.dart';
import 'package:hamrash_admin/viewModel/base_view_model.dart';
import 'package:hamrash_admin/viewModel/teachers_view_model.dart';
import 'package:stupid_simple_sheet/stupid_simple_sheet.dart';

/// Canonical homeroom role values (stored lowercase in DB).
abstract class HomeroomRole {
  static const String main = 'class_teacher';
  static const String assistant = 'assistant_class_teacher';
  static const List<String> all = [main, assistant];

  static String display(String value) {
    switch (value) {
      case main:
        return 'Main teacher';
      case assistant:
        return 'Assistant teacher';
      default:
        return value;
    }
  }

  static String apiName(String value) {
    switch (value) {
      case main:
        return 'class_teacher';
      case assistant:
        return 'assistant_class_teacher';
      default:
        return value;
    }
  }
}

class TeacherDetailViewModel extends BaseViewModel {
  TeacherDetailViewModel({required TeacherModel initial, this.parent})
    : _teacher = initial;

  /// Optional parent list view model — when present, mutations propagate
  /// back so the list stays in sync.
  final TeachersViewModel? parent;

  final _teacherService = locator<TeacherService>();
  final _classService = locator<ClassService>();

  TeacherModel _teacher;
  TeacherModel get teacher => _teacher;

  List<ClassModel> _classes = const [];
  List<ClassModel> get classes => _classes;

  List<SubjectModel> _subjects = const [];
  List<SubjectModel> get subjects => _subjects;

  List<TeacherClassSubject> _assignments = const [];
  List<TeacherClassSubject> get assignments => _assignments;

  TeacherCode? _teacherCode;
  TeacherCode? get teacherCode => _teacherCode;

  bool _saving = false;
  bool get saving => _saving;

  // ─── Derived getters ──────────────────────────────────────────────────

  bool get hasHomeroom => _teacher.homeroomClassId != null;

  ClassModel? get homeroomClass => classById(_teacher.homeroomClassId);

  String? get homeroomRoleDisplay {
    final r = _teacher.homeroomRole;
    return r == null ? null : HomeroomRole.display(r);
  }

  ClassModel? classById(String? id) {
    if (id == null) return null;
    for (final c in _classes) {
      if (c.id == id) return c;
    }
    return null;
  }

  SubjectModel? subjectById(String? id) {
    if (id == null) return null;
    for (final s in _subjects) {
      if (s.id == id) return s;
    }
    return null;
  }

  List<MapEntry<ClassModel, List<TeacherClassSubject>>> groupedAssignments() {
    final Map<String, List<TeacherClassSubject>> map = {};
    for (final a in _assignments) {
      map.putIfAbsent(a.classId, () => []).add(a);
    }
    final entries = <MapEntry<ClassModel, List<TeacherClassSubject>>>[];
    map.forEach((classId, items) {
      final cls = classById(classId);
      if (cls != null) entries.add(MapEntry(cls, items));
    });
    entries.sort(
      (a, b) => a.key.displayName.toLowerCase().compareTo(
        b.key.displayName.toLowerCase(),
      ),
    );
    return entries;
  }

  // ─── Loading ──────────────────────────────────────────────────────────

  Future<void> init() async {
    setBusy(true);
    try {
      final id = _teacher.id;
      if (id != null) {
        final results = await Future.wait([
          _classService.fetchClasses(),
          _classService.fetchSubjects(),
          _teacherService.fetchTeacherClassSubjects(id),
          _teacherService.fetchClaimCode(id),
        ]);
        _classes = results[0] as List<ClassModel>;
        _subjects = results[1] as List<SubjectModel>;
        _assignments = results[2] as List<TeacherClassSubject>;
        _teacherCode = results[3] as TeacherCode?;
      } else {
        final results = await Future.wait([
          _classService.fetchClasses(),
          _classService.fetchSubjects(),
        ]);
        _classes = results[0] as List<ClassModel>;
        _subjects = results[1] as List<SubjectModel>;
      }
    } catch (e, st) {
      await handleError(
        e,
        stackTrace: st,
        context: 'TeacherDetailViewModel.init',
        userMessage: 'Could not load teacher details. Please try again.',
        snappingConfig: const SheetSnappingConfig([0.4]),
      );
    } finally {
      setBusy(false);
      notifyListeners();
    }
  }

  /// Refresh the teacher model itself (used after an edit roundtrip).
  void replaceTeacher(TeacherModel updated) {
    _teacher = updated;
    parent?.replaceTeacher(updated);
    notifyListeners();
  }

  /// Subjects that are (a) assigned to [classId] and (b) not yet taught by
  /// this teacher in that class.
  Future<List<SubjectModel>> availableSubjectsForClass(String classId) async {
    setBusy(true);
    try {
      final classSubjectIds = await _classService.fetchSubjectIdsForClass(
        classId,
      );
      final taughtIds = _assignments
          .where((a) => a.classId == classId)
          .map((a) => a.subjectId)
          .toSet();
      return _subjects
          .where(
            (s) =>
                s.id != null &&
                classSubjectIds.contains(s.id) &&
                !taughtIds.contains(s.id),
          )
          .toList();
    } catch (_) {
      return const [];
    } finally {
      setBusy(false);
    }
  }

  // ─── Homeroom mutations ──────────────────────────────────────────────

  Future<bool> setHomeroom({
    required String classId,
    required String role,
  }) async {
    final id = _teacher.id;
    if (id == null) return false;

    setBusy(true);
    try {
      final updated = _teacher.copyWith(
        homeroomClassId: classId,
        homeroomRole: role,
      );
      final saved = await _teacherService.updateTeacher(id, updated);
      _teacher = saved;
      parent?.replaceTeacher(saved);
      notifyListeners();
      return true;
    } on TeacherHomeroomConflict catch (e, st) {
      final className = classById(classId)?.displayName ?? 'this class';
      final roleLabel = HomeroomRole.display(role);
      await handleError(
        e,
        stackTrace: st,
        context: 'TeacherDetailViewModel.setHomeroom',
        userMessage:
            'Another teacher is already the $roleLabel for $className. '
            'Each class can only have one $roleLabel.',
        snappingConfig: const SheetSnappingConfig([0.4]),
      );
      return false;
    } catch (e, st) {
      await handleError(
        e,
        stackTrace: st,
        context: 'TeacherDetailViewModel.setHomeroom',
        userMessage: 'Could not set homeroom. Please try again.',
        snappingConfig: const SheetSnappingConfig([0.4]),
      );
      return false;
    } finally {
      setBusy(false);
    }
  }

  Future<bool> setHomeroomRole(String role) {
    final classId = _teacher.homeroomClassId;
    if (classId == null) return Future.value(false);
    return setHomeroom(classId: classId, role: role);
  }

  Future<bool> clearHomeroom() async {
    final id = _teacher.id;
    if (id == null) return false;

    setBusy(true);
    try {
      // copyWith can't set null — construct directly.
      final cleared = TeacherModel(
        id: _teacher.id,
        firstName: _teacher.firstName,
        lastName: _teacher.lastName,
        email: _teacher.email,
        phone: _teacher.phone,
        gender: _teacher.gender,
        address: _teacher.address,
        state: _teacher.state,
        avatarUrl: _teacher.avatarUrl,
        avatarUrlId: _teacher.avatarUrlId,
        fcmToken: _teacher.fcmToken,
        isActive: _teacher.isActive,
        homeroomClassId: null,
        homeroomRole: null,
        createdAt: _teacher.createdAt,
        updatedAt: _teacher.updatedAt,
      );
      final saved = await _teacherService.updateTeacher(id, cleared);
      _teacher = saved;
      parent?.replaceTeacher(saved);
      notifyListeners();
      return true;
    } catch (e, st) {
      await handleError(
        e,
        stackTrace: st,
        context: 'TeacherDetailViewModel.clearHomeroom',
        userMessage: 'Could not clear classroom. Please try again.',
        snappingConfig: const SheetSnappingConfig([0.4]),
      );
      return false;
    } finally {
      setBusy(false);
    }
  }

  // ─── Teaching assignment mutations ───────────────────────────────────

  Future<bool> addTeachingAssignment({
    required String classId,
    required String subjectId,
  }) async {
    if (_saving) return false;
    final id = _teacher.id;
    if (id == null) return false;
    if (_assignments.any(
      (a) => a.classId == classId && a.subjectId == subjectId,
    )) {
      return true; // idempotent
    }

    _saving = true;
    setBusy(true);
    notifyListeners();
    try {
      final added = await _teacherService.addClassSubjectForTeacher(
        teacherId: id,
        classId: classId,
        subjectId: subjectId,
      );
      _assignments = [..._assignments, added];
      notifyListeners();
      return true;
    } on TeacherAssignmentConflict catch (e, st) {
      await handleError(
        e,
        stackTrace: st,
        context: 'TeacherDetailViewModel.addTeachingAssignment',
        userMessage: e.message,
        snappingConfig: const SheetSnappingConfig([0.4]),
      );
      return false;
    } catch (e, st) {
      await handleError(
        e,
        stackTrace: st,
        context: 'TeacherDetailViewModel.addTeachingAssignment',
        userMessage: 'Could not assign the subject. Please try again.',
        snappingConfig: const SheetSnappingConfig([0.4]),
      );
      return false;
    } finally {
      _saving = false;
      setBusy(false);
      notifyListeners();
    }
  }

  Future<bool> removeTeachingAssignment(String assignmentId) async {
    setBusy(true);
    try {
      await _teacherService.removeClassSubject(assignmentId);
      _assignments =
          _assignments.where((a) => a.id != assignmentId).toList();
      notifyListeners();
      return true;
    } catch (e, st) {
      await handleError(
        e,
        stackTrace: st,
        context: 'TeacherDetailViewModel.removeTeachingAssignment',
        userMessage: 'Could not remove the assignment. Please try again.',
        snappingConfig: const SheetSnappingConfig([0.4]),
      );
      return false;
    } finally {
      setBusy(false);
    }
  }

  Future<void> getTeachersCode(String teacherId) async {
    try {
      final code = await _teacherService.fetchClaimCode(teacherId);
      if (code != null) {
        _teacherCode = code;
      }
    } catch (e, st) {
      await handleError(
        e,
        stackTrace: st,
        context: 'TeacherDetailViewModel.getTeachersCode',
        userMessage: 'Could not get teacher code. Please try again.',
        snappingConfig: const SheetSnappingConfig([0.4]),
      );
    }
  }

}
