import 'package:hamrash_admin/api/models/supabase_models/class_model.dart';
import 'package:hamrash_admin/api/models/supabase_models/student_model.dart';
import 'package:hamrash_admin/api/services/supabase_services/class_service.dart';
import 'package:hamrash_admin/api/services/supabase_services/parent_service.dart';
import 'package:hamrash_admin/api/services/supabase_services/student_service.dart';
import 'package:hamrash_admin/database/family_realm_service.dart';
import 'package:hamrash_admin/singleton_locator/locator.dart';
import 'package:hamrash_admin/viewModel/base_view_model.dart';
import 'package:hamrash_admin/viewModel/students_view_model.dart';


class StudentDetailViewModel extends BaseViewModel {
  StudentDetailViewModel({
    required StudentModel initial,
    this.parent,
  }) : _student = initial;

  final StudentsViewModel? parent;

  final _studentService = locator<StudentService>();
  final _parentService = locator<ParentService>();
  final _classService = locator<ClassService>();
  final _family = locator<FamilyRealmService>();

  StudentModel _student;
  StudentModel get student => _student;

  List<ClassModel> _classes = const [];
  List<ClassModel> get classes => _classes;

  List<SubjectModel> _subjects = const [];
  List<SubjectModel> get subjects => _subjects;

  /// (link + parent) tuples for every parent linked to this student.
  List<ParentOfStudent> _parents = const [];
  List<ParentOfStudent> get parents => _parents;

  List<StudentSubject> _enrollments = const [];
  List<StudentSubject> get enrollments => _enrollments;

  StudentClaimCode? _claimCode;
  StudentClaimCode? get claimCode => _claimCode;

  bool _saving = false;
  bool get saving => _saving;

  ClassModel? get currentClass => classById(_student.classId);

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

  /// Subjects this student is currently enrolled in, mapped to [SubjectModel].
  List<SubjectModel> get enrolledSubjects {
    final out = <SubjectModel>[];
    for (final e in _enrollments) {
      final s = subjectById(e.subjectId);
      if (s != null) out.add(s);
    }
    out.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return out;
  }

  // ─── Loading ──────────────────────────────────────────────────────────

  Future<void> init() async {
    setBusy(true);
    try {
      final id = _student.id;

      final results = await Future.wait([
        _classService.fetchClasses(),
        _classService.fetchSubjects(),
        if (id != null) _studentService.fetchStudentWithFamily(id),
        if (id != null) _studentService.fetchStudentSubjects(id),
        if (id != null) _studentService.fetchClaimCode(id),
      ]);
      _classes = results[0] as List<ClassModel>;
      _subjects = results[1] as List<SubjectModel>;

      if (id != null) {
        final family = results[2] as StudentFamily?;
        if (family != null) {
          _student = family.student;
          final parentById = {
            for (final p in family.parents)
              if (p.id != null) p.id!: p,
          };
          _parents = [
            for (final l in family.links) (link: l, parent: parentById[l.parentId]!),
          ];
          _sortParents();
        }
        _enrollments = results[3] as List<StudentSubject>;
        _claimCode = results[4] as StudentClaimCode?;
      }
    } catch (e, st) {
      await handleError(
        e,
        stackTrace: st,
        context: 'StudentDetailViewModel.init',
        userMessage: 'Could not load student details. Please try again.',
      );
    } finally {
      setBusy(false);
    }
  }

  void replaceStudent(StudentModel updated) {
    _student = updated;
    parent?.replaceStudent(updated);
    notifyListeners();
  }

  // ─── Subject enrollment ──────────────────────────────────────────────

  /// Subjects assigned to the student's current class that they are not
  /// already enrolled in. Empty list if no class is set.
  Future<List<SubjectModel>> availableSubjectsForClass() async {
    final classId = _student.classId;
    if (classId == null) return const [];
    try {
      final classSubjectIds =
          await _classService.fetchSubjectIdsForClass(classId);
      final enrolledIds = _enrollments.map((e) => e.subjectId).toSet();
      return _subjects
          .where(
            (s) =>
                s.id != null &&
                classSubjectIds.contains(s.id) &&
                !enrolledIds.contains(s.id),
          )
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<bool> enrollInSubject(String subjectId) {
    return _runSave(() async {
      final id = _student.id;
      if (id == null) return false;
      if (_enrollments.any((e) => e.subjectId == subjectId)) return true;
      final added = await _studentService.addStudentSubject(
        studentId: id,
        subjectId: subjectId,
      );
      _enrollments = [..._enrollments, added];
      return true;
    });
  }

  Future<bool> unenrollFromSubject(String enrollmentId) {
    return _runSave(() async {
      await _studentService.removeStudentSubject(enrollmentId);
      _enrollments =
          _enrollments.where((e) => e.id != enrollmentId).toList();
      return true;
    });
  }

  // ─── Parent linking ──────────────────────────────────────────────────

  Future<bool> linkParent({
    required String parentId,
    required String relationship,
    bool isPrimary = false,
  }) {
    return _runSave(() async {
      final sid = _student.id;
      if (sid == null) return false;
      final link = await _studentService.linkParent(
        studentId: sid,
        parentId: parentId,
        relationship: relationship,
        isPrimary: isPrimary,
      );
      // We need the parent model to display — fetch if not yet known.
      ParentModel? parentModel;
      for (final p in _parents) {
        if (p.parent.id == parentId) {
          parentModel = p.parent;
          break;
        }
      }
      parentModel ??= await _parentService.fetchParent(parentId);
      if (parentModel == null) return false;
      _parents = [..._parents, (link: link, parent: parentModel)];
      _sortParents();
      return true;
    });
  }

  Future<bool> updateLink({
    required String linkId,
    String? relationship,
    bool? isPrimary,
  }) {
    return _runSave(() async {
      final updated = await _studentService.updateLink(
        linkId: linkId,
        relationship: relationship,
        isPrimary: isPrimary,
      );
      _parents = _parents
          .map(
            (p) =>
                p.link.id == linkId ? (link: updated, parent: p.parent) : p,
          )
          .toList();
      _sortParents();
      return true;
    });
  }

  Future<bool> unlinkParent(String linkId) {
    return _runSave(() async {
      await _studentService.unlinkParent(linkId);
      _parents = _parents.where((p) => p.link.id != linkId).toList();
      return true;
    });
  }

  /// Parents that exist in the cache but aren't yet linked to this student.
  /// Used to populate the "link existing parent" picker.
  List<ParentModel> unlinkedParents() {
    final linkedIds = _parents.map((p) => p.parent.id).toSet();
    return _family
        .getAllParents()
        .map(_family.parentModelFromRealm)
        .where((p) => !linkedIds.contains(p.id))
        .toList();
  }

  // ─── Internal helpers ────────────────────────────────────────────────

  void _sortParents() {
    _parents.sort((a, b) {
      if (a.link.isPrimary != b.link.isPrimary) {
        return a.link.isPrimary ? -1 : 1;
      }
      return a.parent.lastName
          .toLowerCase()
          .compareTo(b.parent.lastName.toLowerCase());
    });
  }

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
        context: 'StudentDetailViewModel._runSave',
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
