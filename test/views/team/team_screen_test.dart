import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hamrash_admin/core/widgets/app_divider.dart';
import 'package:hamrash_admin/api/models/organization_models/member_school.dart';
import 'package:hamrash_admin/api/models/organization_models/organization.dart';
import 'package:hamrash_admin/api/models/organization_models/organization_member.dart';
import 'package:hamrash_admin/api/models/team/staff_filter.dart';
import 'package:hamrash_admin/api/models/team/staff_member.dart';
import 'package:hamrash_admin/api/models/team/staff_page.dart';
import 'package:hamrash_admin/api/services/supabase_services/team_service.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/widgets/app_badge.dart';
import 'package:hamrash_admin/core/widgets/app_cards.dart';
import 'package:hamrash_admin/core/widgets/app_empty_state.dart';
import 'package:hamrash_admin/core/widgets/app_list_row.dart';
import 'package:hamrash_admin/core/widgets/app_shimmer.dart';
import 'package:hamrash_admin/core/widgets/app_icons.dart';
import 'package:hamrash_admin/core/widgets/button/bouncy_button.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_variants.dart';
import 'package:hamrash_admin/core/widgets/navigation/app_nav_button.dart';
import 'package:hamrash_admin/core/widgets/app_spinner.dart';
import 'package:hamrash_admin/views/team/widgets/staff_filter_sheet.dart';
import 'package:hamrash_admin/singleton_locator/locator.dart';
import 'package:hamrash_admin/views/team/team_screen.dart';
import 'package:hamrash_admin/views/team/widgets/staff_avatar.dart';
import 'package:hamrash_admin/views/team/widgets/staff_list_card.dart';
import 'package:hamrash_admin/views/team/widgets/team_skeleton.dart';

import 'staff_page_fake.dart';

/// Only `listStaffPage` is used by the list; everything else would be a real
/// database call, which these tests never make.
class _FakeTeam implements TeamService {
  _FakeTeam(this.people);

  List<StaffMember> people;

  /// Set to keep the page in its loading state until the test completes it.
  Completer<StaffPage>? pending;

  /// Answers the list with no rows, but counts that still see everyone, as
  /// if the people matching were removed before the list loaded.
  bool listComesBackEmpty = false;

  /// Makes every page after the first fail.
  bool failMore = false;

  /// Holds back every page after the first until the test completes it.
  Completer<StaffPage>? moreGate;

  final calls = <({StaffFilter filter, String? cursor, int limit})>[];

  @override
  Future<StaffPage> listStaffPage({
    required String organizationId,
    StaffFilter filter = StaffFilter.initial,
    int limit = TeamService.pageSize,
    String? cursor,
  }) {
    calls.add((filter: filter, cursor: cursor, limit: limit));
    if (cursor != null && failMore) return Future.error(Exception('offline'));
    if (cursor != null && moreGate != null) return moreGate!.future;
    if (pending != null) return pending!.future;
    final page = fakeStaffPage(
      people,
      filter: filter,
      limit: limit,
      cursor: cursor,
    );
    if (listComesBackEmpty) {
      return Future.value(
        StaffPage(
          rows: const [],
          nextCursor: null,
          total: 0,
          counts: page.counts,
        ),
      );
    }
    return Future.value(page);
  }

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

