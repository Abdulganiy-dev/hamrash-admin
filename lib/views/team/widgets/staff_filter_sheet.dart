import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/organization_models/organization_member.dart';
import 'package:hamrash_admin/api/models/team/staff_filter.dart';
import 'package:hamrash_admin/api/models/team/staff_member.dart';
import 'package:hamrash_admin/core/bottomSheets/app_sheet.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/widgets/app_search_field.dart';
import 'package:hamrash_admin/core/widgets/app_segmented_control.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_variants.dart';
import 'package:hamrash_admin/views/people/people_filter_options.dart';
import 'package:hamrash_admin/views/people/widgets/filter_sheet_parts.dart';

/// 9.4 · Filter and search the staff list. Works on a local draft: "Show
/// results" applies it and closes, closing any other way throws it away.
/// Nothing is asked of the server until then.
class StaffFilterSheet extends StatefulWidget {
  const StaffFilterSheet({
    super.key,
    required this.initial,
    this.options = PeopleFilterOptions.empty,
  });

  /// The filter the list is showing now.
  final StaffFilter initial;

  /// The subjects and classes the Teaches pickers offer. Without any subject
  /// the Teaches section is left out.
  final PeopleFilterOptions options;

  /// Resolves to the new filter, or null when the sheet was closed without
  /// applying.
  static Future<StaffFilter?> show(
    BuildContext context, {
    required StaffFilter initial,
    PeopleFilterOptions options = PeopleFilterOptions.empty,
  }) => Navigator.of(context).push<StaffFilter>(
    AppSheetRoute<StaffFilter>(
      size: AppSheetSize.floating,
      child: StaffFilterSheet(initial: initial, options: options),
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
      headerAction: FilterResetAction(enabled: !_draft.isDefault, onPressed: _reset),
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
          FilterSection(
            title: 'Login',
            child: FilterChips<StaffLoginFilter>(
              values: StaffLoginFilter.values,
              labelOf: (login) => login.label,
              isSelected: (login) => _draft.login == login,
              onTap: (login) => _change(_draft.copyWith(login: login)),
            ),
          ),
          FilterSection(
            title: 'Role',
            child: FilterChips<OrganizationMemberRole>(
              values: StaffFilter.roleOptions,
              labelOf: (role) => role.teamLabel,
              isSelected: _draft.roles.contains,
              onTap: (role) =>
                  _change(_draft.copyWith(roles: _toggled(_draft.roles, role))),
            ),
          ),
          FilterSection(
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
          if (widget.options.subjects.isNotEmpty)
            FilterSection(
              title: 'Teaches',
              child: FilterPickRows(
                hint: 'Lists each teacher with the classes where they teach it.',
                rows: [
                  FilterPickRow(
                    label: 'Subject',
                    anyLabel: 'Any subject',
                    sheetTitle: 'Subject',
                    searchHint: 'Search subjects',
                    options: widget.options.subjects,
                    value: _draft.subject,
                    onChanged: (pick) => _change(
                      pick == null
                          ? _draft.copyWith(clearSubject: true)
                          : _draft.copyWith(subject: pick),
                    ),
                  ),
                  FilterPickRow(
                    label: 'Class',
                    anyLabel: 'Any class',
                    sheetTitle: 'Class',
                    searchHint: 'Search classes',
                    options: widget.options.classes,
                    value: _draft.schoolClass,
                    onChanged: (pick) => _change(
                      pick == null
                          ? _draft.copyWith(clearClass: true)
                          : _draft.copyWith(schoolClass: pick),
                    ),
                  ),
                ],
              ),
            ),
          FilterSection(
            title: 'Status',
            child: FilterChips<StaffRecordStatus>(
              values: StaffRecordStatus.values,
              labelOf: (status) => status.label,
              isSelected: _draft.statuses.contains,
              onTap: (status) => _change(
                _draft.copyWith(statuses: _toggled(_draft.statuses, status)),
              ),
            ),
          ),
          FilterSection(
            title: 'Sort by',
            gapAfter: 0,
            child: FilterChips<StaffSort>(
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
