import 'package:hamrash_admin/api/models/organization_models/member_school.dart';
import 'package:hamrash_admin/api/models/organization_models/school_area.dart';
import 'package:hamrash_admin/api/models/organization_models/school_snapshot.dart';
import 'package:hamrash_admin/api/models/organization_models/setup_progress.dart';
import 'package:hamrash_admin/api/services/supabase_services/school_service.dart';
import 'package:hamrash_admin/singleton_locator/locator.dart';
import 'package:hamrash_admin/viewModel/base_view_model.dart';

/// 5.1 · More tab: the school, the areas that run it, and account actions.
/// Which areas show, and which can be opened, follows [MemberSchool.accessTo].
class MoreViewModel extends BaseViewModel {
  MoreViewModel({required this.school, SchoolService? service})
    : _service = service ?? locator<SchoolService>();

  final MemberSchool school;
  final SchoolService _service;

  SetupProgress? _progress;
  CurrentTerm? _currentTerm;
  TeamCount? _team;
  Object? _error;

  Object? get error => _error;
  bool get loading => _progress == null && _error == null;

  /// Areas this person can see, in tile order.
  List<SchoolArea> get areas => SchoolArea.values
      .where((area) => school.accessTo(area).isVisible)
      .toList();

  AreaAccess accessTo(SchoolArea area) => school.accessTo(area);

  /// School leaders run these areas; everyone else can only look at them.
  String get areasTitle =>
      school.canRunSetup ? 'Run your school' : 'About your school';

  /// The line under each tile's title.
  String statusFor(SchoolArea area) => switch (area) {
    SchoolArea.academicCalendar => _currentTerm?.label ?? _notSetUp,
    SchoolArea.classes => _doneOr(SetupStep.classes),
    SchoolArea.subjects => _doneOr(SetupStep.subjects),
    SchoolArea.grading => _doneOr(SetupStep.grading),
    SchoolArea.team => _team?.label ?? 'Admins, principal, VP and bursar',
    SchoolArea.schoolDetails => 'Logo, address, contacts',
  };

  static const _notSetUp = 'Not set up yet';

  String _doneOr(SetupStep step) =>
      (_progress?.isDone(step) ?? false) ? 'Set up' : _notSetUp;

  /// Why this person can't open [area], or null when they can. The academic
  /// calendar has a read-only view, so seeing it is enough; the other area
  /// pages are for changing things and need [AreaAccess.manage].
  String? blockedReason(SchoolArea area) {
    final access = accessTo(area);
    if (access == AreaAccess.none) {
      return "You don't have access to ${area.title.toLowerCase()}";
    }
    if (access == AreaAccess.manage || area == SchoolArea.academicCalendar) {
      return null;
    }
    return area == SchoolArea.schoolDetails
        ? "Only the owner can change the school's details"
        : 'Only the owner, admins, the principal and vice principals can '
              'change this';
  }

  /// First load: shows the spinner, then the page or an error view.
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
        context: 'More.load',
        showErrorModal: false,
      );
    }
    notifyListeners();
  }

  /// Pull to refresh, and after a setup page saves. Keeps what's on screen
  /// and rethrows a failure for [AppRefreshScrollView]'s error toast.
  Future<void> refresh() async {
    try {
      await _fetch();
      _error = null;
    } catch (error, stackTrace) {
      await handleError(
        error,
        stackTrace: stackTrace,
        context: 'More.refresh',
        showErrorModal: false,
      );
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  Future<void> _fetch() async {
    final showTeam = accessTo(SchoolArea.team).isVisible;
    final results = await Future.wait<Object?>([
      _service.getSetupProgress(school.organization),
      // Tiles still work without these, so a failure isn't fatal.
      _optional(_service.getCurrentTerm(school.id)),
      if (showTeam) _optional(_service.getTeamCount(school.id)),
    ]);
    _progress = results[0] as SetupProgress;
    _currentTerm = results[1] as CurrentTerm?;
    _team = showTeam ? results[2] as TeamCount? : null;
  }

  static Future<T?> _optional<T>(Future<T?> request) async {
    try {
      return await request;
    } catch (_) {
      return null;
    }
  }
}
