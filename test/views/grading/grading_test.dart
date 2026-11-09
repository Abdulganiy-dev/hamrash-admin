import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hamrash_admin/api/models/grading/grade_boundary.dart';
import 'package:hamrash_admin/api/models/grading/grading_setup.dart';
import 'package:hamrash_admin/api/models/grading/score_column.dart';
import 'package:hamrash_admin/api/models/organization_models/member_school.dart';
import 'package:hamrash_admin/api/models/organization_models/organization.dart';
import 'package:hamrash_admin/api/models/organization_models/organization_member.dart';
import 'package:hamrash_admin/api/services/supabase_services/grading_service.dart';
import 'package:hamrash_admin/api/services/supabase_services/supabase_refusal.dart';
import 'package:hamrash_admin/core/widgets/app_alert_dialog.dart';
import 'package:hamrash_admin/core/widgets/app_icons.dart';
import 'package:hamrash_admin/core/widgets/app_section_action.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_variants.dart';
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
}) => GradeBoundary(
  id: grade,
  grade: grade,
  minPercent: min,
  remark: remark,
  isPass: isPass,
);

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
      expect(setup.detailsOf(setup.boundaries.last), 'Fail · Not a pass');
      expect(
        setup.detailsOf(_grade('X', 10, null, isPass: false)),
        'Not a pass',
      );
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
        'C already starts at 50. Pick a number no other grade uses.',
      );
      expect(setup.percentProblem('50', except: setup.boundaries[2]), isNull);
      expect(setup.percentProblem('100'), contains('below 100'));
      expect(setup.percentProblem('65.555'), contains('2 decimal places'));
      expect(setup.percentProblem('x'), isNotNull);
    });

    test('says where a grade goes up to', () {
      expect(setup.goesUpTo('65'), '69.99, where A starts');
      expect(setup.goesUpTo('72'), '100');
      expect(setup.goesUpTo('50', except: setup.boundaries[1]), isNull);
      expect(
        setup.goesUpTo('55', except: setup.boundaries[2]),
        '59.99, where B starts',
      );
    });
  });

  group('GradingViewModel', () {
    Future<(GradingViewModel, _Grading)> loaded(
      OrganizationMemberRole role, {
      _Grading? service,
    }) async {
      final fake = service ?? _Grading();
      final model = GradingViewModel(school: _school(role), service: fake);
      await model.load();
      return (model, fake);
    }

    test(
      'a leader starts from the start page when nothing is set up',
      () async {
        final (model, _) = await loaded(OrganizationMemberRole.principal);
        expect(model.showStart, isTrue);
        expect(model.showNotSetUp, isFalse);

        model.buildOwn();
        expect(model.showStart, isFalse);
        expect(model.building, isTrue);
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

  group('GradingScreen', () {
    Future<void> pump(
      WidgetTester tester,
      OrganizationMemberRole role,
      _Grading service,
    ) async {
      locator.registerSingleton<GradingService>(service);
      addTearDown(locator.reset);
      tester.view.physicalSize = const Size(390, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(home: GradingScreen(school: _school(role))),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('the start page offers the standard setup or your own', (
      tester,
    ) async {
      await pump(tester, OrganizationMemberRole.owner, _Grading());

      expect(find.text('Grading isn’t set up yet'), findsOneWidget);
      expect(find.text('Use the standard setup'), findsOneWidget);
      expect(find.text('Build my own'), findsOneWidget);

      await tester.tap(find.text('Build my own'));
      await tester.pumpAndSettle();

      expect(find.text('Grading isn’t set up yet'), findsNothing);
      expect(find.text('No score columns yet'), findsOneWidget);
      expect(find.text('Not covered: 0 to 100'), findsOneWidget);
      expect(find.text('Add column'), findsOneWidget);
      expect(find.text('Add grade'), findsOneWidget);
      expect(find.text('Add a grade from 0'), findsOneWidget);
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
      await pump(
        tester,
        OrganizationMemberRole.principal,
        _Grading(columns: _standardColumns(), grades: _standardGrades()),
      );

      expect(find.text('CA 1'), findsOneWidget);
      expect(find.text('Out of 60'), findsOneWidget);
      expect(
        find.textContaining('so the columns don’t have to add up'),
        findsOneWidget,
      );
      expect(find.text('Covers 0 to 100'), findsOneWidget);
      expect(find.text('60 to 69'), findsOneWidget);
      expect(find.text('Excellent · Pass'), findsOneWidget);
      expect(find.text('Fail · Not a pass'), findsOneWidget);
      expect(find.byType(AppSectionAction), findsNWidgets(2));
      expect(find.byIcon(AppIcons.chevronRight), findsNWidgets(9));
      expect(find.text('Add a grade from 0'), findsNothing);
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
      await pump(
        tester,
        OrganizationMemberRole.bursar,
        _Grading(columns: _standardColumns(), grades: _standardGrades()),
      );

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

    testWidgets('the column sheet previews the total and checks the marks', (
      tester,
    ) async {
      await pump(
        tester,
        OrganizationMemberRole.owner,
        _Grading(columns: _standardColumns(), grades: _standardGrades()),
      );

      await tester.tap(find.text('Add column'));
      await tester.pumpAndSettle();
      expect(find.text('Add a score column'), findsOneWidget);
      expect(find.text('Enter the marks first'), findsOneWidget);

      await tester.enterText(find.widgetWithText(TextField, 'e.g. 20'), '20');
      await tester.pumpAndSettle();
      expect(find.text('120 marks, from 100 now'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextField, 'e.g. 20').first,
        '0',
      );
      await tester.pumpAndSettle();
      expect(
        find.text(
          'A column has to be out of more than 0. Enter at least 0.01.',
        ),
        findsOneWidget,
      );
      expect(find.text('Enter the marks first'), findsOneWidget);
    });
  });
}
