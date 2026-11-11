import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hamrash_admin/api/models/organization_models/organization_member.dart';
import 'package:hamrash_admin/api/models/students/parent_match.dart';
import 'package:hamrash_admin/api/models/students/student_filter.dart';
import 'package:hamrash_admin/api/models/students/student_profile.dart';
import 'package:hamrash_admin/api/services/supabase_services/supabase_refusal.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_variants.dart';
import 'package:hamrash_admin/views/students/student_detail/student_detail_screen.dart';
import 'package:hamrash_admin/views/students/student_detail/student_detail_view_model.dart';
import 'package:hamrash_admin/views/students/student_detail/widgets/move_arm_sheet.dart';
import 'package:hamrash_admin/views/students/student_detail/widgets/optional_subjects_sheet.dart';
import 'package:hamrash_admin/views/students/student_detail/widgets/student_parent_row.dart';
import 'package:hamrash_admin/views/team/widgets/access_card.dart';
import 'package:hamrash_admin/views/team/widgets/staff_info_rows.dart';

import 'student_detail_fakes.dart';

Future<FakeStudents> _pump(
  WidgetTester tester,
  StudentProfile student, {
  OrganizationMemberRole role = OrganizationMemberRole.admin,
}) async {
  tester.view.physicalSize = const Size(800, 3600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final service = FakeStudents(student);
  final school = schoolFor(role);
  await tester.pumpWidget(
    MaterialApp(
      home: StudentDetailScreen(
        school: school,
        studentId: student.id,
        viewModel: StudentDetailViewModel(
          school: school,
          studentId: student.id,
          students: service,
          now: () => DateTime(2026, 11, 11),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return service;
}

void main() {
  testWidgets('a leader sees every section of an active student', (
    tester,
  ) async {
    await _pump(tester, abdullahi());

    expect(find.text('Abdullahi Yusuf'), findsOneWidget);
    expect(find.text('JSS 1B · KCL/2026/0021'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
    // Class
    expect(find.text('2026/27'), findsOneWidget);
    expect(find.text('JSS 1B · Ibrahim Bello'), findsOneWidget);
    expect(find.text('Subjects · 2 core, 2 optional'), findsOneWidget);
    expect(find.text('Agricultural Science, French'), findsOneWidget);
    // Parents
    expect(find.text('Mrs Halima Yusuf'), findsOneWidget);
    expect(find.text('Mother · Primary contact'), findsOneWidget);
    expect(find.text('Mr Musa Yusuf'), findsOneWidget);
    expect(find.text('Father · 0803 112 4455'), findsOneWidget);
    // Details and Personal
    expect(find.text('KCL/2026/0021'), findsWidgets);
    expect(find.text('8 Sep 2026'), findsOneWidget);
    expect(find.text('2 Mar 2014'), findsOneWidget);
    expect(find.text('Kano · Nassarawa'), findsOneWidget);
    expect(find.text('Leaders and their teachers'), findsOneWidget);
    expect(find.text('O+'), findsOneWidget);
    // Access: one app, no role row
    expect(find.text('Access'), findsOneWidget);
    expect(find.text('Hamrash Student'), findsOneWidget);
    expect(find.text('Not on app'), findsOneWidget);
    expect(find.text('Role'), findsNothing);
    expect(find.text('Change status'), findsOneWidget);
    expect(
      find.text('Only for a mistake. Removes their records.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'a bursar sees Class, Parents and Details and nothing to change',
    (tester) async {
      await _pump(tester, abdullahi(), role: OrganizationMemberRole.bursar);

      expect(find.text('Class'), findsOneWidget);
      expect(find.text('Parents'), findsOneWidget);
      expect(find.text('Details'), findsOneWidget);
      expect(find.text('Personal'), findsNothing);
      expect(find.text('Access'), findsNothing);
      expect(find.text('Change'), findsNothing);
      expect(find.text('Add'), findsNothing);
      expect(find.bySemanticsLabel('More actions'), findsNothing);
      // read-only rows have no chevrons to tap
      expect(
        tester
            .widget<StaffTeachingRow>(
              find.byKey(const ValueKey('student-class')),
            )
            .onTap,
        isNull,
      );
      expect(
        tester
            .widget<StudentParentRow>(find.byKey(const ValueKey('parent-p1')))
            .onTap,
        isNull,
      );
    },
  );

  testWidgets('a student who has left shows the banner and no Access', (
    tester,
  ) async {
    await _pump(tester, abdullahi(status: StudentStatusFilter.withdrawn));

    expect(find.text('Withdrawn'), findsOneWidget);
    expect(find.text('Withdrawn on 10 Nov 2026'), findsOneWidget);
    expect(
      find.text(
        "They're off the JSS 1B list. Their results and parents stay on record.",
      ),
      findsOneWidget,
    );
    expect(find.text('Last placed 2026/27'), findsOneWidget);
    expect(find.text('Access'), findsNothing);
    expect(find.text('Personal'), findsNothing);
    expect(find.text('Change status'), findsOneWidget);
  });

  testWidgets('on the app: suspend and remove, with what remove also does', (
    tester,
  ) async {
    await _pump(
      tester,
      abdullahi(login: loginWith(OrganizationMemberStatus.active)),
    );

    expect(find.text('On app'), findsOneWidget);
    expect(find.text('Joined 3 Sep 2026'), findsOneWidget);
    expect(find.text('Suspend access'), findsOneWidget);
    expect(
      find.text('Only for a mistake. Also removes their login.'),
      findsOneWidget,
    );
    expect(find.text('Cancel invite'), findsNothing);
  });

  testWidgets('a principal does not get suspend, cancel or remove', (
    tester,
  ) async {
    await _pump(
      tester,
      abdullahi(login: loginWith(OrganizationMemberStatus.active)),
      role: OrganizationMemberRole.principal,
    );

    expect(find.text('Change status'), findsOneWidget);
    expect(find.text('Suspend access'), findsNothing);
    expect(find.text('Remove student'), findsNothing);
  });

  testWidgets('tapping Not on app makes the invite and shows the code', (
    tester,
  ) async {
    await _pump(tester, abdullahi());

    await tester.tap(find.text('Not on app'));
    await tester.pumpAndSettle();

    expect(find.text("Abdullahi's invite is ready"), findsOneWidget);
    expect(find.text('Share invite'), findsOneWidget);
    expect(find.textContaining('R4TB'), findsWidgets);
    expect(find.textContaining('Open the Hamrash student app'), findsOneWidget);
  });

  testWidgets('a refused invite says why instead of opening the sheet', (
    tester,
  ) async {
    final service = await _pump(tester, abdullahi());
    service.failWith = const SupabaseRefusal(
      'Only active students can be given a login',
    );

    await tester.tap(find.text('Not on app'));
    await tester.pumpAndSettle();

    expect(find.text("Abdullahi's invite is ready"), findsNothing);
  });

  testWidgets('Remove student asks first and says what goes', (tester) async {
    final service = await _pump(
      tester,
      abdullahi(login: loginWith(OrganizationMemberStatus.active)),
    );

    await tester.tap(find.text('Remove student'));
    await tester.pumpAndSettle();

    expect(find.text('Remove Abdullahi Yusuf?'), findsOneWidget);
    expect(
      find.text('Their class place and subjects for 2026/27 go'),
      findsOneWidget,
    );
    expect(find.text('Their student app login stops working'), findsOneWidget);
    expect(find.text('Change status instead'), findsOneWidget);
    expect(service.removedId, isNull);
  });

  testWidgets('Change status: pick withdrawn and save', (tester) async {
    final service = await _pump(tester, abdullahi());

    await tester.tap(find.text('Change status'));
    await tester.pumpAndSettle();
    expect(find.text('In school now'), findsOneWidget);
    expect(find.text('Moved to another school'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('student-status-withdrawn')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(AppPrimaryButton, 'Mark as withdrawn'),
    );
    await tester.pumpAndSettle();

    expect(service.savedStatus, StudentStatusFilter.withdrawn);
  });

  testWidgets('a parent: unlink says who becomes the primary contact', (
    tester,
  ) async {
    final service = await _pump(tester, abdullahi());

    await tester.tap(find.text('Mrs Halima Yusuf'));
    await tester.pumpAndSettle();
    expect(find.text('Change relationship'), findsOneWidget);
    expect(find.text('Unlink from Abdullahi'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget); // she has an email
    await tester.tap(find.text('Unlink from Abdullahi'));
    await tester.pumpAndSettle();

    expect(find.text('Unlink Mrs Halima Yusuf?'), findsOneWidget);
    expect(
      find.textContaining('Mr Musa Yusuf becomes the primary contact'),
      findsOneWidget,
    );
    expect(find.text('Keep them linked'), findsOneWidget);
    await tester.tap(find.widgetWithText(AppDestructiveButton, 'Unlink'));
    await tester.pumpAndSettle();
    expect(service.unlinked?.parentId, 'p1');
    expect(service.unlinked?.newPrimary, 'p2');
  });

  testWidgets('a parent without an email has no Email button', (tester) async {
    await _pump(tester, abdullahi());

    await tester.tap(find.text('Mr Musa Yusuf'));
    await tester.pumpAndSettle();

    expect(find.text('0803 112 4455'), findsOneWidget);
    expect(find.text('Message'), findsOneWidget);
    expect(find.text('Email'), findsNothing);
  });

  testWidgets('Add a parent: the Add student sheet, find one and use them', (
    tester,
  ) async {
    final service = await _pump(tester, abdullahi());
    service.matches = const [
      ParentMatch(
        id: 'p7',
        title: 'Mr',
        firstName: 'Sani',
        lastName: 'Danladi',
        phone: '+2348052209134',
        childrenNames: ['Musa'],
      ),
    ];

    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    expect(find.text('Add a parent'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, '08052209134');
    await tester.pump();
    await tester.tap(find.widgetWithText(AppPrimaryButton, 'Find parent'));
    await tester.pumpAndSettle();

    expect(find.text('Mr Sani Danladi'), findsOneWidget);
    expect(find.text('Parent of Musa'), findsOneWidget);
    expect(find.text('Found'), findsOneWidget);
    expect(find.text('Relationship to Abdullahi'), findsOneWidget);
    // Mr suggests Father, so the button is ready.
    await tester.tap(find.widgetWithText(AppPrimaryButton, 'Use Mr Danladi'));
    await tester.pumpAndSettle();

    expect(service.linked?.parentId, 'p7');
    expect(service.linked?.relationship.value, 'father');
    expect(service.linked?.primary, isFalse);
  });

  testWidgets('Add a parent: one they already have is called out', (
    tester,
  ) async {
    final service = await _pump(tester, abdullahi());
    service.matches = const [
      ParentMatch(
        id: 'p2',
        title: 'Mr',
        firstName: 'Musa',
        lastName: 'Yusuf',
        phone: '+2348031124455',
      ),
    ];

    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '08031124455');
    await tester.pump();
    await tester.tap(find.widgetWithText(AppPrimaryButton, 'Find parent'));
    await tester.pumpAndSettle();

    expect(find.text('Mr Musa Yusuf is already added.'), findsOneWidget);
    expect(service.linked, isNull);
  });

  testWidgets('Add a parent: a number nobody has opens the new parent form', (
    tester,
  ) async {
    final service = await _pump(tester, abdullahi());
    service.matches = const [];

    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '08052209134');
    await tester.pump();
    await tester.tap(find.widgetWithText(AppPrimaryButton, 'Find parent'));
    await tester.pumpAndSettle();

    expect(find.text('New parent'), findsOneWidget);
    expect(
      find.text('No one at your school has this number yet.'),
      findsOneWidget,
    );
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Occupation'), findsOneWidget);
    expect(find.text('Home address'), findsWidgets);
    expect(find.widgetWithText(AppPrimaryButton, 'Add parent'), findsOneWidget);
  });

  testWidgets('a parent can be opened from the sheet', (tester) async {
    await _pump(tester, abdullahi());

    await tester.tap(find.text('Mrs Halima Yusuf'));
    await tester.pumpAndSettle();

    expect(find.text('View profile'), findsOneWidget);
  });

  testWidgets('Move to another arm: the current arm is marked, pick another', (
    tester,
  ) async {
    final service = await _pump(tester, abdullahi());
    service.droppedOnMove = 1;

    await tester.tap(find.byKey(const ValueKey('student-class')));
    await tester.pumpAndSettle();

    expect(find.text('Move to another arm'), findsOneWidget);
    expect(
      find.text('JSS 1 · Scores already recorded stay with their old arm.'),
      findsOneWidget,
    );
    expect(find.text('Now · 30 students · Lead Ibrahim Bello'), findsOneWidget);
    expect(find.text('29 students · No lead yet'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('arm-row-arm-1a')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(AppPrimaryButton, 'Move to JSS 1A'));
    await tester.pumpAndSettle();

    expect(service.movedTo, 'arm-1a');
  });

  testWidgets('Move to another arm: a refusal stays in the sheet', (
    tester,
  ) async {
    final service = await _pump(tester, abdullahi());
    service.failWith = const SupabaseRefusal('That arm is switched off');

    await tester.tap(find.byKey(const ValueKey('student-class')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('arm-row-arm-1c')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(AppPrimaryButton, 'Move to JSS 1C'));
    await tester.pumpAndSettle();

    expect(find.text('That arm is switched off'), findsOneWidget);
    expect(find.byType(MoveArmSheet), findsOneWidget);
  });

  testWidgets('Optional subjects: tick, count and save', (tester) async {
    final service = await _pump(tester, abdullahi());

    await tester.tap(find.byKey(const ValueKey('student-subjects')));
    await tester.pumpAndSettle();

    expect(find.byType(OptionalSubjectsSheet), findsOneWidget);
    expect(find.text('Abdullahi’s subjects'), findsOneWidget);
    expect(
      find.text(
        'JSS 1B has 3 optional subjects. Tick the ones Abdullahi takes.',
      ),
      findsOneWidget,
    );
    expect(find.text('Included for everyone'), findsOneWidget);
    expect(find.text('2 of 3 chosen'), findsOneWidget);
    expect(find.text('Choosing none is fine.'), findsOneWidget);
    expect(
      tester
          .widget<AppPrimaryButton>(
            find.widgetWithText(AppPrimaryButton, 'Save changes'),
          )
          .isDisabled,
      isTrue,
    );

    await tester.tap(find.byKey(const ValueKey('optional-music')));
    await tester.pumpAndSettle();
    expect(find.text('3 of 3 chosen'), findsOneWidget);
    expect(
      find.text('5 subjects in total · 2 compulsory + 3 optional'),
      findsOneWidget,
    );
    await tester.tap(find.widgetWithText(AppPrimaryButton, 'Save changes'));
    await tester.pumpAndSettle();

    expect(service.savedOptional, {'agric', 'french', 'music'});
  });

  testWidgets('Change details opens with their values and saves a change', (
    tester,
  ) async {
    final service = await _pump(tester, abdullahi());

    await tester.tap(find.text('Change'));
    await tester.pumpAndSettle();

    expect(find.text('For Abdullahi Yusuf'), findsOneWidget);
    expect(
      find.text('Admission number KCL/2026/0021 can’t be changed.'),
      findsOneWidget,
    );
    final save = find.widgetWithText(AppPrimaryButton, 'Save changes');
    expect(tester.widget<AppPrimaryButton>(save).isDisabled, isTrue);
    await tester.enterText(
      find.widgetWithText(TextField, 'Abdullahi'),
      'Abdullah',
    );
    await tester.pump();
    expect(tester.widget<AppPrimaryButton>(save).isDisabled, isFalse);
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(service.savedChanges?.firstName, 'Abdullah');
    expect(service.savedChanges?.lastName, 'Yusuf');
    expect(service.savedChanges?.bloodGroup, 'O+');
  });

  testWidgets('the Access card has no role and the student app row', (
    tester,
  ) async {
    await _pump(tester, abdullahi());

    expect(find.byType(AccessAppCard), findsOneWidget);
    expect(find.byType(AccessActionsCard), findsOneWidget);
  });
}
