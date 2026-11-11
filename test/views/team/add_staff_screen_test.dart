import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hamrash_admin/api/models/organization_models/member_school.dart';
import 'package:hamrash_admin/api/models/organization_models/organization.dart';
import 'package:hamrash_admin/api/models/organization_models/organization_member.dart';
import 'package:hamrash_admin/api/models/team/staff_member.dart';
import 'package:hamrash_admin/api/services/supabase_services/team_service.dart';
import 'package:hamrash_admin/core/widgets/app_segmented_control.dart';
import 'package:hamrash_admin/core/widgets/pickers/app_picker_field.dart';
import 'package:hamrash_admin/singleton_locator/locator.dart';
import 'package:hamrash_admin/views/team/add_staff/add_staff_screen.dart';
import 'package:hamrash_admin/views/team/widgets/choice_list_sheet.dart';

class _FakeTeam implements TeamService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final _school = MemberSchool(
  organization: Organization(
    id: 'kings',
    name: 'Kings College',
    status: OrganizationStatus.trial,
    createdBy: 'platform',
    numberPrefix: 'KCL',
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  ),
  roles: const [OrganizationMemberRole.owner],
);

void main() {
  setUp(() {
    locator.registerSingleton<TeamService>(_FakeTeam());
    addTearDown(locator.reset);
  });

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(home: AddStaffScreen(school: _school)));
    await tester.pumpAndSettle();
  }

  AppPickerField picker(WidgetTester tester, String label) =>
      tester.widget<AppPickerField>(find.widgetWithText(AppPickerField, label));

  testWidgets('shows the new optional sections', (tester) async {
    await pump(tester);

    expect(find.text('Name'), findsOneWidget);
    expect(find.text('About them'), findsOneWidget);
    expect(find.text('Where they live'), findsOneWidget);
    expect(find.text('Reach them'), findsOneWidget);
    expect(find.textContaining('Middle name'), findsOneWidget);
    expect(find.text('Gender'), findsOneWidget);
    expect(find.text('State'), findsOneWidget);
    expect(find.text('LGA'), findsOneWidget);
    expect(find.text('Home address'), findsOneWidget);
    expect(find.text('Date of birth'), findsOneWidget);
    expect(find.textContaining('Employment date'), findsOneWidget);
    expect(find.text('State of origin'), findsOneWidget);
    expect(find.text('Choose a state first'), findsOneWidget);

    final gender = tester.widget<AppSegmentedControl<StaffGender>>(
      find.byType(AppSegmentedControl<StaffGender>),
    );
    expect(gender.selected, isNull);
    expect(find.text('Date of birth'), findsOneWidget);
  });

  testWidgets('LGA waits for a state and a new state clears it', (
    tester,
  ) async {
    await pump(tester);

    expect(picker(tester, 'LGA').enabled, isFalse);

    await tester.tap(find.widgetWithText(AppPickerField, 'State'));
    await tester.pumpAndSettle();
    expect(find.text('Choose a state'), findsOneWidget);
    expect(find.text('Search states'), findsOneWidget);
    await tester.enterText(
      find.descendant(
        of: find.byType(ChoiceListSheet<String>),
        matching: find.byType(TextField),
      ),
      'Lagos',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lagos').last);
    await tester.pumpAndSettle();

    expect(picker(tester, 'State').valueText, 'Lagos');
    expect(picker(tester, 'LGA').enabled, isTrue);

    await tester.tap(find.widgetWithText(AppPickerField, 'LGA'));
    await tester.pumpAndSettle();
    expect(find.text('Choose an LGA'), findsOneWidget);
    await tester.enterText(
      find.descendant(
        of: find.byType(ChoiceListSheet<String>),
        matching: find.byType(TextField),
      ),
      'Ikeja',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ikeja').last);
    await tester.pumpAndSettle();
    expect(picker(tester, 'LGA').valueText, 'Ikeja');

    await tester.tap(find.widgetWithText(AppPickerField, 'State'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byType(ChoiceListSheet<String>),
        matching: find.byType(TextField),
      ),
      'Oyo',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Oyo').last);
    await tester.pumpAndSettle();

    expect(picker(tester, 'State').valueText, 'Oyo');
    expect(picker(tester, 'LGA').valueText, isNull);
  });

  testWidgets('the staff type waits for a job title', (tester) async {
    await pump(tester);

    expect(find.text('Staff type'), findsOneWidget);
    expect(picker(tester, 'Staff type').enabled, isFalse);
    expect(picker(tester, 'Staff type').valueText, isNull);
    expect(find.text('Choose a job title first'), findsOneWidget);
  });

  testWidgets('a job title fills the staff type in', (tester) async {
    await pump(tester);

    await tester.tap(find.widgetWithText(AppPickerField, 'Job title'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Teacher').last);
    await tester.pumpAndSettle();

    expect(picker(tester, 'Staff type').enabled, isTrue);
    expect(picker(tester, 'Staff type').valueText, 'Teaching');
    expect(find.text('Choose a job title first'), findsNothing);

    await tester.tap(find.widgetWithText(AppPickerField, 'Job title'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bursar').last);
    await tester.pumpAndSettle();

    expect(picker(tester, 'Staff type').valueText, 'Non-teaching');
  });

  testWidgets('a picked staff type survives a job title change', (
    tester,
  ) async {
    await pump(tester);

    await tester.tap(find.widgetWithText(AppPickerField, 'Job title'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Admin').last);
    await tester.pumpAndSettle();
    expect(picker(tester, 'Staff type').valueText, 'Non-teaching');

    await tester.tap(find.widgetWithText(AppPickerField, 'Staff type'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Teaching').last);
    await tester.pumpAndSettle();
    expect(picker(tester, 'Staff type').valueText, 'Teaching');

    await tester.tap(find.widgetWithText(AppPickerField, 'Job title'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bursar').last);
    await tester.pumpAndSettle();

    expect(picker(tester, 'Staff type').valueText, 'Teaching');
  });
}
