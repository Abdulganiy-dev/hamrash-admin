import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hamrash_admin/core/widgets/app_divider.dart';
import 'package:hamrash_admin/api/models/organization_models/member_school.dart';
import 'package:hamrash_admin/api/models/organization_models/organization.dart';
import 'package:hamrash_admin/api/models/organization_models/organization_member.dart';
import 'package:hamrash_admin/api/models/team/staff_member.dart';
import 'package:hamrash_admin/api/services/supabase_services/team_service.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/widgets/app_badge.dart';
import 'package:hamrash_admin/core/widgets/app_cards.dart';
import 'package:hamrash_admin/core/widgets/app_empty_state.dart';
import 'package:hamrash_admin/core/widgets/app_list_row.dart';
import 'package:hamrash_admin/core/widgets/app_shimmer.dart';
import 'package:hamrash_admin/core/widgets/app_icons.dart';
import 'package:hamrash_admin/singleton_locator/locator.dart';
import 'package:hamrash_admin/views/team/team_screen.dart';
import 'package:hamrash_admin/views/team/widgets/staff_avatar.dart';
import 'package:hamrash_admin/views/team/widgets/staff_list_card.dart';
import 'package:hamrash_admin/views/team/widgets/team_skeleton.dart';

/// Only `listStaff` is used by the list; everything else would be a real
/// database call, which these tests never make.
class _FakeTeam implements TeamService {
  _FakeTeam(this.people);

  List<StaffMember> people;

  /// Set to keep the page in its loading state until the test completes it.
  Completer<List<StaffMember>>? pending;

  @override
  Future<List<StaffMember>> listStaff(String organizationId) =>
      pending?.future ?? Future.value([...people]);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

StaffLogin _login({
  String id = 'm1',
  OrganizationMemberRole role = OrganizationMemberRole.teacher,
  OrganizationMemberStatus status = OrganizationMemberStatus.invited,
  String? code = 'K7M2QX9P',
  DateTime? joinedAt,
  DateTime? createdAt,
}) => StaffLogin(
  id: id,
  role: role,
  status: status,
  claimCode: code,
  joinedAt: joinedAt,
  createdAt: createdAt ?? DateTime(2026, 11, 5),
);

StaffMember _staff({
  required String id,
  required String firstName,
  String lastName = 'Okafor',
  String? jobTitle,
  DateTime? createdAt,
  StaffLogin? login,
}) => StaffMember(
  id: id,
  firstName: firstName,
  lastName: lastName,
  jobTitle: jobTitle,
  phone: '+2348030000000',
  staffType: 'non_teaching',
  status: StaffRecordStatus.active,
  createdAt: createdAt ?? DateTime(2026, 11, 8),
  memberId: login?.id,
  login: login,
);

final _owner = _staff(
  id: 'own',
  firstName: 'Amina',
  lastName: 'Bello',
  jobTitle: 'Owner',
  login: _login(
    id: 'm-owner',
    role: OrganizationMemberRole.owner,
    status: OrganizationMemberStatus.active,
    code: null,
    joinedAt: DateTime(2026, 9, 3),
  ),
);

final _admin = _staff(
  id: 'adm',
  firstName: 'Chidi',
  lastName: 'Eze',
  jobTitle: 'Admin',
  login: _login(
    id: 'm-admin',
    role: OrganizationMemberRole.admin,
    status: OrganizationMemberStatus.active,
    code: null,
    joinedAt: DateTime(2026, 9, 3),
  ),
);

final _bursar = _staff(
  id: 'bur',
  firstName: 'Ada',
  lastName: 'Nwosu',
  jobTitle: 'Bursar',
  login: _login(id: 'm-bursar', role: OrganizationMemberRole.bursar),
);

final _teacher = _staff(
  id: 'tch',
  firstName: 'Tunde',
  lastName: 'Ade',
  jobTitle: 'Teacher',
);

final _allStaff = [_owner, _admin, _bursar, _teacher];

MemberSchool _school() => MemberSchool(
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
  memberIds: const ['m-owner'],
);

Future<void> _pumpTeam(WidgetTester tester, _FakeTeam service) async {
  locator.registerSingleton<TeamService>(service);
  addTearDown(locator.reset);

  await tester.pumpWidget(MaterialApp(home: TeamScreen(school: _school())));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('all staff sit in one card, one hairline apart', (tester) async {
    await _pumpTeam(tester, _FakeTeam(_allStaff));

    expect(find.byType(StaffListCard), findsOneWidget);
    expect(find.byType(AppCard), findsOneWidget);
    expect(find.byType(StaffListDivider), findsNWidgets(_allStaff.length - 1));

    // Faint (stone-50), inset to the text column: 16 + 44 avatar + 12 = 72.
    final divider = find.byType(StaffListDivider).first;
    final fill = tester.widget<ColoredBox>(
      find.descendant(of: divider, matching: find.byType(ColoredBox)),
    );
    expect(fill.color, AppDivider.faint);
    final box = tester.getRect(divider);
    final line = tester.getRect(
      find.descendant(of: divider, matching: find.byType(ColoredBox)),
    );
    expect(line.height, 1);
    expect(line.left - box.left, 72);
    expect(box.right - line.right, 16);

    // No card, arrow or separate row widgets per person any more.
    expect(find.byType(AppListRow), findsNothing);
    expect(
      find.descendant(
        of: find.byType(StaffListCard),
        matching: find.byWidgetPredicate(
          (widget) => widget is AppIcon && widget.icon == AppIcons.chevronRight,
        ),
      ),
      findsNothing,
    );

    // Names and the role line sit in that one card.
    expect(find.text('Amina Bello'), findsOneWidget);
    expect(find.text('Chidi Eze'), findsOneWidget);
    expect(find.text('Ada Nwosu'), findsOneWidget);
    expect(find.text('Tunde Ade'), findsOneWidget);
    expect(find.text('Owner · you'), findsOneWidget);
    expect(find.textContaining('Admin · joined'), findsOneWidget);
    expect(find.textContaining('Bursar · code shared'), findsOneWidget);
  });

  testWidgets('the card keeps 8.1\'s gutters and row height', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpTeam(tester, _FakeTeam(_allStaff));

    expect(tester.getSize(find.byType(AppCard)).width, 390 - 32);

    final row = find
        .ancestor(
          of: find.text('Amina Bello'),
          matching: find.byType(Container),
        )
        .first;
    // 12 above and below the 44 avatar, before the 1px divider.
    expect(tester.getSize(row).height, 68);
    expect(tester.takeException(), isNull);
  });

