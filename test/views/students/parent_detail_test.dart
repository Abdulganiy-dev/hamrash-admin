import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hamrash_admin/api/models/organization_models/organization_member.dart';
import 'package:hamrash_admin/api/models/students/parent_profile.dart';
import 'package:hamrash_admin/api/services/supabase_services/supabase_refusal.dart';
import 'package:hamrash_admin/core/widgets/app_alert_dialog.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_variants.dart';
import 'package:hamrash_admin/views/students/parent_detail/parent_detail_screen.dart';
import 'package:hamrash_admin/views/students/parent_detail/parent_detail_view_model.dart';
import 'package:hamrash_admin/views/team/widgets/access_card.dart';

import 'student_detail_fakes.dart';

ParentDetailViewModel _model(
  FakeStudents service, {
  OrganizationMemberRole role = OrganizationMemberRole.admin,
}) => ParentDetailViewModel(
  school: schoolFor(role),
  parentId: 'p1',
  students: service,
);

Future<(ParentDetailViewModel, FakeStudents)> _loaded(
  ParentProfile parent, {
  OrganizationMemberRole role = OrganizationMemberRole.admin,
}) async {
  final service = FakeStudents(abdullahi())..parent = parent;
  final model = _model(service, role: role);
  await model.load();
  return (model, service);
}

