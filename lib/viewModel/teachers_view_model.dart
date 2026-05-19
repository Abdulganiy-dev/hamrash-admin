import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/supabase_models/teacher_model.dart';
import 'package:hamrash_admin/api/services/supabase_services/teacher_service.dart';
import 'package:hamrash_admin/singleton_locator/locator.dart';
import 'package:hamrash_admin/viewModel/base_view_model.dart';

class TeachersViewModel extends BaseViewModel {
  final _teacherService = locator<TeacherService>();

  static const int _pageSize = 20;
  static const int _searchLimit = 50;
  static const Duration _searchDebounce = Duration(milliseconds: 300);

  /// Master list — always kept sorted by (last_name, id). Holds everything
  /// we've fetched so far: pagination pages + any teachers pulled in by
  /// server-side searches.
  List<TeacherModel> _teachers = [];
  List<TeacherModel> get teachers => _teachers;

  String _searchQuery = '';
  Timer? _searchTimer;
  bool _searchingRemote = false;
  bool get searchingRemote => _searchingRemote;

  TeacherCursor? _cursor;
  bool _hasMore = true;
  bool get hasMore => _hasMore;

  bool _loadingMore = false;
  bool get loadingMore => _loadingMore;

  
  List<TeacherModel> get filteredTeachers {
    if (_searchQuery.isEmpty) return _teachers;
    final q = _searchQuery.toLowerCase();
    return _teachers.where((t) {
      return t.firstName.toLowerCase().contains(q) ||
          t.lastName.toLowerCase().contains(q) ||
          t.fullName.toLowerCase().contains(q) ||
          (t.email?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  void init(BuildContext context) {
    loadData();
  }

  // ─── Search ──────────────────────────────────────────────────────────

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();

    _searchTimer?.cancel();
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      _searchingRemote = false;
      return;
    }
    _searchTimer = Timer(_searchDebounce, () => _runRemoteSearch(trimmed));
  }

  Future<void> _runRemoteSearch(String query) async {
    if (_searchQuery.trim() != query) return;
    setBusy(true);
    _searchingRemote = true;
    notifyListeners();
    try {
      final page = await _teacherService.fetchTeachersPage(
        limit: _searchLimit,
        search: query,
      );
      if (_searchQuery.trim() != query) return; 
      _mergeSorted(page.teachers);
    } catch (_) {
     
    } finally {
      if (_searchQuery.trim() == query) _searchingRemote = false;
      setBusy(false);
      notifyListeners();
    }
  }

  // ─── Pagination ──────────────────────────────────────────────────────

  Future<void> loadData() async {
    setBusy(true);
    _teachers = [];
    _cursor = null;
    _hasMore = true;
    try {
      await _loadNextPage();
    } catch (e, st) {
      await handleError(
        e,
        stackTrace: st,
        context: 'TeachersViewModel.loadData',
        userMessage: 'Failed to load teachers. Please try again.',
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
        context: 'TeachersViewModel.loadMore',
        userMessage: 'Could not load more teachers.',
      );
    } finally {
      _loadingMore = false;
      notifyListeners();
    }
  }

  Future<void> _loadNextPage() async {
    final page = await _teacherService.fetchTeachersPage(
      after: _cursor,
      limit: _pageSize,
    );
    _mergeSorted(page.teachers);
    _hasMore = page.hasMore;
    if (page.teachers.isNotEmpty) {
      final last = page.teachers.last;
      if (last.id != null) {
        _cursor = TeacherCursor(lastName: last.lastName, id: last.id!);
      }
    }
  }

  // ─── Local mutations (called from create/edit/delete flows) ──────────

  void addTeacher(TeacherModel teacher) {
    _mergeSorted([teacher]);
    notifyListeners();
  }

  void replaceTeacher(TeacherModel updated) {
    _teachers = _teachers
        .map((t) => t.id == updated.id ? updated : t)
        .toList();
    _resort();
    notifyListeners();
  }

  Future<bool> deleteTeacher(TeacherModel teacher) async {
    setBusy(true);
    try {
      await _teacherService.deleteTeacher(teacher.id!);
      _teachers = _teachers.where((t) => t.id != teacher.id).toList();
      notifyListeners();
      return true;
    } catch (e, st) {
      await handleError(
        e,
        stackTrace: st,
        context: 'TeachersViewModel.deleteTeacher',
        userMessage: 'Failed to delete teacher. Please try again.',
      );
      return false;
    } finally {
      setBusy(false);
    }
  }


  void _mergeSorted(List<TeacherModel> incoming) {
    if (incoming.isEmpty) return;
    final byId = <String, TeacherModel>{
      for (final t in _teachers)
        if (t.id != null) t.id!: t,
    };
    for (final t in incoming) {
      if (t.id != null) byId[t.id!] = t;
    }
    _teachers = byId.values.toList();
    _resort();
  }

  void _resort() {
    _teachers.sort((a, b) {
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
