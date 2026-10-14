import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/bottomSheets/app_sheet.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_types.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_variants.dart';
import 'package:hamrash_admin/core/widgets/default_scaffold.dart';
import 'package:hamrash_admin/services/navigation_service.dart';
import 'package:hamrash_admin/views/academic_calendar/create_session/create_session_view_model.dart';
import 'package:hamrash_admin/views/academic_calendar/widgets/session_sheets.dart';
import 'package:hamrash_admin/views/academic_calendar/widgets/session_summary_card.dart';
import 'package:hamrash_admin/views/academic_calendar/widgets/session_terms_section.dart';
import 'package:stacked/stacked.dart';

class CreateSessionScreen extends StatelessWidget {
  const CreateSessionScreen({
    super.key,
    required this.organizationId,
    this.startYear,
  });

  final String organizationId;

  /// See [CreateSessionViewModel.startYear].
  final int? startYear;

  @override
  Widget build(
    BuildContext context,
  ) => ViewModelBuilder<CreateSessionViewModel>.reactive(
    viewModelBuilder: () => CreateSessionViewModel(
      organizationId: organizationId,
      startYear: startYear,
    ),
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

                SessionSummaryCard(
                  label: startYear == null ? 'Current session' : 'New session',
                  model: model,
                  onEdit: () => _editSession(context, model),
                ),
                const SizedBox(height: 8),
                SessionTermsSection(
                  model: model,
                  onAddTerm: () => _editTerm(context, model, null),
                  onOpenTerm: (index) => _editTerm(context, model, index),
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
