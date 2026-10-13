import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/bottomSheets/app_sheet.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/utils/app_date_format.dart';
import 'package:hamrash_admin/core/widgets/app_cards.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/app_text_field.dart';
import 'package:hamrash_admin/core/widgets/button/app_button.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_types.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_variants.dart';
import 'package:hamrash_admin/core/widgets/button/bouncy_button.dart';
import 'package:hamrash_admin/core/widgets/default_scaffold.dart';
import 'package:hamrash_admin/core/widgets/pickers/app_date_fields.dart';
import 'package:hamrash_admin/services/navigation_service.dart';
import 'package:hamrash_admin/views/academic_calendar/create_session/create_session_view_model.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:stacked/stacked.dart';

/// Setup step 2: create a session using the session details flow.
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
                        _TermRow(
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
                Navigator.of(context).pop(true);
              }
            },
            child: const Text('Save calendar'),
          ),
        ),
      ),
    ),
  );

  Future<void> _editSession(
    BuildContext context,
    CreateSessionViewModel model,
  ) async {
    var name = model.draft.name;
    var dates = model.draft.dates;
    await AppSheet.show<void>(
      context: context,
      title: 'Edit session',
      size: AppSheetSize.floating,
      subtitle: '${model.draft.name} · ${model.draft.terms.length} terms',
      body: StatefulBuilder(
        builder: (sheetContext, update) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SheetNameField(
              initialName: name,
              onChanged: (value) => name = value,
            ),
            const SizedBox(height: 20),
            AppDateRangeField(
              label: 'Session dates',
              value: dates,
              firstDate: DateTime(dates.start.year - 1),
              lastDate: DateTime(dates.end.year + 2, 12, 31),
              onChanged: (value) => update(() => dates = value),
            ),
            const SizedBox(height: 16),
            const AppText(
              'Every term has to fit inside these dates. If a change leaves one outside, we’ll point it out before you save.',
              variant: AppTextVariant.body,
              colorType: AppTextColor.textBody,
            ),
          ],
        ),
      ),
      footer: AppPrimaryButton(
        size: AppButtonSize.large,
        onPressed: () {
          model.editSession(name, dates);
          Navigator.of(context).pop();
        },
        child: const Text('Save session'),
      ),
    );
  }

  Future<void> _editTerm(
    BuildContext context,
    CreateSessionViewModel model,
    int? index,
  ) async {
    final adding = index == null;
    final term = adding ? null : model.draft.terms[index];
    var name = term?.name ?? '';
    var dates = term?.dates;
    var isCurrent = index == model.draft.currentTermIndex;
    await AppSheet.show<void>(
      context: context,
      title: adding ? 'Add a term' : term!.name,
      size: AppSheetSize.floating,
      subtitle:
          'Term ${(index ?? model.draft.terms.length) + 1} of ${adding ? model.draft.terms.length + 1 : model.draft.terms.length} in ${model.draft.name}',
      body: StatefulBuilder(
        builder: (sheetContext, update) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SheetNameField(
              initialName: name,
              onChanged: (value) => name = value,
            ),
            const SizedBox(height: 20),
            AppDateRangeField(
              label: 'Term dates',
              value: dates,
              firstDate: model.draft.dates.start,
              lastDate: model.draft.dates.end,
              onChanged: (value) => update(() => dates = value),
            ),
            const SizedBox(height: 16),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Current term'),
              subtitle: const Text(
                'Attendance, fees and results use this term. Only one at a time.',
              ),
              activeTrackColor: AppPalette.aubergine500,
              value: isCurrent,
              onChanged: isCurrent
                  ? null
                  : (value) => update(() => isCurrent = value),
            ),

            if (!adding && index == model.draft.currentTermIndex) ...[
              const SizedBox(height: 16),
              const AppText(
                'Make another term current before removing this one.',
                variant: AppTextVariant.caption,
                colorType: AppTextColor.textMuted,
              ),
            ],
          ],
        ),
      ),
      footer: Column(
        children: [
          AppPrimaryButton(
            size: AppButtonSize.large,
            onPressed: () {
              if (name.trim().isEmpty || dates == null) return;
              if (adding) {
                model.addTerm(name, dates!);
                if (isCurrent) {
                  model.editTerm(
                    model.draft.terms.length - 1,
                    name,
                    dates!,
                    isCurrent: true,
                  );
                }
              } else {
                model.editTerm(index, name, dates!, isCurrent: isCurrent);
              }
              Navigator.of(context).pop();
            },
            child: Text(adding ? 'Add term' : 'Save term'),
          ),

          if (!adding && index != model.draft.currentTermIndex) ...[
            const SizedBox(height: 16),
            BouncyButton(
              onPressed: () {
                model.removeTerm(index);
                NavigationService.popScreen();
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    LucideIcons.trash2,
                    size: 18,
                    color: LightColors.errorErrorText,
                  ),
                  const SizedBox(width: 8),
                  AppText(
                    'Remove term',
                    style: AppTypography.button.copyWith(
                      color: LightColors.errorErrorText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Keep the controller alive through the sheet's closing animation.
class _SheetNameField extends StatefulWidget {
  const _SheetNameField({required this.initialName, required this.onChanged});

  final String initialName;
  final ValueChanged<String> onChanged;

  @override
  State<_SheetNameField> createState() => _SheetNameFieldState();
}

class _SheetNameFieldState extends State<_SheetNameField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialName,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppTextField(
    label: 'Name',
    controller: _controller,
    onChanged: widget.onChanged,
    textInputAction: TextInputAction.done,
  );
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

class _TermRow extends StatelessWidget {
  const _TermRow({
    required this.index,
    required this.model,
    required this.onTap,
  });
  final int index;
  final CreateSessionViewModel model;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final term = model.draft.terms[index];
    final current = model.draft.currentTermIndex == index;
    final dates = term.dates;
    final dateLine =
        '${DateFormat('d MMM').format(dates.start)} – ${DateFormat('d MMM').format(dates.end)}';
    final week = ((DateTime.now().difference(dates.start).inDays + 1) / 7)
        .ceil()
        .clamp(1, 99);
    return BouncyButton(
      onPressed: onTap,
      child: Material(
        color: current ? AppPalette.aubergine50 : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: current ? AppPalette.aubergine500 : Colors.transparent,
                  shape: BoxShape.circle,
                  border: current
                      ? null
                      : Border.all(color: AppPalette.stone300, width: 1.5),
                ),
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: current ? Colors.white : AppPalette.stone600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      term.name,
                      color: AppPalette.stone900,
                      fontWeight: FontWeight.w900,
                    ),
                    const SizedBox(height: 2),
                    AppText(
                      dateLine,
                      variant: AppTextVariant.body,
                      fontWeight: FontWeight.normal,
                      colorType: current
                          ? AppTextColor.textBody
                          : AppTextColor.textMuted,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (current)
                    AppText(
                      'NOW',
                      color: AppPalette.stone900,
                      fontWeight: FontWeight.w900,
                    ),
                  const SizedBox(height: 2),
                  AppText(
                    current
                        ? 'Week $week of ${(dates.duration.inDays / 7).ceil()}'
                        : AppDateFormat.length(dates),
                    variant: AppTextVariant.body,
                    fontWeight: FontWeight.normal,
                    colorType: current
                        ? AppTextColor.textBody
                        : AppTextColor.textMuted,
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Icon(
                LucideIcons.chevronRight,
                size: 18,
                color: current ? AppPalette.stone900 : AppPalette.stone400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
