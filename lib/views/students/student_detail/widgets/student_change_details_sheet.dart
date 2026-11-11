import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/students/student_details_changes.dart';
import 'package:hamrash_admin/api/models/students/student_health.dart';
import 'package:hamrash_admin/api/models/students/student_profile.dart';
import 'package:hamrash_admin/core/bottomSheets/app_sheet.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/utils/app_date_format.dart';
import 'package:hamrash_admin/core/utils/validation_util.dart';
import 'package:hamrash_admin/core/widgets/app_segmented_control.dart';
import 'package:hamrash_admin/core/widgets/app_sheet_error.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/app_text_field.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_variants.dart';
import 'package:hamrash_admin/core/widgets/pickers/app_date_fields.dart';
import 'package:hamrash_admin/core/widgets/pickers/app_picker_field.dart';
import 'package:hamrash_admin/views/team/widgets/staff_form_fields.dart';

/// 9.14 · Change a student's details: name, gender, birth and admission
/// dates, where they are from, address, blood group, genotype and medical
/// notes. The admission number can't change. `onSave` returns the reason it
/// failed, or null when saved; the sheet then pops `true`.
class StudentChangeDetailsSheet extends StatefulWidget {
  const StudentChangeDetailsSheet({
    super.key,
    required this.student,
    required this.onSave,
  });

  final StudentProfile student;
  final Future<String?> Function(StudentDetailsChanges changes) onSave;

  static Future<bool?> show(
    BuildContext context, {
    required StudentProfile student,
    required Future<String?> Function(StudentDetailsChanges changes) onSave,
  }) => Navigator.of(context).push<bool>(
    AppSheetRoute<bool>(
      size: AppSheetSize.floating,
      child: StudentChangeDetailsSheet(student: student, onSave: onSave),
    ),
  );

  @override
  State<StudentChangeDetailsSheet> createState() =>
      _StudentChangeDetailsSheetState();
}

class _StudentChangeDetailsSheetState extends State<StudentChangeDetailsSheet> {
  StudentProfile get _student => widget.student;

