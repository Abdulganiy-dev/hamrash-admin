import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../api/models/supabase_models/class_delete_preflight.dart';
import '../../../api/models/supabase_models/class_model.dart';
import '../../../api/models/supabase_models/section_model.dart';
import '../../../database/class_realm_service.dart';
import '../../../database/models/class_realm.dart';
import '../../../database/models/section_realm.dart';
import '../../../database/models/subject_realm.dart';
import '../../../database/section_realm_service.dart';
import '../../../database/subject_realm_service.dart';

/// Supabase + Realm for `public.classes`, `public.sections`, and `public.subjects`.
///
/// List fetch: Pattern 1 (Realm first; if empty, fetch from Supabase and persist).
/// On network failure, returns cached Realm rows when available.
/// Mutations: Pattern 3 (write-through — cache mirrors server response).
class ClassService {
  ClassService({
    required ClassRealmService classRealmService,
    required SectionRealmService sectionRealmService,
    required SubjectRealmService subjectRealmService,
  })  : _classRealm = classRealmService,
        _sectionRealm = sectionRealmService,
        _subjectRealm = subjectRealmService;

  final SupabaseClient _supabase = Supabase.instance.client;
  final ClassRealmService _classRealm;
  final SectionRealmService _sectionRealm;
  final SubjectRealmService _subjectRealm;

  static const Duration _timeout = Duration(seconds: 15);

  // ──────────────────────────── Classes ────────────────────────────

