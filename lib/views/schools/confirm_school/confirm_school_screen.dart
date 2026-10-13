import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/organization_models/organization.dart';
import 'package:hamrash_admin/core/bottomSheets/app_sheet.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/widgets/app_cards.dart';
import 'package:hamrash_admin/core/widgets/app_spinner.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/app_text_field.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_types.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_variants.dart';
import 'package:hamrash_admin/core/widgets/button/bouncy_button.dart';
import 'package:hamrash_admin/views/onboarding/widgets/auth_onboarding_widgets.dart';
import 'package:hamrash_admin/views/schools/confirm_school/confirm_school_view_model.dart';
import 'package:hamrash_admin/views/schools/widgets/school_logo.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:stacked/stacked.dart';

/// 10 · Check your school.
class ConfirmSchoolScreen extends StatelessWidget {
  const ConfirmSchoolScreen({
    super.key,
    required this.organization,
    required this.onConfirmed,
    this.firstName,
    this.memberIds = const [],
    this.onBack,
  });

  final Organization organization;
  final String? firstName;
  final ValueChanged<Organization> onConfirmed;

  /// Their memberships at this school, to find their staff record.
  final List<String> memberIds;

  /// Shown when reopened from the checklist, to leave without confirming.
  final VoidCallback? onBack;

  @override
  Widget build(
    BuildContext context,
  ) => ViewModelBuilder<ConfirmSchoolViewModel>.reactive(
    viewModelBuilder: () => ConfirmSchoolViewModel(
      organization: organization,
      firstName: firstName,
      onConfirmed: onConfirmed,
    ),
    builder: (context, model, _) => AuthScreenFrame(
      showBackButton: onBack != null,
      shouldShowKeyBoardDone: false,
      onBack: onBack,
      scrollContent: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppText(
            model.greeting.toUpperCase(),
            style: AppTypography.overline.copyWith(
              color: AppPalette.aubergine500,
            ),
          ),
          const SizedBox(height: AppSpacing.ms),
          const AppText('Check your school', variant: AppTextVariant.h1),
          const SizedBox(height: AppSpacing.ms),
          const AppText(
            "Hamrash filled these in for you. Fix anything that's off; you can change it later.",
            variant: AppTextVariant.bodyLarge,
            colorType: AppTextColor.textBody,
          ),
          const SizedBox(height: 28),
          _DetailsCard(model: model),
        ],
      ),
      footer: AppPrimaryButton(
        size: AppButtonSize.large,
        isLoading: model.busy,
        isDisabled: model.uploadingLogo,
        onPressed: model.confirm,
        child: const AppText('Looks good'),
      ),
    ),
  );
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.model});

  final ConfirmSchoolViewModel model;

  void _edit(BuildContext context, SchoolField field) => _EditFieldSheet.show(
    context,
    field: field,
    initialValue: field.valueOf(model.organization),
    onSave: (value) => model.saveField(field, value),
  );

  @override
  Widget build(BuildContext context) {
    final org = model.organization;
    final hasLogo = org.logoUrl?.isNotEmpty ?? false;
    final rows = [
      SchoolField.address,
      SchoolField.phone,
      SchoolField.email,
      SchoolField.numberPrefix,
    ];

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.ml),
            child: Row(
              children: [
                _LogoButton(
                  logoUrl: org.logoUrl,
                  uploading: model.uploadingLogo,
                  onTap: model.changeLogo,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        org.name,
                        style: AppTypography.h3.copyWith(
                          fontSize: 22,
                          height: 28 / 22,
                          letterSpacing: -0.22,
                          color: AppPalette.stone900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      AppText(
                        hasLogo
                            ? 'Tap the logo to change it'
                            : 'Add a logo for report cards',
                        variant: AppTextVariant.body,
                        colorType: AppTextColor.textMuted,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                _EditLink(onTap: () => _edit(context, SchoolField.name)),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: AppPalette.stone200),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.ml),
            child: Column(
              children: [
                for (final (index, field) in rows.indexed) ...[
                  if (index > 0)
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: AppPalette.stone100,
                    ),
                  _DetailRow(
                    label: field.label,
                    value: field.valueOf(org),
                    helper: field == SchoolField.numberPrefix
                        ? 'Admission numbers look like '
                              '${org.numberPrefix}/${DateTime.now().year}/0001'
                        : null,
                    onEdit: () => _edit(context, field),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoButton extends StatelessWidget {
  const _LogoButton({
    required this.logoUrl,
    required this.uploading,
    required this.onTap,
  });

  final String? logoUrl;
  final bool uploading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Change school logo',
    child: BouncyButton(
      onPressed: uploading ? null : onTap,
      child: SizedBox.square(
        dimension: 56,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            SchoolLogo(logoUrl: logoUrl),
            if (uploading)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0x8C2A1712),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: AppSpinner(size: 20, color: AppPalette.white),
                  ),
                ),
              ),
            Positioned(
              right: -6,
              bottom: -6,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: AppPalette.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: LightColors.strokeColourStrokeCard),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1F2A1712),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  LucideIcons.camera,
                  size: 14,
                  color: AppPalette.stone700,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    required this.onEdit,
    this.helper,
  });

  final String label;
  final String value;
  final String? helper;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.ms),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                label,
                variant: AppTextVariant.caption,
                colorType: AppTextColor.textMuted,
              ),
              const SizedBox(height: 2),
              AppText(
                value.isEmpty ? 'Not added' : value,
                variant: AppTextVariant.bodyLarge,
                colorType: value.isEmpty
                    ? AppTextColor.textMuted
                    : AppTextColor.textStrong,
              ),
              if (helper != null) ...[
                const SizedBox(height: 2),
                AppText(
                  helper!,
                  variant: AppTextVariant.caption,
                  colorType: AppTextColor.textMuted,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 14),
        _EditLink(onTap: onEdit, label: value.isEmpty ? 'Add' : 'Edit'),
      ],
    ),
  );
}

