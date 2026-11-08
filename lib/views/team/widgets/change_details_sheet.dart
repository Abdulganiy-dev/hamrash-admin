import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hamrash_admin/api/models/organization_models/organization_member.dart';
import 'package:hamrash_admin/api/models/team/staff_details_changes.dart';
import 'package:hamrash_admin/api/models/team/staff_job_title.dart';
import 'package:hamrash_admin/api/models/team/staff_member.dart';
import 'package:hamrash_admin/api/models/team/staff_private_details.dart';
import 'package:hamrash_admin/core/bottomSheets/app_confirm_sheet.dart';
import 'package:hamrash_admin/core/bottomSheets/app_sheet.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/constants/radius_containers.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/widgets/app_badge.dart';
import 'package:hamrash_admin/core/utils/app_date_format.dart';
import 'package:hamrash_admin/core/utils/phone_format.dart';
import 'package:hamrash_admin/core/utils/validation_util.dart';
import 'package:hamrash_admin/core/widgets/app_segmented_control.dart';
import 'package:hamrash_admin/core/widgets/app_sheet_error.dart';
import 'package:hamrash_admin/core/widgets/app_icons.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/app_text_field.dart';
import 'package:hamrash_admin/core/widgets/app_toast.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_variants.dart';
import 'package:hamrash_admin/core/widgets/pickers/app_date_fields.dart';
import 'package:hamrash_admin/core/widgets/pickers/app_picker_field.dart';
import 'package:hamrash_admin/views/team/widgets/role_picker_sheet.dart';
import 'package:hamrash_admin/views/team/widgets/staff_form_fields.dart';

/// 8.11 · Change the details a school keeps about a staff member. The role
/// changes immediately through the existing picker; the rest waits for Save.
/// `update_staff` wants every field, so the view model sends the untouched
/// middle name, gender, number, photo, status and private details back too.
class ChangeDetailsSheet extends StatefulWidget {
  const ChangeDetailsSheet({
    super.key,
    required this.member,
    required this.privateDetails,
    required this.role,
    required this.canChangeRole,
    required this.lockAdmin,
    this.viewerName,
    this.viewerRole,
    required this.onChangeRole,
    required this.onSave,
  });

  final StaffMember member;
  final StaffPrivateDetails privateDetails;

  /// The current login or invite role.
  final OrganizationMemberRole role;

  /// The Role row shows only when the viewer may change roles.
  final bool canChangeRole;

  /// True when the viewer may not issue admin logins.
  final bool lockAdmin;

  final String? viewerName;
  final OrganizationMemberRole? viewerRole;

  /// Applies a picked role now; returns the database's reason on refusal.
  final Future<String?> Function(OrganizationMemberRole) onChangeRole;

  /// Saves the editable fields; returns the reason on refusal, null when
  /// saved.
  final Future<String?> Function(StaffDetailsChanges) onSave;

  @override
  State<ChangeDetailsSheet> createState() => _ChangeDetailsSheetState();
}

class _ChangeDetailsSheetState extends State<ChangeDetailsSheet> {
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _middleName;
  late final TextEditingController _address;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final List<String> _titleLabels;
  late String? _titleLabel;
  late String _staffType;
  late OrganizationMemberRole _role;
  late StaffGender? _gender;
  DateTime? _dateOfBirth;
  late StaffRecordStatus _status;
  DateTime? _employmentDate;
  String? _stateOfOrigin;
  String? _residenceState;
  String? _residenceLga;

  bool _saving = false;
  bool _savingRole = false;
  String? _error;
  String? _roleError;

  StaffMember get _member => widget.member;

