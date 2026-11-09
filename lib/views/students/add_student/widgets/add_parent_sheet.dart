import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hamrash_admin/api/models/students/parent_match.dart';
import 'package:hamrash_admin/api/models/students/parent_relationship.dart';
import 'package:hamrash_admin/core/bottomSheets/app_sheet.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/widgets/animated_section_content.dart';
import 'package:hamrash_admin/core/widgets/app_badge.dart';
import 'package:hamrash_admin/core/widgets/app_icons.dart';
import 'package:hamrash_admin/core/widgets/app_list_row.dart';
import 'package:hamrash_admin/core/widgets/app_photo_field.dart';
import 'package:hamrash_admin/core/widgets/app_segmented_control.dart';
import 'package:hamrash_admin/core/widgets/app_sheet_error.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/app_text_field.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_types.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_variants.dart';
import 'package:hamrash_admin/core/widgets/button/bouncy_button.dart';
import 'package:hamrash_admin/core/widgets/pickers/app_picker_field.dart';
import 'package:hamrash_admin/views/students/add_student/add_student_view_model.dart';
import 'package:hamrash_admin/views/students/add_student/widgets/wizard_photo_field.dart';

/// 11.7 / 11.8 · Add a parent. Search the school's parents by phone first:
/// a match is shown with "Use {name}"; no match opens the new parent form
/// with the number filled in. Pops `true` when a parent was added.
class AddParentSheet extends StatelessWidget {
  const AddParentSheet({super.key, required this.model});

  final AddStudentViewModel model;

  static Future<bool> show(
    BuildContext context, {
    required AddStudentViewModel model,
  }) async {
    model.startParentSheet();
    final added = await Navigator.of(context).push<bool>(
      AppSheetRoute<bool>(
        size: AppSheetSize.floating,
        child: AddParentSheet(model: model),
      ),
    );
    if (added != true) model.parentSheetDismissed();
    return added == true;
  }

  static const _phoneFormatters = [_DigitsAndPlus()];

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: model,
    builder: (context, _) {
      final mode = model.parentMode;
      final creating = mode == ParentSheetMode.newParent;
      return AppSheet(
        title: creating ? 'New parent' : 'Add a parent',
        subtitle: creating
            ? 'No one at your school has this number yet.'
            : 'Search by phone first. A parent who already has a child '
                  'here is found for you.',
        body: AnimatedSectionContent(
          child: switch (mode) {
            ParentSheetMode.newParent => _NewParentForm(
              key: const ValueKey('new'),
              model: model,
            ),
            _ => _Search(key: const ValueKey('search'), model: model),
          },
        ),
        footer: _Footer(model: model),
      );
    },
  );
}

/// Phone fields take digits, and a leading + for +234.
class _DigitsAndPlus extends TextInputFormatter {
  const _DigitsAndPlus();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    final cleaned = text.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleaned == text) return newValue;
    return TextEditingValue(
      text: cleaned,
      selection: TextSelection.collapsed(offset: cleaned.length),
    );
  }
}

class _Search extends StatelessWidget {
  const _Search({super.key, required this.model});

  final AddStudentViewModel model;

  @override
  Widget build(BuildContext context) {
    final match = model.foundParent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppTextField(
          label: 'Phone number',
          hintText: '0803 555 0142',
          controller: model.searchPhone,
          errorText: AddStudentViewModel.phoneProblem(model.searchPhone.text),
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.search,
          inputFormatters: AddParentSheet._phoneFormatters,
          onChanged: (_) => model.searchPhoneChanged(),
          onSubmitted: (_) => model.findParent(),
        ),
        if (match != null) ...[
          const SizedBox(height: AppSpacing.ml),
          _MatchRow(match: match),
          const SizedBox(height: AppSpacing.ml),
          _RelationshipField(model: model),
        ],
      ],
    );
  }
}

/// The parent the phone found (Design System "match row").
class _MatchRow extends StatelessWidget {
  const _MatchRow({required this.match});

  final ParentMatch match;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      AppLeadingPicture(
        leading: match.photoUrl == null
            ? AppListLeading.initials(match.fullName)
            : AppListLeading.network(match.photoUrl!, name: match.fullName),
        size: 52,
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AppText(
              match.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.title.copyWith(
                height: 22 / 16,
                color: LightColors.textStrong,
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
            AppText(
              match.caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.body.copyWith(
                fontSize: 13,
                height: 18 / 13,
                color: LightColors.textMuted,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(width: AppSpacing.sm),
      const AppBadge(
        'Found',
        tone: AppBadgeTone.success,
        icon: AppIcons.check,
        showBorder: false,
      ),
    ],
  );
}

class _RelationshipField extends StatelessWidget {
  const _RelationshipField({required this.model});

  final AddStudentViewModel model;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      AppText(
        'Relationship to ${model.studentFirstName}',
        style: AppTypography.subtitle.copyWith(color: LightColors.textStrong),
      ),
      const SizedBox(height: AppSpacing.sm),
      AppSegmentedControl<ParentRelationship>(
        height: 46,
        options: [
          for (final relationship in ParentRelationship.values)
            AppSegmentOption(value: relationship, label: relationship.label),
        ],
        selected: model.sheetRelationship,
        onChanged: model.pickSheetRelationship,
      ),
    ],
  );
}

class _NewParentForm extends StatelessWidget {
  const _NewParentForm({super.key, required this.model});

