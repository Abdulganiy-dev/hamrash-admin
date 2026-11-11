import 'package:hamrash_admin/api/models/grading/grade_boundary.dart';
import 'package:hamrash_admin/api/models/grading/grading_setup.dart';
import 'package:hamrash_admin/api/models/grading/score_column.dart';
import 'package:hamrash_admin/api/services/supabase_services/supabase_refusal.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The school's grading setup: score columns and grade boundaries, per
/// section. Every member reads them; school leaders change them.
///
/// Score columns keep their direct single-row writes (migration 08) and
/// `reorder_score_columns` (33). Grade boundaries can only change through the
/// whole-set RPCs from migration 34: `set_grade_scale`, `apply_grade_system`,
/// `copy_section_grading` and `remove_section_grade_scale`.
///
/// Refusals come back as [SupabaseRefusal] with a readable message; the
/// RPCs' P0001 messages are written to be shown as they are.
class GradingService {
  GradingService(this._supabase);

  final SupabaseClient _supabase;

  static const leadersOnly =
      'Only the owner, admins, the principal and vice principals can change '
      'grading.';

  /// Every score column and grade boundary of the school, with the
  /// `section_id` that says which set each row belongs to.
  Future<GradingSetup> getSetup(String organizationId) => _run(
    'getSetup',
    () async {
      final results = await Future.wait<List<Map<String, dynamic>>>([
        _supabase
            .from('score_columns')
            .select(ScoreColumn.columns)
            .eq('organization_id', organizationId)
            .order('sort_order')
            .order('name'),
        _supabase
            .from('grade_boundaries')
            .select(GradeBoundary.columns)
            .eq('organization_id', organizationId)
            .order('min_percent', ascending: false),
      ]);
      return GradingSetup(
        columns: results[0].map(ScoreColumn.fromJson).toList(),
        grades: results[1].map(GradeBoundary.fromJson).toList(),
      );
    },
    log: (setup) => {
      'organization_id': organizationId,
      'columns': setup.columns.length,
      'grades': setup.grades.length,
      'section_columns': setup.columns.where((c) => c.sectionId != null).length,
      'section_grades': setup.grades.where((g) => g.sectionId != null).length,
    },
  );

  /// CA 1 (20), CA 2 (20) and Exam (60), and grades A to F, plus WAEC
  /// grades for Senior Secondary (or an older "Secondary" section). Only
  /// for a school with no grading setup yet.
  Future<void> createStandardGrading(String organizationId) =>
      _run('createStandardGrading', () async {
        await _supabase.rpc(
          'create_standard_grading',
          params: {'p_organization_id': organizationId},
        );
      }, log: (_) => {'organization_id': organizationId});

  /// Adds a score column to [sectionId]'s own set, or to the school's when
  /// null. Returns the new column's id.
  Future<String> addScoreColumn({
    required String organizationId,
    required String name,
    required double maxScore,
    required int sortOrder,
    String? sectionId,
  }) => _run(
    'addScoreColumn',
    () async {
      final row = await _supabase
          .from('score_columns')
          .insert({
            'organization_id': organizationId,
            'section_id': ?sectionId,
            'name': name,
            'max_score': maxScore,
            'sort_order': sortOrder,
          })
          .select('id')
          .single();
      return row['id'] as String;
    },
    log: (id) => {
      'organization_id': organizationId,
      'section_id': sectionId,
      'column_id': id,
    },
    duplicate: 'There’s already a column with that name. Pick another name.',
    invalid: 'Enter marks above 0, like 20 or 12.5.',
  );

  Future<void> updateScoreColumn(
    ScoreColumn column, {
    required String name,
    required double maxScore,
  }) => _run(
    'updateScoreColumn',
    () async {
      final changed = await _supabase
          .from('score_columns')
          .update({'name': name, 'max_score': maxScore})
          .eq('id', column.id)
          .select('id');
      refuseIfNothingChanged(changed, leadersOnly);
    },
    log: (_) => {'column_id': column.id},
    duplicate: 'There’s already a column with that name. Pick another name.',
    invalid: 'Enter marks above 0, like 20 or 12.5.',
  );