  @override
  void initState() {
    super.initState();
    _firstName = TextEditingController(text: _member.firstName);
    _lastName = TextEditingController(text: _member.lastName);
    _middleName = TextEditingController(text: _member.middleName ?? '');
    _address = TextEditingController(text: widget.privateDetails.address ?? '');
    _phone = TextEditingController(
      text: PhoneFormat.digitsAfterPrefix(_member.phone ?? ''),
    );
    _email = TextEditingController(text: _member.email ?? '');
    _role = widget.role;
    _staffType = _member.staffType;
    _gender = _member.gender;
    _dateOfBirth = widget.privateDetails.dateOfBirth;
    _status = _member.status;
    _employmentDate = widget.privateDetails.employmentDate;
    _stateOfOrigin = widget.privateDetails.stateOfOrigin;
    _residenceState = widget.privateDetails.residenceState;
    _residenceLga = widget.privateDetails.residenceLga;

    final labels = [
      for (final option in StaffJobTitleOption.values) option.label,
    ];
    final current = _labelFor(_member.jobTitle);
    if (current != null && !labels.contains(current)) labels.add(current);
    _titleLabels = labels;
    _titleLabel = current;
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _middleName.dispose();
    _address.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  /// The picker label for a stored `staff.job_title`, including the saved
  /// "Staff" -> "Other staff" mapping and any custom title.
  static String? _labelFor(String? jobTitle) {
    final title = jobTitle?.trim() ?? '';
    if (title.isEmpty) return null;
    for (final option in StaffJobTitleOption.values) {
      if (option.jobTitle == title) return option.label;
    }
    return title;
  }

  String get _jobTitleValue {
    final label = _titleLabel;
    if (label == null) return '';
    for (final option in StaffJobTitleOption.values) {
      if (option.label == label) return option.jobTitle;
    }
    return label;
  }

  bool get _hasFirstName => _firstName.text.trim().isNotEmpty;
  bool get _hasLastName => _lastName.text.trim().isNotEmpty;

  String? get _firstNameProblem =>
      ValidationUtil.validateFirstName(_firstName.text.trim());
  String? get _lastNameProblem =>
      ValidationUtil.validateLastName(_lastName.text.trim());

  String? get _phoneProblem => PhoneFormat.problem(_phone.text);

  String? get _emailProblem {
    final value = _email.text.trim();
    return value.isEmpty ? null : ValidationUtil.validateEmail(value);
  }

  String? get _storedPhone => PhoneFormat.stored(_phone.text);

  String? get _storedEmail => _storedValue(_email);

  String? get _storedMiddleName => _storedValue(_middleName);

  String? get _storedAddress => _storedValue(_address);

  static String? _storedValue(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
  }

  static String? _clean(String? value) {
    final text = value?.trim() ?? '';
    return text.isEmpty ? null : text;
  }

  static bool _dateChanged(DateTime? value, DateTime? original) {
    if (value == null && original == null) return false;
    if (value == null || original == null) return true;
    return !AppDateFormat.isSameDay(value, original);
  }

  bool get _changed =>
      _firstName.text.trim() != _member.firstName.trim() ||
      _lastName.text.trim() != _member.lastName.trim() ||
      _storedMiddleName != _clean(_member.middleName) ||
      _gender != _member.gender ||
      _dateChanged(_dateOfBirth, widget.privateDetails.dateOfBirth) ||
      _jobTitleValue != (_member.jobTitle?.trim() ?? '') ||
      _staffType != _member.staffType ||
      _status != _member.status ||
      _dateChanged(_employmentDate, widget.privateDetails.employmentDate) ||
      _stateOfOrigin != _clean(widget.privateDetails.stateOfOrigin) ||
      _storedPhone != PhoneFormat.stored(_member.phone ?? '') ||
      _storedEmail != _clean(_member.email) ||
      _storedAddress != _clean(widget.privateDetails.address) ||
      _residenceState != _clean(widget.privateDetails.residenceState) ||
      _residenceLga != _clean(widget.privateDetails.residenceLga);

  bool get _valid =>
      _hasFirstName &&
      _hasLastName &&
      _titleLabel != null &&
      _firstNameProblem == null &&
      _lastNameProblem == null &&
      _phoneProblem == null &&
      _emailProblem == null;

  bool get _canSave => !_saving && _changed && _valid;

  void _changedField() {
    setState(() => _error = null);
  }

  void _pickGender(StaffGender value) {
    setState(() {
      _gender = value;
      _error = null;
    });
  }

  void _pickDateOfBirth(DateTime value) {
    setState(() {
      _dateOfBirth = value;
      _error = null;
    });
  }

  void _pickEmploymentDate(DateTime value) {
    setState(() {
      _employmentDate = value;
      _error = null;
    });
  }

  /// A new state starts the LGA again.
  void _pickState(String value) {
    setState(() {
      _residenceState = value;
      _residenceLga = null;
      _error = null;
    });
  }

  void _pickLga(String value) {
    setState(() {
      _residenceLga = value;
      _error = null;
    });
  }

  Future<void> _pickRole() async {
    if (_savingRole) return;
    final picked = await Navigator.of(context).push<OrganizationMemberRole>(
      AppSheetRoute<OrganizationMemberRole>(
        size: AppSheetSize.floating,
        child: RolePickerSheet(
          selected: _role,
          title: 'Change role',
          lockAdmin: widget.lockAdmin,
          viewerName: widget.viewerName,
          viewerRole: widget.viewerRole,
        ),
      ),
    );
    if (picked == null || picked == _role || !mounted) return;

    setState(() {
      _savingRole = true;
      _roleError = null;
    });
    final error = await widget.onChangeRole(picked);
    if (!mounted) return;
    setState(() {
      _savingRole = false;
      if (error == null) {
        _role = picked;
      } else {
        _roleError = error;
      }
    });
    if (error == null) AppToast.show('Role changed');
  }

  Future<void> _save() async {
    if (!_canSave) return;
    if (_status == StaffRecordStatus.exited &&
        _member.status != StaffRecordStatus.exited) {
      final confirmed = await AppConfirmSheet.show(
        context,
        icon: AppIcons.clock,
        tone: AppBadgeTone.warning,
        title: 'Mark ${_member.firstNameOnly} as exited?',
        message:
            'They stay on the staff list but are no longer active. Their '
            'login is not removed.',
        confirmLabel: 'Mark as exited',
      );
      if (confirmed != true || !mounted) return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final error = await widget.onSave(
      StaffDetailsChanges(
        firstName: _firstName.text.trim(),
        middleName: _storedMiddleName,
        lastName: _lastName.text.trim(),
        gender: _gender,
        dateOfBirth: _dateOfBirth,
        jobTitle: _jobTitleValue,
        staffType: _staffType,
        status: _status,
        employmentDate: _employmentDate,
        stateOfOrigin: _stateOfOrigin,
        phone: _storedPhone,
        email: _storedEmail,
        address: _storedAddress,
        residenceState: _residenceState,
        residenceLga: _residenceLga,
      ),
    );
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _saving = false;
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) => AppSheet(
    title: 'Change details',
    subtitle: 'For ${_member.fullName}',
    bodyPadding: const EdgeInsets.fromLTRB(
      AppSpacing.ml,
      AppSpacing.ms,
      AppSpacing.ml,
      AppSpacing.md,
    ),
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.canChangeRole) ...[
          _RoleGroup(
            role: _role,
            enabled: !_savingRole,
            error: _roleError,
            onTap: _pickRole,
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        StaffFormSection(
          title: 'Name',
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'First name',
                    hintText: 'Chinedu',
                    controller: _firstName,
                    errorText: _firstNameProblem,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => _changedField(),
                  ),
                ),
                const SizedBox(width: AppSpacing.ms),
                Expanded(
                  child: AppTextField(
                    label: 'Last name',
                    hintText: 'Obi',
                    controller: _lastName,
                    errorText: _lastNameProblem,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => _changedField(),
                  ),
                ),
              ],
            ),
            AppTextField(
              key: const ValueKey('change-middle-name'),
              label: 'Middle name',
              isOptional: true,
              optionalStyle: AppTypography.label.copyWith(
                fontSize: 12,
                height: 16 / 12,
                letterSpacing: 0,
                color: LightColors.textMuted,
              ),
              hintText: 'Emeka',
              controller: _middleName,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              onChanged: (_) => _changedField(),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        AppSelectField<String>(
          label: 'Job title',
          value: _titleLabel,
          items: _titleLabels,
          labelBuilder: (label) => label,
          placeholder: 'Choose…',
          onChanged: (label) => setState(() {
            _titleLabel = label;
            _error = null;
          }),
        ),
        const SizedBox(height: AppSpacing.md),
        const _FieldLabel('Staff type'),
        const SizedBox(height: AppSpacing.sm),
        AppSegmentedControl<String>(
          options: const [
            AppSegmentOption(value: 'teaching', label: 'Teaching'),
            AppSegmentOption(value: 'non_teaching', label: 'Non-teaching'),
          ],
          selected: _staffType,
          onChanged: (value) => setState(() {
            _staffType = value;
            _error = null;
          }),
        ),
        const SizedBox(height: AppSpacing.md),
        const _FieldLabel('Status'),
        const SizedBox(height: AppSpacing.sm),
        AppSegmentedControl<StaffRecordStatus>(
          options: const [
            AppSegmentOption(value: StaffRecordStatus.active, label: 'Active'),
            AppSegmentOption(
              value: StaffRecordStatus.onLeave,
              label: 'On leave',
            ),
            AppSegmentOption(value: StaffRecordStatus.exited, label: 'Exited'),
          ],
          selected: _status,
          onChanged: (value) => setState(() {
            _status = value;
            _error = null;
          }),
        ),
        const SizedBox(height: AppSpacing.md),
        AppDateField(
          label: 'Employment date',
          value: _employmentDate,
          placeholder: 'Select date',
          isOptional: true,
          firstDate: DateTime(1940),
          lastDate: DateTime.now(),
          valueFormatter: AppDateFormat.dayMonthYear,
          onChanged: _pickEmploymentDate,
        ),
        const SizedBox(height: AppSpacing.lg),
        StaffFormSection(
          title: 'About them',
          optional: true,
          children: [
            StaffGenderField(value: _gender, onChanged: _pickGender),
            AppDateField(
              label: 'Date of birth',
              value: _dateOfBirth,
              placeholder: 'Select date',
              firstDate: DateTime(1940),
              lastDate: DateTime.now(),
              valueFormatter: AppDateFormat.dayMonthYear,
              onChanged: _pickDateOfBirth,
            ),
            StaffStateField(
              value: _stateOfOrigin,
              onChanged: (value) => setState(() {
                _stateOfOrigin = value;
                _error = null;
              }),
              sheetSubtitle: 'For ${_member.fullName}',
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        StaffFormSection(
          title: 'Where they live',
          optional: true,
          children: [
            StaffLocationFields(
              state: _residenceState,
              lga: _residenceLga,
              onStateChanged: _pickState,
              onLgaChanged: _pickLga,
              sheetSubtitle: 'For ${_member.fullName}',
            ),
            AppTextField(
              key: const ValueKey('change-address'),
              label: 'Home address',
              hintText: 'Street, area',
              controller: _address,
              minLines: 2,
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => _changedField(),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        StaffFormSection(
          title: 'Reach them',
          optional: true,
          children: [
            AppTextField(
              label: 'Phone',
              prefixText: '+234',
              hintText: '8030000000',
              controller: _phone,
              errorText: _phoneProblem,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(13),
              ],
              onChanged: (_) => _changedField(),
            ),
            AppTextField(
              label: 'Email',
              isOptional: true,
              hintText: 'name@example.com',
              controller: _email,
              errorText: _emailProblem,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              onChanged: (_) => _changedField(),
            ),
          ],
        ),
        if (_member.staffNumber case final number?
            when number.trim().isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          AppText(
            "Staff number ${number.trim()} can't be changed.",
            style: AppTypography.body.copyWith(
              fontSize: 13,
              height: 18 / 13,
              color: LightColors.textMuted,
            ),
          ),
        ],
      ],
    ),
    footer: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_error case final message?) AppSheetError(message),
        AppPrimaryButton(
          useGradient: true,
          height: 48,
          isLoading: _saving,
          loadingText: 'Saving…',
          isDisabled: !_canSave,
          onPressed: _save,
          child: const Text('Save changes'),
        ),
      ],
    ),
  );
}

/// The one-line label above a control that does not bring its own.
class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => AppText(
    label,
    style: AppTypography.body.copyWith(
      fontSize: 14,
      height: 20 / 14,
      fontWeight: FontWeight.w700,
      color: LightColors.textStrong,
    ),
  );
}

