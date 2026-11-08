import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hamrash_admin/api/models/organization_models/member_school.dart';
import 'package:hamrash_admin/api/models/organization_models/organization.dart';
import 'package:hamrash_admin/api/models/organization_models/organization_member.dart';
import 'package:hamrash_admin/api/models/team/staff_filter.dart';
import 'package:hamrash_admin/api/models/team/staff_member.dart';
import 'package:hamrash_admin/api/models/team/staff_page.dart';
import 'package:hamrash_admin/api/services/supabase_services/team_service.dart';
import 'package:hamrash_admin/views/team/team_view_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'staff_page_fake.dart';

StaffMember _person(int i, {StaffLogin? login}) => StaffMember(
  id: 'p$i',
  firstName: 'Person${i.toString().padLeft(3, '0')}',
  lastName: 'Okafor',
  staffType: 'non_teaching',
  status: StaffRecordStatus.active,
  createdAt: DateTime(2026, 11, 8),
  login: login,
);

final _onApp = StaffLogin(
  id: 'm',
  role: OrganizationMemberRole.teacher,
  status: OrganizationMemberStatus.active,
  createdAt: DateTime(2026, 11, 5),
);

/// Built once in `main`, outside the fake-time zone `testWidgets` runs in.
late final SupabaseClient _client;

typedef _Call = ({StaffFilter filter, String? cursor, int limit});

class _PagedTeam extends TeamService {
  _PagedTeam(this.people) : super(_client);

  List<StaffMember> people;
  final calls = <_Call>[];

  /// Answers instead of the fake server, e.g. to hold a response back.
  Future<StaffPage> Function(_Call call)? handler;

  @override
  Future<StaffPage> listStaffPage({
    required String organizationId,
    StaffFilter filter = StaffFilter.initial,
    int limit = TeamService.pageSize,
    String? cursor,
  }) {
    final call = (filter: filter, cursor: cursor, limit: limit);
    calls.add(call);
    final handler = this.handler;
    if (handler != null) return handler(call);
    return Future.value(
      fakeStaffPage(people, filter: filter, limit: limit, cursor: cursor),
    );
  }
}

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

TeamViewModel _model(_PagedTeam team) =>
    TeamViewModel(school: _school(), team: team);

