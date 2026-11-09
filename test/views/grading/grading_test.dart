import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hamrash_admin/api/models/class_structure/class_structure.dart';
import 'package:hamrash_admin/api/models/grading/grade_boundary.dart';
import 'package:hamrash_admin/api/models/grading/grading_setup.dart';
import 'package:hamrash_admin/api/models/grading/score_column.dart';
import 'package:hamrash_admin/api/models/organization_models/member_school.dart';
import 'package:hamrash_admin/api/models/organization_models/organization.dart';
import 'package:hamrash_admin/api/models/organization_models/organization_member.dart';
import 'package:hamrash_admin/api/services/supabase_services/class_structure_service.dart';
import 'package:hamrash_admin/api/services/supabase_services/grading_service.dart';
import 'package:hamrash_admin/api/services/supabase_services/supabase_refusal.dart';
import 'package:hamrash_admin/core/widgets/app_alert_dialog.dart';
import 'package:hamrash_admin/core/widgets/app_badge.dart';
import 'package:hamrash_admin/core/widgets/app_icons.dart';
import 'package:hamrash_admin/core/widgets/app_section_action.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_variants.dart';
import 'package:hamrash_admin/core/widgets/selection/app_selection_controls.dart';
import 'package:hamrash_admin/singleton_locator/locator.dart';
import 'package:hamrash_admin/views/grading/grading_screen.dart';
import 'package:hamrash_admin/views/grading/grading_view_model.dart';
import 'package:hamrash_admin/views/grading/widgets/standard_setup_sheet.dart';

ScoreColumn _column(String id, String name, double max, int order) =>
    ScoreColumn(id: id, name: name, maxScore: max, sortOrder: order);

GradeBoundary _grade(
  String grade,
  double min,
  String? remark, {
  bool isPass = true,
  String? sectionId,
}) => GradeBoundary(
  id: sectionId == null ? grade : '$sectionId-$grade',
  sectionId: sectionId,
  grade: grade,
  minPercent: min,
  remark: remark,
  isPass: isPass,
);

/// Secondary's own WAEC-style scale.
List<GradeBoundary> _waec() => [
  _grade('A1', 75, 'Excellent', sectionId: 'secondary'),
  _grade('B2', 70, 'Very Good', sectionId: 'secondary'),
  _grade('F9', 0, 'Fail', isPass: false, sectionId: 'secondary'),
];

SchoolSection _section(String id, String name, int order) => SchoolSection(
  id: id,
  name: name,
  sortOrder: order,
  isActive: true,
  classes: const [],
);

