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
import 'package:hamrash_admin/core/widgets/app_cards.dart';
import 'package:hamrash_admin/core/widgets/app_divider.dart';
import 'package:hamrash_admin/core/widgets/app_refresh_scroll_view.dart';
import 'package:hamrash_admin/core/widgets/app_section_action.dart';
import 'package:hamrash_admin/core/widgets/app_segmented_control.dart';
import 'package:hamrash_admin/core/widgets/app_text_field.dart';
import 'package:hamrash_admin/core/widgets/pickers/app_date_fields.dart';
import 'package:hamrash_admin/core/widgets/pickers/app_picker_field.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_variants.dart';
import 'package:hamrash_admin/singleton_locator/locator.dart';
import 'package:hamrash_admin/views/team/staff_detail/staff_detail_screen.dart';
import 'package:hamrash_admin/views/team/widgets/change_details_sheet.dart';
import 'package:hamrash_admin/views/team/widgets/choice_list_sheet.dart';
import 'package:hamrash_admin/views/team/widgets/role_picker_sheet.dart';
import 'package:hamrash_admin/views/team/widgets/staff_form_fields.dart';
import 'package:hamrash_admin/views/team/widgets/staff_info_section.dart';
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
  OrganizationMemberRole? addedRole;
  Object? addFailure;

  @override
  Future<StaffMember> getStaff(String staffId) async => member;

  @override
  Future<StaffLogin> addMemberRole({
    required String memberId,
    required OrganizationMemberRole role,
  }) async {
    if (addFailure case final error?) throw error;
    addedRole = role;
    return StaffLogin(
      id: 'm-new',
      role: role,
      status: OrganizationMemberStatus.active,
      createdAt: DateTime(2026, 11, 11),
    );
  }

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
    if (tester.view.devicePixelRatio != 1) {
      tester.view.physicalSize = const Size(390, 1900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
    }
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

    expect(find.text('Not on app'), findsNWidgets(2));
    expect(find.text('Maths Teacher · Non-teaching'), findsOneWidget);
    expect(find.text('Hamrash Staff'), findsOneWidget);

    expect(find.text('Details'), findsOneWidget);
    expect(find.text('Staff number'), findsOneWidget);
    expect(find.text('Staff type'), findsOneWidget);
    expect(find.text('Non-teaching'), findsOneWidget);
    expect(find.text('Phone'), findsOneWidget);
    // Staff number, phone and email, plus the four Personal rows, have nothing.
    expect(find.text('Not added'), findsNWidgets(9));

    // The Access card holds the app row, the status action and remove for
    // someone never invited.
    expect(find.text('Access'), findsOneWidget);
    expect(find.text('Role'), findsNothing);
    expect(find.text('Suspend access'), findsNothing);

    // The three action circles are there, Call, Message and Email greyed.
    for (final label in ['Call', 'Message', 'Email']) {
      expect(find.text(label), findsWidgets);
    }
    expect(find.text('Contact'), findsNothing);

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
  });

  testWidgets('on the app: success pill, details, personal and Access', (
    tester,
  ) async {
    final member = _member(login: _login(), gender: StaffGender.female)
        .copyWith(
          privateDetails: StaffPrivateDetails(
            dateOfBirth: DateTime(1991, 3, 12),
            address: '14 Bode Thomas, Surulere, Lagos',
            stateOfOrigin: 'Imo',
            employmentDate: DateTime(2020, 9, 1),
            residenceState: 'Lagos',
            residenceLga: 'Ikeja',
          ),
        );
    await pump(tester, member);

    expect(find.text('On app'), findsNWidgets(2));
    expect(find.text('Teacher · Teaching'), findsOneWidget);

    expect(find.text('KCL/STF/0001'), findsOneWidget);
    expect(find.text('0803 000 0000'), findsOneWidget);
    expect(find.text('tunde@example.com'), findsOneWidget);

    expect(find.text('Personal'), findsOneWidget);
    expect(find.text('Only leaders see this'), findsOneWidget);
    expect(find.text('Date of birth'), findsOneWidget);
    expect(find.text('12 Mar 1991'), findsOneWidget);
    expect(find.text('Gender'), findsOneWidget);
    expect(find.text('Female'), findsOneWidget);
    expect(find.text('Lives in'), findsOneWidget);
    expect(find.text('Ikeja, Lagos'), findsOneWidget);
    expect(find.text('Home address'), findsOneWidget);
    expect(find.text('14 Bode Thomas, Surulere, Lagos'), findsOneWidget);
    expect(find.text('Not added'), findsNothing);
    // Status and employment date sit in Details; state of origin in Personal.
    expect(find.text('Status'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
    expect(find.text('Employed'), findsOneWidget);
    expect(find.text('1 Sep 2020'), findsOneWidget);
    expect(find.text('From'), findsOneWidget);
    expect(find.text('Imo'), findsOneWidget);

    // Teaching staff get the card with the session and their two rows.
    expect(find.widgetWithText(StaffSectionTitle, 'Teaching'), findsOneWidget);
    expect(find.text('Homeroom'), findsOneWidget);
    expect(find.text('Not assigned'), findsOneWidget);
    expect(find.text('Subjects · 0 this session'), findsOneWidget);
    expect(find.text('None this session'), findsOneWidget);

    expect(find.text('Access'), findsOneWidget);
    expect(find.text('Joined 3 Sep 2026'), findsOneWidget);
    expect(find.text('Hamrash Staff'), findsOneWidget);
    expect(find.text('Role'), findsOneWidget);
    expect(find.text('Teacher'), findsOneWidget);
    expect(find.text('Add role'), findsOneWidget);
    expect(find.text('Suspend access'), findsOneWidget);
    expect(
      find.text("They stay on the list but can't sign in."),
      findsOneWidget,
    );
    expect(find.text('Invite staff to Hamrash'), findsNothing);
    // Six Details rows and five Personal rows; the Access card draws its own.
    expect(find.byType(StaffInfoRow), findsNWidgets(11));

    expect(
      find.text('Remove from staff list', skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.text('Also removes their login.', skipOffstage: false),
      findsOneWidget,
    );
  });

  testWidgets('Personal shows the one residence part that is known', (
    tester,
  ) async {
    final member = _member(login: _login()).copyWith(
      privateDetails: const StaffPrivateDetails(residenceState: 'Lagos'),
    );
    await pump(tester, member);
    expect(find.text('Lagos'), findsOneWidget);
  });

  testWidgets('a long address wraps and right-aligns without overflow', (
    tester,
  ) async {
    final member = _member(login: _login()).copyWith(
      privateDetails: const StaffPrivateDetails(
        address:
            '22 Ogunlana Drive, Off Adeniran Ogunsanya Street, Surulere, Lagos',
      ),
    );
    await pump(tester, member);
    final address = find.textContaining('22 Ogunlana Drive');
    expect(tester.getSize(address).height, greaterThan(20));
    expect(tester.getSize(address).width, lessThanOrEqualTo(190));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a suspended login reads in the error tone and offers restore', (
    tester,
  ) async {
    await pump(
      tester,
      _member(login: _login(status: OrganizationMemberStatus.suspended)),
    );

    expect(find.text('Suspended'), findsNWidgets(2));
    expect(find.text('Access'), findsOneWidget);
    expect(find.text('Joined 3 Sep 2026'), findsOneWidget);
    expect(find.text('Restore access'), findsOneWidget);
    expect(find.text('They can sign in again.'), findsOneWidget);
  });

  testWidgets('a principal sees Personal but not the Access section', (
    tester,
  ) async {
    await pump(
      tester,
      _member(login: _login()),
      school: _school(role: OrganizationMemberRole.principal),
    );
    expect(find.text('Personal'), findsOneWidget);
    expect(find.text('Access'), findsNothing);
    expect(find.text('Role'), findsNothing);
    expect(find.text('Change'), findsOneWidget);
  });

  testWidgets("the owner's own record has no Access section", (tester) async {
    await pump(
      tester,
      _member(
        jobTitle: 'Owner',
        login: _login(role: OrganizationMemberRole.owner),
      ),
      school: _school(memberIds: ['m1']),
    );
    expect(find.text('On app'), findsOneWidget);
    expect(find.text('Owner · Teaching'), findsOneWidget);
    expect(find.text('Access'), findsNothing);
  });

  testWidgets('the Role row is display only', (tester) async {
    final member = _member(login: _login());
    final service = _FakeTeam(member);
    await pump(tester, member, team: service);

    await tester.tap(find.text('Role'));
    await tester.pumpAndSettle();

    expect(find.text('Change role'), findsNothing);
    expect(find.byType(RolePickerSheet), findsNothing);
    expect(service.changedRole, isNull);
  });

  testWidgets('Add role: pick, confirm, then it says so', (tester) async {
    final member = _member(login: _login());
    final service = _FakeTeam(member);
    await pump(tester, member, team: service);

    await tester.tap(find.byKey(const ValueKey('access-add-role')));
    await tester.pumpAndSettle();
    // 9.42: only roles they don't hold; never owner; nothing picked yet.
    expect(find.text('Add a role'), findsOneWidget);
    expect(find.text('Tunde Ade keeps Teacher.'), findsOneWidget);
    expect(find.byKey(const ValueKey('role-row-teacher')), findsNothing);
    expect(find.byKey(const ValueKey('role-row-owner')), findsNothing);
    expect(
      tester
          .widget<AppPrimaryButton>(
            find.widgetWithText(AppPrimaryButton, 'Continue'),
          )
          .isDisabled,
      isTrue,
    );
    await tester.tap(find.byKey(const ValueKey('role-row-bursar')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(AppPrimaryButton, 'Continue'));
    await tester.pumpAndSettle();

    // 9.43
    expect(find.text('Make Tunde a bursar too?'), findsOneWidget);
    expect(
      find.text('They get fees and school records in Hamrash Admin'),
      findsOneWidget,
    );
    expect(find.text('They stay Teacher'), findsOneWidget);
    await tester.tap(find.widgetWithText(AppPrimaryButton, 'Add bursar'));
    await tester.pumpAndSettle();

    // 9.44
    expect(service.addedRole, OrganizationMemberRole.bursar);
    expect(find.text('Tunde is a bursar too'), findsOneWidget);
  });

  testWidgets(
    'a refused Add role keeps the confirmation open with the reason',
    (tester) async {
      final member = _member(login: _login());
      final service = _FakeTeam(member)
        ..addFailure = const SupabaseRefusal(
          'They already have the bursar role at this school',
        );
      await pump(tester, member, team: service);

      await tester.tap(find.byKey(const ValueKey('access-add-role')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('role-row-bursar')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(AppPrimaryButton, 'Continue'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(AppPrimaryButton, 'Add bursar'));
      await tester.pumpAndSettle();

      expect(find.text('Make Tunde a bursar too?'), findsOneWidget);
      expect(
        find.text('They already have the bursar role at this school'),
        findsOneWidget,
      );
    },
  );

  testWidgets('Suspend access asks for confirmation', (tester) async {
    final member = _member(login: _login());
    final service = _FakeTeam(member);
    await pump(tester, member, team: service);

    await tester.tap(find.byKey(const ValueKey('access-toggle')));
    await tester.pumpAndSettle();
    expect(find.text("Suspend Tunde's access?"), findsOneWidget);
  });

  testWidgets('the action circles launch tel, sms and mailto', (tester) async {
    await pump(tester, _member(login: _login()));

    await tester.tap(find.byKey(const ValueKey('action-call')));
    await tester.tap(find.byKey(const ValueKey('action-message')));
    await tester.tap(find.byKey(const ValueKey('action-email')));
    await tester.pump();
    expect(launcher.opened, [
      'tel:+2348030000000',
      'sms:+2348030000000',
      'mailto:tunde@example.com',
    ]);
  });

  testWidgets('a missing phone or email greys the matching circles', (
    tester,
  ) async {
    await pump(tester, _member(login: _login(), phone: null, email: ''));

    await tester.tap(find.byKey(const ValueKey('action-call')));
    await tester.tap(find.byKey(const ValueKey('action-message')));
    await tester.tap(find.byKey(const ValueKey('action-email')));
    await tester.pump();
    expect(launcher.opened, isEmpty);
  });

  testWidgets('the page has no pinned bar; Remove lives in the Access card', (
    tester,
  ) async {
    await pump(tester, _member(login: _login()));

    expect(find.byKey(const ValueKey('bottom-bar-surface')), findsNothing);
    expect(find.byKey(const ValueKey('bottom-bar-fade')), findsNothing);

    final remove = find.text('Remove from staff list');
    expect(remove, findsOneWidget);
    // Inside the scrolling page and its white card, not a bottom bar.
    expect(
      find.ancestor(of: remove, matching: find.byType(AppRefreshScrollView)),
      findsOneWidget,
    );
    expect(
      find.ancestor(of: remove, matching: find.byType(AppCard)),
      findsOneWidget,
    );
  });

  testWidgets('the details header is 32 tall and Change is flush right', (
    tester,
  ) async {
    await pump(tester, _member(login: _login()));

    final header = find.byKey(const ValueKey('details-header'));
    expect(tester.getSize(header).height, 32);
    final action = find.byType(AppSectionAction);
    expect(
      tester.getTopRight(action).dx,
      closeTo(tester.getTopRight(header).dx, 0.5),
    );
  });

  testWidgets('rows are 52 tall inside the 16 gutter cards', (tester) async {
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pump(tester, _member(login: _login()));

    final rows = find.byType(StaffInfoRow);
    final first = tester.getRect(rows.first);
    // 16 screen gutter + 1 card border + 16 card padding.
    expect(first.left, 33);
    expect(first.width, 390 - 32 - 34);
    expect(first.height, 52);
    expect(find.byType(AppDivider), findsWidgets);
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
    expect(
      tester
          .widget<AppDateField>(
            find.widgetWithText(AppDateField, 'Date of birth'),
          )
          .value,
      DateTime(1990, 5, 1),
    );
    expect(find.text('1 May 1990'), findsOneWidget);
    expect(
      tester
          .widget<AppSegmentedControl<StaffRecordStatus>>(
            find.descendant(
              of: find.byType(ChangeDetailsSheet),
              matching: find.byType(AppSegmentedControl<StaffRecordStatus>),
            ),
          )
          .selected,
      StaffRecordStatus.active,
    );
    expect(
      tester
          .widget<AppDateField>(
            find.byWidgetPredicate(
              (widget) =>
                  widget is AppDateField && widget.label == 'Employment date',
            ),
          )
          .value,
      DateTime(2020, 9, 1),
    );
    expect(find.text('1 Sep 2020'), findsOneWidget);
    expect(
      tester.widget<StaffStateField>(find.byType(StaffStateField)).value,
      'Lagos',
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
    expect(service.savedChanges?.dateOfBirth, DateTime(1990, 5, 1));
    expect(service.savedChanges?.jobTitle, 'Teacher');
    expect(service.savedChanges?.staffType, 'teaching');
    expect(service.savedChanges?.phone, '+2348030000000');
    expect(service.savedChanges?.email, 'tunde@example.com');
    expect(service.savedChanges?.address, '9 New Road');
    expect(service.savedChanges?.residenceState, 'Oyo');
    expect(service.savedChanges?.residenceLga, 'Ibadan North');
    expect(service.savedChanges?.status, StaffRecordStatus.active);
    expect(service.savedChanges?.employmentDate, DateTime(2020, 9, 1));
    expect(service.savedChanges?.stateOfOrigin, 'Lagos');
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

  testWidgets('status and state of origin change and save', (tester) async {
    final member = _member(login: _login());
    final privates = StaffPrivateDetails(
      stateOfOrigin: 'Lagos',
      employmentDate: DateTime(2020, 9, 1),
    );
    final service = _FakeTeam(
      member,
      editRecord: (staff: member, privateDetails: privates),
    );
    tester.view.physicalSize = const Size(390, 1500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pump(tester, member, team: service);
    await openChangeDetails(tester);

    await tester.tap(find.text('On leave'));
    await tester.pump();
    await tester.tap(find.byType(StaffStateField));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byType(ChoiceListSheet<String>),
        matching: find.byType(TextField),
      ),
      'Imo',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Imo').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(AppPrimaryButton, 'Save changes'));
    await tester.pumpAndSettle();

    expect(service.savedChanges?.status, StaffRecordStatus.onLeave);
    expect(service.savedChanges?.stateOfOrigin, 'Imo');
    expect(service.savedChanges?.employmentDate, DateTime(2020, 9, 1));
  });

  testWidgets('marking someone exited asks for confirmation', (tester) async {
    final member = _member(login: _login());
    final service = _FakeTeam(member);
    tester.view.physicalSize = const Size(390, 1500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pump(tester, member, team: service);
    await openChangeDetails(tester);

    await tester.tap(find.text('Exited'));
    await tester.pump();
    await tester.tap(find.widgetWithText(AppPrimaryButton, 'Save changes'));
    await tester.pumpAndSettle();

    expect(find.text('Mark Tunde as exited?'), findsOneWidget);
    expect(find.textContaining('login is not removed'), findsOneWidget);
    expect(service.savedChanges, isNull);

    await tester.tap(find.widgetWithText(AppPrimaryButton, 'Mark as exited'));
    await tester.pumpAndSettle();
    expect(service.savedChanges?.status, StaffRecordStatus.exited);
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
    tester.view.physicalSize = Size(width, 2000);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = FakeViewPadding.zero;
    addTearDown(tester.view.reset);
    await pump(tester, member);
  }

  testWidgets('the app row starts the invite when there is no login', (
    tester,
  ) async {
    await pump(tester, _member());

    expect(find.text('Hamrash Staff'), findsOneWidget);
    await tester.tap(find.text('Hamrash Staff'));
    await tester.pumpAndSettle();

    expect(find.text('Invite staff to Hamrash'), findsOneWidget);
  });

  testWidgets('Change status saves the record status, not the login', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final member = _member(login: _login());
    final team = _FakeTeam(member);
    await pump(tester, member, team: team);

    await tester.ensureVisible(find.text('Change status'));
    await tester.tap(find.text('Change status'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('On leave'));
    await tester.pumpAndSettle();
    // The floating sheet's footer sits at the bottom of the tall test view;
    // fire the button directly rather than hit-testing that edge.
    tester
        .widget<AppPrimaryButton>(
          find.widgetWithText(AppPrimaryButton, 'Save status'),
        )
        .onPressed!();
    await tester.pumpAndSettle();

    expect(team.savedChanges?.status, StaffRecordStatus.onLeave);
    expect(team.changedRole, isNull);
  });

  testWidgets('long names, emails and addresses fit at 390', (tester) async {
    await pumpAtWidth(
      tester,
      390,
      _member(
        firstName: 'Chidinma-Adaeze',
        lastName: 'Okonkwo-Nwankwo',
        jobTitle: 'Vice principal',
        email: 'avery.long.email.address.for.one.teacher@example.school',
        login: _login(),
      ).copyWith(
        privateDetails: const StaffPrivateDetails(
          address:
              '22 Ogunlana Drive, Off Adeniran Ogunsanya Street, Surulere, '
              'Lagos',
          residenceLga: 'Ibadan North-East',
          residenceState: 'Akwa Ibom',
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('long names, emails and addresses fit at 320', (tester) async {
    await pumpAtWidth(
      tester,
      320,
      _member(
        firstName: 'Chidinma-Adaeze',
        lastName: 'Okonkwo-Nwankwo',
        jobTitle: 'Vice principal',
        email: 'avery.long.email.address.for.one.teacher@example.school',
        login: _login(),
      ).copyWith(
        privateDetails: const StaffPrivateDetails(
          address:
              '22 Ogunlana Drive, Off Adeniran Ogunsanya Street, Surulere, '
              'Lagos',
          residenceLga: 'Ibadan North-East',
          residenceState: 'Akwa Ibom',
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
