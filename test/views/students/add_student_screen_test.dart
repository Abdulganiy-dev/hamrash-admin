import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hamrash_admin/api/models/team/staff_member.dart';
import 'package:hamrash_admin/core/widgets/app_step_segments.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_variants.dart';
import 'package:hamrash_admin/views/students/add_student/add_student_screen.dart';
import 'package:hamrash_admin/views/students/add_student/add_student_view_model.dart';

import 'add_student_fakes.dart';

void main() {
  late Fakes fakes;
  late AddStudentViewModel model;

  setUp(() {
    fakes = Fakes();
    model = fakes.model();
  });

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: AddStudentScreen(school: school(), viewModel: model),
      ),
    );
    await tester.pumpAndSettle();
  }

  AppStepSegments segments(WidgetTester tester) =>
      tester.widget<AppStepSegments>(find.byType(AppStepSegments));

  testWidgets('moves forward and back through the steps and keeps typed text', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text('Who is the student?'), findsOneWidget);
    expect(find.text('STEP 1 OF 5 · STUDENT'), findsOneWidget);
    expect(segments(tester).current, 0);
    expect(segments(tester).count, 5);

    await tester.enterText(find.byType(TextField).at(0), 'Ada');
    await tester.enterText(find.byType(TextField).at(1), 'Obi');
    model
      ..pickGender(StaffGender.female)
      ..pickDateOfBirth(DateTime(2015, 3, 14));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(AppPrimaryButton, 'Continue'));
    await tester.pumpAndSettle();
    expect(model.step, AddStudentStep.parents);
    expect(find.text('Who are the parents?'), findsOneWidget);
    expect(find.text('No parent added yet'), findsOneWidget);
    expect(segments(tester).current, 1);

    await tester.tap(find.bySemanticsLabel('Back'));
    await tester.pumpAndSettle();
    expect(model.step, AddStudentStep.student);
    expect(find.text('Who is the student?'), findsOneWidget);
    expect(find.text('Ada'), findsOneWidget);
    expect(find.text('Obi'), findsOneWidget);
    expect(segments(tester).current, 0);
  });

  testWidgets('Continue stays off until the step is valid', (tester) async {
    await pump(tester);

    final button = tester.widget<AppPrimaryButton>(
      find.widgetWithText(AppPrimaryButton, 'Continue'),
    );
    expect(button.isDisabled, isTrue);
    await tester.tap(find.text('Continue'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(model.step, AddStudentStep.student);
  });

  testWidgets('back on the first step with something typed asks first', (
    tester,
  ) async {
    await pump(tester);
    await tester.enterText(find.byType(TextField).at(0), 'Ada');
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Discard this student?'), findsOneWidget);

    await tester.tap(find.widgetWithText(AppSecondaryButton, 'Keep editing'));
    await tester.pumpAndSettle();
    expect(find.text('Discard this student?'), findsNothing);
    expect(model.step, AddStudentStep.student);
    expect(model.firstName.text, 'Ada');
  });

  testWidgets('every step and the registered page render', (tester) async {
    await pump(tester);
    model
      ..firstName.text = 'Ada'
      ..lastName.text = 'Obi'
      ..pickGender(StaffGender.female)
      ..pickDateOfBirth(DateTime(2015, 3, 14))
      ..next();
    await tester.pumpAndSettle();

    fakes.students.matches = const [ngozi];
    model
      ..startParentSheet()
      ..searchPhone.text = '08035550142';
    await model.findParent();
    model.useFoundParent();
    await tester.pumpAndSettle();
    expect(find.text('Main contact'), findsOneWidget);

    model.next();
    await tester.pumpAndSettle();
    expect(find.text('Which class do they join?'), findsOneWidget);
    await tester.tap(find.text('JSS 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gold'));
    await tester.pumpAndSettle();
    expect(find.text('JSS 1 Gold'), findsOneWidget);
    expect(model.canContinue, isTrue);

    model.next();
    await tester.pumpAndSettle();
    expect(find.text('Pick optional subjects'), findsOneWidget);
    await tester.tap(find.text('French'));
    await tester.pumpAndSettle();
    expect(find.text('1 chosen'), findsOneWidget);

    model.next();
    await tester.pumpAndSettle();
    expect(find.text('Register student'), findsOneWidget);
    expect(find.text('Class and subjects'), findsOneWidget);

    await tester.tap(find.widgetWithText(AppPrimaryButton, 'Register student'));
    await tester.pumpAndSettle();
    expect(find.text('Ada is registered'), findsOneWidget);
    expect(find.text('KCL/2026/0042'), findsOneWidget);
    expect(segments(tester).complete, isTrue);

    await tester.tap(
      find.widgetWithText(AppSecondaryButton, 'Add another student'),
    );
    await tester.pumpAndSettle();
    expect(find.text('Who is the student?'), findsOneWidget);
    expect(model.firstName.text, isEmpty);
  });

  testWidgets('no current session shows the blocked state', (tester) async {
    fakes.structure.session = null;
    await pump(tester);
    model
      ..firstName.text = 'Ada'
      ..lastName.text = 'Obi'
      ..pickGender(StaffGender.female)
      ..pickDateOfBirth(DateTime(2015, 3, 14))
      ..next();
    fakes.students.matches = const [ngozi];
    model
      ..startParentSheet()
      ..searchPhone.text = '08035550142';
    await model.findParent();
    model
      ..useFoundParent()
      ..next();
    await tester.pumpAndSettle();
    expect(find.text('There’s no current session'), findsOneWidget);
    expect(find.text('Open academic sessions'), findsOneWidget);
  });
}
