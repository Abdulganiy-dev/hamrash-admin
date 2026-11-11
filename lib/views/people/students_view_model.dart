import 'package:hamrash_admin/api/models/organization_models/member_school.dart';
import 'package:hamrash_admin/api/models/students/student_filter.dart';
import 'package:hamrash_admin/api/models/students/student_summary.dart';
import 'package:hamrash_admin/api/services/supabase_services/class_structure_service.dart';
import 'package:hamrash_admin/api/services/supabase_services/student_service.dart';
import 'package:hamrash_admin/singleton_locator/locator.dart';
import 'package:hamrash_admin/viewModel/base_view_model.dart';

/// One group on the Students list: an arm and the students of it loaded so
/// far.
class StudentGroup {
  const StudentGroup({
    required this.title,
    required this.students,
    required this.count,
  });

  /// "JSS 1A", or "Not in a class" for students with no arm this session.
  final String title;
  final List<StudentSummary> students;

  /// Everyone in the arm who matches the filters, loaded or not.
  final int count;

  /// "32 students".
  String get countLabel => '$count ${count == 1 ? 'student' : 'students'}';
}

/// 9.1 · The Students side of the People tab: the school's students in class
/// order, a page at a time.
///
/// The server searches, filters, sorts and pages the list (`list_students`);
/// this keeps the pages loaded so far, the applied [filter] and the arm
/// counts. A subject filter makes each row carry the subject and its teacher.
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

  List<StudentSummary> _rows = const [];
  Map<String, int> _groupCounts = const {};
  String? _sessionName;
  Object? _error;
  Object? _loadMoreError;
  bool _loading = true;
  bool _loadingMore = false;
  bool _loadedOnce = false;
  String? _nextCursor;
  int _total = 0;
  StudentFilter _filter = StudentFilter.initial;

  /// Bumped by every request for page 1, so a slow answer to an old filter
  /// can't replace the newer one.
  int _token = 0;

  StudentFilter get filter => _filter;
  List<StudentSummary> get students => _rows;
  Object? get error => _error;
  Object? get loadMoreError => _loadMoreError;
  bool get loading => _loading;
  bool get loadingMore => _loadingMore;
  bool get hasMore => _nextCursor != null;

  /// Students matching every filter, across all pages.
  int get total => _total;

  /// A page has loaded at least once and the last attempt didn't fail, so
  /// the page's actions can stay put while a new filter loads.
  bool get ready => _loadedOnce && _error == null;

  /// "2026/27", for the page's subtitle. Null before a session is current.
  String? get sessionName => _sessionName;

  /// 9.1a · A loaded school with no students at all.
  bool get isEmpty =>
      !_loading && _error == null && _rows.isEmpty && _filter.isDefault;

  /// 9.1c · Filters or a search are applied and nobody matches.
  bool get showNoResults =>
      !_loading && _error == null && _rows.isEmpty && !_filter.isDefault;

  /// Registering students is for leaders; a bursar only looks.
  bool get canAdd => school.canRunSetup;

  /// The loaded students in arm groups, in the server's order. Each header
  /// counts the whole arm, so it stays right while the rest loads.
  List<StudentGroup> get groups {
    final groups = <StudentGroup>[];
    var current = <StudentSummary>[];
    String? currentKey;
    void flush() {
      if (current.isEmpty) return;
      groups.add(
        StudentGroup(
          title: current.first.armLabel ?? 'Not in a class',
          students: current,
          count: _groupCounts[currentKey ?? ''] ?? current.length,
        ),
      );
    }

    for (final student in _rows) {
      if (current.isNotEmpty && student.armId != currentKey) {
        flush();
        current = [];
      }
      currentKey = student.armId;
      current.add(student);
    }
    flush();
    return groups;
  }

  /// "Mathematics · Mr. John" under a student while a subject is picked, the
  /// admission number otherwise. A subject nobody teaches there says so.
  String subtitleFor(StudentSummary student) {
    final subject = student.subject;
    if (subject == null) return student.admissionNumber;
    return subject.hasTeacher
        ? '${subject.name} · Teacher: ${subject.teacherName}'
        : '${subject.name} · No teacher assigned yet';
  }

  Future<void> applyFilter(StudentFilter value) async {
    if (value == _filter) return;
    _filter = value;
    await load();
  }

  Future<void> removeChip(StudentFilterChip chip) => applyFilter(chip.without);
  Future<void> clearFilters() => applyFilter(StudentFilter.initial);

  /// Page 1 with the skeleton showing.
  Future<void> load() async {
    final token = ++_token;
    _error = null;
    _loadMoreError = null;
    _loading = true;
    _loadingMore = false;
    notifyListeners();
    try {
      await _readSession();
      final page = await _fetch(token);
      if (page != null) _take(page);
    } catch (error, stackTrace) {
      if (token != _token) return;
      _error = error;
      await handleError(
        error,
        stackTrace: stackTrace,
        context: 'Students.load',
        showErrorModal: false,
      );
    }
    if (token != _token) return;
    _loading = false;
    if (!isDisposed) notifyListeners();
  }

  /// Pull to refresh, and after a student is registered: keeps the list and
  /// rethrows a failure for the error toast.
  Future<void> refresh() async {
    final token = ++_token;
    try {
      final page = await _fetch(token);
      if (page != null) {
        _take(page);
        _error = null;
        _loading = false;
      }
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

  /// The next page, added under the rows already loaded.
  Future<void> loadMore() async {
    final cursor = _nextCursor;
    if (cursor == null || _loading || _loadingMore || _loadMoreError != null) {
      return;
    }
    final token = _token;
    _loadingMore = true;
    notifyListeners();
    try {
      final page = await _students.listStudentsPage(
        organizationId: school.id,
        filter: _filter,
        cursor: cursor,
      );
      if (token != _token) return;
      final known = {for (final student in _rows) student.id};
      _rows = [
        ..._rows,
        for (final student in page.rows)
          if (known.add(student.id)) student,
      ];
      _nextCursor = page.nextCursor;
      _total = page.total;
      _groupCounts = page.groupCounts;
    } catch (error, stackTrace) {
      if (token != _token) return;
      _loadMoreError = error;
      await handleError(
        error,
        stackTrace: stackTrace,
        context: 'Students.loadMore',
        showErrorModal: false,
      );
    } finally {
      if (token == _token) {
        _loadingMore = false;
        if (!isDisposed) notifyListeners();
      }
    }
  }

  Future<void> retryLoadMore() {
    _loadMoreError = null;
    return loadMore();
  }

  /// The session's name is only the page's subtitle: a failed read leaves it
  /// as it was.
  Future<void> _readSession() async {
    try {
      final session = await _structure.getCurrentSession(school.id);
      _sessionName = session?.name;
    } catch (_) {}
  }

  Future<StudentPage?> _fetch(int token) async {
    final page = await _students.listStudentsPage(
      organizationId: school.id,
      filter: _filter,
    );
    return token == _token ? page : null;
  }

  void _take(StudentPage page) {
    _rows = page.rows;
    _nextCursor = page.nextCursor;
    _total = page.total;
    _groupCounts = page.groupCounts;
    _loadMoreError = null;
    _loadingMore = false;
    _loadedOnce = true;
  }
}