/// The current role, one line about what it means, and a chevron. The whole
/// 56 tall row opens the existing role picker.
class _RoleGroup extends StatelessWidget {
  const _RoleGroup({
    required this.role,
    required this.enabled,
    required this.onTap,
    this.error,
  });

  final OrganizationMemberRole role;
  final bool enabled;
  final VoidCallback onTap;
  final String? error;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const _FieldLabel('Role'),
      const SizedBox(height: AppSpacing.sm),
      Semantics(
        button: true,
        enabled: enabled,
        label: 'Role',
        value: role.teamLabel,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: enabled ? onTap : null,
          child: Container(
            height: 56,
            padding: const EdgeInsets.only(left: AppSpacing.md, right: 14),
            decoration: BoxDecoration(
              color: AppPalette.stone50,
              borderRadius: AppRadius.brControl,
              border: Border.all(color: AppPalette.stone200),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AppText(
                        role.teamLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.body.copyWith(
                          fontSize: 16,
                          height: 22 / 16,
                          fontWeight: FontWeight.w600,
                          color: LightColors.textStrong,
                        ),
                      ),
                      AppText(
                        role.teamDescription,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption.copyWith(
                          height: 16 / 12,
                          color: LightColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                const AppIcon(
                  AppIcons.chevronRight,
                  size: 18,
                  color: AppPalette.stone400,
                ),
              ],
            ),
          ),
        ),
      ),
      if (error case final message?) ...[
        const SizedBox(height: AppSpacing.sm),
        AppText(
          message,
          style: AppTypography.body.copyWith(
            fontSize: 13,
            height: 18 / 13,
            color: LightColors.errorErrorText,
          ),
        ),
      ],
    ],
  );
}