  late final _firstName = TextEditingController(text: _student.firstName);
  late final _middleName = TextEditingController(
    text: _student.middleName ?? '',
  );
  late final _lastName = TextEditingController(text: _student.lastName);
  late final _address = TextEditingController(
    text: _student.details.address ?? '',
  );
  late final _notes = TextEditingController(
    text: _student.details.medicalNotes ?? '',
  );
  late StudentGender? _gender = _student.gender;
  late DateTime? _dateOfBirth = _student.details.dateOfBirth;
  late DateTime? _admissionDate = _student.admissionDate;
  late String? _state = _clean(_student.details.stateOfOrigin);
  late String? _lga = _clean(_student.details.lga);
  late String? _bloodGroup = _clean(_student.details.bloodGroup);
  late String? _genotype = _clean(_student.details.genotype);

  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    for (final controller in [
      _firstName,
      _middleName,
      _lastName,
      _address,
      _notes,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  static String? _clean(String? value) {
    final text = value?.trim() ?? '';
    return text.isEmpty ? null : text;
  }

  static String? _text(TextEditingController controller) =>
      _clean(controller.text);

  String? get _firstNameProblem =>
      ValidationUtil.validateFirstName(_firstName.text.trim());
  String? get _lastNameProblem =>
      ValidationUtil.validateLastName(_lastName.text.trim());

  static bool _dateChanged(DateTime? value, DateTime? original) {
    if (value == null && original == null) return false;
    if (value == null || original == null) return true;
    return !AppDateFormat.isSameDay(value, original);
  }

  bool get _changed =>
      _firstName.text.trim() != _student.firstName.trim() ||
      _lastName.text.trim() != _student.lastName.trim() ||
      _text(_middleName) != _clean(_student.middleName) ||
      _gender != _student.gender ||
      _dateChanged(_dateOfBirth, _student.details.dateOfBirth) ||
      _dateChanged(_admissionDate, _student.admissionDate) ||
      _state != _clean(_student.details.stateOfOrigin) ||
      _lga != _clean(_student.details.lga) ||
      _text(_address) != _clean(_student.details.address) ||
      _bloodGroup != _clean(_student.details.bloodGroup) ||
      _genotype != _clean(_student.details.genotype) ||
      _text(_notes) != _clean(_student.details.medicalNotes);

  bool get _valid =>
      _firstName.text.trim().isNotEmpty &&
      _lastName.text.trim().isNotEmpty &&
      _firstNameProblem == null &&
      _lastNameProblem == null;

  bool get _canSave => !_saving && _changed && _valid;

  void _touch(VoidCallback change) => setState(() {
    change();
    _error = null;
  });

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final error = await widget.onSave(
      StudentDetailsChanges(
        firstName: _firstName.text.trim(),
        middleName: _text(_middleName),
        lastName: _lastName.text.trim(),
        gender: _gender,
        admissionDate: _admissionDate,
        dateOfBirth: _dateOfBirth,
        stateOfOrigin: _state,
        lga: _lga,
        address: _text(_address),
        bloodGroup: _bloodGroup,
        genotype: _genotype,
        medicalNotes: _text(_notes),
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
    subtitle: 'For ${_student.fullName}',
    bodyPadding: const EdgeInsets.fromLTRB(
      AppSpacing.ml,
      AppSpacing.ms,
      AppSpacing.ml,
      AppSpacing.md,
    ),
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StaffFormSection(
          title: 'Name',
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'First name',
                    hintText: 'Adaeze',
                    controller: _firstName,
                    errorText: _firstNameProblem,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => _touch(() {}),
                  ),
                ),
                const SizedBox(width: AppSpacing.ms),
                Expanded(
                  child: AppTextField(
                    label: 'Last name',
                    hintText: 'Okonkwo',
                    controller: _lastName,
                    errorText: _lastNameProblem,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => _touch(() {}),
                  ),
                ),
              ],
            ),
            AppTextField(
              label: 'Middle name',
              isOptional: true,
              optionalStyle: AppTypography.label.copyWith(
                fontSize: 12,
                height: 16 / 12,
                letterSpacing: 0,
                color: LightColors.textMuted,
              ),
              hintText: 'Chioma',
              controller: _middleName,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              onChanged: (_) => _touch(() {}),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        StaffFormSection(
          title: 'About them',
          children: [
            _GenderField(
              value: _gender,
              onChanged: (value) => _touch(() => _gender = value),
            ),
            AppDateField(
              label: 'Date of birth',
              value: _dateOfBirth,
              placeholder: 'Select date',
              isOptional: true,
              firstDate: DateTime(1990),
              lastDate: DateTime.now(),
              valueFormatter: AppDateFormat.dayMonthYear,
              onChanged: (value) => _touch(() => _dateOfBirth = value),
            ),
            AppDateField(
              label: 'Admitted',
              value: _admissionDate,
              placeholder: 'Select date',
              isOptional: true,
              firstDate: DateTime(1990),
              lastDate: DateTime.now(),
              valueFormatter: AppDateFormat.dayMonthYear,
              onChanged: (value) => _touch(() => _admissionDate = value),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        StaffFormSection(
          title: 'Where they are from',
          children: [
            StaffLocationFields(
              stateLabel: 'State of origin',
              state: _state,
              lga: _lga,
              sheetSubtitle: 'For ${_student.fullName}',
              onStateChanged: (value) => _touch(() {
                _state = value;
                _lga = null;
              }),
              onLgaChanged: (value) => _touch(() => _lga = value),
            ),
            AppTextField(
              label: 'Home address',
              hintText: '12 Ogui Road, Enugu',
              controller: _address,
              minLines: 2,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => _touch(() {}),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        StaffFormSection(
          title: 'Health',
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AppSelectField<String>(
                    label: 'Blood group',
                    value: _bloodGroup,
                    items: BloodGroups.values,
                    placeholder: 'Select',
                    onChanged: (value) => _touch(() => _bloodGroup = value),
                  ),
                ),
                const SizedBox(width: AppSpacing.ms),
                Expanded(
                  child: AppSelectField<String>(
                    label: 'Genotype',
                    value: _genotype,
                    items: Genotypes.values,
                    placeholder: 'Select',
                    onChanged: (value) => _touch(() => _genotype = value),
                  ),
                ),
              ],
            ),
            AppTextField(
              label: 'Medical notes',
              isOptional: true,
              optionalStyle: AppTypography.label.copyWith(
                fontSize: 12,
                height: 16 / 12,
                letterSpacing: 0,
                color: LightColors.textMuted,
              ),
              hintText: 'Allergies, conditions or anything a teacher should know',
              controller: _notes,
              minLines: 3,
              maxLines: 6,
              keyboardType: TextInputType.multiline,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => _touch(() {}),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        AppText(
          'Admission number ${_student.admissionNumber} can’t be changed.',
          style: AppTypography.body.copyWith(
            fontSize: 13,
            height: 18 / 13,
            color: LightColors.textMuted,
          ),
        ),
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

/// Gender as a two-way switch with its label above.
class _GenderField extends StatelessWidget {
  const _GenderField({required this.value, required this.onChanged});

  final StudentGender? value;
  final ValueChanged<StudentGender> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      AppText(
        'Gender',
        style: AppTypography.body.copyWith(
          fontSize: 14,
          height: 20 / 14,
          fontWeight: FontWeight.w700,
          color: LightColors.textStrong,
        ),
      ),
      const SizedBox(height: AppSpacing.sm),
      AppSegmentedControl<StudentGender>(
        options: [
          for (final gender in StudentGender.values)
            AppSegmentOption(value: gender, label: gender.label),
        ],
        selected: value,
        onChanged: onChanged,
      ),
    ],
  );
}
