import 'package:hamrash_admin/api/models/organization_models/member_school.dart';
import 'package:hamrash_admin/api/models/students/student_summary.dart';
import 'package:hamrash_admin/api/services/supabase_services/class_structure_service.dart';
import 'package:hamrash_admin/api/services/supabase_services/student_service.dart';
import 'package:hamrash_admin/singleton_locator/locator.dart';
import 'package:hamrash_admin/viewModel/base_view_model.dart';

/// One group on the Students list: an arm and the students in it.
class StudentGroup {
  const StudentGroup({required this.title, required this.students});

  /// "JSS 1A", or "Not in a class" for students with no arm this session.
  final String title;
  final List<StudentSummary> students;

  /// "32 students".
  String get countLabel =>
      '${students.length} ${students.length == 1 ? 'student' : 'students'}';
}

/// 9.1 · The Students side of the People tab: the school's active students
/// grouped by the class and arm they are in this session.
class StudentsViewModel extends BaseViewModel {
  StudentsViewModel({
    required this.school,
    StudentService? students,
    ClassStructureService? structure,
  }) : _students = students ?? locator<StudentService>(),
       _structure = structure ?? locator<ClassStructureService>();

  final MemberSchool school;
  final StudentService _students;
  final ClassStructureService _structure;

  List<StudentGroup> _groups = const [];
  String? _sessionName;
  Object? _error;
  bool _loading = true;

  List<StudentGroup> get groups => _groups;

  /// "2026/27", for the page's subtitle. Null before a session is current.
  String? get sessionName => _sessionName;
  Object? get error => _error;
  bool get loading => _loading;

  /// 9.1a · A loaded school with no students yet.
  bool get isEmpty => !_loading && _error == null && _groups.isEmpty;

  /// Registering students is for leaders; a bursar only looks.
  bool get canAdd => school.canRunSetup;

  Future<void> load() async {
    _error = null;
    _loading = true;
    notifyListeners();
    try {
      await _fetch();
    } catch (error, stackTrace) {
      _error = error;
      await handleError(
        error,
        stackTrace: stackTrace,
        context: 'Students.load',
        showErrorModal: false,
      );
    }
    _loading = false;
    if (!isDisposed) notifyListeners();
  }

  /// Pull to refresh: keeps the list and rethrows for the error toast.
  Future<void> refresh() async {
    try {
      await _fetch();
      _error = null;
    } catch (error, stackTrace) {
      await handleError(
        error,
        stackTrace: stackTrace,
        context: 'Students.refresh',
        showErrorModal: false,
      );
      rethrow;
    } finally {
      if (!isDisposed) notifyListeners();
    }
  }

  Future<void> _fetch() async {
    // Without a current session nobody has an arm; the list still shows.
    final session = await _structure
        .getCurrentSession(school.id)
        .catchError((_) => null);
    final students = await _students.listStudents(
      organizationId: school.id,
      sessionId: session?.id,
    );
    _sessionName = session?.name;
    _groups = groupByArm(students);
  }

  /// Classes in their order, arms A to Z inside a class, and students with no
  /// arm last.
  static List<StudentGroup> groupByArm(List<StudentSummary> students) {
    final byArm = <String, List<StudentSummary>>{};
    for (final student in students) {
      byArm.putIfAbsent(student.armId ?? '', () => []).add(student);
    }
    final keys = byArm.keys.toList()
      ..sort((a, b) {
        if (a.isEmpty != b.isEmpty) return a.isEmpty ? 1 : -1;
        final first = byArm[a]!.first;
        final second = byArm[b]!.first;
        final order = first.classOrder.compareTo(second.classOrder);
        if (order != 0) return order;
        return (first.armLabel ?? '').compareTo(second.armLabel ?? '');
      });
    return [
      for (final key in keys)
        StudentGroup(
          title: byArm[key]!.first.armLabel ?? 'Not in a class',
          students: byArm[key]!,
        ),
    ];
  }
}
