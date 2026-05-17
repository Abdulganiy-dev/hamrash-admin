import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/supabase_models/class_model.dart';
import 'package:hamrash_admin/api/services/supabase_services/class_service.dart';
import 'package:hamrash_admin/singleton_locator/locator.dart';
import 'package:hamrash_admin/viewModel/base_view_model.dart';

class ClassesViewModel extends BaseViewModel {
  final _classService = locator<ClassService>();

  List<ClassModel> _classes = [];
  List<ClassModel> get classes => _classes;

  List<SubjectModel> _subjects = [];
  List<SubjectModel> get subjects => _subjects;

  void init(BuildContext context) {
    loadData();
  }

  Future<void> loadData() async {
    setBusy(true);
    try {
      final results = await Future.wait([
        _classService.fetchClasses(),
        _classService.fetchSubjects(),
      ]);
      _classes = results[0] as List<ClassModel>;
      _subjects = results[1] as List<SubjectModel>;
    } catch (e, st) {
      await handleError(
        e,
        stackTrace: st,
        context: 'ClassesViewModel.loadData',
        userMessage: 'Failed to load classes. Please try again.',
      );
    } finally {
      setBusy(false);
    }
  }

  Future<bool> createClass({
    required String name,
    String? section,
    List<String> subjectIds = const [],
  }) async {
    setBusy(true);
    try {
      final created = await _classService.insertClass(
        ClassModel(name: name, section: section?.trim().isEmpty == true ? null : section?.trim(), isActive: true),
      );
      if (subjectIds.isNotEmpty) {
        await _classService.setSubjectsForClass(created.id!, subjectIds);
      }
      await loadData();
      return true;
    } catch (e, st) {
      await handleError(
        e,
        stackTrace: st,
        context: 'ClassesViewModel.createClass',
        userMessage: 'Failed to create class. Please try again.',
      );
      return false;
    } finally {
      setBusy(false);
    }
  }

  Future<bool> updateClass({
    required ClassModel existing,
    required String name,
    String? section,
    List<String> subjectIds = const [],
  }) async {
    setBusy(true);
    try {
      await _classService.updateClass(
        existing.id!,
        existing.copyWith(
          name: name,
          section: section?.trim().isEmpty == true ? null : section?.trim(),
        ),
      );
      await _classService.setSubjectsForClass(existing.id!, subjectIds);
      await loadData();
      return true;
    } catch (e, st) {
      await handleError(
        e,
        stackTrace: st,
        context: 'ClassesViewModel.updateClass',
        userMessage: 'Failed to update class. Please try again.',
      );
      return false;
    } finally {
      setBusy(false);
    }
  }

  Future<bool> deleteClass(ClassModel classModel) async {
    setBusy(true);
    try {
      await _classService.deleteClass(classModel.id!);
      _classes.removeWhere((c) => c.id == classModel.id);
      notifyListeners();
      return true;
    } catch (e, st) {
      await handleError(
        e,
        stackTrace: st,
        context: 'ClassesViewModel.deleteClass',
        userMessage: 'Failed to delete class. Please try again.',
      );
      return false;
    } finally {
      setBusy(false);
    }
  }

  Future<List<String>> getSubjectIdsForClass(String classId) async {
    try {
      return await _classService.fetchSubjectIdsForClass(classId);
    } catch (_) {
      return [];
    }
  }
}
