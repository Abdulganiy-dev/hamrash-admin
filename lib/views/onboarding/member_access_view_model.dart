import 'package:hamrash_admin/api/services/supabase_services/organization_member_service.dart';
import 'package:hamrash_admin/services/error_logger_service.dart';
import 'package:hamrash_admin/singleton_locator/locator.dart';
import 'package:hamrash_admin/viewModel/base_view_model.dart';

class MemberAccessViewModel extends BaseViewModel {
  MemberAccessViewModel(this.clerkUserId, {OrganizationMemberService? service})
    : _service = service ?? locator<OrganizationMemberService>();

  final String clerkUserId;
  final OrganizationMemberService _service;

  bool _checked = false;
  bool _hasMembership = false;
  Object? _error;

  bool get checked => _checked;
  bool get hasMembership => _hasMembership;
  Object? get error => _error;

  Future<void> check() async {
    _checked = false;
    _hasMembership = false;
    _error = null;
    notifyListeners();

    try {
      _hasMembership = await _service.hasMembership(clerkUserId);
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
}
