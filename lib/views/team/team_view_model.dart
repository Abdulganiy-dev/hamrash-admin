import 'package:hamrash_admin/api/models/organization_models/member_school.dart';
import 'package:hamrash_admin/api/models/team/staff_member.dart';
import 'package:hamrash_admin/api/services/supabase_services/team_service.dart';
import 'package:hamrash_admin/core/utils/app_date_format.dart';
import 'package:hamrash_admin/singleton_locator/locator.dart';
import 'package:hamrash_admin/viewModel/base_view_model.dart';

/// The three views on the team list (8.1).
enum TeamFilter { all, onApp, notOnApp }

/// 8.1–8.3 · Everyone on the school's staff list, with their login when they
/// have one. Leaders add people and open a person's page; bursars never
/// reach this screen.
class TeamViewModel extends BaseViewModel {
  TeamViewModel({
    required this.school,
    TeamService? team,
    DateTime Function()? now,
  }) : _team = team ?? locator<TeamService>(),
       _now = now ?? DateTime.now;

  final MemberSchool school;
  final TeamService _team;
  final DateTime Function() _now;

  List<StaffMember>? _staff;
  Object? _error;
  bool _changed = false;

  TeamFilter filter = TeamFilter.all;

  Object? get error => _error;
  bool get loading => _staff == null && _error == null;
  bool get canAdd => school.canRunSetup;

  /// Something was saved, so the page that opened this one should reload.
  bool get changed => _changed;

  List<StaffMember> get staff => _staff ?? const [];

  int get allCount => staff.length;

  int get onAppCount => staff
      .where(
        (person) =>
            person.access == StaffAccess.onApp ||
            person.access == StaffAccess.owner,
      )
      .length;

  int get notOnAppCount => allCount - onAppCount;

  List<StaffMember> get visibleStaff => switch (filter) {
    TeamFilter.all => staff,
    TeamFilter.onApp => [
      for (final person in staff)
        if (person.access == StaffAccess.onApp ||
            person.access == StaffAccess.owner)
          person,
    ],
    TeamFilter.notOnApp => [
      for (final person in staff)
        if (person.access != StaffAccess.onApp &&
            person.access != StaffAccess.owner)
          person,
    ],
  };

  bool get isEmpty => staff.isEmpty;

  /// 8.2 is rare: the owner's own staff record is made when they join.
  bool get showEmptyState => !loading && _error == null && isEmpty;

  /// "Owner · you", "Admin · joined 3 Sep", "Bursar · code shared 5 Nov",
  /// "Teacher · added today", "Teacher · suspended".
  String subtitleFor(StaffMember person) {
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

  void pickFilter(TeamFilter value) {
    filter = value;
    notifyListeners();
  }

  Future<void> load() async {
    _error = null;
    notifyListeners();
    try {
      await _fetch();
    } catch (error, stackTrace) {
      _error = error;
      await handleError(
        error,
        stackTrace: stackTrace,
        context: 'Team.load',
        showErrorModal: false,
      );
    }
    notifyListeners();
  }

  /// Pull to refresh: keeps the page and rethrows for the error toast.
  Future<void> refresh() async {
    try {
      await _fetch();
      _error = null;
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
    try {
      await _fetch();
      _error = null;
      _changed = true;
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

  Future<void> _fetch() async {
    final people = await _team.listStaff(school.id);
    // The owner's record reads first, then everyone by name.
    people.sort((a, b) {
      final aOwner = a.access == StaffAccess.owner ? 0 : 1;
      final bOwner = b.access == StaffAccess.owner ? 0 : 1;
      if (aOwner != bOwner) return aOwner - bOwner;
      return a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase());
    });
    _staff = people;
  }
}
