import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/supabase_models/teacher_model.dart';
import 'package:hamrash_admin/api/services/supabase_services/teacher_service.dart';
import 'package:hamrash_admin/singleton_locator/locator.dart';
import 'package:hamrash_admin/viewModel/base_view_model.dart';

class TeachersViewModel extends BaseViewModel {
  final _teacherService = locator<TeacherService>();

  List<TeacherModel> _teachers = [];
  List<TeacherModel> get teachers => _teachers;

  String _searchQuery = '';

  List<TeacherModel> get filteredTeachers {
    if (_searchQuery.isEmpty) return _teachers;
    final q = _searchQuery.toLowerCase();
    return _teachers.where((t) {
      return t.fullName.toLowerCase().contains(q) ||
          (t.email?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  void init(BuildContext context) {
    loadData();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> loadData() async {
    setBusy(true);
    try {
      _teachers = await _teacherService.fetchTeachers();
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

  void addTeacher(TeacherModel teacher) {
    _teachers = [..._teachers, teacher];
    notifyListeners();
  }

  void replaceTeacher(TeacherModel updated) {
    _teachers = _teachers
        .map((t) => t.id == updated.id ? updated : t)
        .toList();
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
}
