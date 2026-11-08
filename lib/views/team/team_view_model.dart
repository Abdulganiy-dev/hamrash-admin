import 'dart:async';

import 'package:hamrash_admin/api/models/organization_models/member_school.dart';
import 'package:hamrash_admin/api/models/team/staff_filter.dart';
import 'package:hamrash_admin/api/models/team/staff_member.dart';
import 'package:hamrash_admin/api/models/team/staff_page.dart';
import 'package:hamrash_admin/api/services/supabase_services/team_service.dart';
import 'package:hamrash_admin/core/utils/app_date_format.dart';
import 'package:hamrash_admin/singleton_locator/locator.dart';
import 'package:hamrash_admin/viewModel/base_view_model.dart';

/// 8.1–8.2 · Everyone on the school's staff list, with their login when they
/// have one. Leaders add people and open a person's page; bursars never
/// reach this screen.
///
/// The server searches, filters, sorts and pages the list (`list_staff`);
/// this keeps the pages loaded so far, the applied [filter] and the chip
/// counts.
class TeamViewModel extends BaseViewModel {
  TeamViewModel({
    required this.school,
    TeamService? team,
    DateTime Function()? now,
    this.searchDebounce = const Duration(milliseconds: 300),
  }) : _team = team ?? locator<TeamService>(),
       _now = now ?? DateTime.now;

  final MemberSchool school;
  final TeamService _team;
  final DateTime Function() _now;

  /// How long typing pauses before [setSearch] asks the server.
  final Duration searchDebounce;

  List<StaffMember> _rows = const [];
  Object? _error;
  Object? _loadMoreError;
  bool _loading = true;
  bool _loadingMore = false;
  bool _changed = false;
  bool _loadedOnce = false;
  String? _nextCursor;
  int _total = 0;
  StaffCounts _counts = StaffCounts.zero;
  StaffFilter _filter = StaffFilter.initial;
  Timer? _searchTimer;

  /// Bumped by every request for page 1, so a slow answer to an old filter
  /// can't replace the newer one.
  int _token = 0;

  StaffFilter get filter => _filter;
  Object? get error => _error;
  Object? get loadMoreError => _loadMoreError;

  /// The first page is loading (first visit, or after the filter changed).
  bool get loading => _loading;
  bool get loadingMore => _loadingMore;

  /// A page has loaded at least once and the last attempt didn't fail, so
  /// the page's actions can stay put while a new filter loads.
  bool get ready => _loadedOnce && _error == null;
  bool get canAdd => school.canRunSetup;

  /// Something was saved, so the page that opened this one should reload.
  bool get changed => _changed;

  /// Every row loaded so far, in the server's order.
  List<StaffMember> get staff => _rows;
  String? get nextCursor => _nextCursor;
  bool get hasMore => _nextCursor != null;

  /// People matching every filter, across all pages.
  int get total => _total;
  StaffCounts get counts => _counts;

  /// 8.2 is rare: the owner's own staff record is made when they join.
  bool get showEmptyState =>
      !_loading && _error == null && _rows.isEmpty && _filter.isDefault;

  /// 8.1b · Filters or a search are applied and nothing matches.
  bool get showNoResults =>
      !_loading && _error == null && _rows.isEmpty && !_filter.isDefault;

  /// "Owner · you", "Admin · joined 3 Sep", "Bursar · code shared 5 Nov",
  /// "Teacher · added today", "Teacher · suspended". A non-active record
  /// gets " · on leave" or " · exited" as the suffix.
  String subtitleFor(StaffMember person) {
    final base = _subtitleFor(person);
    return switch (person.status) {
      StaffRecordStatus.active => base,
      StaffRecordStatus.onLeave => '$base · on leave',
      StaffRecordStatus.exited => '$base · exited',
    };
  }

  String _subtitleFor(StaffMember person) {
    final login = person.login;
    final role = person.role.teamLabel;
    if (login == null) {
      return '$role · added ${AppDateFormat.relative(person.createdAt, now: _now())}';
    }
    switch (person.access) {
      case StaffAccess.owner:
        return school.memberIds.contains(login.id) ? 'Owner · you' : 'Owner';
      case StaffAccess.onApp:
        return '$role · joined '
            '${AppDateFormat.relative(login.joinedAt ?? login.createdAt, now: _now())}';
      case StaffAccess.invitePending:
        return '$role · code shared '
            '${AppDateFormat.relative(login.createdAt, now: _now())}';
      case StaffAccess.suspended:
        return '$role · suspended';
      case StaffAccess.notOnApp:
        return '$role · added ${AppDateFormat.relative(person.createdAt, now: _now())}';
    }
  }

