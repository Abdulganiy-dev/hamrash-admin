import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/supabase_models/student_model.dart';
import 'package:hamrash_admin/api/services/supabase_services/student_service.dart';
import 'package:hamrash_admin/singleton_locator/locator.dart';
import 'package:hamrash_admin/viewModel/base_view_model.dart';

/// Mirrors [TeachersViewModel]: keyset pagination over `fetch_students_page`,
/// local-first hybrid search (cache match → no remote; nothing local → debounce
/// remote search), and a master list that stays sorted alphabetically.
class StudentsViewModel extends BaseViewModel {
  final _studentService = locator<StudentService>();

  static const int _pageSize = 20;
  static const int _searchLimit = 50;
  static const Duration _searchDebounce = Duration(milliseconds: 300);

  List<StudentModel> _students = [];
  List<StudentModel> get students => _students;

  String _searchQuery = '';
  Timer? _searchTimer;
  bool _searchScheduled = false;
  bool _searchingRemote = false;
  bool get searchingRemote => _searchingRemote;
  bool get isSearchPending => _searchScheduled || _searchingRemote;

  StudentCursor? _cursor;
  bool _hasMore = true;
  bool get hasMore => _hasMore;

  bool _loadingMore = false;
  bool get loadingMore => _loadingMore;

  List<StudentModel> get filteredStudents {
    if (_searchQuery.isEmpty) return _students;
    return _filterLocally(_searchQuery);
  }

  List<StudentModel> _filterLocally(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return _students;
    return _students.where((s) => _matchesQuery(s, q)).toList();
  }

  bool _matchesQuery(StudentModel s, String q) {
    return s.firstName.toLowerCase().contains(q) ||
        s.lastName.toLowerCase().contains(q) ||
        s.fullName.toLowerCase().contains(q) ||
        (s.email?.toLowerCase().contains(q) ?? false) ||
        (s.admissionNumber?.toLowerCase().contains(q) ?? false);
  }

  void init(BuildContext context) {
    loadData();
  }

  // ─── Search ──────────────────────────────────────────────────────────

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();

    _searchTimer?.cancel();
    _searchScheduled = false;
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      _searchingRemote = false;
      return;
    }
    if (_filterLocally(trimmed).isNotEmpty) {
      _searchingRemote = false;
      return;
    }
    _searchScheduled = true;
    notifyListeners();
    _searchTimer = Timer(_searchDebounce, () {
      _searchScheduled = false;
      if (_searchQuery.trim() != trimmed) return;
      if (_filterLocally(trimmed).isNotEmpty) return;
      _runRemoteSearch(trimmed);
    });
  }

  Future<void> _runRemoteSearch(String query) async {
    if (_searchQuery.trim() != query) return;
    setBusy(true);
    _searchingRemote = true;
    notifyListeners();
    try {
      final page = await _studentService.fetchStudentsPage(
        limit: _searchLimit,
        search: query,
      );
      if (_searchQuery.trim() != query) return;
      _mergeSorted(page.students);
    } catch (_) {
      // Silent: locally filtered list stays visible.
    } finally {
      if (_searchQuery.trim() == query) _searchingRemote = false;
      setBusy(false);
      notifyListeners();
    }
  }

  // ─── Pagination ──────────────────────────────────────────────────────

  Future<void> loadData() async {
    setBusy(true);
    _students = [];
    _cursor = null;
    _hasMore = true;
    try {
      await _loadNextPage();
    } catch (e, st) {
      await handleError(
        e,
        stackTrace: st,
        context: 'StudentsViewModel.loadData',
        userMessage: 'Failed to load students. Please try again.',
      );
    } finally {
      setBusy(false);
    }
  }

  Future<void> loadMore() async {
    if (_loadingMore || !_hasMore || busy) return;
    _loadingMore = true;
    notifyListeners();
    try {
      await _loadNextPage();
    } catch (e, st) {
      await handleError(
        e,
        stackTrace: st,
        context: 'StudentsViewModel.loadMore',
        userMessage: 'Could not load more students.',
      );
    } finally {
      _loadingMore = false;
      notifyListeners();
    }
  }

  Future<void> _loadNextPage() async {
    final page = await _studentService.fetchStudentsPage(
      after: _cursor,
      limit: _pageSize,
    );
    _mergeSorted(page.students);
    _hasMore = page.hasMore;
    if (page.students.isNotEmpty) {
      final last = page.students.last;
      if (last.id != null) {
        _cursor = StudentCursor(lastName: last.lastName, id: last.id!);
      }
    }
  }

  // ─── Local mutations ────────────────────────────────────────────────

  void addStudent(StudentModel student) {
    _mergeSorted([student]);
    notifyListeners();
  }

  void replaceStudent(StudentModel updated) {
    _students = _students
        .map((s) => s.id == updated.id ? updated : s)
        .toList();
    _resort();
    notifyListeners();
  }

  Future<bool> deleteStudent(StudentModel student) async {
    setBusy(true);
    try {
      await _studentService.deleteStudent(student.id!);
      _students = _students.where((s) => s.id != student.id).toList();
      notifyListeners();
      return true;
    } catch (e, st) {
      await handleError(
        e,
        stackTrace: st,
        context: 'StudentsViewModel.deleteStudent',
        userMessage: 'Failed to delete student. Please try again.',
      );
      return false;
    } finally {
      setBusy(false);
    }
  }

  void _mergeSorted(List<StudentModel> incoming) {
    if (incoming.isEmpty) return;
    final byId = <String, StudentModel>{
      for (final s in _students)
        if (s.id != null) s.id!: s,
    };
    for (final s in incoming) {
      if (s.id != null) byId[s.id!] = s;
    }
    _students = byId.values.toList();
    _resort();
  }

  void _resort() {
    _students.sort((a, b) {
      final ln = a.lastName.toLowerCase().compareTo(b.lastName.toLowerCase());
      if (ln != 0) return ln;
      return (a.id ?? '').compareTo(b.id ?? '');
    });
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    super.dispose();
  }
}