  testWidgets('each row ends in one status pill', (tester) async {
    await _pumpTeam(tester, _FakeTeam(_allStaff));

    expect(find.byType(AppBadge), findsNWidgets(_allStaff.length));
    expect(find.text('Owner'), findsOneWidget);
    expect(find.text('On app'), findsOneWidget);
    expect(find.text('Code ready'), findsOneWidget);
    expect(find.text('Not on app'), findsOneWidget);
  });

  testWidgets('a pending invite draws the dashed avatar ring', (tester) async {
    await _pumpTeam(tester, _FakeTeam(_allStaff));

    final pending = find.byWidgetPredicate(
      (widget) => widget is StaffAvatar && widget.pending,
    );
    expect(pending, findsOneWidget);
    expect(
      find.descendant(
        of: pending,
        matching: find.byWidgetPredicate(
          (widget) => widget is CustomPaint && widget.foregroundPainter != null,
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('tapping a row opens that person', (tester) async {
    StaffMember? opened;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StaffListCard(
            staff: [_owner, _admin],
            subtitleFor: (person) => 'Owner · you',
            onOpen: (person) => opened = person,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Chidi Eze'));
    await tester.pump();

    expect(opened?.id, 'adm');
  });

  testWidgets('no staff shows 8.2 with the pinned add button', (tester) async {
    await _pumpTeam(tester, _FakeTeam(const []));

    final empty = find.byType(AppEmptyState);
    expect(empty, findsOneWidget);
    expect(
      tester.widget<AppEmptyState>(empty).iconTileColor,
      LightColors.categoryTealMute,
    );
    expect(find.text('No staff yet'), findsOneWidget);
    expect(
      find.text(
        'Add each person who works at the school. You can invite them to '
        'the app now or later.',
      ),
      findsOneWidget,
    );
    expect(find.byType(StaffListCard), findsNothing);
    expect(find.byType(StaffListDivider), findsNothing);

    // The page's one action stays pinned at the bottom.
    expect(find.text('Add staff member'), findsOneWidget);
  });

  testWidgets('loading shows chips and one card of skeleton rows', (
    tester,
  ) async {
    final service = _FakeTeam(_allStaff)
      ..pending = Completer<List<StaffMember>>();
    locator.registerSingleton<TeamService>(service);
    addTearDown(locator.reset);

    await tester.pumpWidget(MaterialApp(home: TeamScreen(school: _school())));
    await tester.pump();

    expect(find.byType(TeamSkeleton), findsOneWidget);
    expect(find.byType(AppCard), findsOneWidget);

    // Let the load finish so nothing is left pending.
    service.pending!.complete(<StaffMember>[]);
    await tester.pumpAndSettle();
  });

  testWidgets('the skeleton card separates its rows with hairlines', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Padding(padding: EdgeInsets.all(16), child: TeamSkeleton()),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(AppCard), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is ShimmerBox && widget.height == 44,
      ),
      findsNWidgets(5),
    );

    // Drop the shimmer animation before the test ends.
    await tester.pumpWidget(const SizedBox());
  });
}
