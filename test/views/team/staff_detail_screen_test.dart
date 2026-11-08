import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hamrash_admin/api/models/organization_models/member_school.dart';
import 'package:hamrash_admin/api/models/organization_models/organization.dart';
import 'package:hamrash_admin/api/models/organization_models/organization_member.dart';
import 'package:hamrash_admin/api/models/team/staff_member.dart';
import 'package:hamrash_admin/api/services/supabase_services/team_service.dart';
import 'package:hamrash_admin/core/widgets/app_refresh_scroll_view.dart';
import 'package:hamrash_admin/core/widgets/app_svg_icon.dart';
import 'package:hamrash_admin/singleton_locator/locator.dart';
import 'package:hamrash_admin/views/team/staff_detail/staff_detail_screen.dart';
import 'package:hamrash_admin/views/team/widgets/quick_action_pill.dart';
import 'package:hamrash_admin/views/team/widgets/staff_access_card.dart';
import 'package:hamrash_admin/views/team/widgets/staff_danger_action.dart';
import 'package:hamrash_admin/views/team/widgets/staff_details_card.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

/// Only `getStaff` is used by the page; everything else would be a real
/// database call, which these tests never make.
class _FakeTeam implements TeamService {
  _FakeTeam(this.member);

  final StaffMember member;

  @override
  Future<StaffMember> getStaff(String staffId) async => member;

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
  String? jobTitle = 'Teacher',
  String? staffNumber = 'KCL/STF/0001',
  String staffType = 'teaching',
  StaffRecordStatus status = StaffRecordStatus.active,
  String? phone = '+2348030000000',
  String? email = 'tunde@example.com',
  StaffLogin? login,
}) => StaffMember(
  id: 's1',
  firstName: firstName,
  lastName: 'Ade',
  jobTitle: jobTitle,
  phone: phone,
  email: email,
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
  }) async {
    locator.registerSingleton<TeamService>(_FakeTeam(member));
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

  QuickActionPill action(WidgetTester tester, String label) =>
      tester.widget<QuickActionPill>(
        find.widgetWithText(QuickActionPill, label),
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
    expect(find.text('Maths Teacher · Staff app'), findsOneWidget);
    expect(find.text("Tunde doesn't have a login yet"), findsOneWidget);
    expect(find.text('Invite to Hamrash'), findsOneWidget);

    // Details: the missing number and contact rows read as placeholders.
    expect(find.text('Details'), findsOneWidget);
    expect(find.text('Job title'), findsOneWidget);
    expect(find.text('Maths Teacher'), findsOneWidget);
    expect(find.text('Staff type'), findsOneWidget);
    expect(find.text('Non-teaching'), findsOneWidget);
    expect(find.text('Staff no.'), findsOneWidget);
    expect(find.text('Not set'), findsOneWidget);
    expect(find.text('Record'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
    expect(find.text('Not added'), findsNWidgets(2)); // phone and email
    expect(find.text('Phone'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(StaffDetailsCard),
        matching: find.text('Email'),
      ),
      findsOneWidget,
    );

    // All three actions stay visible but cannot open anything.
    expect(action(tester, 'Call').onTap, isNull);
    expect(action(tester, 'Message').onTap, isNull);
    expect(action(tester, 'Email').onTap, isNull);
    expect(find.bySemanticsLabel('Call Tunde'), findsOneWidget);
    expect(find.bySemanticsLabel('Message Tunde'), findsOneWidget);
    expect(find.bySemanticsLabel('Email Tunde'), findsOneWidget);

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
    expect(find.text('Teacher · joined 3 Sep'), findsOneWidget);
    expect(find.text("Tunde doesn't have a login yet"), findsNothing);

    expect(find.text('KCL/STF/0001'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
    expect(find.text('+2348030000000'), findsOneWidget);
    expect(find.text('tunde@example.com'), findsOneWidget);

    expect(find.text('Access'), findsOneWidget);
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
      _member(
        login: _login(status: OrganizationMemberStatus.suspended),
      ),
    );

    expect(find.text('Suspended'), findsOneWidget);
    expect(find.text('Teacher · access suspended'), findsOneWidget);
    expect(find.text('Access'), findsOneWidget);
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
    expect(find.text('Owner · you'), findsOneWidget);
    expect(find.text('Access'), findsNothing);
    expect(find.byType(StaffDangerAction), findsNothing);
  });

  testWidgets('quick actions open tel, sms and mailto', (tester) async {
    await pump(tester, _member(login: _login()));

    expect(action(tester, 'Call').onTap, isNotNull);
    expect(action(tester, 'Message').onTap, isNotNull);
    expect(action(tester, 'Email').onTap, isNotNull);

    await tester.tap(find.text('Call'));
    await tester.pump();
    expect(launcher.opened, ['tel:+2348030000000']);

    await tester.tap(find.text('Message'));
    await tester.pump();
    expect(launcher.opened.last, 'sms:+2348030000000');

    await tester.tap(find.widgetWithText(QuickActionPill, 'Email'));
    await tester.pump();
    expect(launcher.opened.last, 'mailto:tunde@example.com');
  });

  testWidgets('an empty address disables Email only', (tester) async {
    await pump(tester, _member(login: _login(), email: ''));

    expect(action(tester, 'Call').onTap, isNotNull);
    expect(action(tester, 'Message').onTap, isNotNull);
    expect(action(tester, 'Email').onTap, isNull);

    await tester.tap(find.widgetWithText(QuickActionPill, 'Email'));
    await tester.pump();
    expect(launcher.opened, isEmpty);
  });

  testWidgets('quick actions share equal widths and a centre line', (
    tester,
  ) async {
    await pump(tester, _member(login: _login()));

    const labels = ['Call', 'Message', 'Email'];
    final widths = [
      for (final label in labels)
        tester.getSize(find.widgetWithText(QuickActionPill, label)).width,
    ];
    expect(widths[0], closeTo(widths[1], 0.01));
    expect(widths[1], closeTo(widths[2], 0.01));

    for (final label in labels) {
      final pill = find.widgetWithText(QuickActionPill, label);
      final icon = find.descendant(
        of: pill,
        matching: find.byType(AppSvgIcon),
      );
      final text = find.descendant(of: pill, matching: find.text(label));
      expect(
        (tester.getCenter(icon).dy - tester.getCenter(text).dy).abs(),
        lessThanOrEqualTo(0.5),
        reason: '$label icon should sit on the label centre line',
      );
    }
  });

  testWidgets('the danger action is a pinned bottom bar', (tester) async {
    await pump(tester, _member(login: _login()));

    final danger = find.byType(StaffDangerAction);
    expect(danger, findsOneWidget);
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

  testWidgets('the details grid splits the card exactly in half', (
    tester,
  ) async {
    await pump(tester, _member(login: _login()));

    final card = find.byType(StaffDetailsCard);
    final divider = find.byKey(const ValueKey('details-vertical-divider'));
    expect(divider, findsNWidgets(3));
    for (var i = 0; i < 3; i++) {
      expect(tester.getSize(divider.at(i)).width, 1);
      expect(
        tester.getCenter(divider.at(i)).dx,
        closeTo(tester.getCenter(card).dx, 0.5),
      );
    }
  });
}