  final AddStudentViewModel model;

  @override
  Widget build(BuildContext context) {
    final first = model.newParentFirstName.text.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        WizardPhotoField(
          model: model,
          draft: model.newParentPhoto,
          name: model.newParentName,
          sheetTitle: first.isEmpty
              ? 'Photo of this parent'
              : 'Photo of $first',
          size: AppPhotoFieldSize.compact,
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 96,
              child: AppSelectField<String>(
                label: 'Title',
                value: model.newParentTitle,
                items: ParentTitles.values,
                placeholder: 'Title',
                onChanged: model.pickNewParentTitle,
              ),
            ),
            const SizedBox(width: AppSpacing.ms),
            Expanded(
              child: AppTextField(
                label: 'First name',
                hintText: 'Emeka',
                controller: model.newParentFirstName,
                errorText: model.newParentFirstNameProblem,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                onChanged: (_) => model.sheetChanged(),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          label: 'Last name',
          hintText: 'Okafor',
          controller: model.newParentLastName,
          errorText: model.newParentLastNameProblem,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          onChanged: (_) => model.sheetChanged(),
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          label: 'Phone number',
          hintText: '0803 555 0142',
          controller: model.newParentPhone,
          errorText: AddStudentViewModel.phoneProblem(
            model.newParentPhone.text,
          ),
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          inputFormatters: AddParentSheet._phoneFormatters,
          onChanged: (_) => model.sheetChanged(),
        ),
        const SizedBox(height: AppSpacing.md),
        _RelationshipField(model: model),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          label: 'Email',
          hintText: 'emeka.okafor@example.com',
          controller: model.newParentEmail,
          errorText: model.newParentEmailProblem,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          textInputAction: TextInputAction.next,
          onChanged: (_) => model.sheetChanged(),
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          label: 'Occupation',
          hintText: 'Civil engineer',
          controller: model.newParentOccupation,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.next,
          onChanged: (_) => model.sheetChanged(),
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          label: 'Home address',
          hintText: '12 Ogui Road, Enugu',
          controller: model.newParentAddress,
          minLines: 3,
          maxLines: 6,
          contentPadding: EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          keyboardType: TextInputType.multiline,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.done,
          onChanged: (_) => model.sheetChanged(),
        ),
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.model});

  final AddStudentViewModel model;

  Future<void> _useFound(BuildContext context) async {
    if (model.useFoundParent() && context.mounted) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _addNew(BuildContext context) async {
    final added = await model.addNewParent();
    if (added && context.mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final match = model.foundParent;
    final Widget primary = switch (model.parentMode) {
      ParentSheetMode.search => AppPrimaryButton(
        size: AppButtonSize.large,
        useGradient: true,
        isLoading: model.searching,
        loadingText: 'Searching…',
        isDisabled: !model.canSearch && !model.searching,
        onPressed: model.findParent,
        child: const Text('Find parent'),
      ),
      ParentSheetMode.found => AppPrimaryButton(
        size: AppButtonSize.large,
        useGradient: true,
        isDisabled: !model.canUseFound,
        onPressed: () => _useFound(context),
        child: Text('Use ${match?.shortName ?? 'this parent'}'),
      ),
      ParentSheetMode.newParent => AppPrimaryButton(
        size: AppButtonSize.large,
        useGradient: true,
        isLoading: model.searching,
        loadingText: 'Checking…',
        isDisabled: !model.canAddNewParent && !model.searching,
        onPressed: () => _addNew(context),
        child: const Text('Add parent'),
      ),
    };
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (model.parentNotice case final notice?) AppSheetError(notice),
        primary,
        if (model.parentMode == ParentSheetMode.found) ...[
          // 8 here + 8 of padding around the label = 16 visible.
          const SizedBox(height: AppSpacing.sm),
          BouncyButton(
            onPressed: model.searching ? null : model.tryAnotherNumber,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: AppText(
                'Not them? Try another number',
                textAlign: TextAlign.center,
                style: AppTypography.button.copyWith(
                  color: LightColors.primaryPrimaryText,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
