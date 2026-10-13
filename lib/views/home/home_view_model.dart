import 'package:hamrash_admin/api/models/organization_models/member_school.dart';
import 'package:hamrash_admin/api/models/organization_models/setup_progress.dart';
import 'package:hamrash_admin/api/models/organization_models/staff_profile.dart';
import 'package:hamrash_admin/api/services/supabase_services/school_service.dart';
import 'package:hamrash_admin/core/widgets/app_toast.dart';
import 'package:hamrash_admin/singleton_locator/locator.dart';
import 'package:hamrash_admin/viewModel/base_view_model.dart';

/// 11 / 12 · Home while the school is being set up. Owners and admins get
/// the checklist; everyone else sees how far setup has got.
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

  String hintFor(SetupStep step) => switch (step) {
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

  Future<void> load() async {
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait<Object?>([
        _service.getSetupProgress(school.organization),
        // The header still works without these, so a failure isn't fatal.
        _service
            .getMyStaffProfile(school.id, school.memberIds)
            .catchError((_) => null),
        if (!school.canManage)
          _service.getOwnerName(school.id).catchError((_) => null),
      ]);
      _progress = results[0] as SetupProgress;
      _me = results[1] as StaffProfile?;
      if (results.length > 2) _ownerName = results[2] as String?;
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

  void openStep(SetupStep step) {
    if (!school.canManage) return;
    if (step == SetupStep.schoolDetails) {
      onOpenSchoolDetails?.call();
      return;
    }
    AppToast.show('${step.title} is coming soon');
  }
}
