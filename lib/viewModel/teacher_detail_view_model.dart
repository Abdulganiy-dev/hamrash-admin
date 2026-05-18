import 'package:hamrash_admin/api/models/supabase_models/class_model.dart';
import 'package:hamrash_admin/api/models/supabase_models/teacher_model.dart';
import 'package:hamrash_admin/api/services/supabase_services/class_service.dart';
import 'package:hamrash_admin/api/services/supabase_services/teacher_service.dart';
import 'package:hamrash_admin/singleton_locator/locator.dart';
import 'package:hamrash_admin/viewModel/base_view_model.dart';
import 'package:hamrash_admin/viewModel/teachers_view_model.dart';

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
  TeacherDetailViewModel({
    required TeacherModel initial,
    this.parent,
  }) : _teacher = initial;

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

  /// Active assignments grouped by class id, sorted by class displayName.
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
      _classes = await _classService.fetchClasses();
      _subjects = await _classService.fetchSubjects();
      final id = _teacher.id;
      if (id != null) {
        _assignments = await _teacherService.fetchTeacherClassSubjects(id);
      }
    } catch (e, st) {
      await handleError(
        e,
        stackTrace: st,
        context: 'TeacherDetailViewModel.init',
        userMessage: 'Could not load teacher details. Please try again.',
      );
    } finally {
      setBusy(false);
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
    }
  }

  // ─── Homeroom mutations ──────────────────────────────────────────────

  Future<bool> setHomeroom({
    required String classId,
    required String role,
  }) {
    return _runSave(() async {
      final id = _teacher.id;
      if (id == null) return false;
      final updated = _teacher.copyWith(
        homeroomClassId: classId,
        homeroomRole: role,
      );
      final saved = await _teacherService.updateTeacher(id, updated);
      _teacher = saved;
      parent?.replaceTeacher(saved);
      return true;
    });
  }

  Future<bool> setHomeroomRole(String role) {
    final classId = _teacher.homeroomClassId;
    if (classId == null) return Future.value(false);
    return setHomeroom(classId: classId, role: role);
  }

  Future<bool> clearHomeroom() {
    return _runSave(() async {
      final id = _teacher.id;
      if (id == null) return false;
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
      return true;
    });
  }

  // ─── Teaching assignment mutations ───────────────────────────────────

  Future<bool> addTeachingAssignment({
    required String classId,
    required String subjectId,
  }) {
    return _runSave(() async {
      final id = _teacher.id;
      if (id == null) return false;
      if (_assignments.any(
        (a) => a.classId == classId && a.subjectId == subjectId,
      )) {
        return true; // idempotent
      }
      final added = await _teacherService.addClassSubjectForTeacher(
        teacherId: id,
        classId: classId,
        subjectId: subjectId,
      );
      _assignments = [..._assignments, added];
      return true;
    });
  }

  Future<bool> removeTeachingAssignment(String assignmentId) {
    return _runSave(() async {
      await _teacherService.removeClassSubject(assignmentId);
      _assignments = _assignments
          .where((a) => a.id != assignmentId)
          .toList();
      return true;
    });
  }

  // ─── Internal save helper ────────────────────────────────────────────

  Future<bool> _runSave(Future<bool> Function() op) async {
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
        context: 'TeacherDetailViewModel._runSave',
        userMessage: 'Could not save changes. Please try again.',
      );
      return false;
    } finally {
      _saving = false;
      setBusy(false);
      notifyListeners();
    }
  }
}