  /// Realm first; if empty, fetch from Supabase, persist, then return.
  Future<List<ClassModel>> fetchClasses() async {
    try {
      if (_classRealm.hasClasses()) {
        return _classRealm.getAllClasses().map(_classFromRealm).toList();
      }

      final response = await _supabase
          .from('classes')
          .select()
          .order('name', ascending: true)
          .timeout(_timeout);

      final list = (response as List<dynamic>)
          .map((e) => ClassModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();

      if (list.isNotEmpty) {
        await _classRealm.saveClasses(list);
      }
      return list;
    } catch (_) {
      if (_classRealm.hasClasses()) {
        return _classRealm.getAllClasses().map(_classFromRealm).toList();
      }
      rethrow;
    }
  }

  Future<ClassModel> insertClass(ClassModel model) async {
    final inserted = await _supabase
        .from('classes')
        .insert(model.toInsertJson())
        .select()
        .single();

    final result = ClassModel.fromJson(Map<String, dynamic>.from(inserted));
    await _classRealm.saveClass(result);
    return result;
  }

  Future<ClassModel> updateClass(String id, ClassModel model) async {
    final updated = await _supabase
        .from('classes')
        .update(model.toUpdateJson())
        .eq('id', id)
        .select()
        .single();

    final result = ClassModel.fromJson(Map<String, dynamic>.from(updated));
    await _classRealm.saveClass(result);
    return result;
  }

  Future<void> deleteClass(String id) async {
    await _supabase.from('classes').delete().eq('id', id).timeout(_timeout);
    await _classRealm.deleteClass(id);
  }

  // ─────────────── Class delete: preflight + helpers ───────────────

  /// Returns a snapshot of everything that will block (or be auto-removed
  /// by) deleting class [id]. Use this to drive the resolution UI before
  /// attempting the actual delete.
  Future<ClassDeletePreflight> preflightClassDelete(String id) async {
    final response = await _supabase
        .rpc('preflight_class_delete', params: {'p_class_id': id})
        .timeout(_timeout);
    return ClassDeletePreflight.fromJson(
      Map<String, dynamic>.from(response as Map),
    );
  }

  /// Bulk-move a set of students into [newClassId]. The
  /// `students_purge_subjects_on_class_change` DB trigger clears their old
  /// subject enrollments automatically.
  Future<void> moveStudentsToClass({
    required List<String> studentIds,
    required String newClassId,
  }) async {
    if (studentIds.isEmpty) return;
    await _supabase
        .from('students')
        .update({
          'class_id': newClassId,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .inFilter('id', studentIds)
        .timeout(_timeout);
  }

  /// Bulk-unassign students from their class (sets `class_id = null`).
  Future<void> unassignStudentsFromClass(List<String> studentIds) async {
    if (studentIds.isEmpty) return;
    await _supabase
        .from('students')
        .update({
          'class_id': null,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .inFilter('id', studentIds)
        .timeout(_timeout);
  }

  /// Soft-delete: mark a class inactive without removing dependencies.
  /// Recommended over hard delete for classes with history.
  Future<ClassModel> deactivateClass(String id) async {
    final updated = await _supabase
        .from('classes')
        .update({
          'is_active': false,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id)
        .select()
        .single();
    final model = ClassModel.fromJson(Map<String, dynamic>.from(updated));
    await _classRealm.saveClass(model);
    return model;
  }

  // ──────────────────────────── Sections ───────────────────────────

  /// Realm first; if empty, fetch from Supabase, persist, then return.
  Future<List<SectionModel>> fetchSections() async {
    try {
      if (_sectionRealm.hasSections()) {
        return _sectionRealm.getAllSections().map(_sectionFromRealm).toList();
      }

      final response = await _supabase
          .from('sections')
          .select()
          .order('name', ascending: true)
          .timeout(_timeout);

      final list = (response as List<dynamic>)
          .map(
            (e) =>
                SectionModel.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList();

      if (list.isNotEmpty) {
        await _sectionRealm.saveSections(list);
      }
      return list;
    } catch (_) {
      if (_sectionRealm.hasSections()) {
        return _sectionRealm.getAllSections().map(_sectionFromRealm).toList();
      }
      rethrow;
    }
  }

  Future<SectionModel> insertSection(SectionModel model) async {
    final inserted = await _supabase
        .from('sections')
        .insert(model.toInsertJson())
        .select()
        .single();

    final result =
        SectionModel.fromJson(Map<String, dynamic>.from(inserted));
    await _sectionRealm.saveSection(result);
    return result;
  }

  Future<SectionModel> updateSection(String id, SectionModel model) async {
    final updated = await _supabase
        .from('sections')
        .update(model.toUpdateJson())
        .eq('id', id)
        .select()
        .single();

    final result =
        SectionModel.fromJson(Map<String, dynamic>.from(updated));
    await _sectionRealm.saveSection(result);
    return result;
  }

  Future<void> deleteSection(String id) async {
    await _supabase.from('sections').delete().eq('id', id).timeout(_timeout);
    await _sectionRealm.deleteSection(id);
  }

  // ──────────────────── Class–Subject assignments ───────────────────

  /// Returns subject IDs currently assigned to [classId].
  Future<List<String>> fetchSubjectIdsForClass(String classId) async {
    final response = await _supabase
        .from('class_subjects')
        .select('subject_id')
        .eq('class_id', classId)
        .timeout(_timeout);

    return (response as List<dynamic>)
        .map((e) => e['subject_id'] as String)
        .toList();
  }

  /// Returns true if [classId] has at least one subject assignment.
  Future<bool> classHasSubjects(String classId) async {
    final response = await _supabase
        .from('class_subjects')
        .select('id')
        .eq('class_id', classId)
        .limit(1)
        .timeout(_timeout);
    return (response as List).isNotEmpty;
  }

  /// Returns how many classes [subjectId] is currently assigned to.
  Future<int> subjectClassCount(String subjectId) async {
    final response = await _supabase
        .from('class_subjects')
        .select('id')
        .eq('subject_id', subjectId)
        .timeout(_timeout);
    return (response as List).length;
  }

  /// Replaces the subject assignment for [classId] with [subjectIds].
  Future<void> setSubjectsForClass(
    String classId,
    List<String> subjectIds,
  ) async {
    await _supabase
        .from('class_subjects')
        .delete()
        .eq('class_id', classId)
        .timeout(_timeout);

    if (subjectIds.isEmpty) return;

    final rows = subjectIds
        .map((sid) => {'class_id': classId, 'subject_id': sid})
        .toList();

    await _supabase.from('class_subjects').insert(rows).timeout(_timeout);
  }

  // ──────────────────────────── Subjects ───────────────────────────

  /// Realm first; if empty, fetch from Supabase, persist, then return.
  Future<List<SubjectModel>> fetchSubjects() async {
    try {
      if (_subjectRealm.hasSubjects()) {
        return _subjectRealm.getAllSubjects().map(_subjectFromRealm).toList();
      }

      final response = await _supabase
          .from('subjects')
          .select()
          .order('name', ascending: true)
          .timeout(_timeout);

      final list = (response as List<dynamic>)
          .map(
            (e) => SubjectModel.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList();

      if (list.isNotEmpty) {
        await _subjectRealm.saveSubjects(list);
      }
      return list;
    } catch (_) {
      if (_subjectRealm.hasSubjects()) {
        return _subjectRealm.getAllSubjects().map(_subjectFromRealm).toList();
      }
      rethrow;
    }
  }

  Future<SubjectModel> insertSubject(SubjectModel model) async {
    final name = model.name.trim();
    if (await _subjectNameExists(name)) {
      throw DuplicateSubjectNameException(name);
    }

    final inserted = await _supabase
        .from('subjects')
        .insert(model.copyWith(name: name).toInsertJson())
        .select()
        .single();

    final result =
        SubjectModel.fromJson(Map<String, dynamic>.from(inserted));
    await _subjectRealm.saveSubject(result);
    return result;
  }

  Future<SubjectModel> updateSubject(String id, SubjectModel model) async {
    final name = model.name.trim();

    final updated = await _supabase
        .from('subjects')
        .update(model.copyWith(name: name).toUpdateJson())
        .eq('id', id)
        .select()
        .single();

    final result =
        SubjectModel.fromJson(Map<String, dynamic>.from(updated));
    await _subjectRealm.saveSubject(result);
    return result;
  }

  Future<void> deleteSubject(String id) async {
    await _supabase.from('subjects').delete().eq('id', id).timeout(_timeout);
    await _subjectRealm.deleteSubject(id);
  }


  ClassModel _classFromRealm(ClassRealm r) {
    return ClassModel(
      id: r.id,
      name: r.name,
      section: r.section,
      isActive: r.isActive,
      createdAt: r.createdAt,
      updatedAt: r.updatedAt,
    );
  }

  SectionModel _sectionFromRealm(SectionRealm r) {
    return SectionModel(
      id: r.id,
      name: r.name,
      createdAt: r.createdAt,
      updatedAt: r.updatedAt,
    );
  }

  SubjectModel _subjectFromRealm(SubjectRealm r) {
    return SubjectModel(
      id: r.id,
      name: r.name,
      description: r.description,
      isActive: r.isActive,
      createdAt: r.createdAt,
      updatedAt: r.updatedAt,
    );
  }

  Future<bool> _subjectNameExists(String name, {String? excludeId}) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return false;

    var query =
        _supabase.from('subjects').select('id').ilike('name', trimmed);
    if (excludeId != null) {
      query = query.neq('id', excludeId);
    }

    final row = await query.maybeSingle().timeout(_timeout);
    return row != null;
  }
}

class DuplicateSubjectNameException implements Exception {
  DuplicateSubjectNameException(this.name);

  final String name;

  @override
  String toString() =>
      'A subject named "$name" already exists.';
}
