import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hamrash_admin/api/models/organization_models/member_school.dart';
import 'package:hamrash_admin/api/models/team/staff_job_title.dart';
import 'package:hamrash_admin/api/models/team/staff_member.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/widgets/app_keyboard_bar.dart';
import 'package:hamrash_admin/core/widgets/app_list_row.dart';
import 'package:hamrash_admin/core/widgets/app_sheet_error.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/app_text_field.dart';
import 'package:hamrash_admin/core/widgets/app_toast.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_types.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_variants.dart';
import 'package:hamrash_admin/core/widgets/button/bouncy_button.dart';
import 'package:hamrash_admin/core/widgets/default_scaffold.dart';
import 'package:hamrash_admin/core/widgets/pickers/app_picker_field.dart';
import 'package:hamrash_admin/services/navigation_service.dart';
import 'package:hamrash_admin/views/team/add_staff/add_staff_view_model.dart';
import 'package:hamrash_admin/views/team/widgets/staff_form_fields.dart';
import 'package:stacked/stacked.dart';

/// What the add form pops: the person it made (to open their page), and
/// whether anything was added at all (so the list reloads).
class AddStaffOutcome {
  const AddStaffOutcome({this.created, required this.addedAny});

  final StaffMember? created;
  final bool addedAny;
}

/// 8.3 · Add Staff Members: who they are, their job title, and how to reach
/// them. Saving goes straight to their staff page; "Save and add another"
/// stays here.
class AddStaffScreen extends StatelessWidget {
  const AddStaffScreen({super.key, required this.school});

  final MemberSchool school;

  @override
  Widget build(BuildContext context) =>
      ViewModelBuilder<AddStaffViewModel>.reactive(
        viewModelBuilder: () => AddStaffViewModel(school: school),
        builder: (context, model, _) {
          final keyboardOpen = AppKeyboardBar.isKeyboardOpen(context);
          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop) _close(model);
            },
            child: DefaultScaffold(
              title: 'Add Staff Members',
              showBackButton: true,
              onBackPressed: () => _close(model),
              backgroundColor: AppPalette.linen,
              extendBody: keyboardOpen,
              body: _Form(model: model),
              bottomNavigationBar: keyboardOpen
                  ? const AppKeyboardBar()
                  : _SaveBar(
                      model: model,
                      onSave: () => _save(model),
                      onSaveAnother: () => _saveAnother(model),
                    ),
            ),
          );
        },
      );

  static void _close(AddStaffViewModel model) => NavigationService.popScreen(
    model.addedAny ? const AddStaffOutcome(addedAny: true) : null,
  );

  static Future<void> _save(AddStaffViewModel model) async {
    final result = await model.save();
    if (result.staff case final staff?) {
      AppToast.show('${staff.fullName} added to staff');
      NavigationService.popScreen(
        AddStaffOutcome(created: staff, addedAny: true),
      );
    }
  }

  static Future<void> _saveAnother(AddStaffViewModel model) async {
    final result = await model.save();
    if (result.staff case final staff?) {
      AppToast.show('${staff.fullName} added to staff');
      model.clearForAnother();
    }
  }
}

class _Form extends StatelessWidget {
  const _Form({required this.model});

  final AddStaffViewModel model;

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Builder(
        builder: (context) => Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.md,
            ScaffoldInsets.bodyTopInsetOf(context),
            AppSpacing.md,
            AppSpacing.lg + keyboard,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppText(
                'Who are you adding?',
                style: AppTypography.heading(
                  32,
                  lineHeight: 40,
                ).copyWith(letterSpacing: -0.64, color: LightColors.textStrong),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  AppLeadingPicture(
                    leading: AppListLeading.initials(model.previewName),
                    size: 52,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppText(
                          model.previewName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.heading(18, lineHeight: 24)
                              .copyWith(
                                fontWeight: FontWeight.w800,
                                color: LightColors.textStrong,
                              ),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        AppText(
                          model.previewSubtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.body.copyWith(
                            fontWeight: FontWeight.w600,
                            color: LightColors.textBody,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
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
                          controller: model.firstName,
                          errorText: model.firstNameProblem,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          onChanged: (_) => model.changed(),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.ms),
                      Expanded(
                        child: AppTextField(
                          label: 'Last name',
                          hintText: 'Obi',
                          controller: model.lastName,
                          errorText: model.lastNameProblem,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          onChanged: (_) => model.changed(),
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
                    hintText: 'Emeka',
                    controller: model.middleName,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => model.changed(),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              AppSelectField<StaffJobTitleOption>(
                label: 'Job title',
                value: model.jobTitle,
                items: StaffJobTitleOption.values,
                labelBuilder: (option) => option.label,
                onChanged: model.pickJobTitle,
              ),
              const SizedBox(height: AppSpacing.lg),
              StaffFormSection(
                title: 'About them',
                optional: true,
                children: [
                  StaffGenderField(
                    value: model.gender,
                    onChanged: model.pickGender,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              StaffFormSection(
                title: 'Where they live',
                optional: true,
                children: [
                  StaffLocationFields(
                    state: model.residenceState,
                    lga: model.residenceLga,
                    onStateChanged: model.pickState,
                    onLgaChanged: model.pickLga,
                  ),
                  AppTextField(
                    label: 'Home address',
                    hintText: 'Street, area',
                    controller: model.address,
                    minLines: 2,
                    maxLines: 2,
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: (_) => model.changed(),
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
                    controller: model.phone,
                    errorText: model.phoneProblem,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(13),
                    ],
                    onChanged: (_) => model.changed(),
                  ),
                  AppTextField(
                    label: 'Email',
                    isOptional: true,
                    hintText: 'name@example.com',
                    controller: model.email,
                    errorText: model.emailProblem,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    onChanged: (_) => model.changed(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SaveBar extends StatelessWidget {
  const _SaveBar({
    required this.model,
    required this.onSave,
    required this.onSaveAnother,
  });

  final AddStaffViewModel model;
  final VoidCallback onSave;
  final VoidCallback onSaveAnother;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.sm,
        AppSpacing.screen,
        AppSpacing.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (model.error case final message?) AppSheetError(message),
          AppPrimaryButton(
            size: AppButtonSize.large,
            isLoading: model.saving,
            loadingText: 'Saving…',
            isDisabled: !model.canSave,
            onPressed: onSave,
            child: const Text('Save staff member'),
          ),
          // 8 here + 8 of padding above the label = 16 visible between the
          // two buttons.
          const SizedBox(height: AppSpacing.sm),
          BouncyButton(
            onPressed: model.saving ? null : onSaveAnother,
            isDisabled: !model.canSave,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: AppText(
                'Save and add another',
                textAlign: TextAlign.center,
                style: AppTypography.button.copyWith(
                  color: model.canSave
                      ? LightColors.primaryPrimaryText
                      : LightColors.textDisabled,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