List<SchoolSection> _sections() => [
  _section('nursery', 'Nursery', 1),
  _section('primary', 'Primary', 2),
  _section('secondary', 'Secondary', 3),
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

List<ScoreColumn> _standardColumns() => [
  _column('ca1', 'CA 1', 20, 1),
  _column('ca2', 'CA 2', 20, 2),
  _column('exam', 'Exam', 60, 3),
];

List<GradeBoundary> _standardGrades({bool withFail = true}) => [
  _grade('A', 70, 'Excellent'),
  _grade('B', 60, 'Very Good'),
  _grade('C', 50, 'Good'),
  _grade('D', 45, 'Fair'),
  _grade('E', 40, 'Pass'),
  if (withFail) _grade('F', 0, 'Fail', isPass: false),
];

class _Grading implements GradingService {
  _Grading({List<ScoreColumn>? columns, List<GradeBoundary>? grades})
    : columns = columns ?? [],
      grades = grades ?? [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  List<ScoreColumn> columns;
  List<GradeBoundary> grades;
  Object? failWith;
  bool standardRequested = false;
  ({String name, double max, int order})? added;
  ScoreColumn? removedColumn;
  ({String? sectionId, String grade, double min, bool isPass})? addedGrade;

  /// One entry per bulk insert, and how many grades went in each.
  final copies = <({String sectionId, int grades})>[];

  /// Grades inserted one at a time.
  int singleInserts = 0;
  final deletedScales = <String>[];
  final swaps = <(String, String)>[];

  @override
  Future<GradingSetup> getSetup(String organizationId) async =>
      GradingSetup(columns: columns, boundaries: grades);

  @override
  Future<void> createStandardGrading(String organizationId) async {
    if (failWith case final error?) throw error;
    standardRequested = true;
    columns = _standardColumns();
    grades = _standardGrades();
  }

  @override
  Future<void> addScoreColumn({
    required String organizationId,
    required String name,
    required double maxScore,
    required int sortOrder,
  }) async {
    if (failWith case final error?) throw error;
    added = (name: name, max: maxScore, order: sortOrder);
    columns = [...columns, _column(name, name, maxScore, sortOrder)];
  }

  @override
  Future<void> addGradeBoundary({
    required String organizationId,
    required String grade,
    required double minPercent,
    required String? remark,
    required bool isPass,
    String? sectionId,
  }) async {
    if (failWith case final error?) throw error;
    singleInserts++;
    addedGrade = (
      sectionId: sectionId,
      grade: grade,
      min: minPercent,
      isPass: isPass,
    );
    grades = [
      ...grades,
      _grade(grade, minPercent, remark, isPass: isPass, sectionId: sectionId),
    ];
  }

  @override
  Future<void> copyScaleToSection({
    required String organizationId,
    required String sectionId,
    required List<GradeBoundary> grades,
  }) async {
    if (failWith case final error?) throw error;
    copies.add((sectionId: sectionId, grades: grades.length));
    this.grades = [
      ...this.grades,
      for (final g in grades)
        _grade(
          g.grade,
          g.minPercent,
          g.remark,
          isPass: g.isPass,
          sectionId: sectionId,
        ),
    ];
  }

  @override
  Future<void> deleteSectionScale({
    required String organizationId,
    required String sectionId,
  }) async {
    if (failWith case final error?) throw error;
    deletedScales.add(sectionId);
    grades = [
      for (final g in grades)
        if (g.sectionId != sectionId) g,
    ];
  }

  @override
  Future<void> swapScoreColumnOrder(ScoreColumn a, ScoreColumn b) async {
    if (failWith case final error?) throw error;
    swaps.add((a.id, b.id));
    columns = [
      for (final c in columns)
        if (c.id == a.id)
          _column(c.id, c.name, c.maxScore, b.sortOrder)
        else if (c.id == b.id)
          _column(c.id, c.name, c.maxScore, a.sortOrder)
        else
          c,
    ];
  }

  @override
  Future<void> deleteScoreColumn(ScoreColumn column) async {
    if (failWith case final error?) throw error;
    removedColumn = column;
    columns = [
      for (final existing in columns)
        if (existing.id != column.id) existing,
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
  // Real Nunito metrics, so text widths match the app rather than the wider
  // test fallback font.
  setUpAll(() async {
    final loader = FontLoader('Nunito');
    for (final file in ['Regular', 'Bold', 'ExtraBold']) {
      loader.addFont(rootBundle.load('assets/fonts/Nunito-$file.ttf'));
    }
    await loader.load();
  });

  group('GradingSetup', () {
    final setup = GradingSetup(
      columns: _standardColumns(),
      boundaries: _standardGrades(),
    );

    test('adds up the columns', () {
      expect(setup.totalMarks, 100);
      expect(setup.nextSortOrder, 4);
      expect(setup.isComplete, isTrue);
      expect(setup.uncoveredRange, isNull);
    });

    test('shows each grade from where it starts to just before the next', () {
      expect(
        [for (final b in setup.boundaries) setup.rangeOf(b)],
        [
          '70 to 100',
          '60 to 69',
          '50 to 59',
          '45 to 49',
          '40 to 44',
          '0 to 39',
        ],
      );
      expect(setup.detailsOf(setup.boundaries.first), 'Excellent · Pass');
    });

    test('lists a remark with Pass or Fail, without repeating the word', () {
      expect(setup.detailsOf(_grade('B', 60, 'Very Good')), 'Very Good · Pass');
      expect(
        setup.detailsOf(_grade('D', 40, 'Poor', isPass: false)),
        'Poor · Fail',
      );
      expect(setup.detailsOf(_grade('E', 40, 'Pass')), 'Pass');
      expect(setup.detailsOf(setup.boundaries.last), 'Fail');
      expect(setup.detailsOf(_grade('X', 10, null, isPass: false)), 'Fail');
      expect(setup.detailsOf(_grade('Y', 10, '  ')), 'Pass');
    });

    test('says what the scale leaves out when nothing starts at 0', () {
      final incomplete = GradingSetup(
        columns: const [],
        boundaries: _standardGrades(withFail: false),
      );
      expect(incomplete.uncoveredRange, '0 to 39');
      expect(incomplete.isComplete, isFalse);
      expect(
        GradingSetup(columns: const [], boundaries: const []).uncoveredRange,
        '0 to 100',
      );
    });

    test('checks marks: above 0, up to 2 decimals', () {
      expect(GradingSetup.marksProblem(''), isNull);
      expect(GradingSetup.marksProblem('20'), isNull);
      expect(GradingSetup.marksProblem('12.5'), isNull);
      expect(
        GradingSetup.marksProblem('0'),
        'A column has to be out of more than 0. Enter at least 0.01.',
      );
      expect(GradingSetup.marksProblem('1.234'), contains('2 decimal places'));
      expect(GradingSetup.marksProblem('abc'), isNotNull);
      expect(GradingSetup.marksProblem('10000'), isNotNull);
      expect(GradingSetup.marks('0'), isNull);
      expect(GradingSetup.marks('12,5'), 12.5);
    });

    test('previews the total with a column added or changed', () {
      expect(setup.totalWith('20'), 120);
      expect(setup.totalWith('0'), isNull);
      expect(setup.totalWith(''), isNull);
      expect(setup.totalWith('30', replacing: setup.columns[0]), 110);
    });

    test('checks column and grade names, case-insensitively', () {
      expect(setup.columnNameProblem('exam'), contains('already a column'));
      expect(setup.columnNameProblem('exam', except: setup.columns[2]), isNull);
      expect(setup.columnNameProblem('  '), isNull);
      expect(setup.gradeNameProblem('a'), contains('already a grade'));
      expect(setup.gradeNameProblem('A', except: setup.boundaries[0]), isNull);
    });

    test('checks where a grade starts', () {
      expect(setup.percentProblem(''), isNull);
      expect(setup.percentProblem('65'), isNull);
      expect(
        setup.percentProblem('50', except: setup.boundaries[1]),
        'C already starts at 50. Try 51, or edit C.',
      );
      expect(setup.percentProblem('50', except: setup.boundaries[2]), isNull);
      expect(setup.percentProblem('100'), contains('below 100'));
      expect(setup.percentProblem('65.555'), contains('2 decimal places'));
      expect(setup.percentProblem('x'), isNotNull);
    });

    test('suggests the nearest free whole number above a taken start', () {
      final crowded = GradingSetup(
        columns: const [],
        boundaries: [
          _grade('A', 98, null),
          _grade('B', 99, null),
          _grade('C', 0, null),
        ],
      );
      expect(crowded.percentProblem('98'), 'A already starts at 98. Edit A.');
      expect(crowded.percentProblem('99'), 'B already starts at 99. Edit B.');
      // 50.5 is free, so nothing to say; a taken whole number skips ahead.
      final skip = GradingSetup(
        columns: const [],
        boundaries: [
          _grade('A', 70, null),
          _grade('B', 60, null),
          _grade('C', 61, null),
        ],
      );
      expect(
        skip.percentProblem('60'),
        'B already starts at 60. Try 62, or edit B.',
      );
      expect(skip.percentProblem('60', except: skip.boundaries[2]), isNull);
    });

    test('says what a new grade and the one below it become', () {
      final changes = setup.gradeChanges(name: 'B+', percentText: '65');
      expect(
        [for (final c in changes) '${c.label}|${c.value}'],
        ['New grade|65 to 69', 'B becomes|60 to 64, from 60 to 69'],
      );
      // On top: no grade above, so up to 100.
      expect(
        setup.gradeChanges(name: 'S', percentText: '90').first.value,
        '90 to 100',
      );
      // At the bottom, nothing below to change.
      final bottom = GradingSetup(
        columns: const [],
        boundaries: _standardGrades(withFail: false),
      );
      expect(bottom.gradeChanges(name: 'F', percentText: '0').length, 1);
      // Nothing to say while the start isn't valid.
      expect(setup.gradeChanges(name: 'X', percentText: ''), isEmpty);
      expect(setup.gradeChanges(name: 'X', percentText: '50'), isEmpty);
    });

    test('says what an edited grade and the one below it become', () {
      final b = setup.boundaries[1];
      final changes = setup.gradeChanges(
        name: 'B',
        percentText: '62',
        except: b,
      );
      expect(
        [for (final c in changes) '${c.label}|${c.value}'],
        [
          'B becomes|62 to 69, from 60 to 69',
          'C becomes|50 to 61, from 50 to 59',
        ],
      );
      // Same start: nothing changes.
      expect(
        setup.gradeChanges(name: 'B', percentText: '60', except: b),
        isEmpty,
      );
    });

    test('warns when a grade would sit below one that sorts after it', () {
      final a = setup.boundaries[0];
      expect(
        setup.gradeOrderWarning(name: 'A', percentText: '55', except: a),
        'A will now be below B. Grades usually go down from A.',
      );
      // A new C above A: A ends up below C.
      expect(setup.gradeOrderWarning(name: 'C+', percentText: '65'), isNull);
      expect(
        setup.gradeOrderWarning(name: 'D', percentText: '75'),
        'A will now be below D. Grades usually go down from A.',
      );
      // Fine where it is, or when it only moves among its neighbours.
      expect(
        setup.gradeOrderWarning(name: 'A', percentText: '75', except: a),
        isNull,
      );
      // Names that aren't a letter and a number aren't judged.
      expect(
        setup.gradeOrderWarning(name: 'Distinction', percentText: '55'),
        isNull,
      );
      expect(setup.gradeOrderWarning(name: '', percentText: '55'), isNull);
      // A1, B2 style names compare letters, then numbers.
      final waec = GradingSetup(
        columns: const [],
        boundaries: _waec(),
      ).scoped('secondary');
      expect(
        waec.gradeOrderWarning(name: 'B3', percentText: '80'),
        'A1 will now be below B3. Grades usually go down from A.',
      );
      expect(waec.gradeOrderWarning(name: 'B3', percentText: '65'), isNull);
    });

    test('a new grade is a pass unless it starts below every pass grade', () {
      expect(setup.defaultIsPass(''), isTrue);
      expect(setup.defaultIsPass('65'), isTrue);
      expect(setup.defaultIsPass('40'), isTrue);
      expect(setup.defaultIsPass('39'), isFalse);
      expect(setup.defaultIsPass('0'), isFalse);
      final noPass = GradingSetup(
        columns: const [],
        boundaries: [_grade('F', 0, 'Fail', isPass: false)],
      );
      expect(noPass.defaultIsPass('10'), isTrue);
    });

    test('suggests column names that are not used yet', () {
      expect(setup.columnSuggestions, ['CA 3', 'Test', 'Assignment']);
      final more = GradingSetup(
        columns: [
          _column('a', 'CA 1', 10, 1),
          _column('b', 'CA 3', 10, 2),
          _column('c', 'test', 10, 3),
        ],
        boundaries: const [],
      );
      expect(more.columnSuggestions, ['CA 4', 'Assignment']);
      expect(
        GradingSetup(columns: const [], boundaries: const []).columnSuggestions,
        ['CA 1', 'Test', 'Assignment'],
      );
    });

    test('the total line stays, becomes, or asks for the marks', () {
      final ca2 = setup.columns[1];
      expect(setup.totalLine('20', replacing: ca2), (
        label: 'Total stays',
        value: '100 marks',
        muted: false,
      ));
      expect(setup.totalLine('30', replacing: ca2), (
        label: 'Total becomes',
        value: '110 marks, from 100 now',
        muted: false,
      ));
      expect(setup.totalLine('20').value, '120 marks, from 100 now');
      expect(setup.totalLine('0'), (
        label: 'Total becomes',
        value: 'Enter the marks first',
        muted: true,
      ));
    });

    test('splits the grades into the school default and each section', () {
      final all = GradingSetup(
        columns: _standardColumns(),
        boundaries: [..._standardGrades(), ..._waec()],
      );
      expect(all.boundaries.length, 6);
      expect(all.hasOwnScale('secondary'), isTrue);
      expect(all.hasOwnScale('primary'), isFalse);
      final secondary = all.scoped('secondary');
      expect(secondary.boundaries.map((b) => b.grade), ['A1', 'B2', 'F9']);
      expect(secondary.totalMarks, 100);
      expect(secondary.rangeOf(secondary.boundaries[1]), '70 to 74');
      expect(secondary.isComplete, isTrue);
      expect(identical(all.scoped(null), all), isTrue);
      // A section's grades alone are something, not "nothing set up".
      expect(
        GradingSetup(columns: const [], boundaries: _waec()).isEmpty,
        isFalse,
      );
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

    test(
      'a leader starts from the start page when nothing is set up',
      () async {
        final (model, _) = await loaded(OrganizationMemberRole.principal);
        expect(model.showStart, isTrue);
        expect(model.showNotSetUp, isFalse);
        expect(model.building, isFalse);
      },
    );

    test('someone who can only look is told it is not set up', () async {
      final (model, _) = await loaded(OrganizationMemberRole.bursar);
      expect(model.canChange, isFalse);
      expect(model.showStart, isFalse);
      expect(model.showNotSetUp, isTrue);
    });

    test('goes straight to the setup when there is one', () async {
      final (model, _) = await loaded(
        OrganizationMemberRole.owner,
        service: _Grading(
          columns: _standardColumns(),
          grades: _standardGrades(),
        ),
      );
      expect(model.showStart, isFalse);
      expect(model.setup.totalMarks, 100);
      expect(model.changed, isFalse);
    });

    test('uses the standard setup and reloads', () async {
      final (model, service) = await loaded(OrganizationMemberRole.owner);
      expect(await model.useStandardSetup(), isNull);
      expect(service.standardRequested, isTrue);
      expect(model.setup.isComplete, isTrue);
      expect(model.changed, isTrue);
      expect(model.showStart, isFalse);
    });

    test('hands back the database reason when it refuses', () async {
      final (model, service) = await loaded(OrganizationMemberRole.owner);
      service.failWith = const SupabaseRefusal(
        'This school already has a grading setup; the standard one is only '
        'for a new school',
      );
      expect(await model.useStandardSetup(), contains('already has a grading'));
      expect(model.changed, isFalse);

      service.failWith = Exception('offline');
      expect(
        await model.useStandardSetup(),
        "Couldn't set up grading. Try again.",
      );
    });

    test('adds a column at the end with the marks typed', () async {
      final (model, service) = await loaded(
        OrganizationMemberRole.owner,
        service: _Grading(columns: _standardColumns()),
      );
      expect(await model.addColumn(' Project ', '12.5'), isNull);
      expect(service.added, (name: 'Project', max: 12.5, order: 4));
      expect(model.setup.totalMarks, 112.5);
      expect(model.changed, isTrue);
    });

    test('does not add a column with no valid marks', () async {
      final (model, service) = await loaded(OrganizationMemberRole.owner);
      expect(await model.addColumn('Test', '0'), 'Enter the marks.');
      expect(service.added, isNull);
    });

    test('removing a column says what the total becomes', () async {
      final (model, service) = await loaded(
        OrganizationMemberRole.owner,
        service: _Grading(columns: _standardColumns()),
      );
      final ca2 = model.setup.columns[1];
      expect(model.removeColumnMessage(ca2), contains('80 marks'));
      await model.removeColumn(ca2);
      expect(service.removedColumn?.id, 'ca2');
      expect(model.setup.totalMarks, 80);
    });

    test('a refused removal throws for the confirm sheet', () async {
      final (model, service) = await loaded(
        OrganizationMemberRole.owner,
        service: _Grading(columns: _standardColumns()),
      );
      service.failWith = const SupabaseRefusal('Scores are entered.');
      await expectLater(
        model.removeColumn(model.setup.columns.first),
        throwsA(
          isA<AppAlertError>().having(
            (e) => e.message,
            'message',
            'Scores are entered.',
          ),
        ),
      );
    });

    test('an emptied setup stays on the setup page', () async {
      final (model, _) = await loaded(
        OrganizationMemberRole.owner,
        service: _Grading(columns: [_column('ca1', 'CA 1', 20, 1)]),
      );
      await model.removeColumn(model.setup.columns.first);
      expect(model.setup.isEmpty, isTrue);
      expect(model.showStart, isFalse);
    });
  });

  group('GradingViewModel · scales and order', () {
    Future<(GradingViewModel, _Grading)> loaded(
      OrganizationMemberRole role, {
      List<GradeBoundary>? grades,
    }) async {
      final fake = _Grading(
        columns: _standardColumns(),
        grades: grades ?? [..._standardGrades(), ..._waec()],
      );
      final model = GradingViewModel(
        school: _school(role),
        service: fake,
        structure: _Structure(),
      );
      await model.load();
      return (model, fake);
    }

    test('starts on the school default, with a chip for Secondary', () async {
      final (model, _) = await loaded(OrganizationMemberRole.owner);
      expect(model.inSectionScope, isFalse);
      expect([for (final s in model.ownScaleSections) s.name], ['Secondary']);
      expect(
        [for (final s in model.sectionsWithoutOwnScale) s.name],
        ['Nursery', 'Primary'],
      );
      expect(model.scopeCaption, 'Used by Nursery and Primary.');
      expect(model.canAddScale, isTrue);
      expect(model.setup.boundaries.map((b) => b.grade).first, 'A');
    });

    test('switching to a section swaps the grades and the caption', () async {
      final (model, _) = await loaded(OrganizationMemberRole.owner);
      model.selectScope('secondary');
      expect(model.inSectionScope, isTrue);
      expect(model.setup.boundaries.map((b) => b.grade), ['A1', 'B2', 'F9']);
      expect(
        model.scopeCaption,
        'Secondary’s own grades. Other sections use the school default.',
      );
      // The columns are the school's in every scope.
      expect(model.setup.totalMarks, 100);

      model.selectScope(null);
      expect(model.setup.boundaries.first.grade, 'A');
      // A section with no scale of its own can't be selected.
      model.selectScope('primary');
      expect(model.inSectionScope, isFalse);
    });

    test('names the sections that use the school default, naturally', () {
      expect(GradingViewModel.joinNames(['Nursery']), 'Nursery');
      expect(
        GradingViewModel.joinNames(['Nursery', 'Primary', 'Secondary']),
        'Nursery, Primary and Secondary',
      );
    });

    test('says every section when all of them have their own scale', () async {
      final (model, service) = await loaded(OrganizationMemberRole.owner);
      for (final id in ['nursery', 'primary']) {
        await model.createSectionScale(id);
      }
      expect(service.copies.length, 2);
      model.selectScope(null);
      expect(model.scopeCaption, 'Used by every section.');
      expect(model.canAddScale, isFalse);
    });

    test('only leaders can start a new scale', () async {
      final (model, _) = await loaded(OrganizationMemberRole.bursar);
      expect(model.canAddScale, isFalse);
      expect([for (final s in model.ownScaleSections) s.name], ['Secondary']);
    });

    test('adds a grade to the selected scale', () async {
      final (model, service) = await loaded(OrganizationMemberRole.owner);
      model.selectScope('secondary');
      expect(
        await model.addGrade(
          grade: 'C4',
          percent: '50',
          remark: '',
          isPass: true,
        ),
        isNull,
      );
      expect(service.addedGrade?.sectionId, 'secondary');
      expect(model.setup.boundaries.map((b) => b.grade), contains('C4'));

      // And the school default's grade goes in with no section.
      model.selectScope(null);
      await model.addGrade(grade: 'S', percent: '90', remark: '', isPass: true);
      expect(service.addedGrade?.sectionId, isNull);
    });

    test('checks a new grade against the selected scale only', () async {
      final (model, _) = await loaded(OrganizationMemberRole.owner);
      // 75 is taken in Secondary (A1) but free in the school default.
      expect(model.setup.percentProblem('75'), isNull);
      model.selectScope('secondary');
      expect(model.setup.percentProblem('75'), contains('A1 already starts'));
      expect(model.setup.hasZeroBoundary, isTrue);
    });

    test('a new section scale copies the default in one insert', () async {
      final (model, service) = await loaded(OrganizationMemberRole.owner);
      expect(await model.createSectionScale('primary'), isNull);
      expect(service.copies, [(sectionId: 'primary', grades: 6)]);
      expect(service.singleInserts, 0);
      expect(model.scopeId, 'primary');
      expect(model.setup.boundaries.length, 6);
      expect(model.setup.boundaries.first.grade, 'A');
      expect(model.changed, isTrue);
      expect(model.scopeCaption, startsWith('Primary’s own grades.'));
    });

    test('a refused copy leaves the scope alone and says why', () async {
      final (model, service) = await loaded(OrganizationMemberRole.owner);
      service.failWith = const SupabaseRefusal('Not allowed.');
      expect(await model.createSectionScale('primary'), 'Not allowed.');
      expect(model.scopeId, isNull);
      expect(model.ownScaleSections.length, 1);
    });

    test('there is nothing to copy while the default has no grades', () async {
      final (model, service) = await loaded(
        OrganizationMemberRole.owner,
        grades: _waec(),
      );
      expect(
        await model.createSectionScale('primary'),
        contains('no grades to copy'),
      );
      expect(service.copies, isEmpty);
    });

    test('going back to the school scale deletes the section grades', () async {
      final (model, service) = await loaded(OrganizationMemberRole.owner);
      model.selectScope('secondary');
      await model.removeSectionScale();
      expect(service.deletedScales, ['secondary']);
      expect(model.inSectionScope, isFalse);
      expect(model.ownScaleSections, isEmpty);
      expect(model.setup.boundaries.first.grade, 'A');
      expect(model.changed, isTrue);
    });

    test('a refused removal throws for the confirm sheet', () async {
      final (model, service) = await loaded(OrganizationMemberRole.owner);
      model.selectScope('secondary');
      service.failWith = const SupabaseRefusal('Leaders only.');
      await expectLater(
        model.removeSectionScale(),
        throwsA(isA<AppAlertError>()),
      );
      expect(model.scopeId, 'secondary');
    });

    test(
      'a scope that no longer has a scale falls back to the default',
      () async {
        final (model, service) = await loaded(OrganizationMemberRole.owner);
        model.selectScope('secondary');
        service.grades = _standardGrades();
        await model.refresh();
        expect(model.inSectionScope, isFalse);
      },
    );

    test('moves a column by swapping orders with its neighbour', () async {
      final (model, service) = await loaded(OrganizationMemberRole.owner);
      final ca2 = model.setup.columns[1];
      expect(await model.moveColumn(ca2, 1), isNull);
      expect(service.swaps, [('ca2', 'exam')]);
      expect(model.setup.columns.map((c) => c.id), ['ca1', 'exam', 'ca2']);
      expect(model.changed, isTrue);

      expect(await model.moveColumn(model.setup.columns.first, -1), isNull);
      expect(await model.moveColumn(model.setup.columns.last, 1), isNull);
      expect(service.swaps.length, 1);
    });

    test('a failed move says why and keeps the order', () async {
      final (model, service) = await loaded(OrganizationMemberRole.owner);
      service.failWith = const SupabaseRefusal('Leaders only.');
      expect(
        await model.moveColumn(model.setup.columns[1], -1),
        'Leaders only.',
      );
      expect(model.setup.columns.map((c) => c.id), ['ca1', 'ca2', 'exam']);
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

    _Grading standard({List<GradeBoundary>? grades}) => _Grading(
      columns: _standardColumns(),
      grades: grades ?? _standardGrades(),
    );

    Finder field(String hint) => find.widgetWithText(TextField, hint);

    bool chipSelected(WidgetTester tester, String label) => tester
        .widget<AppFilterChip>(find.widgetWithText(AppFilterChip, label))
        .selected;

    testWidgets('the start page offers only the standard setup', (
      tester,
    ) async {
      await pump(tester, OrganizationMemberRole.owner, _Grading());

      expect(find.text('Grading isn’t set up yet'), findsOneWidget);
      expect(find.text('Use the standard setup'), findsOneWidget);
      expect(find.text('Build my own'), findsNothing);
      expect(
        find.textContaining(
          'Start from the standard setup and change anything',
        ),
        findsOneWidget,
      );
    });

    testWidgets('the standard setup sheet lists what it adds', (tester) async {
      final service = _Grading();
      await pump(tester, OrganizationMemberRole.owner, service);

      await tester.tap(
        find.widgetWithText(AppPrimaryButton, 'Use the standard setup'),
      );
      await tester.pumpAndSettle();
      expect(find.text('Use the standard setup?'), findsOneWidget);
      expect(find.text('70 to 100'), findsOneWidget);
      expect(find.text('Not now'), findsOneWidget);

      await tester.tap(
        find.descendant(
          of: find.byType(StandardSetupSheet),
          matching: find.byType(AppPrimaryButton),
        ),
      );
      await tester.pumpAndSettle();

      expect(service.standardRequested, isTrue);
      expect(find.text('Covers 0 to 100'), findsOneWidget);
      expect(find.textContaining('Total 100 marks.'), findsOneWidget);
    });

    testWidgets('a complete setup shows columns, scale and coverage', (
      tester,
    ) async {
      await pump(tester, OrganizationMemberRole.principal, standard());

      expect(find.text('CA 1'), findsOneWidget);
      expect(find.text('Out of 60'), findsOneWidget);
      expect(
        find.textContaining('so the columns don’t have to add up'),
        findsOneWidget,
      );
      expect(find.text('Covers 0 to 100'), findsOneWidget);
      expect(find.text('60 to 69'), findsOneWidget);
      expect(find.text('Excellent · Pass'), findsOneWidget);
      expect(find.text('Not a pass'), findsNothing);
      expect(find.byType(AppSectionAction), findsNWidgets(2));
      for (final action in tester.widgetList<AppSectionAction>(
        find.byType(AppSectionAction),
      )) {
        expect(action.addBackground, isTrue);
      }
      expect(find.byIcon(AppIcons.chevronRight), findsNWidgets(9));
      expect(find.text('Add a grade from 0'), findsNothing);
    });

    testWidgets('lists a grade as its remark and Pass or Fail', (tester) async {
      await pump(tester, OrganizationMemberRole.principal, standard());

      // D: "Fair · Pass", E: remark is already "Pass", F: already "Fail".
      expect(find.text('Fair · Pass'), findsOneWidget);
      expect(find.text('Pass'), findsOneWidget);
      expect(find.text('Fail'), findsOneWidget);
    });

    testWidgets('a scale with nothing at 0 says what is missing', (
      tester,
    ) async {
      await pump(
        tester,
        OrganizationMemberRole.admin,
        _Grading(grades: _standardGrades(withFail: false)),
      );

      expect(find.text('No score columns yet'), findsOneWidget);
      expect(find.text('Not covered: 0 to 39'), findsOneWidget);
      expect(find.text('Missing. Add a grade from 0.'), findsOneWidget);
      expect(find.text('Add a grade from 0'), findsOneWidget);
    });

    testWidgets('not a leader: read only, no actions', (tester) async {
      await pump(tester, OrganizationMemberRole.bursar, standard());

      expect(find.text('Read only for you'), findsOneWidget);
      expect(find.text('Total 100 marks.'), findsOneWidget);
      expect(find.textContaining('so the columns don’t'), findsNothing);
      expect(find.byType(AppSectionAction), findsNothing);
      expect(find.byIcon(AppIcons.chevronRight), findsNothing);
      expect(find.text('Covers 0 to 100'), findsNothing);
      expect(find.text('70 to 100'), findsOneWidget);
    });

    testWidgets('not a leader and nothing set up: a plain empty state', (
      tester,
    ) async {
      await pump(tester, OrganizationMemberRole.bursar, _Grading());

      expect(find.text('Grading isn’t set up yet'), findsOneWidget);
      expect(find.text('The school’s leaders will set it up.'), findsOneWidget);
      expect(find.text('Use the standard setup'), findsNothing);
      expect(find.text('Build my own'), findsNothing);
    });

    testWidgets('chips pick the school default or a section’s own scale', (
      tester,
    ) async {
      await pump(
        tester,
        OrganizationMemberRole.owner,
        standard(grades: [..._standardGrades(), ..._waec()]),
      );

      expect(find.byType(AppFilterChip), findsNWidgets(3));
      expect(chipSelected(tester, 'School default'), isTrue);
      expect(chipSelected(tester, 'Secondary'), isFalse);
      expect(find.text('New scale'), findsOneWidget);
      expect(find.text('Used by Nursery and Primary.'), findsOneWidget);
      expect(find.text('Use the school’s scale instead'), findsNothing);
      expect(find.text('70 to 100'), findsOneWidget);

      await tester.tap(find.widgetWithText(AppFilterChip, 'Secondary'));
      await tester.pumpAndSettle();

      expect(chipSelected(tester, 'Secondary'), isTrue);
      expect(chipSelected(tester, 'School default'), isFalse);
      expect(
        find.text(
          'Secondary’s own grades. Other sections use the school default.',
        ),
        findsOneWidget,
      );
      expect(find.text('75 to 100'), findsOneWidget);
      expect(find.text('70 to 100'), findsNothing);
      expect(find.text('70 to 74'), findsOneWidget);
      expect(find.text('Covers 0 to 100'), findsOneWidget);
      expect(find.text('Use the school’s scale instead'), findsOneWidget);

      await tester.tap(find.widgetWithText(AppFilterChip, 'School default'));
      await tester.pumpAndSettle();
      expect(find.text('70 to 100'), findsOneWidget);
      expect(find.text('Use the school’s scale instead'), findsNothing);
    });

    testWidgets('read only: chips to look, but no new scale', (tester) async {
      await pump(
        tester,
        OrganizationMemberRole.bursar,
        standard(grades: [..._standardGrades(), ..._waec()]),
      );

      expect(find.byType(AppFilterChip), findsNWidgets(2));
      expect(find.text('New scale'), findsNothing);

      await tester.tap(find.widgetWithText(AppFilterChip, 'Secondary'));
      await tester.pumpAndSettle();
      expect(find.text('75 to 100'), findsOneWidget);
      expect(find.text('Use the school’s scale instead'), findsNothing);
    });

    testWidgets('no chips when the school has no sections', (tester) async {
      await pump(
        tester,
        OrganizationMemberRole.owner,
        standard(),
        sections: const [],
      );
      expect(find.byType(AppFilterChip), findsNothing);
    });

    testWidgets('a new scale copies the default into a section', (
      tester,
    ) async {
      final service = standard();
      await pump(tester, OrganizationMemberRole.owner, service);

      expect(
        find.text('Used by Nursery, Primary and Secondary.'),
        findsOneWidget,
      );
      await tester.tap(find.widgetWithText(AppFilterChip, 'New scale'));
      await tester.pumpAndSettle();

      expect(find.text('Give a section its own scale'), findsOneWidget);
      expect(find.text('Create Nursery scale'), findsOneWidget);
      expect(
        find.textContaining('Other sections keep using the school default'),
        findsOneWidget,
      );

      await tester.tap(find.text('Primary'));
      await tester.pumpAndSettle();
      expect(find.text('Create Primary scale'), findsOneWidget);

      await tester.tap(find.text('Create Primary scale'));
      await tester.pumpAndSettle();

      expect(service.copies, [(sectionId: 'primary', grades: 6)]);
      expect(service.singleInserts, 0);
      expect(chipSelected(tester, 'Primary'), isTrue);
      expect(
        find.text(
          'Primary’s own grades. Other sections use the school default.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('Not now closes the new scale sheet without copying', (
      tester,
    ) async {
      final service = standard();
      await pump(tester, OrganizationMemberRole.owner, service);

      await tester.tap(find.widgetWithText(AppFilterChip, 'New scale'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();

      expect(find.text('Give a section its own scale'), findsNothing);
      expect(service.copies, isEmpty);
    });

    testWidgets('using the school’s scale again asks, then removes it', (
      tester,
    ) async {
      final service = standard(grades: [..._standardGrades(), ..._waec()]);
      await pump(tester, OrganizationMemberRole.owner, service);

      await tester.tap(find.widgetWithText(AppFilterChip, 'Secondary'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Use the school’s scale instead'));
      await tester.pumpAndSettle();
      expect(
        find.text('Use the school’s scale for Secondary?'),
        findsOneWidget,
      );
      expect(service.deletedScales, isEmpty);

      await tester.tap(find.text('Remove Secondary’s scale'));
      await tester.pumpAndSettle();

      expect(service.deletedScales, ['secondary']);
      expect(chipSelected(tester, 'School default'), isTrue);
      expect(find.widgetWithText(AppFilterChip, 'Secondary'), findsNothing);
      expect(find.text('Used by every section.'), findsNothing);
      expect(
        find.text('Used by Nursery, Primary and Secondary.'),
        findsOneWidget,
      );
    });

    testWidgets('the column sheet previews the total and checks the marks', (
      tester,
    ) async {
      await pump(tester, OrganizationMemberRole.owner, standard());

      await tester.tap(find.text('Add column'));
      await tester.pumpAndSettle();
      expect(find.text('Add a score column'), findsOneWidget);
      expect(find.text('Enter the marks first'), findsOneWidget);
      expect(find.textContaining('Up to 2 decimal places'), findsNothing);

      await tester.enterText(field('e.g. 20'), '20');
      await tester.pumpAndSettle();
      expect(find.text('Total becomes'), findsOneWidget);
      expect(find.text('120 marks, from 100 now'), findsOneWidget);

      await tester.enterText(field('e.g. 20').first, '0');
      await tester.pumpAndSettle();
      expect(
        find.text(
          'A column has to be out of more than 0. Enter at least 0.01.',
        ),
        findsOneWidget,
      );
      expect(find.text('Enter the marks first'), findsOneWidget);
    });

    testWidgets('the column sheet suggests names and moves on to the marks', (
      tester,
    ) async {
      await pump(tester, OrganizationMemberRole.owner, standard());

      await tester.tap(find.text('Add column'));
      await tester.pumpAndSettle();

      final chips = find.descendant(
        of: find.byType(Wrap),
        matching: find.byType(AppFilterChip),
      );
      expect(chips, findsNWidgets(3));
      for (final label in ['CA 3', 'Test', 'Assignment']) {
        expect(find.widgetWithText(AppFilterChip, label), findsOneWidget);
      }

      await tester.tap(find.widgetWithText(AppFilterChip, 'Test'));
      await tester.pumpAndSettle();

      final name = tester.widget<TextField>(field('e.g. CA 1'));
      expect(name.controller?.text, 'Test');
      final marks = tester.widget<TextField>(field('e.g. 20'));
      expect(marks.focusNode?.hasFocus, isTrue);
      // Marks are not prefilled.
      expect(marks.controller?.text, '');
    });

    testWidgets('the column sheet hides names that are already columns', (
      tester,
    ) async {
      await pump(
        tester,
        OrganizationMemberRole.owner,
        _Grading(
          columns: [..._standardColumns(), _column('t', 'Test', 10, 4)],
          grades: _standardGrades(),
        ),
      );

      await tester.tap(find.text('Add column'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppFilterChip, 'CA 3'), findsOneWidget);
      expect(find.widgetWithText(AppFilterChip, 'Test'), findsNothing);
      expect(find.widgetWithText(AppFilterChip, 'Assignment'), findsOneWidget);
    });

    testWidgets('editing a column has no chips and says when the total stays', (
      tester,
    ) async {
      await pump(tester, OrganizationMemberRole.owner, standard());

      await tester.tap(find.text('CA 2'));
      await tester.pumpAndSettle();
      expect(find.text('Edit CA 2'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(Wrap),
          matching: find.byType(AppFilterChip),
        ),
        findsNothing,
      );
      expect(find.text('Total stays'), findsOneWidget);
      expect(find.text('100 marks'), findsOneWidget);

      await tester.enterText(field('e.g. 20'), '30');
      await tester.pumpAndSettle();
      expect(find.text('Total becomes'), findsOneWidget);
      expect(find.text('110 marks, from 100 now'), findsOneWidget);
    });

    testWidgets('a taken column name shows after a pause, and on Save', (
      tester,
    ) async {
      final service = standard();
      await pump(tester, OrganizationMemberRole.owner, service);

      await tester.tap(find.text('Add column'));
      await tester.pumpAndSettle();
      await tester.enterText(field('e.g. 20'), '10');
      await tester.enterText(field('e.g. CA 1'), 'exam');
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.textContaining('There’s already a column'), findsNothing);

      await tester.pump(const Duration(milliseconds: 400));
      expect(
        find.text('There’s already a column called exam. Use another name.'),
        findsOneWidget,
      );

      // Typing again hides it until the pause; Save shows it at once.
      await tester.enterText(field('e.g. CA 1'), 'ca 1');
      await tester.pump();
      expect(find.textContaining('There’s already a column'), findsNothing);
      await tester.tap(find.text('Save column'));
      await tester.pump();
      expect(find.textContaining('There’s already a column'), findsOneWidget);
      expect(service.added, isNull);
      await tester.pumpAndSettle();
    });

    testWidgets('the position row moves a column and stops at the ends', (
      tester,
    ) async {
      final service = standard();
      await pump(tester, OrganizationMemberRole.owner, service);

      await tester.tap(find.text('CA 2'));
      await tester.pumpAndSettle();
      expect(find.text('Position'), findsOneWidget);
      expect(find.text('2 of 3'), findsOneWidget);

      await tester.tap(find.byIcon(AppIcons.chevronDown));
      await tester.pumpAndSettle();
      expect(service.swaps, [('ca2', 'exam')]);
      expect(find.text('3 of 3'), findsOneWidget);

      // At the end: down does nothing.
      await tester.tap(find.byIcon(AppIcons.chevronDown));
      await tester.pumpAndSettle();
      expect(service.swaps.length, 1);

      await tester.tap(find.byIcon(AppIcons.chevronUp));
      await tester.pumpAndSettle();
      expect(service.swaps.length, 2);
      expect(find.text('2 of 3'), findsOneWidget);
    });

    testWidgets('a lone column has nothing to move', (tester) async {
      await pump(
        tester,
        OrganizationMemberRole.owner,
        _Grading(
          columns: [_column('ca1', 'CA 1', 100, 1)],
          grades: _standardGrades(),
        ),
      );
      await tester.tap(find.text('CA 1'));
      await tester.pumpAndSettle();
      expect(find.text('Edit CA 1'), findsOneWidget);
      expect(find.text('Position'), findsNothing);
    });

    testWidgets('the grade sheet says what a new grade changes', (
      tester,
    ) async {
      await pump(tester, OrganizationMemberRole.owner, standard());

      await tester.tap(find.text('Add grade'));
      await tester.pumpAndSettle();
      expect(find.text('Add a grade'), findsOneWidget);
      expect(find.text('New grade'), findsNothing);
      expect(find.textContaining('Up to 2 decimal places'), findsNothing);
      expect(find.text('Pass grade'), findsOneWidget);
      expect(find.text('Marks the subject as passed.'), findsOneWidget);

      await tester.enterText(field('e.g. 65'), '65');
      await tester.pumpAndSettle();
      expect(find.text('New grade'), findsOneWidget);
      expect(find.text('65 to 69'), findsOneWidget);
      expect(find.text('B becomes'), findsOneWidget);
      expect(find.text('60 to 64, from 60 to 69'), findsOneWidget);
      expect(find.textContaining('69.99'), findsNothing);
    });

    testWidgets('the grade name field capitalises letters', (tester) async {
      await pump(tester, OrganizationMemberRole.owner, standard());

      await tester.tap(find.text('Add grade'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(field('e.g. A')).textCapitalization,
        TextCapitalization.characters,
      );
    });

    testWidgets('editing a grade shows its own change and the one below', (
      tester,
    ) async {
      await pump(tester, OrganizationMemberRole.owner, standard());

      await tester.tap(find.text('60 to 69'));
      await tester.pumpAndSettle();
      expect(find.text('Edit grade B'), findsOneWidget);
      expect(find.text('B becomes'), findsNothing);
      // The remark is filled in.
      expect(
        tester.widget<TextField>(find.byType(TextField).at(2)).controller?.text,
        'Very Good',
      );

      await tester.enterText(find.byType(TextField).at(1), '62');
      await tester.pumpAndSettle();
      expect(find.text('B becomes'), findsOneWidget);
      expect(find.text('62 to 69, from 60 to 69'), findsOneWidget);
      expect(find.text('C becomes'), findsOneWidget);
      expect(find.text('50 to 61, from 50 to 59'), findsOneWidget);
      expect(find.textContaining('will now be below'), findsNothing);
    });

    testWidgets('a taken start says what to try and hides the preview', (
      tester,
    ) async {
      await pump(tester, OrganizationMemberRole.owner, standard());

      await tester.tap(find.text('60 to 69'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(1), '50');
      await tester.pumpAndSettle();

      expect(
        find.text('C already starts at 50. Try 51, or edit C.'),
        findsOneWidget,
      );
      expect(find.text('B becomes'), findsNothing);
      final save = tester.widget<AppPrimaryButton>(
        find.widgetWithText(AppPrimaryButton, 'Save grade'),
      );
      expect(save.isDisabled, isTrue);
    });

    testWidgets('a grade that would sit below a later letter gets a warning', (
      tester,
    ) async {
      await pump(tester, OrganizationMemberRole.owner, standard());

      await tester.tap(find.text('70 to 100'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(1), '55');
      await tester.pumpAndSettle();

      expect(
        find.text('A will now be below B. Grades usually go down from A.'),
        findsOneWidget,
      );
      // Save stays available: it is a warning, not an error.
      final save = tester.widget<AppPrimaryButton>(
        find.widgetWithText(AppPrimaryButton, 'Save grade'),
      );
      expect(save.isDisabled, isFalse);
    });

    testWidgets('a taken grade name shows after a pause, and on Save', (
      tester,
    ) async {
      final service = standard();
      await pump(tester, OrganizationMemberRole.owner, service);

      await tester.tap(find.text('Add grade'));
      await tester.pumpAndSettle();
      await tester.enterText(field('e.g. 65'), '65');
      await tester.enterText(field('e.g. A'), 'b');
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.textContaining('There’s already a grade'), findsNothing);

      await tester.pump(const Duration(milliseconds: 400));
      expect(
        find.text('There’s already a grade called b. Use another name.'),
        findsOneWidget,
      );

      await tester.enterText(field('e.g. A'), 'c');
      await tester.pump();
      expect(find.textContaining('There’s already a grade'), findsNothing);
      await tester.tap(find.text('Save grade'));
      await tester.pump();
      expect(find.textContaining('There’s already a grade'), findsOneWidget);
      expect(service.addedGrade, isNull);
      await tester.pumpAndSettle();
    });

    testWidgets('the pass switch follows the start until it is touched', (
      tester,
    ) async {
      await pump(
        tester,
        OrganizationMemberRole.owner,
        _Grading(
          columns: _standardColumns(),
          grades: _standardGrades(withFail: false),
        ),
      );
      bool isPass() => tester.widget<AppSwitch>(find.byType(AppSwitch)).value;

      // "Add a grade from 0" starts as not a pass.
      await tester.tap(find.text('Add a grade from 0').first);
      await tester.pumpAndSettle();
      expect(isPass(), isFalse);

      await tester.enterText(field('e.g. 65'), '35');
      await tester.pumpAndSettle();
      expect(isPass(), isFalse);
      await tester.enterText(field('e.g. 65'), '65');
      await tester.pumpAndSettle();
      expect(isPass(), isTrue);

      await tester.tap(find.text('Pass grade'));
      await tester.pumpAndSettle();
      expect(isPass(), isFalse);
      await tester.enterText(field('e.g. 65'), '66');
      await tester.pumpAndSettle();
      expect(isPass(), isFalse);
    });

    testWidgets('saving a grade in a section scale adds it to that section', (
      tester,
    ) async {
      final service = standard(grades: [..._standardGrades(), ..._waec()]);
      await pump(tester, OrganizationMemberRole.owner, service);

      await tester.tap(find.widgetWithText(AppFilterChip, 'Secondary'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add grade'));
      await tester.pumpAndSettle();
      await tester.enterText(field('e.g. A'), 'C4');
      await tester.enterText(field('e.g. 65'), '72');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save grade'));
      await tester.pumpAndSettle();

      expect(service.addedGrade?.sectionId, 'secondary');
      expect(service.addedGrade?.grade, 'C4');
      expect(service.addedGrade?.isPass, isTrue);
    });
  });
}
