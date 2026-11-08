import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/organization_models/organization_member.dart';
import 'package:hamrash_admin/api/models/team/staff_filter.dart';
import 'package:hamrash_admin/api/models/team/staff_member.dart';
import 'package:hamrash_admin/core/bottomSheets/app_sheet.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/widgets/app_badge.dart';
import 'package:hamrash_admin/core/widgets/app_search_field.dart';
import 'package:hamrash_admin/core/widgets/app_segmented_control.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_variants.dart';
import 'package:hamrash_admin/core/widgets/button/bouncy_button.dart';

/// 8.17 · Filter and search the staff list. Works on a local draft: "Show
/// results" applies it and closes, closing any other way throws it away.
/// Nothing is asked of the server until then.
class StaffFilterSheet extends StatefulWidget {
  const StaffFilterSheet({
    super.key,
    required this.initial,
  });

  /// The filter the list is showing now.
  final StaffFilter initial;

  /// Resolves to the new filter, or null when the sheet was closed without
  /// applying.
  static Future<StaffFilter?> show(
    BuildContext context, {
    required StaffFilter initial,
  }) => Navigator.of(context).push<StaffFilter>(
    AppSheetRoute<StaffFilter>(
      size: AppSheetSize.floating,
      child: StaffFilterSheet(initial: initial),
    ),
  );

  @override
  State<StaffFilterSheet> createState() => _StaffFilterSheetState();
}

class _StaffFilterSheetState extends State<StaffFilterSheet> {
  late StaffFilter _draft = widget.initial;
  late final TextEditingController _search = TextEditingController(
    text: widget.initial.search,
  );

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _change(StaffFilter draft) => setState(() => _draft = draft);

  void _reset() {
    _search.clear();
    _change(StaffFilter.initial);
  }

  Set<T> _toggled<T>(Set<T> set, T value) =>
      set.contains(value) ? ({...set}..remove(value)) : {...set, value};

  @override
  Widget build(BuildContext context) {
    return AppSheet(
      title: 'Filter staff',
      headerAction: _ResetAction(
        enabled: !_draft.isDefault,
        onPressed: _reset,
      ),
      bodyPadding: const EdgeInsets.fromLTRB(
        AppSpacing.ml,
        AppSpacing.ml,
        AppSpacing.ml,
        AppSpacing.md,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSearchField(
            controller: _search,
            hintText: 'Search by name, phone or staff number',
            onChanged: (value) => _change(_draft.copyWith(search: value)),
          ),
          const SizedBox(height: AppSpacing.lg),
          _Section(
            title: 'Login',
            child: _Chips<StaffLoginFilter>(
              values: StaffLoginFilter.values,
              labelOf: (login) => login.label,
              isSelected: (login) => _draft.login == login,
              onTap: (login) => _change(_draft.copyWith(login: login)),
            ),
          ),
          _Section(
            title: 'Role',
            child: _Chips<OrganizationMemberRole>(
              values: StaffFilter.roleOptions,
              labelOf: (role) => role.teamLabel,
              isSelected: _draft.roles.contains,
              onTap: (role) =>
                  _change(_draft.copyWith(roles: _toggled(_draft.roles, role))),
            ),
          ),
          _Section(
            title: 'Staff type',
            // The chips elsewhere carry 4 of their own below; this doesn't.
            gapAfter: AppSpacing.lg,
            child: AppSegmentedControl<StaffTypeFilter>(
              options: [
                for (final type in StaffTypeFilter.values)
                  AppSegmentOption(value: type, label: type.label),
              ],
              selected: _draft.staffType,
              onChanged: (type) => _change(_draft.copyWith(staffType: type)),
            ),
          ),
          _Section(
            title: 'Status',
            child: _Chips<StaffRecordStatus>(
              values: StaffRecordStatus.values,
              labelOf: (status) => status.label,
              isSelected: _draft.statuses.contains,
              onTap: (status) => _change(
                _draft.copyWith(statuses: _toggled(_draft.statuses, status)),
              ),
            ),
          ),
          _Section(
            title: 'Sort by',
            gapAfter: 0,
            child: _Chips<StaffSort>(
              values: StaffSort.values,
              labelOf: (sort) => sort.label,
              isSelected: (sort) => _draft.sort == sort,
              onTap: (sort) => _change(_draft.copyWith(sort: sort)),
            ),
          ),
        ],
      ),
      footer: AppPrimaryButton(
        useGradient: true,
        onPressed: () => Navigator.of(context).pop<StaffFilter>(_draft),
        child: const AppText('Show results'),
      ),
    );
  }
}

/// "Reset": aubergine while there is something to reset, stone-400 when not.
class _ResetAction extends StatelessWidget {
  const _ResetAction({required this.enabled, required this.onPressed});

  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: enabled,
    label: 'Reset',
    excludeSemantics: true,
    child: BouncyButton(
      isDisabled: !enabled,
      onPressed: enabled ? onPressed : null,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        alignment: Alignment.center,
        child: AppText(
          'Reset',
          style: AppTypography.subtitle.copyWith(
            color: enabled
                ? LightColors.primaryPrimaryText
                : LightColors.textDisabled,
          ),
        ),
      ),
    ),
  );
}

/// A bold label over its control. The chips bring 4 above and below, so the
/// gaps here are 4 short of the 12 under a label and 24 between sections.
class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.child,
    this.gapAfter = AppSpacing.ml,
  });

  final String title;
  final Widget child;
  final double gapAfter;

  @override
  Widget build(BuildContext context) {
    final chips = child is! AppSegmentedControl;
    return Padding(
      padding: EdgeInsets.only(bottom: gapAfter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppText(
            title,
            style: AppTypography.subtitle.copyWith(
              color: LightColors.textStrong,
            ),
          ),
          SizedBox(height: chips ? AppSpacing.sm : AppSpacing.ms),
          child,
        ],
      ),
    );
  }
}

/// A wrapping group of [AppFilterChip]s, 8 apart.
class _Chips<T> extends StatelessWidget {
  const _Chips({
    required this.values,
    required this.labelOf,
    required this.isSelected,
    required this.onTap,
  });

  final List<T> values;
  final String Function(T value) labelOf;
  final bool Function(T value) isSelected;
  final ValueChanged<T> onTap;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: AppSpacing.sm,
    children: [
      for (final value in values)
        AppFilterChip(
          label: labelOf(value),
          selected: isSelected(value),
          onTap: () => onTap(value),
        ),
    ],
  );
}