  /// Takes [chip] off the applied filters.
  Future<void> removeChip(StaffFilterChip chip) => applyFilter(chip.without);

  /// Takes the search off and keeps the other filters.
  Future<void> clearSearch() => applyFilter(_filter.copyWith(search: ''));

  /// Back to everyone: no search, no filters, the default status and sort.
  Future<void> clearFilters() => applyFilter(StaffFilter.initial);

  /// Typing in a search box: asks the server once the typing pauses.
  void setSearch(String value) {
    _searchTimer?.cancel();
    _searchTimer = Timer(searchDebounce, () {
      if (!isDisposed) applyFilter(_filter.copyWith(search: value));
    });
  }

  /// Narrows the list and loads page 1 again.
  Future<void> applyFilter(StaffFilter value) async {
    _searchTimer?.cancel();
    if (value == _filter) return;
    _filter = value;
    await load();
  }

  /// Page 1 with the skeleton showing.
  Future<void> load() async {
    final token = ++_token;
    _error = null;
    _loadMoreError = null;
    _loading = true;
    _loadingMore = false;
    notifyListeners();
    try {
      final page = await _fetch(token);
      if (page != null) _take(page);
    } catch (error, stackTrace) {
      if (token != _token) return;
      _error = error;
      await handleError(
        error,
        stackTrace: stackTrace,
        context: 'Team.load',
        showErrorModal: false,
      );
    }
    if (token != _token) return;
    _loading = false;
    notifyListeners();
  }

  /// Pull to refresh: keeps the page and rethrows for the error toast.
  Future<void> refresh() async {
    final token = ++_token;
    try {
      final page = await _fetch(token);
      if (page != null) {
        _take(page);
        _error = null;
        _loading = false;
      }
    } catch (error, stackTrace) {
      await handleError(
        error,
        stackTrace: stackTrace,
        context: 'Team.refresh',
        showErrorModal: false,
      );
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  /// After a person is added or their page saved something.
  Future<void> reload() async {
    final token = ++_token;
    try {
      final page = await _fetch(token);
      if (page != null) {
        _take(page);
        _error = null;
        _loading = false;
        _changed = true;
      }
    } catch (error, stackTrace) {
      await handleError(
        error,
        stackTrace: stackTrace,
        context: 'Team.reload',
        showErrorModal: false,
      );
    } finally {
      notifyListeners();
    }
  }

  /// The next page, added under the rows already loaded. Does nothing on the
  /// last page, while a page is loading, or after a failure ([retryLoadMore]
  /// tries again).
  Future<void> loadMore() async {
    final cursor = _nextCursor;
    if (cursor == null || _loading || _loadingMore || _loadMoreError != null) {
      return;
    }
    final token = _token;
    _loadingMore = true;
    notifyListeners();
    try {
      final page = await _team.listStaffPage(
        organizationId: school.id,
        filter: _filter,
        cursor: cursor,
      );
      if (token != _token) return;
      final known = {for (final person in _rows) person.id};
      _rows = [
        ..._rows,
        for (final person in page.rows)
          if (known.add(person.id)) person,
      ];
      _nextCursor = page.nextCursor;
      _total = page.total;
      _counts = page.counts;
    } catch (error, stackTrace) {
      if (token != _token) return;
      _loadMoreError = error;
      await handleError(
        error,
        stackTrace: stackTrace,
        context: 'Team.loadMore',
        showErrorModal: false,
      );
    } finally {
      if (token == _token) {
        _loadingMore = false;
        notifyListeners();
      }
    }
  }

  Future<void> retryLoadMore() {
    _loadMoreError = null;
    return loadMore();
  }

  /// Page 1 for the current filter, or null when a newer request has
  /// started since.
  Future<StaffPage?> _fetch(int token) async {
    final page = await _team.listStaffPage(
      organizationId: school.id,
      filter: _filter,
    );
    return token == _token ? page : null;
  }

  void _take(StaffPage page) {
    _rows = page.rows;
    _nextCursor = page.nextCursor;
    _total = page.total;
    _counts = page.counts;
    _loadMoreError = null;
    _loadingMore = false;
    _loadedOnce = true;
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    super.dispose();
  }
}