class _EditLink extends StatelessWidget {
  const _EditLink({required this.onTap, this.label = 'Edit'});

  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) => BouncyButton(
    onPressed: onTap,
    child: Padding(
      // A bigger tap target than the word itself.
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: AppText(
        label,
        variant: AppTextVariant.subtitle,
        colorType: AppTextColor.textBrand,
      ),
    ),
  );
}

/// Floating sheet with one field and Save. Stays open with the error under
/// the field until the value saves.
class _EditFieldSheet extends StatefulWidget {
  const _EditFieldSheet({
    required this.field,
    required this.initialValue,
    required this.onSave,
  });

  final SchoolField field;
  final String initialValue;
  final Future<String?> Function(String value) onSave;

  static Future<void> show(
    BuildContext context, {
    required SchoolField field,
    required String initialValue,
    required Future<String?> Function(String value) onSave,
  }) => Navigator.of(context).push(
    AppSheetRoute<void>(
      size: AppSheetSize.floating,
      child: _EditFieldSheet(
        field: field,
        initialValue: initialValue,
        onSave: onSave,
      ),
    ),
  );

  @override
  State<_EditFieldSheet> createState() => _EditFieldSheetState();
}

class _EditFieldSheetState extends State<_EditFieldSheet> {
  late final _controller = TextEditingController(text: widget.initialValue)
    ..addListener(_onChanged);
  String? _error;
  bool _saving = false;

  void _onChanged() {
    if (_error != null) setState(() => _error = null);
    if (widget.field == SchoolField.numberPrefix) setState(() {});
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final error = await widget.onSave(_controller.text);
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _saving = false;
        _error = error;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final field = widget.field;
    return AppSheet(
      title: 'Change ${field.label.toLowerCase()}',
      scrollableBody: false,
      // The field's own column would stretch to fill a floating sheet.
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppTextField(
            controller: _controller,
            label: field.label,
            isOptional: !field.isRequired,
            hintText: field.hint,
            helperText: field.helper(field.clean(_controller.text) ?? ''),
            errorText: _error,
            keyboardType: field.keyboardType,
            textCapitalization: field.capitalization,
            autocorrect: false,
            // textInputAction: TextInputAction.done,
            onSubmitted: (_) => _save(),
          ),
        ],
      ),
      footer: AppPrimaryButton(
        isLoading: _saving,
        onPressed: _save,
        child: const AppText('Save'),
      ),
    );
  }
}
