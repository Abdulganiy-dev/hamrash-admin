import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hamrash_admin/api/models/class_structure/class_structure.dart';
import 'package:hamrash_admin/api/models/grading/grade_boundary.dart';
import 'package:hamrash_admin/api/models/grading/grade_editing.dart';
import 'package:hamrash_admin/api/models/grading/grade_review.dart';
import 'package:hamrash_admin/api/models/grading/grade_systems.dart';
import 'package:hamrash_admin/api/models/grading/grading_setup.dart';
import 'package:hamrash_admin/api/models/grading/score_column.dart';
import 'package:hamrash_admin/api/models/grading/section_grading.dart';
import 'package:hamrash_admin/api/models/organization_models/member_school.dart';
import 'package:hamrash_admin/api/models/organization_models/organization.dart';
import 'package:hamrash_admin/api/models/organization_models/organization_member.dart';
import 'package:hamrash_admin/api/services/supabase_services/class_structure_service.dart';
import 'package:hamrash_admin/api/services/supabase_services/grading_service.dart';
import 'package:hamrash_admin/api/services/supabase_services/supabase_refusal.dart';
import 'package:hamrash_admin/core/widgets/app_alert_dialog.dart';
import 'package:hamrash_admin/core/widgets/app_badge.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_variants.dart';
import 'package:hamrash_admin/core/widgets/selection/app_selection_controls.dart';
import 'package:hamrash_admin/singleton_locator/locator.dart';
import 'package:hamrash_admin/views/grading/grades_screen.dart';
import 'package:hamrash_admin/views/grading/grades_view_model.dart';
import 'package:hamrash_admin/views/grading/grading_review_screen.dart';
import 'package:hamrash_admin/views/grading/grading_screen.dart';
import 'package:hamrash_admin/views/grading/grading_view_model.dart';
import 'package:hamrash_admin/views/grading/score_columns_screen.dart';
import 'package:hamrash_admin/views/grading/score_columns_view_model.dart';
import 'package:hamrash_admin/views/grading/section_grading_screen.dart';
import 'package:hamrash_admin/views/grading/section_grading_view_model.dart';
import 'package:hamrash_admin/views/grading/widgets/grade_sheet.dart';

ScoreColumn _column(
  String id,
  String name,
  double max,
  int order, {
  String? sectionId,
}) => ScoreColumn(
  id: id,
  name: name,
  maxScore: max,
  sortOrder: order,
  sectionId: sectionId,
);

GradeBoundary _grade(
  String grade,
  int min,
  int max,
  String? remark, {
  bool isPass = true,
  String? sectionId,
}) => GradeBoundary(
  id: sectionId == null ? grade : '$sectionId-$grade',
  sectionId: sectionId,
  grade: grade,
  minPercent: min,
  maxPercent: max,
  remark: remark,
  isPass: isPass,
);

List<GradeBoundary> _standard({String? sectionId}) => [
  for (final grade in GradeSystem.standard.boundaries)
    grade.copyWith(
      id: '${sectionId ?? 'school'}-${grade.grade}',
      sectionId: sectionId,
    ),
];

List<GradeBoundary> _waec({String? sectionId}) => [
  for (final grade in GradeSystem.waec.boundaries)
    grade.copyWith(
      id: '${sectionId ?? 'school'}-${grade.grade}',
      sectionId: sectionId,
    ),
];

List<ScoreColumn> _standardColumns({String? sectionId}) => [
  _column('${sectionId ?? 'school'}-ca1', 'CA 1', 20, 1, sectionId: sectionId),
  _column('${sectionId ?? 'school'}-ca2', 'CA 2', 20, 2, sectionId: sectionId),
  _column('${sectionId ?? 'school'}-exam', 'Exam', 60, 3, sectionId: sectionId),
];

SchoolSection _section(
  String id,
  String name,
  int order, {
  bool isActive = true,
  List<String> classes = const [],
}) => SchoolSection(
  id: id,
  name: name,
  sortOrder: order,
  isActive: isActive,
  classes: [
    for (final (i, className) in classes.indexed)
      SchoolClass(
        id: '$id-class-$i',
        sectionId: id,
        name: className,
        sortOrder: i + 1,
        isGraduating: false,
        isActive: true,
        arms: const [],
      ),
  ],
);

List<SchoolSection> _sections() => [
  _section('nursery', 'Nursery', 1, classes: ['Nursery 1', 'Nursery 2']),
  _section('primary', 'Primary', 2, classes: ['Primary 1']),
  _section('junior', 'Junior Secondary', 3, classes: ['JSS 1']),
  _section('senior', 'Senior Secondary', 4, classes: ['SS 1']),
  _section('pre', 'Pre-Nursery', 5, isActive: false),
];

class _Structure implements ClassStructureService {
  _Structure([List<SchoolSection>? sections])
    : sections = sections ?? _sections();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  final List<SchoolSection> sections;

  @override
  Future<List<SchoolSection>> getStructure(String organizationId) async =>
      sections;
}

