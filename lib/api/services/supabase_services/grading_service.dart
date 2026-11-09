import 'package:hamrash_admin/api/models/grading/grade_boundary.dart';
import 'package:hamrash_admin/api/models/grading/grading_setup.dart';
import 'package:hamrash_admin/api/models/grading/score_column.dart';
import 'package:hamrash_admin/api/services/supabase_services/supabase_refusal.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The school's grading setup: score columns and grade boundaries. Every
/// member reads them; school leaders change them.
///
/// Only the school's own set (`section_id` null) is handled here, never a
/// section's own overrides.
///
/// Refusals come back as [SupabaseRefusal] with a readable message.
class GradingService {
  GradingService(this._supabase);

  final SupabaseClient _supabase;

  static const leadersOnly =
      'Only the owner, admins, the principal and vice principals can change '
      'grading.';

  /// The school's score columns (report-card order) and grade boundaries.
  Future<GradingSetup> getSetup(String organizationId) => _run(
    'getSetup',
    () async {
      final results = await Future.wait<List<Map<String, dynamic>>>([
        _supabase
            .from('score_columns')
            .select(ScoreColumn.columns)
            .eq('organization_id', organizationId)
            .isFilter('section_id', null)
            .order('sort_order')
            .order('name'),
        _supabase
            .from('grade_boundaries')
            .select(GradeBoundary.columns)
            .eq('organization_id', organizationId)
            .isFilter('section_id', null)
            .order('min_percent', ascending: false),
      ]);
      return GradingSetup(
        columns: results[0].map(ScoreColumn.fromJson).toList(),
        boundaries: results[1].map(GradeBoundary.fromJson).toList(),
      );
    },
    log: (setup) => {
      'organization_id': organizationId,
      'columns': setup.columns.length,
      'grades': setup.boundaries.length,
    },
  );

  /// CA 1 (20), CA 2 (20) and Exam (60), and grades A to F, plus WAEC
  /// grades for a section named Secondary. Only for a school with no
  /// grading setup yet.
  Future<void> createStandardGrading(String organizationId) =>
      _run('createStandardGrading', () async {
        await _supabase.rpc(
          'create_standard_grading',
          params: {'p_organization_id': organizationId},
        );
      }, log: (_) => {'organization_id': organizationId});

  /// Adds a score column at [sortOrder] on the report card.
  Future<void> addScoreColumn({
    required String organizationId,
    required String name,
    required double maxScore,
    required int sortOrder,
  }) => _run(
    'addScoreColumn',
    () async {
      await _supabase.from('score_columns').insert({
        'organization_id': organizationId,
        'name': name,
        'max_score': maxScore,
        'sort_order': sortOrder,
      });
    },
    log: (_) => {'organization_id': organizationId, 'name': name},
    duplicate: 'There’s already a column with that name.',
    invalid: 'A column needs a name and has to be out of more than 0.',
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
    duplicate: 'There’s already a column with that name.',
    invalid: 'A column needs a name and has to be out of more than 0.',
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

  Future<void> addGradeBoundary({
    required String organizationId,
    required String grade,
    required double minPercent,
    required String? remark,
    required bool isPass,
  }) => _run(
    'addGradeBoundary',
    () async {
      await _supabase.from('grade_boundaries').insert({
        'organization_id': organizationId,
        'grade': grade,
        'min_percent': minPercent,
        'remark': remark,
        'is_pass': isPass,
      });
    },
    log: (_) => {'organization_id': organizationId, 'grade': grade},
    duplicate: _gradeTaken,
    invalid: _gradeInvalid,
  );

  Future<void> updateGradeBoundary(
    GradeBoundary boundary, {
    required String grade,
    required double minPercent,
    required String? remark,
    required bool isPass,
  }) => _run(
    'updateGradeBoundary',
    () async {
      final changed = await _supabase
          .from('grade_boundaries')
          .update({
            'grade': grade,
            'min_percent': minPercent,
            'remark': remark,
            'is_pass': isPass,
          })
          .eq('id', boundary.id)
          .select('id');
      refuseIfNothingChanged(changed, leadersOnly);
    },
    log: (_) => {'boundary_id': boundary.id},
    duplicate: _gradeTaken,
    invalid: _gradeInvalid,
  );

  Future<void> deleteGradeBoundary(GradeBoundary boundary) =>
      _run('deleteGradeBoundary', () async {
        final removed = await _supabase
            .from('grade_boundaries')
            .delete()
            .eq('id', boundary.id)
            .select('id');
        refuseIfNothingChanged(removed, leadersOnly);
      }, log: (_) => {'boundary_id': boundary.id});

  static const _gradeTaken =
      'Another grade already has that name or starts at that number.';
  static const _gradeInvalid =
      'A grade needs a name and has to start from 0 up to below 100.';

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
