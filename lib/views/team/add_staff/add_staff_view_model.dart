import 'package:flutter/widgets.dart';
import 'package:hamrash_admin/api/models/organization_models/member_school.dart';
import 'package:hamrash_admin/api/models/team/staff_job_title.dart';
import 'package:hamrash_admin/api/models/team/staff_member.dart';
import 'package:hamrash_admin/api/services/supabase_services/supabase_refusal.dart';
import 'package:hamrash_admin/api/services/supabase_services/team_service.dart';
import 'package:hamrash_admin/core/utils/validation_util.dart';
import 'package:hamrash_admin/singleton_locator/locator.dart';
import 'package:hamrash_admin/viewModel/base_view_model.dart';

/// 8.3 · Add a staff member: name, job title and, optionally, phone and
/// email. Saving makes the record only; inviting is on the person's page.
class AddStaffViewModel extends BaseViewModel {
  AddStaffViewModel({required this.school, TeamService? team})
    : _team = team ?? locator<TeamService>();

  final MemberSchool school;
  final TeamService _team;

  final firstName = TextEditingController();
  final lastName = TextEditingController();
  final phone = TextEditingController();
  final email = TextEditingController();

  StaffJobTitleOption? jobTitle;
  bool _saving = false;
  bool _addedAny = false;
  String? _error;

  bool get saving => _saving;

  /// Something was added, even if the form is still open.
  bool get addedAny => _addedAny;

  String? get error => _error;

  bool get hasFirstName => firstName.text.trim().isNotEmpty;
  bool get hasLastName => lastName.text.trim().isNotEmpty;

  /// Null while the field is empty; Save stays off until both names are
  /// filled, so neither field turns red before anyone has typed.
  String? get firstNameProblem => hasFirstName
      ? ValidationUtil.validateFirstName(firstName.text.trim())
      : null;

  String? get lastNameProblem => hasLastName
      ? ValidationUtil.validateLastName(lastName.text.trim())
      : null;

  /// The field shows the number after the +234 prefix. Accepts a typed
  /// leading 0 or 234 too, and stores the full international number.
  String? get phoneProblem {
    final digits = _phoneDigits;
    if (digits.isEmpty) return null;
    if (digits.length != 10) return 'Enter a 10-digit number after +234';
    return ValidationUtil.validatePhoneNumber('+234$digits');
  }

  String? get emailProblem {
    final value = email.text.trim();
    if (value.isEmpty) return null;
    return ValidationUtil.validateEmail(value);
  }

  String get _phoneDigits {
    var digits = phone.text.replaceAll(RegExp('[^0-9]'), '');
    if (digits.startsWith('234')) digits = digits.substring(3);
    if (digits.startsWith('0')) digits = digits.substring(1);
    return digits;
  }

  String? get _storedPhone {
    final digits = _phoneDigits;
    return digits.isEmpty ? null : '+234$digits';
  }

  String? get _storedEmail {
    final value = email.text.trim();
    return value.isEmpty ? null : value;
  }

  bool get canSave =>
      !_saving &&
      hasFirstName &&
      hasLastName &&
      firstNameProblem == null &&
      lastNameProblem == null &&
      phoneProblem == null &&
      emailProblem == null &&
      jobTitle != null;

  String get previewName {
    final name = '${firstName.text.trim()} ${lastName.text.trim()}'.trim();
    return name.isEmpty ? 'New staff member' : name;
  }

  String get previewSubtitle =>
      '${jobTitle?.label ?? 'Job title'} · not on the app yet';

  void pickJobTitle(StaffJobTitleOption value) {
    jobTitle = value;
    _error = null;
    notifyListeners();
  }

  void changed() {
    _error = null;
    notifyListeners();
  }

  /// Adds the person. Returns their record, or the reason it wasn't added.
  Future<({StaffMember? staff, String? error})> save() async {
    if (_saving) return (staff: null, error: null);
    final job = jobTitle;
    if (!canSave || job == null) {
      notifyListeners();
      return (staff: null, error: null);
    }

    _saving = true;
    _error = null;
    notifyListeners();
    try {
      final staff = await _team.createStaff(
        organizationId: school.id,
        firstName: firstName.text.trim(),
        lastName: lastName.text.trim(),
        phone: _storedPhone,
        email: _storedEmail,
        jobTitle: job.jobTitle,
        staffType: job.staffType,
      );
      _addedAny = true;
      return (staff: staff, error: null);
    } catch (error, stackTrace) {
      await handleError(
        error,
        stackTrace: stackTrace,
        context: 'AddStaff.save',
        showErrorModal: false,
      );
      _error = messageFor(error, "Couldn't add them. Try again.");
      return (staff: null, error: _error);
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  /// "Save and add another": the job title stays, everything else clears.
  void clearForAnother() {
    firstName.clear();
    lastName.clear();
    phone.clear();
    email.clear();
    _error = null;
    notifyListeners();
  }

  static String messageFor(Object error, String fallback) =>
      error is SupabaseRefusal ? error.message : fallback;

  @override
  void dispose() {
    firstName.dispose();
    lastName.dispose();
    phone.dispose();
    email.dispose();
    super.dispose();
  }
}