  testWidgets('loading shows one card of skeleton rows', (
    tester,
  ) async {
    final service = _FakeTeam(_allStaff)
      ..pending = Completer<StaffPage>();
    locator.registerSingleton<TeamService>(service);
    addTearDown(locator.reset);

    await tester.pumpWidget(MaterialApp(home: TeamScreen(school: _school())));
    await tester.pump();

    expect(find.byType(TeamSkeleton), findsOneWidget);
    expect(find.byType(AppCard), findsOneWidget);

    // Let the load finish so nothing is left pending.
    service.pending!.complete(
      const StaffPage(
        rows: [],
        nextCursor: null,
        total: 0,
        counts: StaffCounts.zero,
      ),
    );
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

  group('search and filters', () {
    final filterButton = find.byWidgetPredicate(
      (widget) =>
          widget is AppNavIconButton && widget.icon == AppIcons.slidersHorizontal,
    );
    final sheetButton = find.descendant(
      of: find.byType(StaffFilterSheet),
      matching: find.byType(AppPrimaryButton),
    );

    // Tall, because test text is wide and the sheet would scroll.
    void tallView(WidgetTester tester) {
      tester.view.physicalSize = const Size(390, 2600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    }

    /// Opens 8.17, changes the draft and taps "Show results".
    Future<void> apply(
      WidgetTester tester, {
      String? search,
      String? role,
    }) async {
      await tester.tap(filterButton);
      await tester.pumpAndSettle();
      if (search != null) await tester.enterText(find.byType(TextField), search);
      if (role != null) await tester.tap(find.text(role));
      await tester.tap(sheetButton);
      await tester.pumpAndSettle();
    }

    int applied(WidgetTester tester) =>
        tester.widget<AppNavIconButton>(filterButton).appliedCount;

    testWidgets('the filter button sits left of + and shows no badge', (
      tester,
    ) async {
      tallView(tester);
      await _pumpTeam(tester, _FakeTeam(_allStaff));

      expect(filterButton, findsOneWidget);
      expect(applied(tester), 0);
      final plus = find.byWidgetPredicate(
        (widget) => widget is AppNavIconButton && widget.icon == AppIcons.plus,
      );
      expect(
        tester.getRect(filterButton).right + 8,
        tester.getRect(plus).left,
      );
      // No applied-filters row until something is applied.
      expect(find.textContaining(' of '), findsNothing);
    });

    testWidgets('applying a filter badges the button and lists the chips', (
      tester,
    ) async {
      tallView(tester);
      final service = _FakeTeam(_allStaff);
      await _pumpTeam(tester, service);

      await apply(tester, role: 'Admin');

      expect(service.calls.last.filter.roles, {OrganizationMemberRole.admin});
      expect(service.calls.last.cursor, isNull);
      expect(applied(tester), 1);
      expect(
        find.descendant(of: filterButton, matching: find.text('1')),
        findsOneWidget,
      );
      // One chip with its ×, and "1 of 4": matches of everyone the filters
      // other than the login leave.
      expect(find.text('Admin'), findsOneWidget);
      expect(
        find.descendant(
          of: find.ancestor(
            of: find.text('Admin'),
            matching: find.byType(BouncyButton),
          ),
          matching: find.byWidgetPredicate(
            (widget) => widget is AppIcon && widget.icon == AppIcons.x,
          ),
        ),
        findsOneWidget,
      );
      expect(find.text('1 of 1'), findsOneWidget);
      expect(find.text('Chidi Eze'), findsOneWidget);
      expect(find.text('Amina Bello'), findsNothing);

      // The × takes the filter off and everyone is back.
      await tester.tap(find.text('Admin'));
      await tester.pumpAndSettle();
      expect(service.calls.last.filter.isDefault, isTrue);
      expect(applied(tester), 0);
      expect(find.text('Amina Bello'), findsOneWidget);
      expect(find.textContaining(' of '), findsNothing);
    });

    testWidgets('the login filter works through the sheet', (tester) async {
      tallView(tester);
      final service = _FakeTeam(_allStaff);
      await _pumpTeam(tester, service);

      // No quick chips on the page any more.
      expect(find.byType(AppFilterChip), findsNothing);

      await tester.tap(filterButton);
      await tester.pumpAndSettle();
      await tester.tap(find.text('On app'));
      await tester.tap(sheetButton);
      await tester.pumpAndSettle();

      expect(service.calls.last.filter.login, StaffLoginFilter.onApp);
      expect(applied(tester), 1);
      expect(find.text('On app'), findsOneWidget); // the applied chip
      expect(find.text('2 of 4'), findsOneWidget);
      expect(find.text('Amina Bello'), findsOneWidget);
      expect(find.text('Ada Nwosu'), findsNothing);
    });

    testWidgets('search and filters with no match: "No staff match"', (
      tester,
    ) async {
      tallView(tester);
      final service = _FakeTeam(_allStaff);
      await _pumpTeam(tester, service);
      service.listComesBackEmpty = true;

      await apply(tester, search: 'zzz', role: 'Bursar');

      expect(find.byType(StaffListCard), findsNothing);
      expect(find.text('No staff match'), findsOneWidget);
      expect(
        find.text(
          'Nothing matches “zzz” with these filters. Try fewer filters or a '
          'different spelling.',
        ),
        findsOneWidget,
      );
      expect(find.text('“zzz”'), findsOneWidget);
      expect(find.text('Bursar'), findsOneWidget);
      // The pinned add bar stays.
      expect(find.text('Add staff member'), findsOneWidget);

      service.listComesBackEmpty = false;
      await tester.tap(find.text('Clear filters'));
      await tester.pumpAndSettle();
      expect(service.calls.last.filter, StaffFilter.initial);
      expect(find.byType(StaffListCard), findsOneWidget);
      expect(applied(tester), 0);
    });

    testWidgets('a search alone with no match offers "Clear search"', (
      tester,
    ) async {
      tallView(tester);
      final service = _FakeTeam(_allStaff);
      await _pumpTeam(tester, service);
      service.listComesBackEmpty = true;

      await apply(tester, search: 'Ada');

      expect(find.text('No results for “Ada”'), findsOneWidget);
      expect(
        find.text('Check the spelling, or search by staff number.'),
        findsOneWidget,
      );
      expect(find.text('Clear filters'), findsNothing);

      service.listComesBackEmpty = false;
      await tester.tap(find.text('Clear search'));
      await tester.pumpAndSettle();
      expect(service.calls.last.filter.search, '');
      expect(find.byType(StaffListCard), findsOneWidget);
    });

    testWidgets('filters alone with no match: "No staff match these filters"', (
      tester,
    ) async {
      tallView(tester);
      final service = _FakeTeam(_allStaff);
      await _pumpTeam(tester, service);
      service.listComesBackEmpty = true;

      await apply(tester, role: 'Bursar');

      expect(find.text('No staff match these filters'), findsOneWidget);
      expect(find.text('Try removing a filter.'), findsOneWidget);
      expect(find.text('Clear filters'), findsOneWidget);
    });

    testWidgets('the list pages in as the end comes near', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final service = _FakeTeam([
        for (var i = 0; i < 70; i++) _staff(id: 'p$i', firstName: 'P$i'),
      ]);
      await _pumpTeam(tester, service);

      expect(find.byType(StaffListDivider), findsNWidgets(29));
      expect(service.calls.where((call) => call.cursor != null), isEmpty);

      final list = find.byType(CustomScrollView);
      await tester.drag(list, const Offset(0, -600));
      await tester.pumpAndSettle();
      expect(service.calls.where((call) => call.cursor != null), isEmpty);

      await tester.drag(list, const Offset(0, -2500));
      await tester.pumpAndSettle();
      expect(service.calls.last.cursor, '30');
      expect(find.byType(StaffListDivider), findsNWidgets(59));

      // Last page: 10 more, then no more requests.
      await tester.drag(list, const Offset(0, -6000));
      await tester.pumpAndSettle();
      await tester.drag(list, const Offset(0, -6000));
      await tester.pumpAndSettle();
      expect(find.byType(StaffListDivider), findsNWidgets(69));
      final requests = service.calls.length;
      await tester.drag(list, const Offset(0, -6000));
      await tester.pumpAndSettle();
      expect(service.calls.length, requests);
    });

    testWidgets('a failed page shows a retry row', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final service = _FakeTeam([
        for (var i = 0; i < 70; i++) _staff(id: 'p$i', firstName: 'P$i'),
      ])..failMore = true;
      await _pumpTeam(tester, service);

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -6000));
      await tester.pumpAndSettle();

      final retry = find.text('Couldn’t load more. Tap to retry');
      expect(retry, findsOneWidget);
      expect(find.byType(StaffListDivider), findsNWidgets(29));

      service.failMore = false;
      await tester.tap(retry);
      await tester.pumpAndSettle();
      expect(retry, findsNothing);
      expect(find.byType(StaffListDivider), findsNWidgets(59));
    });

    testWidgets('while the next page loads, a spinner sits under the card', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final service = _FakeTeam([
        for (var i = 0; i < 70; i++) _staff(id: 'p$i', firstName: 'P$i'),
      ]);
      await _pumpTeam(tester, service);

      final gate = service.moreGate = Completer<StaffPage>();

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -1400));
      await tester.pump(const Duration(milliseconds: 100));
      expect(service.calls.last.cursor, '30');
      await tester.pump(const Duration(milliseconds: 100));

      // The spinner joined the end of the list; bring it into view.
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -200));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(AppSpinner), findsOneWidget);

      gate.complete(fakeStaffPage(service.people, cursor: '30'));
      await tester.pumpAndSettle();
      expect(find.byType(AppSpinner), findsNothing);
    });

    testWidgets('with no staff there is nothing to filter', (tester) async {
      await _pumpTeam(tester, _FakeTeam(const []));

      expect(filterButton, findsNothing);
    });
  });
}
