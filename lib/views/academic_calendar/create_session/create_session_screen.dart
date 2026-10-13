import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/bottomSheets/app_sheet.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/widgets/app_cards.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/button/app_button.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_types.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_variants.dart';
import 'package:hamrash_admin/core/widgets/button/bouncy_button.dart';
import 'package:hamrash_admin/core/widgets/default_scaffold.dart';
import 'package:hamrash_admin/services/navigation_service.dart';
import 'package:hamrash_admin/views/academic_calendar/create_session/create_session_view_model.dart';
import 'package:hamrash_admin/views/academic_calendar/create_session/widgets/session_sheets.dart';
import 'package:hamrash_admin/views/academic_calendar/create_session/widgets/session_term_row.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:stacked/stacked.dart';


class CreateSessionScreen extends StatelessWidget {
  const CreateSessionScreen({super.key, required this.organizationId});

  final String organizationId;

  @override
  Widget build(
    BuildContext context,
  ) => ViewModelBuilder<CreateSessionViewModel>.reactive(
    viewModelBuilder: () =>
        CreateSessionViewModel(organizationId: organizationId),
    builder: (context, model, _) => DefaultScaffold(
      title: '${model.draft.name} session',
      subtitle: "We've prefilled this for you",
      showBackButton: true,

      backgroundColor: AppPalette.linen,
      body: SingleChildScrollView(
        child: Builder(
          builder: (context) {
            return ScaffoldColumn(
              children: [
                SizedBox(height: ScaffoldInsets.of(context).bodyTopInset),

                AppCard(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText(
                              'CURRENT SESSION',
                              style: AppTypography.overline.copyWith(
                                color: AppPalette.aubergine500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            AppText(
                              model.draft.name,
                              style: AppTypography.heading(
                                32,
                                lineHeight: 36,
                              ).copyWith(color: AppPalette.stone900),
                            ),
                            const SizedBox(height: 2),
                            AppText(
                              '${model.draft.terms.length} terms · ${model.teachingWeeks} weeks',
                              variant: AppTextVariant.body,
                              colorType: AppTextColor.textMuted,
                            ),
                          ],
                        ),
                      ),
                      _EditPill(onTap: () => _editSession(context, model)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                AppSectionHeader(
                  title: 'Terms',
                  trailing: AppButton(
                    type: AppButtonType.text,
                    text: 'Add a term',
                    isDisabled: model.draft.terms.length >= 6,
                    onPressed: () => _editTerm(context, model, null),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.plus, size: 16),
                        const SizedBox(width: 4),
                        AppText('Add a term', variant: AppTextVariant.subtitle),
                      ],
                    ),
                  ),
                ),

                AppCard(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      for (var i = 0; i < model.draft.terms.length; i++)
                        SessionTermRow(
                          index: i,
                          model: model,
                          onTap: () => _editTerm(context, model, i),
                        ),
                    ],
                  ),
                ),
                if (model.problem case final message?) ...[
                  const SizedBox(height: 12),
                  AppText(
                    message,
                    variant: AppTextVariant.body,
                    colorType: AppTextColor.textBody,
                    style: const TextStyle(color: LightColors.errorErrorText),
                  ),
                ],
                if (model.saveError case final message?) ...[
                  const SizedBox(height: 8),
                  AppText(
                    message,
                    variant: AppTextVariant.body,
                    style: const TextStyle(color: LightColors.errorErrorText),
                  ),
                ],
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: AppPrimaryButton(
            size: AppButtonSize.large,
            isLoading: model.saving,
            loadingText: 'Saving calendar…',
            isDisabled: model.problem != null,
            onPressed: () async {
              if (await model.save() && context.mounted) {
                NavigationService.popScreen(true);
              }
            },
            child: const Text('Save calendar'),
          ),
        ),
      ),
    ),
  );

  void _editSession(BuildContext context, CreateSessionViewModel model) {
    Navigator.of(context).push<void>(
      AppSheetRoute<void>(
        size: AppSheetSize.floating,
        child: EditSessionSheet(model: model),
      ),
    );
  }

  void _editTerm(
    BuildContext context,
    CreateSessionViewModel model,
    int? index,
  ) {
    Navigator.of(context).push<void>(
      AppSheetRoute<void>(
        size: AppSheetSize.floating,
        child: EditTermSheet(model: model, index: index),
      ),
    );
  }
}

class _EditPill extends StatelessWidget {
  const _EditPill({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => BouncyButton(
    onPressed: onTap,
    child: Material(
      color: AppPalette.stone100,
      borderRadius: BorderRadius.circular(999),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: AppText(
          'Edit',
          style: AppTypography.label.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppPalette.stone900,
          ),
        ),
      ),
    ),
  );
}
