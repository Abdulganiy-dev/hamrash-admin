import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hamrash_admin/api/models/students/parent_profile.dart';
import 'package:hamrash_admin/api/models/students/parent_relationship.dart';
import 'package:hamrash_admin/core/bottomSheets/app_sheet.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/utils/phone_format.dart';
import 'package:hamrash_admin/core/utils/validation_util.dart';
import 'package:hamrash_admin/core/widgets/app_sheet_error.dart';
import 'package:hamrash_admin/core/widgets/app_text_field.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_variants.dart';
import 'package:hamrash_admin/core/widgets/pickers/app_picker_field.dart';

/// Change a parent's details: title, name, phone, email, occupation and home
/// address, with the same fields as a new parent in the Add student flow.
/// `onSave` returns the reason it failed, or null when saved; the sheet then
/// pops `true`.
class ParentChangeDetailsSheet extends StatefulWidget {
  const ParentChangeDetailsSheet({
    super.key,
    required this.parent,
    required this.onSave,
  });

  final ParentProfile parent;
  final Future<String?> Function(ParentDetailsChanges changes) onSave;

  static Future<bool?> show(
    BuildContext context, {
    required ParentProfile parent,
    required Future<String?> Function(ParentDetailsChanges changes) onSave,
  }) => Navigator.of(context).push<bool>(
    AppSheetRoute<bool>(
      size: AppSheetSize.floating,
      child: ParentChangeDetailsSheet(parent: parent, onSave: onSave),
    ),
  );

  @override
  State<ParentChangeDetailsSheet> createState() =>
      _ParentChangeDetailsSheetState();
}

class _ParentChangeDetailsSheetState extends State<ParentChangeDetailsSheet> {
  ParentProfile get _parent => widget.parent;

  late final _first = TextEditingController(text: _parent.firstName);
  late final _last = TextEditingController(text: _parent.lastName);
  late final _phone = TextEditingController(
    text: PhoneFormat.digitsAfterPrefix(_parent.phone),
  );
  late final _email = TextEditingController(text: _parent.email ?? '');
  late final _occupation = TextEditingController(
    text: _parent.occupation ?? '',
  );
  late final _address = TextEditingController(text: _parent.address ?? '');
  late String? _title = _parent.title;

  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    for (final controller in [
      _first,
      _last,
      _phone,
      _email,
      _occupation,
      _address,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  static String? _clean(String? value) {
    final text = value?.trim() ?? '';
    return text.isEmpty ? null : text;
  }

  String? get _firstProblem =>
      ValidationUtil.validateFirstName(_first.text.trim());
  String? get _lastProblem =>
      ValidationUtil.validateLastName(_last.text.trim());
  String? get _phoneProblem => PhoneFormat.problem(_phone.text);
  String? get _emailProblem {
    final value = _email.text.trim();
    return value.isEmpty ? null : ValidationUtil.validateEmail(value);
  }

  bool get _changed =>
      _first.text.trim() != _parent.firstName.trim() ||
      _last.text.trim() != _parent.lastName.trim() ||
      PhoneFormat.stored(_phone.text) != PhoneFormat.stored(_parent.phone) ||
      _title != _parent.title ||
      _clean(_email.text) != _parent.email ||
      _clean(_occupation.text) != _parent.occupation ||
      _clean(_address.text) != _parent.address;

  bool get _valid =>
      _first.text.trim().isNotEmpty &&
      _last.text.trim().isNotEmpty &&
      _firstProblem == null &&
      _lastProblem == null &&
      PhoneFormat.stored(_phone.text) != null &&
      _phoneProblem == null &&
      _emailProblem == null;

  bool get _canSave => !_saving && _changed && _valid;

  void _touch() => setState(() => _error = null);

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final error = await widget.onSave(
      ParentDetailsChanges(
        title: _title,
        firstName: _first.text.trim(),
        lastName: _last.text.trim(),
        phone: PhoneFormat.stored(_phone.text)!,
        email: _clean(_email.text),
        occupation: _clean(_occupation.text),
        address: _clean(_address.text),
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
    subtitle: 'For ${_parent.displayName}',
    bodyPadding: const EdgeInsets.fromLTRB(
      AppSpacing.ml,
      AppSpacing.ms,
      AppSpacing.ml,
      AppSpacing.md,
    ),
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 96,
              child: AppSelectField<String>(
                label: 'Title',
                value: _title,
                items: ParentTitles.values,
                placeholder: 'Title',
                isOptional: true,
                onChanged: (value) => setState(() {
                  _title = value;
                  _error = null;
                }),
              ),
            ),
            const SizedBox(width: AppSpacing.ms),
            Expanded(
              child: AppTextField(
                label: 'First name',
                hintText: 'Emeka',
                controller: _first,
                errorText: _firstProblem,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                onChanged: (_) => _touch(),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          label: 'Last name',
          hintText: 'Okafor',
          controller: _last,
          errorText: _lastProblem,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          onChanged: (_) => _touch(),
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          label: 'Phone number',
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
          onChanged: (_) => _touch(),
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          label: 'Email',
          hintText: 'emeka.okafor@example.com',
          controller: _email,
          errorText: _emailProblem,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          textInputAction: TextInputAction.next,
          onChanged: (_) => _touch(),
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          label: 'Occupation',
          hintText: 'Civil engineer',
          controller: _occupation,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.next,
          onChanged: (_) => _touch(),
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          label: 'Home address',
          hintText: '12 Ogui Road, Enugu',
          controller: _address,
          minLines: 3,
          maxLines: 6,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          keyboardType: TextInputType.multiline,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (_) => _touch(),
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