  Future<void> deleteScoreColumn(ScoreColumn column) => _run(
    'deleteScoreColumn',
    () async {
      final removed = await _supabase
          .from('score_columns')
          .delete()
          .eq('id', column.id)
          .select('id');
      refuseIfNothingChanged(removed, leadersOnly);
    },
    log: (_) => {'column_id': column.id},
    inUse:
        'Scores are already entered for this column, so it can’t be removed.',
  );

  /// Puts one set's score columns in a new report-card order. [orderedIds]
  /// is every column in that set, once, in the new order. One call
  /// (migration 33), so the order changes completely or not at all.
  Future<void> reorderScoreColumns(
    String organizationId,
    List<String> orderedIds,
  ) => _run(
    'reorderScoreColumns',
    () async {
      await _supabase.rpc(
        'reorder_score_columns',
        params: {
          'p_organization_id': organizationId,
          'p_column_ids': orderedIds,
        },
      );
    },
    log: (_) => {
      'organization_id': organizationId,
      'columns': orderedIds.length,
    },
  );

  /// Replaces ONE set's whole grade scale: a section's own when [sectionId]
  /// is set, otherwise the school-level set. Every add, edit and remove sends
  /// the complete new list.
  Future<void> setGradeScale({
    required String organizationId,
    required String? sectionId,
    required List<GradeBoundary> grades,
  }) => _run(
    'setGradeScale',
    () async {
      await _supabase.rpc(
        'set_grade_scale',
        params: {
          'p_organization_id': organizationId,
          'p_section_id': sectionId,
          'p_grades': [
            for (final grade in grades)
              {
                'grade': grade.grade,
                'min_percent': grade.minPercent,
                'max_percent': grade.maxPercent,
                'remark': grade.remark,
                'is_pass': grade.isPass,
              },
          ],
        },
      );
    },
    log: (_) => {
      'organization_id': organizationId,
      'section_id': sectionId,
      'grades': grades.length,
    },
  );

  /// Puts the WAEC or Standard preset on one section, atomically.
  Future<void> applyGradeSystem({
    required String organizationId,
    required String sectionId,
    required String system,
  }) => _run(
    'applyGradeSystem',
    () async {
      await _supabase.rpc(
        'apply_grade_system',
        params: {
          'p_organization_id': organizationId,
          'p_section_id': sectionId,
          'p_system': system,
        },
      );
    },
    log: (_) => {
      'organization_id': organizationId,
      'section_id': sectionId,
      'system': system,
    },
  );

  /// Copies score columns and/or grades into [toSectionId], replacing its own
  /// rows of each kind copied. [fromSectionId] null copies the school-level
  /// set ("Give Primary its own setup").
  Future<void> copySectionGrading({
    required String organizationId,
    required String? fromSectionId,
    required String toSectionId,
    required bool columns,
    required bool grades,
  }) => _run(
    'copySectionGrading',
    () async {
      await _supabase.rpc(
        'copy_section_grading',
        params: {
          'p_organization_id': organizationId,
          'p_from_section_id': fromSectionId,
          'p_to_section_id': toSectionId,
          'p_columns': columns,
          'p_grades': grades,
        },
      );
    },
    log: (_) => {
      'organization_id': organizationId,
      'from_section_id': fromSectionId,
      'to_section_id': toSectionId,
      'columns': columns,
      'grades': grades,
    },
  );

  /// Deletes a section's own grade rows, so it uses the school-level scale
  /// again. Score columns are not touched.
  Future<void> removeSectionGradeScale({
    required String organizationId,
    required String sectionId,
  }) => _run(
    'removeSectionGradeScale',
    () async {
      await _supabase.rpc(
        'remove_section_grade_scale',
        params: {
          'p_organization_id': organizationId,
          'p_section_id': sectionId,
        },
      );
    },
    log: (_) => {'organization_id': organizationId, 'section_id': sectionId},
  );

  Future<T> _run<T>(
    String name,
    Future<T> Function() body, {
    required Map<String, Object?> Function(T result) log,
    String? duplicate,
    String? inUse,
    String? invalid,
  }) => runRefusable(
    name,
    body,
    log: log,
    forbidden: leadersOnly,
    duplicate: duplicate,
    inUse: inUse,
    invalid: invalid,
  );
}
