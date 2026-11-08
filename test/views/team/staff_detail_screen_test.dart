import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hamrash_admin/api/models/organization_models/member_school.dart';
import 'package:hamrash_admin/api/models/organization_models/organization.dart';
import 'package:hamrash_admin/api/models/organization_models/organization_member.dart';
import 'package:hamrash_admin/api/models/team/staff_details_changes.dart';
import 'package:hamrash_admin/api/models/team/staff_member.dart';
import 'package:hamrash_admin/api/models/team/staff_private_details.dart';
import 'package:hamrash_admin/api/services/supabase_services/supabase_refusal.dart';
import 'package:hamrash_admin/api/services/supabase_services/team_service.dart';
import 'package:hamrash_admin/core/widgets/app_refresh_scroll_view.dart';
import 'package:hamrash_admin/core/widgets/app_section_action.dart';
import 'package:hamrash_admin/core/widgets/app_segmented_control.dart';
import 'package:hamrash_admin/core/widgets/app_text_field.dart';
import 'package:hamrash_admin/core/widgets/pickers/app_picker_field.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_variants.dart';
import 'package:hamrash_admin/singleton_locator/locator.dart';
import 'package:hamrash_admin/views/team/staff_detail/staff_detail_screen.dart';
import 'package:hamrash_admin/views/team/widgets/change_details_sheet.dart';
import 'package:hamrash_admin/views/team/widgets/choice_list_sheet.dart';
import 'package:hamrash_admin/views/team/widgets/contact_sheet.dart';
import 'package:hamrash_admin/views/team/widgets/staff_access_card.dart';
import 'package:hamrash_admin/views/team/widgets/staff_danger_action.dart';
import 'package:hamrash_admin/views/team/widgets/staff_details_card.dart';
import 'package:hamrash_admin/views/team/widgets/staff_detail_identity.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

/// Only the reads and the one save the page uses are implemented; everything
/// else would be a real database call, which these tests never make.
class _FakeTeam implements TeamService {
  _FakeTeam(this.member, {this.editRecord});

  final StaffMember member;
  ({StaffMember staff, StaffPrivateDetails privateDetails})? editRecord;

  Object? updateFailure;
  StaffMember? savedStaff;
  StaffPrivateDetails? savedPrivate;
  StaffDetailsChanges? savedChanges;
  String? changedRole;

  @override
  Future<StaffMember> getStaff(String staffId) async => member;

  @override
  Future<void> changeRole({
    required String memberId,
    required OrganizationMemberRole role,
  }) async {
    changedRole = role.value;
  }

  @override
  Future<({StaffMember staff, StaffPrivateDetails privateDetails})>
  getStaffForEditing(String staffId) async =>
      editRecord ??
      (staff: member, privateDetails: const StaffPrivateDetails());

