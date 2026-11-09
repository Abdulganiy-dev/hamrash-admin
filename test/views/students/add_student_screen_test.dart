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
    expect(find.text('STEP 1 OF 6 · STUDENT'), findsOneWidget);
    expect(segments(tester).current, 0);
    expect(segments(tester).count, 6);

    await tester.enterText(find.byType(TextField).at(0), 'Ada');
    await tester.enterText(find.byType(TextField).at(1), 'Obi');
    model
      ..pickGender(StaffGender.female)
      ..pickDateOfBirth(DateTime(2015, 3, 14));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(AppPrimaryButton, 'Continue'));
    await tester.pumpAndSettle();
    expect(model.step, AddStudentStep.personal);
    expect(find.text('More about them'), findsOneWidget);
    expect(find.text('STEP 2 OF 6 · PERSONAL DETAILS'), findsOneWidget);
    expect(segments(tester).current, 1);

    expect(
      tester
          .widget<AppPrimaryButton>(
            find.widgetWithText(AppPrimaryButton, 'Continue'),
          )
          .isDisabled,
      isTrue,
    );
    expect(find.text('Skip for now'), findsNothing);
    fillPersonal(model);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(AppPrimaryButton, 'Continue'));
    await tester.pumpAndSettle();
    expect(model.step, AddStudentStep.parents);
    expect(find.text('Who are the parents?'), findsOneWidget);
    expect(find.text('No parent added yet'), findsOneWidget);
    expect(segments(tester).current, 2);

    await tester.tap(find.bySemanticsLabel('Back'));
    await tester.pumpAndSettle();
    expect(model.step, AddStudentStep.personal);
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

  testWidgets('the personal details step shows its fields and waits for them', (
    tester,
  ) async {
    await pump(tester);
    fillStudent(model);
    model.next();
    await tester.pumpAndSettle();

    expect(find.text('State of origin'), findsOneWidget);
    expect(find.text('LGA'), findsOneWidget);
    expect(find.text('Choose a state first'), findsOneWidget);
    expect(find.text('Home address'), findsOneWidget);
    expect(find.text('Blood group'), findsOneWidget);
    expect(find.text('Genotype'), findsOneWidget);
    expect(find.text('Medical notes  (optional)'), findsOneWidget);
    expect(
      find.text('Allergies, conditions or anything a teacher should know'),
      findsOneWidget,
    );
    expect(
      find.text("School leaders and the student's teachers can see these."),
      findsOneWidget,
    );
    AppPrimaryButton button() => tester.widget<AppPrimaryButton>(
      find.widgetWithText(AppPrimaryButton, 'Continue'),
    );
    expect(button().isDisabled, isTrue);

    await tester.tap(find.text('Select').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('O+').last);
    await tester.pumpAndSettle();
    expect(model.bloodGroup, 'O+');
    expect(button().isDisabled, isTrue);

    model
      ..pickStateOfOrigin('Enugu')
      ..pickLga('Nsukka')
      ..pickGenotype('AA');
    await tester.enterText(
      find.widgetWithText(TextField, '12 Ogui Road, Enugu'),
      '12 Ogui Road, Enugu',
    );
    await tester.pumpAndSettle();
    expect(button().isDisabled, isFalse);

    await tester.tap(find.widgetWithText(AppPrimaryButton, 'Continue'));
    await tester.pumpAndSettle();
    expect(model.step, AddStudentStep.parents);
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
    expect(find.text('More about them'), findsOneWidget);
    model
      ..pickStateOfOrigin('Enugu')
      ..pickLga('Nsukka')
      ..pickBloodGroup('O+')
      ..pickGenotype('AA')
      ..address.text = '12 Ogui Road, Enugu'
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
    expect(find.text('Personal details'), findsOneWidget);
    expect(find.text('12 Ogui Road, Enugu'), findsOneWidget);
    expect(find.text('Enugu · Nsukka'), findsOneWidget);
    expect(find.text('State of origin and LGA'), findsOneWidget);
    expect(find.text('O+ · AA'), findsOneWidget);
    expect(find.text('Blood group and genotype'), findsOneWidget);
    expect(find.text('Medical notes'), findsOneWidget);
    expect(find.bySemanticsLabel('Edit personal details'), findsOneWidget);
    // Photo and medical notes are both empty.
    expect(find.text('Not added'), findsNWidgets(2));

    await tester.tap(find.bySemanticsLabel('Edit personal details'));
    await tester.pumpAndSettle();
    expect(model.step, AddStudentStep.personal);
    await tester.tap(find.widgetWithText(AppPrimaryButton, 'Continue'));
    await tester.pumpAndSettle();
    expect(model.step, AddStudentStep.review);

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
    fillPersonal(model);
    model.next();
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
