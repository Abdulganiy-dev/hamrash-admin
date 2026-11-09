import 'package:hamrash_admin/api/models/grading/grade_boundary.dart';
import 'package:hamrash_admin/api/models/grading/grading_setup.dart';
import 'package:hamrash_admin/api/models/grading/score_column.dart';
import 'package:hamrash_admin/api/services/supabase_services/supabase_refusal.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The school's grading setup: score columns and grade boundaries. Every
/// member reads them; school leaders change them.
///
/// Score columns are the school's own (`section_id` null). Grade boundaries
/// are the school default plus any section's own scale, a full set of grades
/// with that `section_id`: a section that has any uses them instead of the
/// school's.
///
/// Refusals come back as [SupabaseRefusal] with a readable message.
class GradingService {
  GradingService(this._supabase);

  final SupabaseClient _supabase;

  static const leadersOnly =
      'Only the owner, admins, the principal and vice principals can change '
      'grading.';

  /// The school's score columns (report-card order) and every grade
  /// boundary: the school default and each section's own scale.
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
      'section_scales': setup.sectionBoundaries.length,
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

  /// Puts the school's score columns in a new report-card order. [orderedIds]
  /// is every column, once, in the new order. One call (migration 33), so the
  /// order changes completely or not at all. A column added or removed by
  /// someone else since the page loaded is refused with a readable message.
  Future<void> reorderScoreColumns(
    String organizationId,
    List<String> orderedIds,
  ) => _run('reorderScoreColumns', () async {
    await _supabase.rpc(
      'reorder_score_columns',
      params: {
        'p_organization_id': organizationId,
        'p_column_ids': orderedIds,
      },
    );
  }, log: (_) => {'organization_id': organizationId, 'columns': orderedIds.length});

  /// Adds a grade to the school default scale, or to [sectionId]'s own scale.
  Future<void> addGradeBoundary({
    required String organizationId,
    required String grade,
    required double minPercent,
    required String? remark,
    required bool isPass,
    String? sectionId,
  }) => _run(
    'addGradeBoundary',
    () async {
      await _supabase.from('grade_boundaries').insert({
        'organization_id': organizationId,
        'section_id': ?sectionId,
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

  /// Gives [sectionId] its own scale, starting as a copy of [grades] (the
  /// school default). All rows go in one insert, so the section gets the whole
  /// scale or nothing: a partial set would silently replace the school's
  /// scale for that section.
  Future<void> copyScaleToSection({
    required String organizationId,
    required String sectionId,
    required List<GradeBoundary> grades,
  }) => _run(
    'copyScaleToSection',
    () async {
      await _supabase.from('grade_boundaries').insert([
        for (final g in grades)
          {
            'organization_id': organizationId,
            'section_id': sectionId,
            'grade': g.grade,
            'min_percent': g.minPercent,
            'remark': g.remark,
            'is_pass': g.isPass,
          },
      ]);
    },
    log: (_) => {
      'organization_id': organizationId,
      'section_id': sectionId,
      'grades': grades.length,
    },
    duplicate: 'That section already has its own grade scale.',
    invalid: _gradeInvalid,
  );

  /// Removes all of [sectionId]'s own grades in one delete, so the section
  /// goes back to the school default.
  Future<void> deleteSectionScale({
    required String organizationId,
    required String sectionId,
  }) => _run(
    'deleteSectionScale',
    () async {
      final removed = await _supabase
          .from('grade_boundaries')
          .delete()
          .eq('organization_id', organizationId)
          .eq('section_id', sectionId)
          .select('id');
      refuseIfNothingChanged(removed, leadersOnly);
    },
    log: (_) => {'organization_id': organizationId, 'section_id': sectionId},
  );

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
