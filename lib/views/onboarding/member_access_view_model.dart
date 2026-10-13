import 'package:hamrash_admin/api/models/organization_models/member_school.dart';
import 'package:hamrash_admin/api/models/organization_models/organization.dart';
import 'package:hamrash_admin/api/models/organization_models/organization_member.dart';
import 'package:hamrash_admin/api/services/supabase_services/organization_member_service.dart';
import 'package:hamrash_admin/core/cache/user_prefrences.dart';
import 'package:hamrash_admin/services/error_logger_service.dart';
import 'package:hamrash_admin/singleton_locator/locator.dart';
import 'package:hamrash_admin/viewModel/base_view_model.dart';

/// Decides what a signed-in person sees: join, pick a school, the paused
/// screen, the details check, or Home.
class MemberAccessViewModel extends BaseViewModel {
  MemberAccessViewModel(
    this.clerkUserId, {
    OrganizationMemberService? service,
    Future<UserPreference> Function()? preferences,
  }) : _service = service ?? locator<OrganizationMemberService>(),
       _preferences = preferences ?? UserPreference.getInstance;

  final String clerkUserId;
  final OrganizationMemberService _service;
  final Future<UserPreference> Function() _preferences;

  bool _checked = false;
  List<OrganizationMember> _memberships = [];
  List<MemberSchool> _schools = [];
  MemberSchool? _selected;
  Object? _error;

  bool get checked => _checked;
  List<OrganizationMember> get memberships => _memberships;

  /// Schools this person can open here, by name.
  List<MemberSchool> get schools => _schools;

  /// The open school, or null while they pick one.
  MemberSchool? get selected => _selected;

  bool get hasMembership => _schools.isNotEmpty;
  bool get canSwitchSchool => _schools.length > 1;
  Object? get error => _error;

  Future<void> check() async {
    _checked = false;
    _error = null;
    notifyListeners();

    try {
      _memberships = await _service.getMembershipsWithOrganizations(
        clerkUserId,
      );
      _schools = MemberSchool.fromMemberships(_memberships);
      _selected = await _schoolToOpen();
    } catch (error, stackTrace) {
      await ErrorLoggerService.logError(
        error,
        stackTrace: stackTrace,
        context: 'Onboarding.organizationMembership',
      );
      _error = error;
    } finally {
      _checked = true;
      notifyListeners();
    }
  }

  /// One school opens straight away; with several, the last one opened,
  /// else the picker.
  Future<MemberSchool?> _schoolToOpen() async {
    if (_schools.length == 1) return _schools.single;
    final lastId = await _lastSchoolId();
    for (final school in _schools) {
      if (school.id == lastId) return school;
    }
    return null;
  }

  Future<String?> _lastSchoolId() async {
    try {
      return (await _preferences()).lastSchoolId;
    } catch (_) {
      return null;
    }
  }

  void selectSchool(MemberSchool school) {
    _selected = school;
    notifyListeners();
    _preferences().then((prefs) => prefs.setLastSchoolId(school.id)).ignore();
  }

  /// Back to the picker.
  void switchSchool() {
    if (!canSwitchSchool) return;
    _selected = null;
    notifyListeners();
  }

  /// Swaps in the school as saved, e.g. after its details were checked.
  void updateSchool(Organization organization) {
    MemberSchool replace(MemberSchool school) => school.id == organization.id
        ? MemberSchool(
            organization: organization,
            roles: school.roles,
            memberIds: school.memberIds,
          )
        : school;
    _schools = _schools.map(replace).toList(growable: false);
    if (_selected case final selected?) _selected = replace(selected);
    notifyListeners();
  }
}
