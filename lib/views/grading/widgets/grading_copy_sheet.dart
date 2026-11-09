import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/class_structure/class_structure.dart';
import 'package:hamrash_admin/api/models/grading/section_grading.dart';
import 'package:hamrash_admin/core/bottomSheets/app_sheet.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/widgets/app_badge.dart';
import 'package:hamrash_admin/core/widgets/app_divider.dart';
import 'package:hamrash_admin/core/widgets/app_sheet_error.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_variants.dart';
import 'package:hamrash_admin/core/widgets/button/bouncy_button.dart';
import 'package:hamrash_admin/core/widgets/selection/app_selection_controls.dart';

enum GradeCopyPart { both, columns, grades }

/// 9.31 · Copy score columns and/or grades from another section into this
/// one. The target keeps its own copy, so later changes stay separate.
class GradingCopySheet extends StatefulWidget {
  const GradingCopySheet({
    super.key,
    required this.target,
    required this.sources,
    required this.gradingOf,
    required this.onCopy,
    this.initialColumns = true,
    this.initialGrades = true,
  });

  final SchoolSection target;
  final List<SchoolSection> sources;
  final SectionGrading Function(SchoolSection source) gradingOf;

  /// Copies into [target]; returns the reason it didn't work, or null.
  final Future<String?> Function(
    String? fromSectionId,
    bool columns,
    bool grades,
  )
  onCopy;

  final bool initialColumns;
  final bool initialGrades;

  @override
  State<GradingCopySheet> createState() => _GradingCopySheetState();
}

class _GradingCopySheetState extends State<GradingCopySheet> {
  SchoolSection? _source;
  late GradeCopyPart _part = widget.initialColumns && widget.initialGrades
      ? GradeCopyPart.both
      : widget.initialGrades
      ? GradeCopyPart.grades
      : GradeCopyPart.columns;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.sources.isNotEmpty) {
      _source = widget.sources.firstWhere(
        (source) => widget.gradingOf(source).isComplete,
        orElse: () => widget.sources.first,
      );
    }
  }

  bool get _wantsColumns => _part != GradeCopyPart.grades;
  bool get _wantsGrades => _part != GradeCopyPart.columns;

  SectionGrading? get _sourceGrading =>
      _source == null ? null : widget.gradingOf(_source!);

  bool get _hasColumns => _sourceGrading?.hasColumns ?? false;
  bool get _hasGrades => _sourceGrading?.gradesTile ?? false;

  bool get _canCopy =>
      !_saving &&
      _source != null &&
      (!_wantsColumns || _hasColumns) &&
      (!_wantsGrades || _hasGrades);

  Future<void> _copy() async {
    final source = _source;
    if (source == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final error = await widget.onCopy(source.id, _wantsColumns, _wantsGrades);
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _saving = false;
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final sourceGrading = _sourceGrading;
    return AppSheet(
      title: 'Copy into ${widget.target.name}',
      subtitle:
          'Start from a section that’s set up. ${widget.target.name} gets its '
          'own copy, so later changes stay separate.',
      bodyPadding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppText(
            'Copy from',
            style: AppTypography.subtitle.copyWith(
              fontSize: 14,
              color: LightColors.textStrong,
            ),
          ),
          const SizedBox(height: 4),
          if (widget.sources.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: AppText(
                'There’s no other section to copy from yet.',
                style: AppTypography.body.copyWith(
                  fontSize: 14,
                  color: LightColors.textMuted,
                ),
              ),
            )
          else
            for (final (i, source) in widget.sources.indexed) ...[
              if (i > 0) const AppDivider(),
              _SourceRow(
                grading: widget.gradingOf(source),
                selected: source.id == _source?.id,
                onTap: () => setState(() {
                  _source = source;
                  _error = null;
                }),
              ),
            ],
          const SizedBox(height: 20),
          AppText(
            'What to copy',
            style: AppTypography.subtitle.copyWith(
              fontSize: 14,
              color: LightColors.textStrong,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AppFilterChip(
                label: 'Both',
                selected: _part == GradeCopyPart.both,
                onTap: () => setState(() => _part = GradeCopyPart.both),
              ),
              AppFilterChip(
                label: 'Score columns',
                selected: _part == GradeCopyPart.columns,
                onTap: () => setState(() => _part = GradeCopyPart.columns),
              ),
              AppFilterChip(
                label: 'Grades',
                selected: _part == GradeCopyPart.grades,
                onTap: () => setState(() => _part = GradeCopyPart.grades),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (sourceGrading != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppPalette.stone50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_wantsColumns)
                    _SummaryLine(
                      label: 'Columns',
                      value: _columnsSummary(sourceGrading),
                    ),
                  if (_wantsColumns && _wantsGrades) const SizedBox(height: 6),
                  if (_wantsGrades)
                    _SummaryLine(
                      label: 'Grades',
                      value: _gradesSummary(sourceGrading),
                    ),
                ],
              ),
            ),
          if (_source != null &&
              ((_wantsColumns && !_hasColumns) ||
                  (_wantsGrades && !_hasGrades))) ...[
            const SizedBox(height: 10),
            AppText(
              _wantsGrades && !_hasGrades
                  ? '${_source!.name} has no grades that cover 0 to 100 yet.'
                  : '${_source!.name} has no score columns yet.',
              style: AppTypography.body.copyWith(
                fontSize: 13,
                height: 18 / 13,
                color: LightColors.errorErrorText,
              ),
            ),
          ],
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
            loadingText: 'Copying…',
            isDisabled: !_canCopy,
            onPressed: _copy,
            child: Text('Copy to ${widget.target.name}'),
          ),
        ],
      ),
    );
  }

  String _columnsSummary(SectionGrading grading) {
    if (!grading.hasColumns) return 'No columns yet';
    final names = grading.columns.map((c) => c.name).join(', ');
    return '$names (${grading.marksLabel})';
  }

  String _gradesSummary(SectionGrading grading) {
    if (!grading.hasGrades) return 'No grades yet';
    if (!grading.gradesTile) {
      return 'Grades don’t cover 0 to 100 yet';
    }
    final ascending = [...grading.grades]
      ..sort((a, b) => a.minPercent.compareTo(b.minPercent));
    return '${grading.grades.length} grades, ${ascending.first.grade} to '
        '${ascending.last.grade} (0 to 100)';
  }
}

class _SourceRow extends StatelessWidget {
  const _SourceRow({
    required this.grading,
    required this.selected,
    required this.onTap,
  });

  final SectionGrading grading;
  final bool selected;
  final VoidCallback onTap;

  String get _summary => grading.usesSchoolSetup
      ? 'School’s setup · ${grading.summary}'
      : grading.summary;

  @override
  Widget build(BuildContext context) => BouncyButton(
    pressedScale: 0.98,
    onPressed: onTap,
    child: SizedBox(
      height: 64,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppText(
                  grading.sectionName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: LightColors.textStrong,
                  ),
                ),
                const SizedBox(height: 2),
                AppText(
                  _summary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body.copyWith(
                    fontSize: 13,
                    height: 18 / 13,
                    color: LightColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          AppRadio<bool>(value: true, groupValue: selected ? true : null),
        ],
      ),
    ),
  );
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 84,
        child: AppText(
          label,
          style: AppTypography.body.copyWith(
            fontSize: 13,
            height: 20 / 13,
            color: LightColors.textMuted,
          ),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: AppText(
          value,
          style: AppTypography.body.copyWith(
            fontSize: 14,
            height: 20 / 14,
            fontWeight: FontWeight.w700,
            color: LightColors.textStrong,
          ),
        ),
      ),
    ],
  );
}
