import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/supabase_models/class_model.dart';
import 'package:hamrash_admin/api/services/supabase_services/class_service.dart';
import 'package:hamrash_admin/singleton_locator/locator.dart';
import 'package:hamrash_admin/viewModel/base_view_model.dart';

class SubjectsViewModel extends BaseViewModel {
  final _classService = locator<ClassService>();

  List<SubjectModel> _subjects = [];
  List<SubjectModel> get subjects => _subjects;

  void init(BuildContext context) {
    loadSubjects();
  }

  Future<void> loadSubjects() async {
    setBusy(true);
    try {
      _subjects = await _classService.fetchSubjects();
    } catch (e, st) {
      await handleError(
        e,
        stackTrace: st,
        context: 'SubjectsViewModel.loadSubjects',
        userMessage: 'Failed to load subjects. Please try again.',
      );
    } finally {
      setBusy(false);
    }
  }

  Future<bool> createSubject({
    required String name,
    String? description,
  }) async {
    setBusy(true);
    try {
      final created = await _classService.insertSubject(
        SubjectModel(
          name: name,
          description: description?.trim().isEmpty == true ? null : description?.trim(),
          isActive: true,
        ),
      );
      _subjects.add(created);
      _subjects.sort((a, b) => a.name.compareTo(b.name));
      notifyListeners();
      return true;
    } on DuplicateSubjectNameException catch (e, st) {
      await handleError(
        e,
        stackTrace: st,
        context: 'SubjectsViewModel.createSubject',
        userMessage: e.toString(),
      );
      return false;
    } catch (e, st) {
      await handleError(
        e,
        stackTrace: st,
        context: 'SubjectsViewModel.createSubject',
        userMessage: 'Failed to create subject. Please try again.',
      );
      return false;
    } finally {
      setBusy(false);
    }
  }

  Future<bool> updateSubject({
    required SubjectModel existing,
    required String name,
    String? description,
  }) async {
    setBusy(true);
    try {
      final updated = await _classService.updateSubject(
        existing.id!,
        existing.copyWith(
          name: name,
          description: description?.trim().isEmpty == true ? null : description?.trim(),
        ),
      );
      final idx = _subjects.indexWhere((s) => s.id == existing.id);
      if (idx != -1) _subjects[idx] = updated;
      _subjects.sort((a, b) => a.name.compareTo(b.name));
      notifyListeners();
      return true;
    } catch (e, st) {
      await handleError(
        e,
        stackTrace: st,
        context: 'SubjectsViewModel.updateSubject',
        userMessage: 'Failed to update subject. Please try again.',
      );
      return false;
    } finally {
      setBusy(false);
    }
  }

  Future<bool> deleteSubject(SubjectModel subject) async {
    setBusy(true);
    try {
      await _classService.deleteSubject(subject.id!);
      _subjects.removeWhere((s) => s.id == subject.id);
      notifyListeners();
      return true;
    } catch (e, st) {
      await handleError(
        e,
        stackTrace: st,
        context: 'SubjectsViewModel.deleteSubject',
        userMessage: 'Failed to delete subject. Please try again.',
      );
      return false;
    } finally {
      setBusy(false);
    }
  }
}