void main() {
  _client = SupabaseClient('https://example.supabase.co', 'k');
  tearDownAll(_client.dispose);

  group('paging', () {
    test('page 1 replaces the rows and keeps the cursor and totals', () async {
      final team = _PagedTeam([for (var i = 0; i < 70; i++) _person(i)]);
      final model = _model(team);
      expect(model.loading, isTrue);

      await model.load();

      expect(model.loading, isFalse);
      expect(model.staff, hasLength(30));
      expect(model.hasMore, isTrue);
      expect(model.total, 70);
      expect(model.counts.all, 70);
      expect(team.calls.single.cursor, isNull);
      expect(team.calls.single.limit, 30);
    });

    test('loadMore appends without repeating anyone, then stops', () async {
      final team = _PagedTeam([for (var i = 0; i < 65; i++) _person(i)]);
      final model = _model(team);
      await model.load();

      await model.loadMore();
      expect(model.staff, hasLength(60));
      expect(model.hasMore, isTrue);

      // A person added meanwhile can shift a page; repeats are dropped.
      final overlapping = fakeStaffPage(
        team.people,
        cursor: '55',
      );
      team.handler = (_) async => overlapping;
      await model.loadMore();
      expect({for (final p in model.staff) p.id}, hasLength(model.staff.length));
      expect(model.staff, hasLength(65));
      expect(model.nextCursor, isNull);

      team.handler = null;
      final before = team.calls.length;
      await model.loadMore();
      expect(team.calls.length, before, reason: 'no cursor, no request');
    });

    test('loadMore does nothing while a page is already loading', () async {
      final team = _PagedTeam([for (var i = 0; i < 70; i++) _person(i)]);
      final model = _model(team);
      await model.load();

      final gate = Completer<StaffPage>();
      team.handler = (_) => gate.future;
      final first = model.loadMore();
      final second = model.loadMore();
      expect(model.loadingMore, isTrue);
      expect(team.calls, hasLength(2)); // page 1, then one page 2

      gate.complete(fakeStaffPage(team.people, cursor: '30'));
      await Future.wait([first, second]);
      expect(model.staff, hasLength(60));
      expect(model.loadingMore, isFalse);
    });

    test('a failed page keeps the rows and retries on request', () async {
      final team = _PagedTeam([for (var i = 0; i < 70; i++) _person(i)]);
      final model = _model(team);
      await model.load();

      team.handler = (_) async => throw Exception('offline');
      await model.loadMore();
      expect(model.loadMoreError, isNotNull);
      expect(model.staff, hasLength(30));
      expect(model.loadingMore, isFalse);

      // Scrolling again doesn't hammer the server...
      final calls = team.calls.length;
      await model.loadMore();
      expect(team.calls.length, calls);

      // ...tapping retry does.
      team.handler = null;
      await model.retryLoadMore();
      expect(model.loadMoreError, isNull);
      expect(model.staff, hasLength(60));
    });

    test('an answer for an old filter is ignored', () async {
      final team = _PagedTeam([for (var i = 0; i < 10; i++) _person(i)]);
      final model = _model(team);
      await model.load();

      final slow = Completer<StaffPage>();
      team.handler = (call) {
        if (call.filter.sort == StaffSort.newest) return slow.future;
        return Future.value(
          fakeStaffPage(team.people.take(2).toList(), filter: call.filter),
        );
      };

      final first = model.applyFilter(
        const StaffFilter(sort: StaffSort.newest),
      );
      final second = model.applyFilter(
        const StaffFilter(staffType: StaffTypeFilter.nonTeaching),
      );
      await second;
      expect(model.staff, hasLength(2));

      // The first filter's answer arrives late with everyone in it.
      slow.complete(fakeStaffPage(team.people));
      await first;
      expect(model.staff, hasLength(2));
      expect(model.filter.staffType, StaffTypeFilter.nonTeaching);
      expect(model.loading, isFalse);
    });

    test('a pull to refresh reloads page 1 under the same filter', () async {
      final team = _PagedTeam([for (var i = 0; i < 70; i++) _person(i)]);
      final model = _model(team);
      await model.load();
      await model.loadMore();
      expect(model.staff, hasLength(60));

      await model.refresh();

      expect(model.staff, hasLength(30));
      expect(team.calls.last.cursor, isNull);
    });
  });

  group('filters', () {
    test('applying a filter loads page 1 again with it', () async {
      final team = _PagedTeam([
        for (var i = 0; i < 6; i++) _person(i, login: i < 4 ? _onApp : null),
      ]);
      final model = _model(team);
      await model.load();

      await model.applyFilter(
        const StaffFilter(login: StaffLoginFilter.notOnApp),
      );

      expect(team.calls.last.filter.login, StaffLoginFilter.notOnApp);
      expect(team.calls.last.cursor, isNull);
      expect(model.staff, hasLength(2));
      expect(model.total, 2);
      // The counts (for "2 of 6") ignore the login.
      expect(model.counts.all, 6);
      expect(model.counts.onApp, 4);
      expect(model.counts.notOnApp, 2);
    });

    test('removing a chip, and clearing, put things back', () async {
      final team = _PagedTeam([_person(0), _person(1)]);
      final model = _model(team);
      await model.applyFilter(
        const StaffFilter(
          search: 'zzz',
          roles: {OrganizationMemberRole.admin},
          sort: StaffSort.newest,
        ),
      );
      expect(model.showNoResults, isTrue);
      expect(model.showEmptyState, isFalse);

      await model.removeChip(
        model.filter.chips.firstWhere((chip) => chip.label == 'Admin'),
      );
      expect(model.filter.roles, isEmpty);
      expect(model.filter.search, 'zzz');

      await model.clearSearch();
      expect(model.filter.search, '');
      expect(model.filter.sort, StaffSort.newest);

      await model.clearFilters();
      expect(model.filter, StaffFilter.initial);
      expect(model.showNoResults, isFalse);
      expect(model.staff, hasLength(2));
    });

    test('an empty school with no filters is the "no staff yet" page', () async {
      final model = _model(_PagedTeam(const []));
      await model.load();

      expect(model.showEmptyState, isTrue);
      expect(model.showNoResults, isFalse);
    });

    // testWidgets runs on fake time, so the debounce can be stepped through.
    testWidgets('typing waits for a pause, then searches once', (tester) async {
      final team = _PagedTeam([_person(0), _person(1)]);
      final model = _model(team);
      await model.load();
      team.calls.clear();

      model.setSearch('a');
      await tester.pump(const Duration(milliseconds: 200));
      model.setSearch('ad');
      await tester.pump(const Duration(milliseconds: 299));
      expect(team.calls, isEmpty);

      await tester.pump(const Duration(milliseconds: 1));
      expect(team.calls, hasLength(1));
      expect(team.calls.single.filter.search, 'ad');
      expect(model.filter.search, 'ad');
      model.dispose();
    });
  });
}
