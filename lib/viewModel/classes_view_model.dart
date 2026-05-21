import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/supabase_models/class_delete_preflight.dart';
import 'package:hamrash_admin/api/models/supabase_models/class_model.dart';
import 'package:hamrash_admin/api/models/supabase_models/section_model.dart';
import 'package:hamrash_admin/api/services/supabase_services/class_service.dart';
import 'package:hamrash_admin/singleton_locator/locator.dart';
import 'package:hamrash_admin/viewModel/base_view_model.dart';

class ClassesViewModel extends BaseViewModel {
  final _classService = locator<ClassService>();

  List<ClassModel> _classes = [];
  List<ClassModel> get classes => _classes;

  List<SubjectModel> _subjects = [];
  List<SubjectModel> get subjects => _subjects;

  List<SectionModel> _arms = [];
  List<SectionModel> get arms => _arms;

  /// Classes grouped by name, e.g. {"JSS 1": [JSS 1 A, JSS 1 B]}.
  Map<String, List<ClassModel>> get groupedClasses {
    final Map<String, List<ClassModel>> grouped = {};
    for (final cls in _classes) {
      grouped.putIfAbsent(cls.name, () => []).add(cls);
    }
    return grouped;
  }

  /// Unique sorted class names, used as quick-pick chips in the add sheet.
  List<String> get existingClassNames =>
      (_classes.map((c) => c.name).toSet().toList()..sort());

  /// Returns true if any classroom currently uses [armName] as its section.
  bool armIsUsed(String armName) =>
      _classes.any((c) => c.section == armName);

  void init(BuildContext context) {
    loadData();
  }

  Future<void> loadData() async {
    setBusy(true);
    try {
      final results = await Future.wait([
        _classService.fetchClasses(),
        _classService.fetchSubjects(),
        _classService.fetchSections(),
      ]);
      _classes = results[0] as List<ClassModel>;
      _subjects = results[1] as List<SubjectModel>;
      _arms = results[2] as List<SectionModel>;
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

  Future<bool> createArm(String name) async {
    setBusy(true);
    try {
      final created = await _classService.insertSection(SectionModel(name: name));
      _arms = [..._arms, created];
      notifyListeners();
      return true;
    } catch (e, st) {
      await handleError(
        e,
        stackTrace: st,
        context: 'ClassesViewModel.createArm',
        userMessage: 'Failed to create arm. Please try again.',
      );
      return false;
    } finally {
      setBusy(false);
    }
  }

  Future<bool> deleteArm(SectionModel arm) async {
    setBusy(true);
    try {
      await _classService.deleteSection(arm.id!);
      _arms.removeWhere((a) => a.id == arm.id);
      notifyListeners();
      return true;
    } catch (e, st) {
      await handleError(
        e,
        stackTrace: st,
        context: 'ClassesViewModel.deleteArm',
        userMessage: 'Failed to delete arm. Please try again.',
      );
      return false;
    } finally {
      setBusy(false);
    }
  }

  static const minClassSubjects = 2;

  Future<bool> createClass({
    required String name,
    required String section,
    required List<String> subjectIds,
  }) async {
    final trimmedSection = section.trim();
    if (trimmedSection.isEmpty || subjectIds.length < minClassSubjects) {
      return false;
    }
    setBusy(true);
    try {
      final created = await _classService.insertClass(
        ClassModel(
          name: name,
          section: trimmedSection,
          isActive: true,
        ),
      );
      await _classService.setSubjectsForClass(created.id!, subjectIds);
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
    required String section,
    required List<String> subjectIds,
  }) async {
    final trimmedSection = section.trim();
    if (trimmedSection.isEmpty || subjectIds.length < minClassSubjects) {
      return false;
    }
    setBusy(true);
    try {
      await _classService.updateClass(
        existing.id!,
        existing.copyWith(
          name: name,
          section: trimmedSection,
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

  Future<bool> classHasSubjects(String classId) async {
    try {
      setBusy(true);
      return await _classService.classHasSubjects(classId);
    } catch (_) {
      return false;
    } finally {
      setBusy(false);
    }
  }

  /// One-shot dependency snapshot for the delete-resolution flow.
  /// Returns null on failure (error already handled).
  Future<ClassDeletePreflight?> preflightDelete(ClassModel cls) async {
    setBusy(true);
    try {
      return await _classService.preflightClassDelete(cls.id!);
    } catch (e, st) {
      await handleError(
        e,
        stackTrace: st,
        context: 'ClassesViewModel.preflightDelete',
        userMessage: 'Could not check dependencies. Please try again.',
      );
      return null;
    } finally {
      setBusy(false);
    }
  }
}
