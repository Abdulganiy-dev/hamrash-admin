import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hamrash_admin/api/models/team/staff_member.dart';
import 'package:hamrash_admin/core/widgets/app_step_segments.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_variants.dart';
import 'package:hamrash_admin/core/widgets/selection/app_selection_controls.dart';
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

  /// Registers Chioma on JSS 1 Gold with French chosen.
  Future<void> reachRegistered() async {
    fillStudent(model);
    model.next();
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
    await model.loadPlacement();
    final jss1 = model.classes.single;
    model
      ..pickClass(jss1)
      ..pickArm(model.armsOf(jss1).first);
    await model.loadOfferings();
    model
      ..next()
      ..toggleSubject('french')
      ..next();
    await model.register();
  }

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
    expect(find.text('1 of 2 chosen'), findsOneWidget);

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
    expect(find.text('JSS 1 Gold · 2026/27'), findsOneWidget);
    expect(find.text('KCL/2026/0042'), findsOneWidget);
    expect(find.text('ADMISSION NUMBER'), findsOneWidget);
    expect(find.text('Copy'), findsOneWidget);

    // Registered: no steps left, so no progress bar and no back arrow.
    expect(find.byType(AppStepSegments), findsNothing);
    expect(find.bySemanticsLabel('Back'), findsNothing);
    expect(find.bySemanticsLabel('Close'), findsOneWidget);

    expect(find.text('Main contact'), findsOneWidget);
    expect(find.text('Mrs Ngozi Okafor'), findsOneWidget);
    expect(find.text('Subjects'), findsOneWidget);
    expect(find.text('1 core · 1 optional'), findsOneWidget);
    expect(find.text('Parents'), findsOneWidget);
    expect(find.text('1 linked'), findsOneWidget);
    expect(find.text('Open Ada’s profile'), findsOneWidget);

    await tester.tap(find.text('Add another student'));
    await tester.pumpAndSettle();
    expect(find.text('Who is the student?'), findsOneWidget);
    expect(model.firstName.text, isEmpty);
    expect(find.byType(AppStepSegments), findsOneWidget);
  });

  testWidgets('Copy puts the admission number on the clipboard', (
    tester,
  ) async {
    final copied = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied.add(
            (call.arguments as Map<Object?, Object?>)['text']! as String,
          );
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    await pump(tester);
    await reachRegistered();
    await tester.pumpAndSettle();

    expect(find.text('Chioma is registered'), findsOneWidget);
    await tester.tap(find.text('Copy'));
    await tester.pumpAndSettle();
    expect(copied, ['KCL/2026/0042']);
  });

  testWidgets('the subjects step shows both sections and the running total', (
    tester,
  ) async {
    await pump(tester);
    fillStudent(model);
    model.next();
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
    await model.loadPlacement();
    model
      ..pickClass(model.classes.single)
      ..pickArm(model.armsOf(model.classes.single).first);
    await model.loadOfferings();
    model.next();
    await tester.pumpAndSettle();
    expect(model.step, AddStudentStep.subjects);

    expect(
      find.text(
        'JSS 1 Gold has 2 to choose from. Tap the ones they will study.',
      ),
      findsOneWidget,
    );
    expect(find.text('Optional subjects'), findsOneWidget);
    expect(find.text('0 of 2 chosen'), findsOneWidget);
    expect(
      find.text('Choosing none is fine. You can set them later.'),
      findsOneWidget,
    );
    expect(find.text('Included for everyone'), findsOneWidget);
    expect(find.text('1 subject'), findsOneWidget);
    expect(find.text('Maths'), findsOneWidget);
    expect(find.text('1 subject in total'), findsOneWidget);
    expect(find.text('· compulsory only'), findsOneWidget);

    List<bool?> boxes() => [
      for (final box in tester.widgetList<AppCheckbox>(
        find.byType(AppCheckbox),
      ))
        box.value,
    ];
    expect(boxes(), [false, false]);

    await tester.tap(find.text('French'));
    await tester.pumpAndSettle();
    expect(boxes(), [true, false]);
    expect(find.text('1 of 2 chosen'), findsOneWidget);
    expect(find.text('2 subjects in total'), findsOneWidget);
    expect(find.text('· 1 compulsory + 1 optional'), findsOneWidget);

    await tester.tap(find.text('Music'));
    await tester.pumpAndSettle();
    expect(boxes(), [true, true]);
    expect(find.text('3 subjects in total'), findsOneWidget);

    await tester.tap(find.text('French'));
    await tester.pumpAndSettle();
    expect(boxes(), [false, true]);
    expect(model.chosenSubjectIds, {'music'});

    // Continue stays on with any choice, and the total is only on this step.
    await tester.tap(find.widgetWithText(AppPrimaryButton, 'Continue'));
    await tester.pumpAndSettle();
    expect(model.step, AddStudentStep.review);
    expect(find.textContaining('in total'), findsNothing);
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
