import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/team/staff_member.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/constants/nigeria_locations.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/widgets/app_segmented_control.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/pickers/app_picker_field.dart';
import 'package:hamrash_admin/views/team/widgets/choice_list_sheet.dart';

/// One titled group on a staff form, with "Optional" beside the title and
/// 16px between its fields.
class StaffFormSection extends StatelessWidget {
  const StaffFormSection({
    super.key,
    required this.title,
    this.optional = false,
    required this.children,
  });

  final String title;
  final bool optional;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Flexible(
            child: AppText(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.body.copyWith(
                fontSize: 16,
                height: 22 / 16,
                fontWeight: FontWeight.w800,
                color: LightColors.textStrong,
              ),
            ),
          ),
          if (optional) ...[
            const SizedBox(width: AppSpacing.sm),
            AppText(
              'Optional',
              style: AppTypography.body.copyWith(
                fontSize: 13,
                height: 20 / 13,
                fontWeight: FontWeight.w600,
                color: LightColors.textBody,
              ),
            ),
          ],
        ],
      ),
      const SizedBox(height: AppSpacing.ms),
      for (var i = 0; i < children.length; i++) ...[
        if (i > 0) const SizedBox(height: AppSpacing.md),
        children[i],
      ],
    ],
  );
}

/// "Gender" and the two-option segmented control. Starts unselected.
class StaffGenderField extends StatelessWidget {
  const StaffGenderField({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final StaffGender? value;
  final ValueChanged<StaffGender> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      AppText(
        'Gender',
        style: AppTypography.subtitle.copyWith(color: LightColors.textStrong),
      ),
      const SizedBox(height: AppSpacing.sm),
      AppSegmentedControl<StaffGender>(
        options: const [
          AppSegmentOption(value: StaffGender.male, label: 'Male'),
          AppSegmentOption(value: StaffGender.female, label: 'Female'),
        ],
        selected: value,
        onChanged: onChanged,
      ),
    ],
  );
}

/// State and LGA side by side. LGA waits for a state and a state change
/// clears it through [onStateChanged].
class StaffLocationFields extends StatelessWidget {
  const StaffLocationFields({
    super.key,
    required this.state,
    required this.lga,
    required this.onStateChanged,
    required this.onLgaChanged,
    this.sheetSubtitle,
  });

  final String? state;
  final String? lga;
  final ValueChanged<String> onStateChanged;
  final ValueChanged<String> onLgaChanged;

  /// "For Chinedu Obi" in the choice sheet while editing.
  final String? sheetSubtitle;

  Future<void> _pickState(BuildContext context) async {
    final picked = await ChoiceListSheet.show<String>(
      context: context,
      title: 'Choose a state',
      subtitle: sheetSubtitle,
      searchHint: 'Search states',
      items: NigeriaLocations.states,
      labelBuilder: (value) => value,
      selected: state,
    );
    if (picked != null) onStateChanged(picked);
  }

  Future<void> _pickLga(BuildContext context) async {
    final currentState = state;
    if (currentState == null) return;
    final picked = await ChoiceListSheet.show<String>(
      context: context,
      title: 'Choose an LGA',
      subtitle: sheetSubtitle,
      searchHint: 'Search LGAs',
      items: NigeriaLocations.lgasOf(currentState),
      labelBuilder: (value) => value,
      selected: lga,
    );
    if (picked != null) onLgaChanged(picked);
  }

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: AppPickerField(
          label: 'State',
          valueText: state,
          placeholder: 'Choose',
          onTap: () => _pickState(context),
        ),
      ),
      const SizedBox(width: AppSpacing.ms),
      Expanded(
        child: AppPickerField(
          label: 'LGA',
          valueText: lga,
          placeholder: 'Choose',
          enabled: state != null,
          helperText: state == null ? 'Choose a state first' : null,
          onTap: () => _pickLga(context),
        ),
      ),
    ],
  );
}