  @override
  Future<StaffMember> updateStaffDetails({
    required StaffMember staff,
    required StaffPrivateDetails privateDetails,
    required StaffDetailsChanges changes,
  }) async {
    if (updateFailure case final error?) throw error;
    savedStaff = staff;
    savedPrivate = privateDetails;
    savedChanges = changes;
    return member;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Records the URI the page asks the phone to open.
class _FakeLauncher extends UrlLauncherPlatform {
  final List<String> opened = [];
  bool result = true;

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    opened.add(url);
    return result;
  }
}

StaffLogin _login({
  OrganizationMemberRole role = OrganizationMemberRole.teacher,
  OrganizationMemberStatus status = OrganizationMemberStatus.active,
  DateTime? joinedAt,
}) => StaffLogin(
  id: 'm1',
  role: role,
  status: status,
  joinedAt: joinedAt ?? DateTime(2026, 9, 3),
  createdAt: DateTime(2026, 9, 3),
);

StaffMember _member({
  String firstName = 'Tunde',
  String lastName = 'Ade',
  String? jobTitle = 'Teacher',
  String? staffNumber = 'KCL/STF/0001',
  String staffType = 'teaching',
  StaffRecordStatus status = StaffRecordStatus.active,
  String? phone = '+2348030000000',
  String? email = 'tunde@example.com',
  String? middleName,
  StaffGender? gender,
  String? photoId,
  String? photoUrl,
  StaffLogin? login,
}) => StaffMember(
  id: 's1',
  firstName: firstName,
  lastName: lastName,
  jobTitle: jobTitle,
  phone: phone,
  email: email,
  middleName: middleName,
  gender: gender,
  photoId: photoId,
  photoUrl: photoUrl,
  staffNumber: staffNumber,
  staffType: staffType,
  status: status,
  createdAt: DateTime(2026, 11, 8),
  memberId: login?.id,
  login: login,
);

MemberSchool _school({
  OrganizationMemberRole role = OrganizationMemberRole.owner,
  List<String> memberIds = const [],
}) => MemberSchool(
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
  memberIds: memberIds,
);

void main() {
  late _FakeLauncher launcher;
  late UrlLauncherPlatform originalLauncher;

  setUp(() {
    originalLauncher = UrlLauncherPlatform.instance;
    launcher = _FakeLauncher();
    UrlLauncherPlatform.instance = launcher;
  });

  tearDown(() {
    UrlLauncherPlatform.instance = originalLauncher;
    locator.reset();
  });

  Future<void> pump(
    WidgetTester tester,
    StaffMember member, {
    MemberSchool? school,
    _FakeTeam? team,
  }) async {
    locator.registerSingleton<TeamService>(team ?? _FakeTeam(member));
    await tester.pumpWidget(
      MaterialApp(
        home: StaffDetailScreen(
          school: school ?? _school(),
          staffId: member.id,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  AppPrimaryButton saveButton(WidgetTester tester) =>
      tester.widget<AppPrimaryButton>(
        find.widgetWithText(AppPrimaryButton, 'Save changes'),
      );

  Future<void> openChangeDetails(WidgetTester tester) async {
    await tester.tap(find.text('Change'));
    await tester.pumpAndSettle();
  }

  Finder field(String label) => find.descendant(
    of: find.widgetWithText(AppTextField, label),
    matching: find.byType(TextField),
  );

  testWidgets('not on the app: neutral state, invite block and empty details', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pump(
      tester,
      _member(
        jobTitle: 'Maths Teacher',
        staffNumber: null,
        staffType: 'non_teaching',
        phone: null,
        email: null,
      ),
    );

    expect(find.text('Not on app'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(StaffDetailIdentity),
        matching: find.text('Maths Teacher'),
      ),
      findsOneWidget,
    );
    expect(find.text('Invite to Hamrash'), findsOneWidget);
    expect(
      find.text('They get a code to join. It never expires.'),
      findsOneWidget,
    );
    expect(find.text("Tunde doesn't have a login yet"), findsNothing);

    // Details has only the two bands: staff number/type, phone/email.
    expect(find.text('Details'), findsOneWidget);
    expect(find.text('Job title'), findsNothing);
    expect(find.text('Record'), findsNothing);
    expect(find.text('Role'), findsNothing);
    expect(find.text('Staff type'), findsOneWidget);
    expect(find.text('Non-teaching'), findsOneWidget);
    expect(find.text('Staff no.'), findsOneWidget);
    expect(find.text('Not set'), findsOneWidget);
    expect(find.text('Not added'), findsNWidgets(2)); // phone and email
    expect(find.text('Phone'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(StaffDetailsCard),
        matching: find.text('Email'),
      ),
      findsOneWidget,
    );

    // One round contact button; no leftover action row.
    expect(
      tester.getSize(find.byKey(const ValueKey('staff-contact-button'))),
      const Size(44, 44),
    );
    expect(find.bySemanticsLabel('Contact Tunde'), findsOneWidget);
    expect(find.text('Call'), findsNothing);
    expect(find.text('Message'), findsNothing);

    expect(
      find.text('Remove from staff list', skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.text(
        'Their record is removed. Nothing else changes.',
        skipOffstage: false,
      ),
      findsOneWidget,
    );
    expect(launcher.opened, isEmpty);
    handle.dispose();
  });

  testWidgets('on the app: success pill, record and the Access card', (
    tester,
  ) async {
    await pump(tester, _member(login: _login()));

    expect(find.text('On app'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(StaffDetailIdentity),
        matching: find.text('Teacher'),
      ),
      findsOneWidget,
    );
    expect(find.text("Tunde doesn't have a login yet"), findsNothing);

    expect(find.text('KCL/STF/0001'), findsOneWidget);
    expect(find.text('0803 000 0000'), findsOneWidget);
    expect(find.text('tunde@example.com'), findsOneWidget);
    expect(find.text('Job title'), findsNothing);
    expect(find.text('Record'), findsNothing);
    expect(find.text('Role'), findsNothing);

    expect(find.text('Access'), findsOneWidget);
    expect(find.text('Joined 3 Sep'), findsOneWidget);
    expect(find.text('Change role'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(StaffAccessCard),
        matching: find.text('Teacher'),
      ),
      findsOneWidget,
    );
    expect(find.text('Suspend access'), findsOneWidget);
    expect(
      find.text("They stay on the list but can't sign in."),
      findsOneWidget,
    );

    expect(
      find.text('Remove from staff list', skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.text('Also removes their login.', skipOffstage: false),
      findsOneWidget,
    );
  });

  testWidgets('a suspended login reads in the error tone and offers restore', (
    tester,
  ) async {
    await pump(
      tester,
      _member(login: _login(status: OrganizationMemberStatus.suspended)),
    );

    expect(find.text('Suspended'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(StaffDetailIdentity),
        matching: find.text('Teacher'),
      ),
      findsOneWidget,
    );
    expect(find.text('Access'), findsOneWidget);
    expect(find.text('Joined 3 Sep'), findsOneWidget);
    expect(find.text('Restore access'), findsOneWidget);
    expect(find.text('They can sign in again.'), findsOneWidget);
  });

  testWidgets('a principal does not see the Access card', (tester) async {
    await pump(
      tester,
      _member(login: _login()),
      school: _school(role: OrganizationMemberRole.principal),
    );
    expect(find.text('Access'), findsNothing);
    expect(find.text('Change role'), findsNothing);
    expect(find.text('Change'), findsOneWidget);
    expect(find.byType(StaffDangerAction), findsNothing);
  });

  testWidgets("the owner's own record has no Access card", (tester) async {
    await pump(
      tester,
      _member(
        jobTitle: 'Owner',
        login: _login(role: OrganizationMemberRole.owner),
      ),
      school: _school(memberIds: ['m1']),
    );
    expect(find.text('On app'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(StaffDetailIdentity),
        matching: find.text('Owner'),
      ),
      findsOneWidget,
    );
    expect(find.text('Access'), findsNothing);
    expect(find.byType(StaffDangerAction), findsNothing);
  });

  Future<void> openContact(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('staff-contact-button')));
    await tester.pumpAndSettle();
  }

  Future<void> tapContactRow(WidgetTester tester, String label) async {
    await tester.tap(
      find.descendant(
        of: find.byType(ContactSheet),
        matching: find.text(label),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the contact sheet opens with all three ways to reach them', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pump(tester, _member(login: _login()));
    await openContact(tester);

    expect(find.byType(ContactSheet), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(ContactSheet),
        matching: find.text('Contact Tunde'),
      ),
      findsOneWidget,
    );
    expect(find.text('Teacher · Staff app'), findsOneWidget);
    final sheet = find.byType(ContactSheet);
    for (final label in ['Call', 'Message', 'Email']) {
      expect(
        find.descendant(of: sheet, matching: find.text(label)),
        findsOneWidget,
      );
    }
    expect(
      find.descendant(of: sheet, matching: find.text('0803 000 0000')),
      findsNWidgets(2),
    );
    expect(
      find.descendant(of: sheet, matching: find.text('tunde@example.com')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: sheet, matching: find.text('Not added')),
      findsNothing,
    );
    expect(find.bySemanticsLabel('Call Tunde, 0803 000 0000'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('contact rows launch tel, sms and mailto after closing', (
    tester,
  ) async {
    await pump(tester, _member(login: _login()));

    await openContact(tester);
    await tapContactRow(tester, 'Call');
    expect(launcher.opened, ['tel:+2348030000000']);
    expect(find.byType(ContactSheet), findsNothing);

    await openContact(tester);
    await tapContactRow(tester, 'Message');
    expect(launcher.opened.last, 'sms:+2348030000000');

    await openContact(tester);
    await tapContactRow(tester, 'Email');
    expect(launcher.opened.last, 'mailto:tunde@example.com');
  });

  testWidgets('a missing phone disables Call and Message only', (tester) async {
    await pump(tester, _member(login: _login(), phone: null));
    await openContact(tester);

    expect(
      find.descendant(
        of: find.byType(ContactSheet),
        matching: find.text('Not added'),
      ),
      findsNWidgets(2),
    );

    await tapContactRow(tester, 'Call');
    expect(launcher.opened, isEmpty);
    expect(find.byType(ContactSheet), findsOneWidget);

    await tapContactRow(tester, 'Message');
    expect(launcher.opened, isEmpty);
    expect(find.byType(ContactSheet), findsOneWidget);

    await tapContactRow(tester, 'Email');
    expect(launcher.opened, ['mailto:tunde@example.com']);
  });

  testWidgets('a missing email disables Email only', (tester) async {
    await pump(tester, _member(login: _login(), email: ''));
    await openContact(tester);

    expect(
      find.descendant(
        of: find.byType(ContactSheet),
        matching: find.text('Not added'),
      ),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Email Tunde, Not added'), findsOneWidget);

    await tapContactRow(tester, 'Email');
    expect(launcher.opened, isEmpty);
    expect(find.byType(ContactSheet), findsOneWidget);
  });

  testWidgets('the danger action is a pinned bottom bar', (tester) async {
    await pump(tester, _member(login: _login()));

    final danger = find.byType(StaffDangerAction);
    expect(danger, findsOneWidget);
    // The footer paints its own hairline, so the scaffold fade is off.
    expect(find.byKey(const ValueKey('bottom-bar-fade')), findsNothing);
    expect(find.byKey(const ValueKey('bottom-bar-surface')), findsOneWidget);
    // Inside the scaffold's bottom bar, not the scrolling page.
    expect(
      find.ancestor(of: danger, matching: find.byType(AppRefreshScrollView)),
      findsNothing,
    );
    expect(
      find.ancestor(of: danger, matching: find.byType(SafeArea)),
      findsWidgets,
    );
  });

  testWidgets('the details card has two bands of two columns', (tester) async {
    await pump(tester, _member(login: _login()));

    final card = tester.getRect(find.byType(StaffDetailsCard));
    for (final band in [1, 2]) {
      expect(
        tester.getSize(find.byKey(ValueKey('details-band-$band'))).height,
        56,
      );
      final divider = find.byKey(ValueKey('details-divider-$band'));
      expect(tester.getSize(divider).width, 1);
      expect(
        tester.getCenter(divider).dx,
        closeTo(card.center.dx, 1),
        reason: 'band $band divider must be exactly centred',
      );
    }
    expect(find.byKey(const ValueKey('details-hairline-1')), findsOneWidget);
  });

  testWidgets('the details header is 44 tall and Change is flush right', (
    tester,
  ) async {
    await pump(tester, _member(login: _login()));

    final header = find.byKey(const ValueKey('details-header'));
    expect(tester.getSize(header).height, 44);
    final action = find.byType(AppSectionAction);
    expect(tester.getSize(action).height, 44);
    expect(
      tester.getTopRight(action).dx,
      closeTo(tester.getTopRight(find.byType(StaffDetailsCard)).dx, 0.5),
    );
  });

  testWidgets('a non-leader has no Change button', (tester) async {
    await pump(
      tester,
      _member(login: _login()),
      school: _school(role: OrganizationMemberRole.teacher),
    );
    expect(find.text('Change'), findsNothing);
  });

  testWidgets('Change opens the details sheet for a leader', (tester) async {
    await pump(tester, _member(login: _login()));
    await openChangeDetails(tester);

    expect(find.byType(ChangeDetailsSheet), findsOneWidget);
    expect(find.text('Change details'), findsOneWidget);
    expect(find.text('For Tunde Ade'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(ChangeDetailsSheet),
        matching: find.text('Role'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('a record with no login has no Role row', (tester) async {
    final noLogin = _member(
      jobTitle: 'Teacher',
      staffNumber: null,
      staffType: 'non_teaching',
      phone: null,
      email: null,
    );
    await pump(tester, noLogin, team: _FakeTeam(noLogin));
    await openChangeDetails(tester);
    expect(
      find.descendant(
        of: find.byType(ChangeDetailsSheet),
        matching: find.text('Role'),
      ),
      findsNothing,
    );
  });

  testWidgets('a pending invite keeps its Role row', (tester) async {
    final pending = _member(
      login: _login(status: OrganizationMemberStatus.invited),
    );
    await pump(tester, pending, team: _FakeTeam(pending));
    await openChangeDetails(tester);
    expect(
      find.descendant(
        of: find.byType(ChangeDetailsSheet),
        matching: find.text('Role'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('Save waits for a change and a valid form', (tester) async {
    await pump(tester, _member(login: _login()));
    await openChangeDetails(tester);

    expect(saveButton(tester).isDisabled, isTrue);

    await tester.enterText(field('First name'), 'Tunde');
    await tester.pump();
    expect(saveButton(tester).isDisabled, isTrue);

    await tester.enterText(field('First name'), 'Chidi');
    await tester.pump();
    expect(saveButton(tester).isDisabled, isFalse);

    await tester.enterText(field('First name'), '');
    await tester.pump();
    expect(saveButton(tester).isDisabled, isTrue);
  });

  testWidgets('the sheet role changes immediately through the picker', (
    tester,
  ) async {
    final member = _member(login: _login());
    final service = _FakeTeam(member);
    await pump(tester, member, team: service);
    await openChangeDetails(tester);

    await tester.tap(find.text(OrganizationMemberRole.teacher.teamDescription));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('role-row-admin')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(AppPrimaryButton, 'Use Admin'));
    await tester.pumpAndSettle();

    expect(service.changedRole, 'admin');
    expect(
      find.descendant(
        of: find.byType(ChangeDetailsSheet),
        matching: find.text('Admin'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('saving sends the complete record with hidden fields intact', (
    tester,
  ) async {
    final member = _member(
      login: _login(),
      middleName: 'Chidi',
      gender: StaffGender.male,
      photoId: 'photo-1',
      photoUrl: 'https://example.com/tunde.jpg',
    );
    final privates = StaffPrivateDetails(
      dateOfBirth: DateTime(1990, 5, 1),
      address: '1 School Road',
      stateOfOrigin: 'Lagos',
      employmentDate: DateTime(2020, 9, 1),
      residenceState: 'Lagos',
      residenceLga: 'Ikeja',
    );
    final service = _FakeTeam(
      member,
      editRecord: (staff: member, privateDetails: privates),
    );
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pump(tester, member, team: service);
    await openChangeDetails(tester);

    // Prefilled from the staff row and private details.
    expect(
      tester
          .widget<AppPickerField>(find.widgetWithText(AppPickerField, 'State'))
          .valueText,
      'Lagos',
    );
    expect(
      tester
          .widget<AppPickerField>(find.widgetWithText(AppPickerField, 'LGA'))
          .valueText,
      'Ikeja',
    );
    expect(
      tester
          .widget<AppSegmentedControl<StaffGender>>(
            find.descendant(
              of: find.byType(ChangeDetailsSheet),
              matching: find.byType(AppSegmentedControl<StaffGender>),
            ),
          )
          .selected,
      StaffGender.male,
    );

    await tester.enterText(field('First name'), 'Chidi');
    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('change-middle-name')),
        matching: find.byType(TextField),
      ),
      'Emeka',
    );
    await tester.tap(find.text('Female'));
    await tester.pump();

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
    expect(
      tester
          .widget<AppPickerField>(find.widgetWithText(AppPickerField, 'LGA'))
          .valueText,
      isNull,
    );

    await tester.tap(find.widgetWithText(AppPickerField, 'LGA'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byType(ChoiceListSheet<String>),
        matching: find.byType(TextField),
      ),
      'Ibadan North',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ibadan North').last);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('change-address')),
        matching: find.byType(TextField),
      ),
      '9 New Road',
    );
    await tester.pump();
    await tester.tap(find.widgetWithText(AppPrimaryButton, 'Save changes'));
    await tester.pumpAndSettle();

    expect(service.savedChanges?.firstName, 'Chidi');
    expect(service.savedChanges?.middleName, 'Emeka');
    expect(service.savedChanges?.lastName, 'Ade');
    expect(service.savedChanges?.gender, StaffGender.female);
    expect(service.savedChanges?.jobTitle, 'Teacher');
    expect(service.savedChanges?.staffType, 'teaching');
    expect(service.savedChanges?.phone, '+2348030000000');
    expect(service.savedChanges?.email, 'tunde@example.com');
    expect(service.savedChanges?.address, '9 New Road');
    expect(service.savedChanges?.residenceState, 'Oyo');
    expect(service.savedChanges?.residenceLga, 'Ibadan North');
    expect(service.savedStaff?.middleName, 'Chidi');
    expect(service.savedStaff?.gender, StaffGender.male);
    expect(service.savedStaff?.photoId, 'photo-1');
    expect(service.savedStaff?.staffNumber, 'KCL/STF/0001');
    expect(service.savedPrivate?.address, '1 School Road');
    expect(service.savedPrivate?.stateOfOrigin, 'Lagos');
    expect(service.savedPrivate?.dateOfBirth, DateTime(1990, 5, 1));
    expect(service.savedPrivate?.employmentDate, DateTime(2020, 9, 1));
    expect(find.byType(ChangeDetailsSheet), findsNothing);
  });

  testWidgets('a refused save stays in the sheet with its message', (
    tester,
  ) async {
    const refusal = SupabaseRefusal(
      'Only the owner, admins, the principal and vice principals can change '
      'staff details.',
    );
    final member = _member(login: _login());
    final service = _FakeTeam(member)..updateFailure = refusal;
    await pump(tester, member, team: service);
    await openChangeDetails(tester);

    await tester.enterText(field('First name'), 'Chidi');
    await tester.pump();
    await tester.tap(find.widgetWithText(AppPrimaryButton, 'Save changes'));
    await tester.pumpAndSettle();

    expect(find.byType(ChangeDetailsSheet), findsOneWidget);
    expect(find.text(refusal.message), findsOneWidget);
  });

  Future<void> pumpAtWidth(
    WidgetTester tester,
    double width,
    StaffMember member,
  ) async {
    tester.view.physicalSize = Size(width, 844);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = FakeViewPadding.zero;
    addTearDown(tester.view.reset);
    await pump(tester, member);
  }

  testWidgets('long names and emails fit at 390', (tester) async {
    await pumpAtWidth(
      tester,
      390,
      _member(
        firstName: 'Chidinma-Adaeze',
        lastName: 'Okonkwo-Nwankwo',
        jobTitle: 'Vice principal',
        email: 'avery.long.email.address.for.one.teacher@example.school',
        login: _login(),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('long names and emails fit at 320', (tester) async {
    await pumpAtWidth(
      tester,
      320,
      _member(
        firstName: 'Chidinma-Adaeze',
        lastName: 'Okonkwo-Nwankwo',
        jobTitle: 'Vice principal',
        email: 'avery.long.email.address.for.one.teacher@example.school',
        login: _login(),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