Future<FakeStudents> _pump(
  WidgetTester tester,
  ParentProfile parent, {
  OrganizationMemberRole role = OrganizationMemberRole.admin,
}) async {
  tester.view.physicalSize = const Size(800, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final service = FakeStudents(abdullahi())..parent = parent;
  await tester.pumpWidget(
    MaterialApp(
      home: ParentDetailScreen(
        school: schoolFor(role),
        parentId: 'p1',
        viewModel: _model(service, role: role),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return service;
}

void main() {
  group('ParentDetailViewModel', () {
    test('reads like the design', () async {
      final (model, _) = await _loaded(parentFixture());

      expect(model.parent.displayName, 'Mrs Halima Yusuf');
      expect(model.identityMeta, 'Parent of 2 · Pharmacist');
      expect(model.statusLabel, 'Not on app');
      expect(model.phoneLabel, '0803 445 1290');
      expect(model.parent.children.first.caption, 'JSS 1B · Primary contact');
      expect(model.parent.children.last.caption, 'Primary 4A');
    });

    test('a parent with no children', () async {
      final (model, _) = await _loaded(
        parentFixture(children: false).copyWith(),
      );
      expect(model.identityMeta, 'No children yet · Pharmacist');
    });

    test('the Access card is one app, in each state', () async {
      final states = {
        null: (AccessState.notOnApp, null),
        loginWith(OrganizationMemberStatus.invited, code: 'R4TB8KXW'): (
          AccessState.codeReady,
          'Invited 8 Nov',
        ),
        loginWith(OrganizationMemberStatus.active): (
          AccessState.onApp,
          'Joined 3 Sep 2026',
        ),
        loginWith(OrganizationMemberStatus.suspended): (
          AccessState.suspended,
          'Joined 3 Sep 2026',
        ),
      };
      for (final entry in states.entries) {
        final (model, _) = await _loaded(parentFixture(login: entry.key));
        final apps = model.accessApps();
        expect(apps.single.appName, 'Hamrash Student');
        expect(apps.single.roles, isEmpty);
        expect(apps.single.state, entry.value.$1);
        expect(model.accessCaption, entry.value.$2);
      }
    });

    test('who may do what', () async {
      final (admin, _) = await _loaded(parentFixture());
      expect(admin.canEdit, isTrue);
      expect(admin.canManageAccess, isTrue);
      expect(admin.canInvite, isTrue);

      final (principal, _) = await _loaded(
        parentFixture(),
        role: OrganizationMemberRole.principal,
      );
      expect(principal.canEdit, isTrue);
      expect(principal.canManageAccess, isFalse);

      final (bursar, _) = await _loaded(
        parentFixture(),
        role: OrganizationMemberRole.bursar,
      );
      expect(bursar.canEdit, isFalse);
    });

    test('saving details sends them and marks the page changed', () async {
      final (model, service) = await _loaded(parentFixture());

      final error = await model.saveDetails(
        ParentDetailsChanges.of(model.parent),
      );

      expect(error, isNull);
      expect(service.savedParent?.phone, '+2348034451290');
      expect(model.changed, isTrue);
    });

    test('a refused save returns the reason', () async {
      final (model, service) = await _loaded(parentFixture());
      service.failWith = const SupabaseRefusal(
        'A parent with this phone number is already at the school.',
      );

      expect(
        await model.saveDetails(ParentDetailsChanges.of(model.parent)),
        'A parent with this phone number is already at the school.',
      );
    });

    test('the invite returns the code and the message', () async {
      final (model, service) = await _loaded(parentFixture());

      final result = await model.invite();

      expect(service.invitedParentId, 'p1');
      expect(result.code, 'R4TB8KXW');
      expect(
        model.shareMessage('R4TB8KXW'),
        'Hi Halima, Kings College has added you on Hamrash. Open the Hamrash '
        'student app, sign in with Apple or Google, and enter R4TB-8KXW.',
      );
    });

    test('removing says what goes and closes the page', () async {
      final (model, service) = await _loaded(
        parentFixture(login: loginWith(OrganizationMemberStatus.active)),
      );

      expect(model.removeTitle, 'Remove Mrs Halima Yusuf?');
      expect(model.removeBullets, [
        'Their record and their link to 2 children are removed',
        'Their login stops working',
      ]);

      await model.remove();

      expect(service.removedParentId, 'p1');
      expect(model.removed, isTrue);
    });

    test('a refused removal or suspend throws for the confirm sheet', () async {
      final (model, service) = await _loaded(
        parentFixture(login: loginWith(OrganizationMemberStatus.active)),
      );
      service.failWith = const SupabaseRefusal(
        'Only the owner and admins can do this.',
      );

      await expectLater(model.remove(), throwsA(isA<AppAlertError>()));
      await expectLater(
        model.setSuspended(true),
        throwsA(isA<AppAlertError>()),
      );
      expect(model.removed, isFalse);
    });
  });

  group('ParentDetailScreen', () {
    testWidgets('a leader sees children, details and access', (tester) async {
      await _pump(tester, parentFixture());

      expect(find.text('Mrs Halima Yusuf'), findsOneWidget);
      expect(find.text('Parent of 2 · Pharmacist'), findsOneWidget);
      expect(
        find.text('Not on app'),
        findsNWidgets(2),
      ); // the pill and the card
      expect(find.text('Children'), findsOneWidget);
      expect(find.text('Abdullahi Yusuf'), findsOneWidget);
      expect(find.text('JSS 1B · Primary contact'), findsOneWidget);
      expect(find.text('Aisha Yusuf'), findsOneWidget);
      expect(find.text('Primary 4A'), findsOneWidget);
      expect(find.text('Details'), findsOneWidget);
      expect(find.text('0803 445 1290'), findsOneWidget);
      expect(find.text('halima.y@gmail.com'), findsOneWidget);
      expect(find.text('Pharmacist'), findsWidgets);
      expect(find.text('22 Ahmadu Bello Way, Victoria Island'), findsOneWidget);
      expect(find.text('Access'), findsOneWidget);
      expect(find.text('Hamrash Student'), findsOneWidget);
      expect(find.text('Remove parent'), findsOneWidget);
      expect(
        find.text(
          'Only for a mistake. Removes their record and their links to their '
          'children.',
        ),
        findsOneWidget,
      );
      expect(find.byType(AccessAppCard), findsOneWidget);
    });

    testWidgets('on the app: suspend and remove with the login line', (
      tester,
    ) async {
      await _pump(
        tester,
        parentFixture(login: loginWith(OrganizationMemberStatus.active)),
      );

      expect(find.text('On app'), findsNWidgets(2));
      expect(find.text('Joined 3 Sep 2026'), findsOneWidget);
      expect(find.text('Suspend access'), findsOneWidget);
      expect(
        find.text('Only for a mistake. Removes their record, links and login.'),
        findsOneWidget,
      );
    });

    testWidgets('a bursar reads children and details only', (tester) async {
      await _pump(tester, parentFixture(), role: OrganizationMemberRole.bursar);

      expect(find.text('Children'), findsOneWidget);
      expect(find.text('Details'), findsOneWidget);
      expect(find.text('Access'), findsNothing);
      expect(find.text('Change'), findsNothing);
    });

    testWidgets('tapping Not on app makes the invite', (tester) async {
      final service = await _pump(tester, parentFixture());

      await tester.tap(find.text('Not on app').last);
      await tester.pumpAndSettle();

      expect(service.invitedParentId, 'p1');
      expect(find.text("Halima's invite is ready"), findsOneWidget);
    });

    testWidgets('Change details opens with their values and saves', (
      tester,
    ) async {
      final service = await _pump(tester, parentFixture());

      await tester.tap(find.text('Change'));
      await tester.pumpAndSettle();

      expect(find.text('For Mrs Halima Yusuf'), findsOneWidget);
      final save = find.widgetWithText(AppPrimaryButton, 'Save changes');
      expect(tester.widget<AppPrimaryButton>(save).isDisabled, isTrue);
      await tester.enterText(
        find.widgetWithText(TextField, 'Pharmacist'),
        'Doctor',
      );
      await tester.pump();
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();

      expect(service.savedParent?.occupation, 'Doctor');
      expect(service.savedParent?.firstName, 'Halima');
      expect(service.savedParent?.phone, '+2348034451290');
    });

    testWidgets('Remove parent asks first and says what goes', (tester) async {
      final service = await _pump(tester, parentFixture());

      await tester.tap(find.text('Remove parent'));
      await tester.pumpAndSettle();

      expect(find.text('Remove Mrs Halima Yusuf?'), findsOneWidget);
      expect(
        find.text('Their record and their link to 2 children are removed'),
        findsOneWidget,
      );
      expect(service.removedParentId, isNull);
    });
  });
}
