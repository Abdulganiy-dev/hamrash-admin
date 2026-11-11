import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/students/student_filter.dart';
import 'package:hamrash_admin/core/bottomSheets/app_sheet.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/widgets/app_badge.dart';
import 'package:hamrash_admin/core/widgets/app_search_field.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_variants.dart';
import 'package:hamrash_admin/views/people/people_filter_options.dart';
import 'package:hamrash_admin/views/people/widgets/filter_sheet_parts.dart';

/// 9.2 · Filter and search the students list: class, an arm in it, the
/// subject they take, status and sort. Works on a local draft: "Show
/// results" applies it and closes, closing any other way throws it away.
class StudentFilterSheet extends StatefulWidget {
  const StudentFilterSheet({
    super.key,
    required this.initial,
    required this.options,
  });

  /// The filter the list is showing now.
  final StudentFilter initial;

  /// The classes, arms and subjects to pick from.
  final PeopleFilterOptions options;

  /// Resolves to the new filter, or null when the sheet was closed without
  /// applying.
  static Future<StudentFilter?> show(
    BuildContext context, {
    required StudentFilter initial,
    required PeopleFilterOptions options,
  }) => Navigator.of(context).push<StudentFilter>(
    AppSheetRoute<StudentFilter>(
      size: AppSheetSize.floating,
      child: StudentFilterSheet(initial: initial, options: options),
    ),
  );

  @override
  State<StudentFilterSheet> createState() => _StudentFilterSheetState();
}

class _StudentFilterSheetState extends State<StudentFilterSheet> {
  late StudentFilter _draft = widget.initial;
  late final TextEditingController _search = TextEditingController(
    text: widget.initial.search,
  );

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _change(StudentFilter draft) => setState(() => _draft = draft);

  void _reset() {
    _search.clear();
    _change(StudentFilter.initial);
  }

  Set<T> _toggled<T>(Set<T> set, T value) =>
      set.contains(value) ? ({...set}..remove(value)) : {...set, value};

  @override
  Widget build(BuildContext context) {
    final options = widget.options;
    final arms = options.armsIn(_draft.schoolClass);
    return AppSheet(
      title: 'Filter students',
      headerAction: FilterResetAction(
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
            hintText: 'Search by name or admission number',
            onChanged: (value) => _change(_draft.copyWith(search: value)),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (options.classes.isNotEmpty)
            FilterSection(
              title: 'Class',
              child: Wrap(
                spacing: AppSpacing.sm,
                children: [
                  AppFilterChip(
                    label: 'All',
                    selected: _draft.schoolClass == null,
                    onTap: () => _change(_draft.copyWith(clearClass: true)),
                  ),
                  for (final schoolClass in options.classes)
                    AppFilterChip(
                      label: schoolClass.label,
                      selected: _draft.schoolClass == schoolClass,
                      onTap: () =>
                          _change(_draft.copyWith(schoolClass: schoolClass)),
                    ),
                ],
              ),
            ),
          if (_draft.schoolClass != null && arms.isNotEmpty)
            FilterSection(
              title: 'Arm in ${_draft.schoolClass!.label}',
              child: Wrap(
                spacing: AppSpacing.sm,
                children: [
                  AppFilterChip(
                    label: 'All arms',
                    selected: _draft.arm == null,
                    onTap: () => _change(_draft.copyWith(clearArm: true)),
                  ),
                  for (final arm in arms)
                    AppFilterChip(
                      label: arm.label,
                      selected: _draft.arm == arm,
                      onTap: () => _change(_draft.copyWith(arm: arm)),
                    ),
                ],
              ),
            ),
          if (options.subjects.isNotEmpty)
            FilterSection(
              title: 'Subject',
              child: FilterPickRows(
                hint: 'Shows each student with their class and the teacher '
                    'for it.',
                rows: [
                  FilterPickRow(
                    label: 'Taking',
                    anyLabel: 'Any subject',
                    sheetTitle: 'Subject',
                    searchHint: 'Search subjects',
                    options: options.subjects,
                    value: _draft.subject,
                    onChanged: (pick) => _change(
                      pick == null
                          ? _draft.copyWith(clearSubject: true)
                          : _draft.copyWith(subject: pick),
                    ),
                  ),
                ],
              ),
            ),
          FilterSection(
            title: 'Status',
            child: FilterChips<StudentStatusFilter>(
              values: StudentStatusFilter.values,
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
            child: FilterChips<StudentSort>(
              values: StudentSort.values,
              labelOf: (sort) => sort.label,
              isSelected: (sort) => _draft.sort == sort,
              onTap: (sort) => _change(_draft.copyWith(sort: sort)),
            ),
          ),
        ],
      ),
      footer: AppPrimaryButton(
        useGradient: true,
        onPressed: () => Navigator.of(context).pop<StudentFilter>(_draft),
        child: const AppText('Show results'),
      ),
    );
  }
}
