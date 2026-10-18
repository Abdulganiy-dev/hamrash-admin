import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/bottomSheets/app_sheet.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/widgets/app_search_field.dart';
import 'package:hamrash_admin/core/widgets/app_segmented_control.dart';
import 'package:hamrash_admin/core/widgets/app_sheet_error.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_variants.dart';
import 'package:hamrash_admin/core/widgets/button/bouncy_button.dart';
import 'package:hamrash_admin/core/widgets/selection/app_selection_rows.dart';
import 'package:hamrash_admin/views/subjects/class_subjects/class_subjects_view_model.dart';
import 'package:hamrash_admin/core/widgets/app_svg_icon.dart';

/// What the add sheet ended with: how many subjects it added, or a request
/// to create one that isn't listed.
typedef AddSubjectsResult = ({int added, bool create});

/// 7.5 · Pick subjects the class (or arm) doesn't take yet, compulsory or
/// optional.
class AddSubjectsSheet extends StatefulWidget {
  const AddSubjectsSheet({
    super.key,
    required this.model,
    this.preselected = const {},
  });

  final ClassSubjectsViewModel model;

  /// Ticked when the sheet opens, e.g. a subject just created.
  final Set<String> preselected;

  @override
  State<AddSubjectsSheet> createState() => _AddSubjectsSheetState();
}

class _AddSubjectsSheetState extends State<AddSubjectsSheet> {
  late final Set<String> _picked = {...widget.preselected};
  String _query = '';
  bool _compulsory = true;
  bool _saving = false;
  String? _error;

  Future<void> _save() async {
    final count = _picked.length;
    setState(() {
      _saving = true;
      _error = null;
    });
    final message = await widget.model.addSubjects(
      _picked.toList(),
      compulsory: _compulsory,
    );
    if (!mounted) return;
    if (message == null) {
      Navigator.of(
        context,
      ).pop<AddSubjectsResult>((added: count, create: false));
      return;
    }
    setState(() {
      _saving = false;
      _error = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final model = widget.model;
    final addable = model.addable;
    final wanted = _query.trim().toLowerCase();
    final shown = [
      for (final subject in addable)
        if (wanted.isEmpty ||
            subject.name.toLowerCase().contains(wanted) ||
            (subject.code?.toLowerCase().contains(wanted) ?? false))
          subject,
    ];
    final where = model.arm == null
        ? model.schoolClass!.name
        : model.targetLabel;
    final count = _picked.length;

    return AppSheet(
      title: 'Add subjects',
      subtitle: 'To ${model.targetLabel}',
      bodyPadding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSearchField(
            hintText: 'Search subjects',
            onChanged: (value) => setState(() => _query = value),
          ),
          const SizedBox(height: 16),
          AppText(
            'Add as',
            style: AppTypography.subtitle.copyWith(
              color: LightColors.textStrong,
            ),
          ),
          const SizedBox(height: 8),
          AppSegmentedControl(
            height: 40,
            options: const [
              AppSegmentOption(value: true, label: 'Compulsory'),
              AppSegmentOption(value: false, label: 'Optional'),
            ],
            selected: _compulsory,
            onChanged: (value) => setState(() => _compulsory = value),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: AppText(
                  'Not in $where yet',
                  style: AppTypography.subtitle.copyWith(
                    color: LightColors.textStrong,
                  ),
                ),
              ),
              AppText(
                addable.length == 1
                    ? '1 subject'
                    : '${addable.length} subjects',
                style: AppTypography.caption.copyWith(
                  color: LightColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (shown.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: AppText(
                addable.isEmpty
                    ? 'Every subject is already here.'
                    : 'No subject matches "${_query.trim()}".',
                style: AppTypography.body.copyWith(
                  color: LightColors.textMuted,
                ),
              ),
            )
          else
            AppRowGroup.inset(
              children: [
                for (final subject in shown)
                  AppCheckboxRow(
                    title: subject.name,
                    subtitle: subject.code,
                    value: _picked.contains(subject.id),
                    onChanged: (value) => setState(() {
                      value
                          ? _picked.add(subject.id)
                          : _picked.remove(subject.id);
                      _error = null;
                    }),
                  ),
              ],
            ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: BouncyButton(
              onPressed: () => Navigator.of(
                context,
              ).pop<AddSubjectsResult>((added: 0, create: true)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const AppSvgIcon(
                      AppSvgIcons.plus,
                      size: 16,
                      color: LightColors.primaryPrimaryDefault,
                    ),
                    const SizedBox(width: 6),
                    AppText(
                      'Not listed? Create a subject',
                      style: AppTypography.button.copyWith(
                        color: LightColors.textBrand,
                      ),
                    ),
                  ],
                ),
              ),
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
            height: 52,
            isLoading: _saving,
            loadingText: 'Adding…',
            isDisabled: count == 0,
            onPressed: _save,
            child: Text(
              count == 0
                  ? 'Add subjects'
                  : count == 1
                  ? 'Add 1 subject'
                  : 'Add $count subjects',
            ),
          ),
        ],
      ),
    );
  }
}