class _Grading implements GradingService {
  _Grading({List<ScoreColumn>? columns, List<GradeBoundary>? grades})
    : columns = columns ?? [],
      grades = grades ?? [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  List<ScoreColumn> columns;
  List<GradeBoundary> grades;
  Object? failWith;
  int _ids = 0;

  final setScales = <({String? sectionId, List<GradeBoundary> grades})>[];
  final appliedSystems = <({String sectionId, String system})>[];
  final copies = <({String? from, String to, bool columns, bool grades})>[];
  final removedScales = <String>[];
  final reorders = <List<String>>[];
  ({String? sectionId, String name, double max, int order})? added;
  ScoreColumn? removedColumn;
  ScoreColumn? updatedColumn;

  @override
  Future<GradingSetup> getSetup(String organizationId) async {
    if (failWith case final error?) throw error;
    return GradingSetup(columns: [...columns], grades: [...grades]);
  }

  @override
  Future<String> addScoreColumn({
    required String organizationId,
    required String name,
    required double maxScore,
    required int sortOrder,
    String? sectionId,
  }) async {
    if (failWith case final error?) throw error;
    final id = 'new-${++_ids}';
    added = (sectionId: sectionId, name: name, max: maxScore, order: sortOrder);
    columns = [
      ...columns,
      _column(id, name, maxScore, sortOrder, sectionId: sectionId),
    ];
    return id;
  }

  @override
  Future<void> updateScoreColumn(
    ScoreColumn column, {
    required String name,
    required double maxScore,
  }) async {
    if (failWith case final error?) throw error;
    updatedColumn = column;
    columns = [
      for (final existing in columns)
        if (existing.id == column.id)
          existing.copyWith(name: name, maxScore: maxScore)
        else
          existing,
    ];
  }

  @override
  Future<void> deleteScoreColumn(ScoreColumn column) async {
    if (failWith case final error?) throw error;
    removedColumn = column;
    columns = [
      for (final c in columns)
        if (c.id != column.id) c,
    ];
  }

  @override
  Future<void> reorderScoreColumns(
    String organizationId,
    List<String> orderedIds,
  ) async {
    if (failWith case final error?) throw error;
    reorders.add(orderedIds);
    columns = [
      for (final (i, id) in orderedIds.indexed)
        columns.firstWhere((c) => c.id == id).copyWith(sortOrder: i + 1),
      for (final c in columns)
        if (!orderedIds.contains(c.id)) c,
    ];
  }

  @override
  Future<void> setGradeScale({
    required String organizationId,
    required String? sectionId,
    required List<GradeBoundary> grades,
  }) async {
    if (failWith case final error?) throw error;
    setScales.add((sectionId: sectionId, grades: grades));
    this.grades = [
      for (final existing in this.grades)
        if (existing.sectionId != sectionId) existing,
      for (final grade in grades) grade.copyWith(sectionId: sectionId),
    ];
  }

  @override
  Future<void> applyGradeSystem({
    required String organizationId,
    required String sectionId,
    required String system,
  }) async {
    if (failWith case final error?) throw error;
    appliedSystems.add((sectionId: sectionId, system: system));
    final preset = GradeSystem.values.byName(system).boundaries;
    grades = [
      for (final existing in grades)
        if (existing.sectionId != sectionId) existing,
      for (final grade in preset)
        grade.copyWith(id: '$sectionId-${grade.grade}', sectionId: sectionId),
    ];
  }

  @override
  Future<void> copySectionGrading({
    required String organizationId,
    required String? fromSectionId,
    required String toSectionId,
    required bool columns,
    required bool grades,
  }) async {
    if (failWith case final error?) throw error;
    copies.add((
      from: fromSectionId,
      to: toSectionId,
      columns: columns,
      grades: grades,
    ));
    if (columns) {
      final source = [
        for (final c in this.columns)
          if (c.sectionId == fromSectionId) c,
      ];
      this.columns = [
        for (final c in this.columns)
          if (c.sectionId != toSectionId) c,
        for (final c in source) c.copyWith(sectionId: toSectionId),
      ];
    }
    if (grades) {
      final source = [
        for (final g in this.grades)
          if (g.sectionId == fromSectionId) g,
      ];
      this.grades = [
        for (final g in this.grades)
          if (g.sectionId != toSectionId) g,
        for (final g in source)
          g.copyWith(id: '$toSectionId-${g.grade}', sectionId: toSectionId),
      ];
    }
  }

  @override
  Future<void> removeSectionGradeScale({
    required String organizationId,
    required String sectionId,
  }) async {
    if (failWith case final error?) throw error;
    removedScales.add(sectionId);
    grades = [
      for (final g in grades)
        if (g.sectionId != sectionId) g,
    ];
  }
}

MemberSchool _school(OrganizationMemberRole role) => MemberSchool(
  organization: Organization(
    id: 'kings',
    name: 'Kings College',
    status: OrganizationStatus.trial,
    createdBy: 'platform',
    numberPrefix: 'KCL',
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  ),
  roles: [role],
);

void main() {
  setUpAll(() async {
    final loader = FontLoader('Nunito');
    for (final file in ['Regular', 'Bold', 'ExtraBold']) {
      loader.addFont(rootBundle.load('assets/fonts/Nunito-$file.ttf'));
    }
    await loader.load();
  });

  group('SectionGrading', () {
    final setup = GradingSetup(
      columns: [
        ..._standardColumns(),
        _column('junior-ca1', 'CA 1', 20, 1, sectionId: 'junior'),
        _column('junior-ca2', 'CA 2', 20, 2, sectionId: 'junior'),
        _column('junior-exam', 'Exam', 60, 3, sectionId: 'junior'),
      ],
      grades: [
        ..._standard(),
        ..._waec(sectionId: 'nursery'),
      ],
    );

    test('falls back independently for columns and grades', () {
      final nursery = setup.forSectionId('nursery', sectionName: 'Nursery');
      expect(nursery.hasOwnGrades, isTrue);
      expect(nursery.hasOwnColumns, isFalse);
      expect(nursery.usesSchoolColumns, isTrue);
      expect(nursery.usesSchoolGrades, isFalse);
      expect(nursery.gradeSystem, GradeSystem.waec);

      final primary = setup.forSectionId('primary', sectionName: 'Primary');
      expect(primary.hasOwnColumns, isFalse);
      expect(primary.hasOwnGrades, isFalse);
      expect(primary.usesSchoolColumns, isTrue);
      expect(primary.usesSchoolGrades, isTrue);
      expect(primary.usesSchoolSetup, isTrue);
      expect(primary.status, GradingStatus.setUp);
      expect(primary.summary, '3 columns · 100 marks · Standard grades');
    });

    test('status follows both parts, and a legacy gap is not set up', () {
      final junior = setup.forSectionId(
        'junior',
        sectionName: 'Junior Secondary',
      );
      expect(junior.hasColumns, isTrue);
      expect(junior.hasGrades, isTrue);
      expect(junior.status, GradingStatus.setUp);
      expect(junior.summary, '3 columns · 100 marks · Standard grades');

      final empty = GradingSetup(
        columns: _standardColumns(),
        grades: const [],
      ).forSectionId('senior', sectionName: 'Senior Secondary');
      expect(empty.status, GradingStatus.partlySetUp);
      expect(empty.gradesSummary, 'No grades yet');

      final none = GradingSetup(
        columns: const [],
        grades: const [],
      ).forSectionId('senior', sectionName: 'Senior Secondary');
      expect(none.status, GradingStatus.notSetUp);
      expect(none.summary, 'No columns or grades yet');

      final legacy = GradingSetup(
        columns: _standardColumns(),
        grades: [
          _grade('A', 70, 100, 'Excellent'),
          _grade('B', 60, 69, 'Very Good'),
          _grade('C', 50, 59, 'Good'),
          _grade('D', 45, 49, 'Fair'),
          _grade('E', 40, 44, 'Pass'),
        ],
      ).forSectionId('primary', sectionName: 'Primary');
      expect(legacy.status, GradingStatus.partlySetUp);
      expect(legacy.gradesTile, isFalse);
      expect(legacy.uncoveredRange, '0 to 39');
      expect(
        legacy.summary,
        '3 columns · 100 marks · Grades don’t cover 0 to 100',
      );
      expect(legacy.gradesSummary, '5 grades · doesn’t cover 0 to 100 yet');
    });

    test('reads ranges, remarks and the grade for a percentage', () {
      final grading = setup.forSectionId('primary', sectionName: 'Primary');
      expect(grading.rangeOf(grading.grades.first), '70 to 100');
      expect(grading.detailsOf(grading.grades.first), 'Excellent · Pass');
      expect(grading.detailsOf(_grade('E', 40, 44, 'Pass')), 'Pass');
      expect(
        grading.detailsOf(_grade('F', 0, 39, null, isPass: false)),
        'Fail',
      );
      expect(grading.gradeFor(85)?.grade, 'A');
      expect(grading.gradeFor(70)?.grade, 'A');
      expect(grading.gradeFor(69)?.grade, 'B');
      expect(grading.gradeFor(0)?.grade, 'F');
    });

    test('detects the preset, or leaves a custom scale alone', () {
      final standard = setup.forSectionId('primary');
      expect(standard.gradeSystem, GradeSystem.standard);
      expect(standard.gradesSummary, 'Standard · 6 grades · covers 0 to 100');
      final waec = setup.forSectionId('nursery');
      expect(waec.gradesSummary, 'WAEC · 9 grades · covers 0 to 100');
      final custom = GradingSetup(
        columns: const [],
        grades: [_grade('X', 0, 100, 'Custom')],
      ).forSectionId('primary');
      expect(custom.gradeSystem, isNull);
      expect(custom.gradesSummary, '1 grade · covers 0 to 100');
    });

    test('checks column names, marks, total and suggestions', () {
      final grading = setup.forSectionId('primary', sectionName: 'Primary');
      expect(
        grading.columnNameProblem('exam'),
        'Primary already has a column called exam. Pick another name.',
      );
      expect(
        SectionGrading.marksProblem('0'),
        'Enter marks above 0, like 20 or 12.5.',
      );
      expect(
        SectionGrading.marksProblem('1.234'),
        contains('2 decimal places'),
      );
      expect(SectionGrading.marks('12,5'), 12.5);
      expect(grading.totalWith('20'), 120);
      expect(grading.totalLine('20', replacing: grading.columns[1]), (
        label: 'Total stays',
        value: '100 marks',
        muted: false,
      ));
      expect(grading.columnSuggestions, ['CA 3', 'Test', 'Assignment']);
      expect(grading.shareOf(grading.columns[2]), 60);
    });

    test('checks grade names and the default pass state', () {
      final grading = setup.forSectionId('primary', sectionName: 'Primary');
      expect(
        grading.gradeNameProblem('a'),
        'Primary already has a grade called a.',
      );
      expect(
        grading.gradeNameProblem('A', except: grading.grades.first),
        isNull,
      );
      expect(grading.defaultIsPass('0'), isFalse);
      expect(grading.defaultIsPass('65'), isTrue);
    });
  });

  group('GradeEditor', () {
    final grades = _standard();

    test('editing To moves where the grade above starts', () {
      final b = grades.firstWhere((g) => g.grade == 'B');
      final result = GradeEditor.edit(
        grades: grades,
        original: b,
        name: 'B',
        from: 60,
        to: 70,
        remark: 'Very Good',
        isPass: true,
        sectionName: 'Junior Secondary',
      );
      expect(result.error, isNull);
      expect(
        [for (final c in result.changes) '${c.label}|${c.value}'],
        ['B becomes|60 to 70, from 60 to 69', 'A will start at|71, from 70'],
      );
      final next = result.grades!;
      expect(next.firstWhere((g) => g.grade == 'B').maxPercent, 70);
      expect(next.firstWhere((g) => g.grade == 'A').minPercent, 71);
      expect(gradeRangesTile(next), isTrue);
    });

    test('editing From moves where the grade below ends', () {
      final a = grades.firstWhere((g) => g.grade == 'A');
      final result = GradeEditor.edit(
        grades: grades,
        original: a,
        name: 'A',
        from: 72,
        to: 100,
        remark: 'Excellent',
        isPass: true,
        sectionName: 'Junior Secondary',
      );
      expect(
        [for (final c in result.changes) '${c.label}|${c.value}'],
        ['A becomes|72 to 100, from 70 to 100', 'B will end at|71, from 69'],
      );
      expect(result.grades!.firstWhere((g) => g.grade == 'B').maxPercent, 71);
    });

    test('locks the top To and the bottom From', () {
      final a = grades.firstWhere((g) => g.grade == 'A');
      expect(
        GradeEditor.edit(
          grades: grades,
          original: a,
          name: 'A',
          from: 70,
          to: 99,
          remark: null,
          isPass: true,
          sectionName: 'Junior Secondary',
        ).error,
        'The top grade always goes up to 100.',
      );
      final f = grades.firstWhere((g) => g.grade == 'F');
      expect(
        GradeEditor.edit(
          grades: grades,
          original: f,
          name: 'F',
          from: 2,
          to: 39,
          remark: null,
          isPass: false,
          sectionName: 'Junior Secondary',
        ).error,
        'The lowest grade always starts at 0.',
      );
    });

    test('refuses a change that would cover a whole neighbour', () {
      final a = grades.firstWhere((g) => g.grade == 'A');
      expect(
        GradeEditor.edit(
          grades: grades,
          original: a,
          name: 'A',
          from: 60,
          to: 100,
          remark: null,
          isPass: true,
          sectionName: 'Junior Secondary',
        ).error,
        'This would cover all of B (60 to 69). Change or remove B first.',
      );
      final b = grades.firstWhere((g) => g.grade == 'B');
      expect(
        GradeEditor.edit(
          grades: grades,
          original: b,
          name: 'B',
          from: 60,
          to: 100,
          remark: null,
          isPass: true,
          sectionName: 'Junior Secondary',
        ).error,
        'This would cover all of A (70 to 100). Change or remove A first.',
      );
    });

    test('refuses From above To and duplicate names', () {
      final b = grades.firstWhere((g) => g.grade == 'B');
      expect(
        GradeEditor.edit(
          grades: grades,
          original: b,
          name: 'B',
          from: 72,
          to: 69,
          remark: null,
          isPass: true,
          sectionName: 'Junior Secondary',
        ).error,
        'From can’t be higher than To. Make From 69 or lower, or To 72 or higher.',
      );
      expect(
        GradeEditor.edit(
          grades: grades,
          original: b,
          name: 'a',
          from: 60,
          to: 69,
          remark: null,
          isPass: true,
          sectionName: 'Junior Secondary',
        ).error,
        'Junior Secondary already has a grade called a.',
      );
    });

    test('adding inside a band splits it', () {
      final result = GradeEditor.add(
        grades: grades,
        name: 'B+',
        from: 65,
        remark: null,
        isPass: true,
        sectionName: 'Junior Secondary',
      );
      expect(
        [for (final c in result.changes) '${c.label}|${c.value}'],
        ['B+ (new)|65 to 69', 'B becomes|60 to 64, from 60 to 69'],
      );
      final next = result.grades!;
      expect(next.firstWhere((g) => g.grade == 'B+').range, '65 to 69');
      expect(next.firstWhere((g) => g.grade == 'B').range, '60 to 64');
      expect(gradeRangesTile(next), isTrue);
    });

    test('adding from 0 fills a legacy gap and keeps the grade above', () {
      final legacy = [
        _grade('A', 70, 100, 'Excellent'),
        _grade('B', 60, 69, 'Very Good'),
        _grade('C', 50, 59, 'Good'),
        _grade('D', 45, 49, 'Fair'),
        _grade('E', 40, 44, 'Pass'),
      ];
      final result = GradeEditor.add(
        grades: legacy,
        name: 'F',
        from: 0,
        remark: 'Fail',
        isPass: false,
        sectionName: 'Junior Secondary',
      );
      expect(
        [for (final c in result.changes) '${c.label}|${c.value}'],
        ['F (new)|0 to 39', 'E stays|40 to 44'],
      );
      expect(result.grades!.firstWhere((g) => g.grade == 'F').range, '0 to 39');
      expect(gradeRangesTile(result.grades!), isTrue);
    });

    test('a new grade cannot start where one already starts', () {
      final result = GradeEditor.add(
        grades: grades,
        name: 'B2',
        from: 60,
        remark: null,
        isPass: true,
        sectionName: 'Junior Secondary',
      );
      expect(
        result.error,
        'B already starts at 60. Start this grade higher to split B, or edit '
        'B instead.',
      );
    });

    test('removing a grade lets the grade below absorb the range', () {
      final top = GradeEditor.remove(
        grades: grades,
        target: grades.firstWhere((g) => g.grade == 'A'),
        sectionName: 'Junior Secondary',
        sectionOwned: true,
      );
      expect(top.grades.firstWhere((g) => g.grade == 'B').range, '60 to 100');
      expect(top.message, contains('B now covers 60 to 100'));

      final middle = GradeEditor.remove(
        grades: grades,
        target: grades.firstWhere((g) => g.grade == 'B'),
        sectionName: 'Junior Secondary',
        sectionOwned: true,
      );
      expect(middle.grades.firstWhere((g) => g.grade == 'C').range, '50 to 69');
      expect(middle.absorbedBy, 'C');
      expect(gradeRangesTile(middle.grades), isTrue);
    });

    test('removing the bottom grade lets the one above expand down', () {
      final bottom = GradeEditor.remove(
        grades: grades,
        target: grades.firstWhere((g) => g.grade == 'F'),
        sectionName: 'Junior Secondary',
        sectionOwned: true,
      );
      expect(bottom.grades.firstWhere((g) => g.grade == 'E').range, '0 to 44');
      expect(bottom.message, contains('E now covers 0 to 44'));
    });

    test('removing the last grade leaves an empty, section-owned set', () {
      final only = GradeEditor.remove(
        grades: [_grade('A', 0, 100, 'Excellent')],
        target: _grade('A', 0, 100, 'Excellent'),
        sectionName: 'Primary',
        sectionOwned: true,
      );
      expect(only.isEmpty, isTrue);
      expect(only.message, contains('use the school’s grades again'));
    });
  });

  group('GradeReview', () {
    final grading = GradingSetup(
      columns: _standardColumns(),
      grades: _standard(),
    ).forSectionId('junior', sectionName: 'Junior Secondary');

    test('adds the scores up and rounds the percentage before grading', () {
      final review = GradeReview.calculate(
        grading: grading,
        scores: {'school-ca1': '17', 'school-ca2': '15', 'school-exam': '54'},
      );
      expect(review.totalScore, 86);
      expect(review.totalMarks, 100);
      expect(review.percent, 86);
      expect(review.percentLabel, '86%');
      expect(review.scoreLine, '86 out of 100 marks');
      expect(review.grade?.grade, 'A');
      expect(review.gradeLine, 'Pass · 70 to 100');
    });

    test('rounds half-up and clamps a score to its column', () {
      final three = GradingSetup(
        columns: [
          _column('a', 'A', 1, 1),
          _column('b', 'B', 1, 2),
          _column('c', 'C', 1, 3),
        ],
        grades: _standard(),
      ).forSectionId('junior');
      final rounded = GradeReview.calculate(
        grading: three,
        scores: {'a': '1', 'b': '1', 'c': '0'},
      );
      expect(rounded.percent, 67);
      expect(rounded.grade?.grade, 'B');

      final clamped = GradeReview.calculate(
        grading: grading,
        scores: {'school-ca1': '30', 'school-ca2': '', 'school-exam': ''},
      );
      expect(clamped.totalScore, 20);
      expect(clamped.percent, 20);
      expect(clamped.grade?.grade, 'F');
    });

    test('a total that is not 100 still reads as a percentage', () {
      final thirty = GradingSetup(
        columns: [_column('a', 'CA 1', 10, 1), _column('b', 'CA 2', 20, 2)],
        grades: _standard(),
      ).forSectionId('junior');
      final review = GradeReview.calculate(
        grading: thirty,
        scores: {'a': '10', 'b': '5'},
      );
      expect(review.scoreLine, '15 out of 30 marks');
      expect(review.percent, 50);
      expect(review.grade?.grade, 'C');
    });
  });

  group('GradingViewModel', () {
    Future<(GradingViewModel, _Grading)> loaded(
      OrganizationMemberRole role, {
      _Grading? service,
    }) async {
      final fake = service ?? _Grading();
      final model = GradingViewModel(
        school: _school(role),
        service: fake,
        structure: _Structure(),
      );
      await model.load();
      return (model, fake);
    }

    test('hides switched-off sections and counts only active ones', () async {
      final (model, _) = await loaded(
        OrganizationMemberRole.owner,
        service: _Grading(),
      );
      expect(model.activeSections.map((s) => s.name), [
        'Nursery',
        'Primary',
        'Junior Secondary',
        'Senior Secondary',
      ]);
      expect(
        model.sections.map((s) => s.sectionName),
        isNot(contains('Pre-Nursery')),
      );
      expect(model.sectionCount, 4);
    });

    test('summarises each active section and its set-up count', () async {
      final (model, _) = await loaded(
        OrganizationMemberRole.owner,
        service: _Grading(
          columns: [
            ..._standardColumns(),
            _column('junior-ca1', 'CA 1', 20, 1, sectionId: 'junior'),
            _column('junior-ca2', 'CA 2', 20, 2, sectionId: 'junior'),
            _column('junior-exam', 'Exam', 60, 3, sectionId: 'junior'),
          ],
          grades: [
            ..._standard(),
            ..._waec(sectionId: 'nursery'),
            _grade('A', 70, 100, 'Excellent', sectionId: 'junior'),
            _grade('B', 60, 69, 'Very Good', sectionId: 'junior'),
            _grade('C', 50, 59, 'Good', sectionId: 'junior'),
            _grade('D', 45, 49, 'Fair', sectionId: 'junior'),
            _grade('E', 40, 44, 'Pass', sectionId: 'junior'),
          ],
        ),
      );
      final byName = {
        for (final section in model.sections) section.sectionName: section,
      };
      expect(byName['Nursery']!.status, GradingStatus.setUp);
      expect(byName['Nursery']!.hasOwnGrades, isTrue);
      expect(byName['Primary']!.usesSchoolSetup, isTrue);
      expect(byName['Primary']!.status, GradingStatus.setUp);
      expect(byName['Junior Secondary']!.status, GradingStatus.partlySetUp);
      expect(byName['Senior Secondary']!.usesSchoolSetup, isTrue);
      expect(model.setUpCount, 3);
    });

    test('a non-leader is read only', () async {
      final (model, _) = await loaded(OrganizationMemberRole.bursar);
      expect(model.canChange, isFalse);
    });

    test('with no school rows every active section is not set up', () async {
      final (model, _) = await loaded(OrganizationMemberRole.owner);
      expect(
        model.sections.every((s) => s.status == GradingStatus.notSetUp),
        isTrue,
      );
      expect(model.setUpCount, 0);
    });
  });

  group('SectionGradingViewModel', () {
    Future<(SectionGradingViewModel, _Grading)> loaded(
      OrganizationMemberRole role, {
      _Grading? service,
      SchoolSection? section,
    }) async {
      final fake =
          service ?? _Grading(columns: _standardColumns(), grades: _standard());
      final model = SectionGradingViewModel(
        school: _school(role),
        section: section ?? _sections().first,
        service: fake,
        structure: _Structure(),
      );
      await model.load();
      return (model, fake);
    }

    test('give own setup copies both parts from the school', () async {
      final (model, fake) = await loaded(OrganizationMemberRole.owner);
      expect(await model.giveOwnSetup(), isNull);
      expect(fake.copies, [
        (from: null, to: 'nursery', columns: true, grades: true),
      ]);
      expect(model.changed, isTrue);
      expect(model.grading.hasOwnColumns, isTrue);
      expect(model.grading.hasOwnGrades, isTrue);
    });

    test(
      'copying from a source that follows the school uses the school set',
      () async {
        final (model, fake) = await loaded(OrganizationMemberRole.owner);
        final primary = model.copySources.firstWhere(
          (s) => s.name == 'Primary',
        );
        expect(
          await model.copyFrom(
            sourceSectionId: primary.id,
            columns: true,
            grades: false,
          ),
          isNull,
        );
        expect(fake.copies.single.from, isNull);
      },
    );

    test(
      'copying from a section with its own rows uses that section',
      () async {
        final (model, fake) = await loaded(
          OrganizationMemberRole.owner,
          service: _Grading(
            columns: [
              ..._standardColumns(),
              ..._standardColumns(sectionId: 'primary'),
            ],
            grades: _standard(),
          ),
        );
        expect(
          await model.copyFrom(
            sourceSectionId: 'primary',
            columns: true,
            grades: false,
          ),
          isNull,
        );
        expect(fake.copies.single.from, 'primary');
      },
    );

    test('a refused copy returns the database message', () async {
      final (model, fake) = await loaded(OrganizationMemberRole.owner);
      fake.failWith = const SupabaseRefusal('Nothing to copy.');
      expect(await model.giveOwnSetup(), 'Nothing to copy.');
      expect(model.changed, isFalse);
    });
  });

  group('ScoreColumnsViewModel', () {
    Future<(ScoreColumnsViewModel, _Grading)> loaded({
      _Grading? service,
      SchoolSection? section,
    }) async {
      final fake =
          service ??
          _Grading(
            columns: _standardColumns(sectionId: 'junior'),
            grades: _standard(sectionId: 'junior'),
          );
      final model = ScoreColumnsViewModel(
        school: _school(OrganizationMemberRole.owner),
        section: section ?? _sections()[2],
        service: fake,
        structure: _Structure(),
      );
      await model.load();
      return (model, fake);
    }

    test('adds a column and puts it in the chosen position', () async {
      final (model, fake) = await loaded();
      expect(await model.addColumn('Test', '10', position: 2), isNull);
      expect(fake.added?.sectionId, 'junior');
      expect(fake.added?.order, 4);
      expect(fake.reorders.single, [
        'junior-ca1',
        'new-1',
        'junior-ca2',
        'junior-exam',
      ]);
      expect(model.grading.columns[1].name, 'Test');
      expect(model.changed, isTrue);
    });

    test('validates the name and marks before adding', () async {
      final (model, fake) = await loaded();
      expect(
        await model.addColumn('Exam', '10', position: 4),
        'Junior Secondary already has a column called Exam. Pick another name.',
      );
      expect(
        await model.addColumn('Test', '0', position: 4),
        'Enter marks above 0, like 20 or 12.5.',
      );
      expect(fake.added, isNull);
    });

    test('moves a column and saves the whole order', () async {
      final (model, fake) = await loaded();
      final ca2 = model.columns[1];
      expect(await model.moveColumn(ca2, 1), isNull);
      expect(fake.reorders.single, ['junior-ca1', 'junior-exam', 'junior-ca2']);
      expect(model.changed, isTrue);
    });

    test('a refused removal throws for the confirm sheet', () async {
      final (model, fake) = await loaded();
      fake.failWith = const SupabaseRefusal('Scores are entered.');
      await expectLater(
        model.removeColumn(model.columns.first),
        throwsA(isA<AppAlertError>()),
      );
    });

    test(
      'a section that follows the school has no own columns to edit',
      () async {
        final (model, _) = await loaded(
          service: _Grading(columns: _standardColumns(), grades: _standard()),
          section: _sections()[1],
        );
        expect(model.inheritsColumns, isTrue);
        expect(model.hasColumns, isTrue);
        expect(await model.giveOwnSetup(), isNull);
      },
    );
  });

  group('GradesViewModel', () {
    Future<(GradesViewModel, _Grading)> loaded({
      _Grading? service,
      SchoolSection? section,
    }) async {
      final fake =
          service ??
          _Grading(
            columns: _standardColumns(sectionId: 'junior'),
            grades: _standard(sectionId: 'junior'),
          );
      final model = GradesViewModel(
        school: _school(OrganizationMemberRole.owner),
        section: section ?? _sections()[2],
        service: fake,
        structure: _Structure(),
      );
      await model.load();
      return (model, fake);
    }

    test('applies WAEC or Standard', () async {
      final (model, fake) = await loaded();
      expect(await model.applySystem(GradeSystem.waec), isNull);
      expect(fake.appliedSystems.single.system, 'waec');
      expect(model.grading.grades.length, 9);
      expect(model.system, GradeSystem.waec);
      expect(model.changed, isTrue);
    });

    test('sends the whole new scale for an edit', () async {
      final (model, fake) = await loaded();
      final b = model.grading.grades.firstWhere((g) => g.grade == 'B');
      final result = GradeEditor.edit(
        grades: model.grading.grades,
        original: b,
        name: 'B',
        from: 60,
        to: 70,
        remark: 'Very Good',
        isPass: true,
        sectionName: model.section.name,
      );
      expect(await model.saveScale(result.grades!), isNull);
      expect(fake.setScales.single.grades.length, 6);
      expect(
        fake.setScales.single.grades
            .firstWhere((g) => g.grade == 'A')
            .minPercent,
        71,
      );
    });

    test('removing the last grade goes back to the school scale', () async {
      final only = _grade('A', 0, 100, 'Excellent', sectionId: 'junior');
      final (model, fake) = await loaded(
        service: _Grading(
          columns: _standardColumns(sectionId: 'junior'),
          grades: [only],
        ),
      );
      await model.removeGrade(only);
      expect(fake.removedScales, ['junior']);
      expect(fake.setScales, isEmpty);
    });

    test(
      'removing a middle grade sends the neighbour that absorbs it',
      () async {
        final (model, fake) = await loaded();
        final b = model.grading.grades.firstWhere((g) => g.grade == 'B');
        expect(model.removalOf(b).absorbedBy, 'C');
        await model.removeGrade(b);
        expect(
          fake.setScales.single.grades
              .firstWhere((g) => g.grade == 'C')
              .maxPercent,
          69,
        );
      },
    );

    test('copying from an inherited source uses the school set', () async {
      final (model, fake) = await loaded();
      final primary = model.copySources.firstWhere((s) => s.name == 'Primary');
      expect(await model.copyGradesFrom(primary), isNull);
      expect(fake.copies.single.from, isNull);
    });

    test('copying both parts resolves a mixed source part by part', () async {
      final (model, fake) = await loaded(
        service: _Grading(
          columns: [
            ..._standardColumns(),
            ..._standardColumns(sectionId: 'primary'),
          ],
          grades: _standard(),
        ),
      );
      final primary = model.copySources.firstWhere((s) => s.name == 'Primary');
      expect(
        await model.copyFrom(primary, columns: true, grades: true),
        isNull,
      );
      expect(fake.copies.length, 2);
      expect(fake.copies.first.from, 'primary');
      expect(fake.copies.first.columns, isTrue);
      expect(fake.copies.last.from, isNull);
      expect(fake.copies.last.grades, isTrue);
    });

    test('a non-leader cannot change anything, but sees the system', () async {
      final model = GradesViewModel(
        school: _school(OrganizationMemberRole.bursar),
        section: _sections()[2],
        service: _Grading(
          columns: _standardColumns(sectionId: 'junior'),
          grades: _standard(sectionId: 'junior'),
        ),
        structure: _Structure(),
      );
      await model.load();
      expect(model.canChange, isFalse);
      expect(model.system, GradeSystem.standard);
    });
  });

  group('GradingScreen', () {
    Future<void> pump(
      WidgetTester tester,
      OrganizationMemberRole role,
      _Grading service, {
      List<SchoolSection>? sections,
    }) async {
      locator.registerSingleton<GradingService>(service);
      locator.registerSingleton<ClassStructureService>(_Structure(sections));
      addTearDown(locator.reset);
      tester.view.physicalSize = const Size(390, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(home: GradingScreen(school: _school(role))),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('lists active sections with their status and count', (
      tester,
    ) async {
      await pump(
        tester,
        OrganizationMemberRole.owner,
        _Grading(
          columns: [
            ..._standardColumns(),
            ..._standardColumns(sectionId: 'junior'),
            ..._standardColumns(sectionId: 'pre'),
          ],
          grades: [
            ..._standard(),
            ..._waec(sectionId: 'nursery'),
            ..._standard(sectionId: 'pre'),
            _grade('A', 70, 100, 'Excellent', sectionId: 'junior'),
            _grade('B', 60, 69, 'Very Good', sectionId: 'junior'),
            _grade('C', 50, 59, 'Good', sectionId: 'junior'),
            _grade('D', 45, 49, 'Fair', sectionId: 'junior'),
            _grade('E', 40, 44, 'Pass', sectionId: 'junior'),
          ],
        ),
      );

      expect(find.text('Grade each section its own way'), findsOneWidget);
      expect(find.text('Sections'), findsOneWidget);
      expect(find.text('3 of 4 set up'), findsOneWidget);
      expect(find.text('Nursery'), findsOneWidget);
      expect(find.text('Primary'), findsOneWidget);
      expect(find.text('Junior Secondary'), findsOneWidget);
      expect(find.text('Senior Secondary'), findsOneWidget);
      expect(find.text('Pre-Nursery'), findsNothing);
      expect(find.text('Uses the school’s setup'), findsNWidgets(2));
      expect(find.text('Partly set up'), findsOneWidget);
      expect(find.text('Set up'), findsNWidgets(3));
      expect(
        find.text('3 columns · 100 marks · Grades don’t cover 0 to 100'),
        findsOneWidget,
      );
    });

    testWidgets('read only: a banner, but the sections still open', (
      tester,
    ) async {
      await pump(
        tester,
        OrganizationMemberRole.bursar,
        _Grading(columns: _standardColumns(), grades: _standard()),
      );
      expect(find.text('Read only for you'), findsOneWidget);
      expect(find.text('Sections'), findsOneWidget);
      expect(find.text('Set up'), findsNWidgets(4));
    });

    testWidgets('no active section: create your sections first', (
      tester,
    ) async {
      await pump(
        tester,
        OrganizationMemberRole.owner,
        _Grading(),
        sections: const [],
      );
      expect(find.text('Create your sections first'), findsOneWidget);
      expect(find.text('Go to Classes and arms'), findsOneWidget);
    });

    testWidgets('a school with no setup shows every section as not set up', (
      tester,
    ) async {
      await pump(tester, OrganizationMemberRole.owner, _Grading());
      expect(find.text('0 of 4 set up'), findsOneWidget);
      expect(find.text('Not set up'), findsNWidgets(4));
      expect(find.text('No columns or grades yet'), findsNWidgets(4));
    });
  });

  group('SectionGradingScreen', () {
    Future<void> pump(
      WidgetTester tester,
      _Grading service,
      SchoolSection section, {
      OrganizationMemberRole role = OrganizationMemberRole.owner,
    }) async {
      locator.registerSingleton<GradingService>(service);
      locator.registerSingleton<ClassStructureService>(_Structure());
      addTearDown(locator.reset);
      tester.view.physicalSize = const Size(390, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: SectionGradingScreen(school: _school(role), section: section),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('not set up: two tasks, copy row and no review button', (
      tester,
    ) async {
      await pump(tester, _Grading(), _sections()[2]);
      expect(find.text('Set up Junior Secondary'), findsOneWidget);
      expect(find.text('Score columns'), findsOneWidget);
      expect(find.text('Grades'), findsOneWidget);
      expect(find.text('Not set up'), findsNWidgets(2));
      expect(find.text('Copy from another section'), findsOneWidget);
      expect(find.text('Review Junior Secondary'), findsNothing);
    });

    testWidgets('set up: the two summaries and a pinned review button', (
      tester,
    ) async {
      await pump(
        tester,
        _Grading(
          columns: _standardColumns(sectionId: 'junior'),
          grades: _standard(sectionId: 'junior'),
        ),
        _sections()[2],
      );
      expect(find.text('Junior Secondary is ready'), findsOneWidget);
      expect(find.text('3 columns · 100 marks'), findsOneWidget);
      expect(
        find.text('Standard · 6 grades · covers 0 to 100'),
        findsOneWidget,
      );
      expect(find.text('Review Junior Secondary'), findsOneWidget);
    });

    testWidgets('inherited: shows the rows, give own setup and copy instead', (
      tester,
    ) async {
      await pump(
        tester,
        _Grading(columns: _standardColumns(), grades: _standard()),
        _sections()[1],
      );
      expect(find.text('Primary follows the school’s grading'), findsOneWidget);
      expect(find.text('Uses the school’s setup'), findsOneWidget);
      expect(find.text('CA 1'), findsOneWidget);
      expect(find.text('Give Primary its own setup'), findsOneWidget);
      expect(find.text('Copy from another section instead'), findsOneWidget);
    });

    testWidgets('read only: no give-own-setup action', (tester) async {
      await pump(
        tester,
        _Grading(columns: _standardColumns(), grades: _standard()),
        _sections()[1],
        role: OrganizationMemberRole.bursar,
      );
      expect(find.text('Read only for you'), findsOneWidget);
      expect(find.text('Give Primary its own setup'), findsNothing);
      expect(find.text('Copy from another section instead'), findsNothing);
    });
  });

  group('ScoreColumnsScreen', () {
    Future<void> pump(
      WidgetTester tester,
      _Grading service,
      SchoolSection section, {
      OrganizationMemberRole role = OrganizationMemberRole.owner,
    }) async {
      locator.registerSingleton<GradingService>(service);
      locator.registerSingleton<ClassStructureService>(_Structure());
      addTearDown(locator.reset);
      tester.view.physicalSize = const Size(390, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: ScoreColumnsScreen(school: _school(role), section: section),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('shows the total, shares and the columns', (tester) async {
      await pump(
        tester,
        _Grading(
          columns: _standardColumns(sectionId: 'junior'),
          grades: _standard(sectionId: 'junior'),
        ),
        _sections()[2],
      );
      expect(find.text('100'), findsOneWidget);
      expect(find.text('marks in total'), findsOneWidget);
      expect(find.text('20%'), findsNWidgets(4));
      expect(find.text('60%'), findsNWidgets(2));
      expect(find.text('Columns'), findsOneWidget);
      expect(find.text('Add column'), findsOneWidget);
      expect(find.text('Copy columns from another section'), findsOneWidget);
    });

    testWidgets('empty state opens the add-column sheet', (tester) async {
      await pump(tester, _Grading(), _sections()[3]);
      expect(
        find.text('No score columns in Senior Secondary yet'),
        findsOneWidget,
      );
      await tester.tap(find.widgetWithText(AppPrimaryButton, 'Add a column'));
      await tester.pumpAndSettle();
      expect(find.text('Add a column to Senior Secondary'), findsOneWidget);
      expect(find.text('Add column'), findsOneWidget);
    });

    testWidgets('a column sheet previews the total and hides used names', (
      tester,
    ) async {
      await pump(
        tester,
        _Grading(
          columns: _standardColumns(sectionId: 'junior'),
          grades: _standard(sectionId: 'junior'),
        ),
        _sections()[2],
      );
      await tester.tap(find.text('Add column'));
      await tester.pumpAndSettle();
      expect(find.text('Add a column to Junior Secondary'), findsOneWidget);
      expect(find.widgetWithText(AppFilterChip, 'CA 3'), findsOneWidget);
      expect(find.widgetWithText(AppFilterChip, 'Test'), findsOneWidget);
      expect(find.text('Enter the marks first'), findsOneWidget);
      await tester.enterText(find.widgetWithText(TextField, 'e.g. 20'), '10');
      await tester.pumpAndSettle();
      expect(find.text('110 marks, from 100 now'), findsOneWidget);
      expect(find.text('4 of 4, last'), findsOneWidget);
    });
  });

  group('GradesScreen', () {
    Future<void> pump(
      WidgetTester tester,
      _Grading service,
      SchoolSection section, {
      OrganizationMemberRole role = OrganizationMemberRole.owner,
    }) async {
      locator.registerSingleton<GradingService>(service);
      locator.registerSingleton<ClassStructureService>(_Structure());
      addTearDown(locator.reset);
      tester.view.physicalSize = const Size(390, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: GradesScreen(school: _school(role), section: section),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('no grades: choose a system, WAEC selected', (tester) async {
      final service = _Grading(columns: _standardColumns(sectionId: 'junior'));
      await pump(tester, service, _sections()[2]);
      expect(
        find.text('Which grades should Junior Secondary use?'),
        findsOneWidget,
      );
      expect(find.text('WAEC grades'), findsOneWidget);
      expect(find.text('Usual for SS'), findsOneWidget);
      expect(find.text('Standard grades'), findsOneWidget);
      expect(find.text('Use Standard grades'), findsOneWidget);

      await tester.tap(find.text('WAEC grades'));
      await tester.pumpAndSettle();
      expect(find.text('Use WAEC grades'), findsOneWidget);
      await tester.tap(
        find.widgetWithText(AppPrimaryButton, 'Use WAEC grades'),
      );
      await tester.pumpAndSettle();

      expect(service.appliedSystems.single.system, 'waec');
      expect(find.text('Covers 0 to 100'), findsOneWidget);
      expect(find.text('70 to 100'), findsNothing);
      expect(find.text('75 to 100'), findsOneWidget);
    });

    testWidgets('ranges show the coverage and each band', (tester) async {
      await pump(
        tester,
        _Grading(
          columns: _standardColumns(sectionId: 'junior'),
          grades: _standard(sectionId: 'junior'),
        ),
        _sections()[2],
      );
      expect(find.text('Covers 0 to 100'), findsOneWidget);
      expect(find.text('70 to 100'), findsOneWidget);
      expect(find.text('Excellent · Pass'), findsOneWidget);
      expect(find.text('Fail'), findsOneWidget);
      expect(find.text('Change to WAEC grades'), findsOneWidget);
      expect(find.text('Copy grades from another section'), findsOneWidget);
      expect(find.text('Add grade'), findsOneWidget);
    });

    testWidgets('a legacy gap is a warning with add from 0', (tester) async {
      await pump(
        tester,
        _Grading(
          columns: _standardColumns(sectionId: 'junior'),
          grades: [
            _grade('A', 70, 100, 'Excellent', sectionId: 'junior'),
            _grade('B', 60, 69, 'Very Good', sectionId: 'junior'),
            _grade('C', 50, 59, 'Good', sectionId: 'junior'),
            _grade('D', 45, 49, 'Fair', sectionId: 'junior'),
            _grade('E', 40, 44, 'Pass', sectionId: 'junior'),
          ],
        ),
        _sections()[2],
      );
      expect(find.text('Not covered: 0 to 39'), findsOneWidget);
      expect(find.text('Add a grade from 0'), findsOneWidget);
      expect(find.text('Change to WAEC grades'), findsNothing);
    });

    testWidgets('changing the system asks first, then replaces', (
      tester,
    ) async {
      final service = _Grading(
        columns: _standardColumns(sectionId: 'junior'),
        grades: _standard(sectionId: 'junior'),
      );
      await pump(tester, service, _sections()[2]);
      await tester.tap(find.text('Change to WAEC grades'));
      await tester.pumpAndSettle();
      expect(find.text('Replace Junior Secondary’s grades?'), findsOneWidget);
      expect(
        find.textContaining('will be replaced by the 9 WAEC'),
        findsOneWidget,
      );
      expect(find.text('Keep Standard grades'), findsOneWidget);

      await tester.ensureVisible(find.text('Replace with WAEC grades'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.text('Replace with WAEC grades'),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();
      expect(service.appliedSystems.single.system, 'waec');
      expect(find.text('75 to 100'), findsOneWidget);
    });
  });

  group('GradeSheet', () {
    Future<void> pump(
      WidgetTester tester, {
      required SectionGrading grading,
      GradeBoundary? grade,
      String? initialFrom,
      Future<String?> Function(List<GradeBoundary>)? onSave,
    }) async {
      tester.view.physicalSize = const Size(390, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GradeSheet(
              grading: grading,
              grade: grade,
              initialFrom: initialFrom,
              onSave: onSave ?? (_) async => null,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('editing To shows the range and the neighbour that moves', (
      tester,
    ) async {
      final grading = GradingSetup(
        columns: _standardColumns(sectionId: 'junior'),
        grades: _standard(sectionId: 'junior'),
      ).forSectionId('junior', sectionName: 'Junior Secondary');
      final b = grading.grades.firstWhere((g) => g.grade == 'B');
      await pump(tester, grading: grading, grade: b);

      expect(find.text('Edit grade B'), findsOneWidget);
      await tester.enterText(find.widgetWithText(TextField, 'e.g. 69'), '70');
      await tester.pumpAndSettle();
      expect(find.text('B becomes'), findsOneWidget);
      expect(find.text('60 to 70, from 60 to 69'), findsOneWidget);
      expect(find.text('A will start at'), findsOneWidget);
      expect(find.text('71, from 70'), findsOneWidget);
    });

    testWidgets('a change that covers a neighbour is refused', (tester) async {
      final grading = GradingSetup(
        columns: _standardColumns(sectionId: 'junior'),
        grades: _standard(sectionId: 'junior'),
      ).forSectionId('junior', sectionName: 'Junior Secondary');
      final a = grading.grades.firstWhere((g) => g.grade == 'A');
      await pump(tester, grading: grading, grade: a);

      await tester.enterText(find.widgetWithText(TextField, 'e.g. 60'), '60');
      await tester.pumpAndSettle();
      expect(
        find.text(
          'This would cover all of B (60 to 69). Change or remove B first.',
        ),
        findsOneWidget,
      );
      final save = tester.widget<AppPrimaryButton>(
        find.widgetWithText(AppPrimaryButton, 'Save grade'),
      );
      expect(save.isDisabled, isTrue);
    });

    testWidgets('adding splits a band and previews both parts', (tester) async {
      final grading = GradingSetup(
        columns: _standardColumns(sectionId: 'junior'),
        grades: _standard(sectionId: 'junior'),
      ).forSectionId('junior', sectionName: 'Junior Secondary');
      await pump(tester, grading: grading);
      await tester.enterText(find.widgetWithText(TextField, 'e.g. A'), 'B+');
      await tester.enterText(find.widgetWithText(TextField, 'e.g. 60'), '65');
      await tester.pumpAndSettle();

      expect(find.text('B+ (new)'), findsOneWidget);
      expect(find.text('65 to 69'), findsOneWidget);
      expect(find.text('B becomes'), findsOneWidget);
      expect(find.text('60 to 64, from 60 to 69'), findsOneWidget);
    });

    testWidgets('adding from 0 fills the gap and turns the pass off', (
      tester,
    ) async {
      final grading = GradingSetup(
        columns: _standardColumns(),
        grades: [
          _grade('A', 70, 100, 'Excellent'),
          _grade('B', 60, 69, 'Very Good'),
          _grade('C', 50, 59, 'Good'),
          _grade('D', 45, 49, 'Fair'),
          _grade('E', 40, 44, 'Pass'),
        ],
      ).forSectionId('junior', sectionName: 'Junior Secondary');
      await pump(tester, grading: grading, initialFrom: '0');
      await tester.enterText(find.widgetWithText(TextField, 'e.g. A'), 'F');
      await tester.pumpAndSettle();
      expect(find.text('Add a grade from 0'), findsOneWidget);
      expect(find.text('0 to 39'), findsOneWidget);
      final switchWidget = tester.widget<AppSwitch>(find.byType(AppSwitch));
      expect(switchWidget.value, isFalse);
    });
  });

  group('GradingReviewScreen', () {
    testWidgets('works the score out locally and marks the grade bar', (
      tester,
    ) async {
      locator.registerSingleton<GradingService>(
        _Grading(
          columns: _standardColumns(sectionId: 'junior'),
          grades: _standard(sectionId: 'junior'),
        ),
      );
      addTearDown(locator.reset);
      tester.view.physicalSize = const Size(390, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: GradingReviewScreen(
            school: _school(OrganizationMemberRole.owner),
            section: _sections()[2],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Set up · already saved'), findsOneWidget);
      expect(find.text('How Junior Secondary is graded'), findsOneWidget);
      expect(find.text('86%'), findsNWidgets(2));
      expect(find.text('86 out of 100 marks'), findsOneWidget);
      expect(find.text('A'), findsWidgets);
      expect(find.text('Pass · 70 to 100'), findsOneWidget);

      final fields = find.byType(TextField);
      expect(fields, findsNWidgets(3));
      await tester.enterText(fields.first, '0');
      await tester.pumpAndSettle();
      expect(find.text('69%'), findsNWidgets(2));
      expect(find.text('69 out of 100 marks'), findsOneWidget);
      expect(find.text('Pass · 60 to 69'), findsOneWidget);
    });
  });
}
