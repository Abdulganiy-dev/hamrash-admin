import 'package:hamrash_admin/api/models/organization_models/member_school.dart';
import 'package:hamrash_admin/api/models/organization_models/setup_progress.dart';
import 'package:hamrash_admin/api/models/organization_models/staff_profile.dart';
import 'package:hamrash_admin/api/services/supabase_services/school_service.dart';
import 'package:hamrash_admin/core/widgets/app_toast.dart';
import 'package:hamrash_admin/singleton_locator/locator.dart';
import 'package:hamrash_admin/viewModel/base_view_model.dart';

/// 11 / 12 · Home while the school is being set up. School leaders get the
/// checklist; bursars see how far setup has got.
class HomeViewModel extends BaseViewModel {
  HomeViewModel({
    required this.school,
    required this.signedInName,
    this.signedInImageUrl,
    this.onOpenSchoolDetails,
    SchoolService? service,
    DateTime Function()? now,
  }) : _service = service ?? locator<SchoolService>(),
       _now = now ?? DateTime.now;

  final MemberSchool school;

  /// From the sign-in account; used until (or unless) a staff record loads.
  final String signedInName;
  final String? signedInImageUrl;

  /// Reopens "Check your school" from the checklist.
  final void Function()? onOpenSchoolDetails;
  final SchoolService _service;
  final DateTime Function() _now;

  SetupProgress? _progress;
  String? _ownerName;
  StaffProfile? _me;
  Object? _error;

  /// The name the school knows them by: their staff record, else the
  /// sign-in account.
  String get displayName => switch (_me?.fullName) {
    final String name when name.isNotEmpty => name,
    _ => signedInName,
  };

  String? get photoUrl => switch (_me?.photoUrl) {
    final String url when url.isNotEmpty => url,
    _ => signedInImageUrl,
  };

  SetupProgress? get progress => _progress;
  Object? get error => _error;
  bool get loading => _progress == null && _error == null;

  /// "Trial · Setting up", or just "Active" once setup is done.
  String get statusLine {
    final status = school.organization.status.label;
    final progress = _progress;
    if (progress == null || progress.isComplete) return status;
    return '$status · Setting up';
  }

  /// "2026/27": a Nigerian session starts in September.
  String get currentSessionName {
    final now = _now();
    final start = now.month >= 9 ? now.year : now.year - 1;
    return '$start/${((start + 1) % 100).toString().padLeft(2, '0')}';
  }

  /// School details and inviting the team stay with owners and admins.
  bool canOpen(SetupStep step) =>
      school.canRunSetup &&
      (school.canEditSchool ||
          (step != SetupStep.schoolDetails && step != SetupStep.team));

  String hintFor(SetupStep step) => switch (step) {
    _ when !canOpen(step) => 'The owner or an admin does this',
    SetupStep.academicCalendar =>
      'Add $currentSessionName and the current term',
    _ => step.hint,
  };

  /// "Amina Bello, the owner, is getting Kings College ready."
  String get beingSetUpMessage {
    final who = _ownerName == null ? 'The owner' : '$_ownerName, the owner,';
    return '$who is getting ${school.name} ready. Classes, students and fees '
        "appear here as they're added.";
  }

  /// First load: shows the spinner, then the card or an error view.
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
        context: 'Home.load',
        showErrorModal: false,
      );
    }
    notifyListeners();
  }

  /// Pull to refresh: keeps what's on screen and rethrows a failure, so
  /// [AppRefreshScrollView] can spring back with its error toast.
  Future<void> refresh() async {
    try {
      await _fetch();
      _error = null;
    } catch (error, stackTrace) {
      await handleError(
        error,
        stackTrace: stackTrace,
        context: 'Home.refresh',
        showErrorModal: false,
      );
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  Future<void> _fetch() async {
    final results = await Future.wait<Object?>([
      _service.getSetupProgress(school.organization),
      // The header still works without these, so a failure isn't fatal.
      _service
          .getMyStaffProfile(school.id, school.memberIds)
          .catchError((_) => null),
      if (!school.canRunSetup)
        _service.getOwnerName(school.id).catchError((_) => null),
    ]);
    _progress = results[0] as SetupProgress;
    _me = results[1] as StaffProfile?;
    if (results.length > 2) _ownerName = results[2] as String?;
  }

  void openStep(SetupStep step) {
    if (!canOpen(step)) return;
    if (step == SetupStep.schoolDetails) {
      onOpenSchoolDetails?.call();
      return;
    }
    AppToast.show('${step.title} is coming soon');
  }
}
