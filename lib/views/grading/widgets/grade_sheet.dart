import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hamrash_admin/api/models/grading/grade_boundary.dart';
import 'package:hamrash_admin/api/models/grading/grade_editing.dart';
import 'package:hamrash_admin/api/models/grading/section_grading.dart';
import 'package:hamrash_admin/core/bottomSheets/app_sheet.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/widgets/app_icons.dart';
import 'package:hamrash_admin/core/widgets/app_sheet_error.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/app_text_field.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_variants.dart';
import 'package:hamrash_admin/core/widgets/button/app_sheet_link_action.dart';
import 'package:hamrash_admin/core/widgets/button/bouncy_button.dart';
import 'package:hamrash_admin/core/widgets/selection/app_selection_controls.dart';
import 'package:hamrash_admin/views/grading/widgets/grading_preview_line.dart';

/// 9.35–9.38 · Add or edit one grade: its name, From and To, remark and
/// whether it is a pass. Moves the neighbouring ranges as the design does:
/// editing To moves where the grade above starts, editing From moves where
/// the grade below ends. Pops `true` once saved.
class GradeSheet extends StatefulWidget {
  const GradeSheet({
    super.key,
    required this.grading,
    required this.onSave,
    this.grade,
    this.initialFrom,
    this.onRemove,
  });

  final SectionGrading grading;

  /// Saves the whole new scale; returns the reason it wasn't saved, or null.
  final Future<String?> Function(List<GradeBoundary> grades) onSave;

  /// Null to add a new grade.
  final GradeBoundary? grade;

  /// Starting point filled in for a new grade, e.g. "0".
  final String? initialFrom;

  /// Run after this sheet closes, to ask for confirmation. Null for a new
  /// grade.
  final VoidCallback? onRemove;

  @override
  State<GradeSheet> createState() => _GradeSheetState();
}

class _GradeSheetState extends State<GradeSheet> {
  late final GradeBoundary? _saved = widget.grade;
  late final _name = TextEditingController(text: _saved?.grade ?? '');
  late final _from = TextEditingController(
    text: _saved?.minPercent.toString() ?? widget.initialFrom ?? '',
  );
  late final _to = TextEditingController(
    text: _saved?.maxPercent.toString() ?? '',
  );
  late final _remark = TextEditingController(text: _saved?.remark ?? '');
  late bool _isPass =
      _saved?.isPass ?? widget.grading.defaultIsPass(widget.initialFrom ?? '');
  final _nameFocus = FocusNode();

  bool _passTouched = false;
  bool _showNameError = false;
  Timer? _nameTimer;
  static const _nameDelay = Duration(milliseconds: 500);
  bool _saving = false;
  String? _error;

  bool get _isNew => _saved == null;

  @override
  void initState() {
    super.initState();
    _nameFocus.addListener(() {
      if (!_nameFocus.hasFocus) _revealNameError();
    });
    _refreshDerivedTo();
  }

  /// A new grade's To follows the band it splits; it isn't typed.
  void _refreshDerivedTo() {
    if (!_isNew) return;
    final text = _derivedTo?.toString() ?? '';
    if (_to.text == text) return;
    _to.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  int? get _derivedTo {
    final from = _whole(_from);
    if (from == null) return null;
    final ascending = [...widget.grading.grades]
      ..sort((a, b) => a.minPercent.compareTo(b.minPercent));
    if (ascending.isEmpty) return from == 0 ? 100 : null;
    final lowest = ascending.first;
    if (from == 0 && lowest.minPercent > 0) return lowest.minPercent - 1;
    final band = ascending
        .where((g) => from >= g.minPercent && from <= g.maxPercent)
        .firstOrNull;
    if (band == null || from == band.minPercent) return null;
    return band.maxPercent;
  }

  @override
  void dispose() {
    _nameTimer?.cancel();
    _nameFocus.dispose();
    _name.dispose();
    _from.dispose();
    _to.dispose();
    _remark.dispose();
    super.dispose();
  }

  String get _gradeName => _name.text.trim();

  String? get _nameProblem =>
      widget.grading.gradeNameProblem(_gradeName, except: _saved);
  String? get _nameError => _showNameError ? _nameProblem : null;

  int? _whole(TextEditingController controller) {
    final text = controller.text.trim();
    if (text.isEmpty) return null;
    return int.tryParse(text);
  }

  bool _invalidNumber(TextEditingController controller) {
    final text = controller.text.trim();
    if (text.isEmpty) return false;
    final value = int.tryParse(text);
    return value == null || value < 0 || value > 100;
  }

  bool get _isTop {
    final saved = _saved;
    if (saved == null) return false;
    final ascending = [...widget.grading.grades]
      ..sort((a, b) => a.minPercent.compareTo(b.minPercent));
    return ascending.isNotEmpty && ascending.last.id == saved.id;
  }

  bool get _isBottom {
    final saved = _saved;
    if (saved == null) return false;
    final ascending = [...widget.grading.grades]
      ..sort((a, b) => a.minPercent.compareTo(b.minPercent));
    return ascending.isNotEmpty && ascending.first.id == saved.id;
  }

  GradeEditOutcome get _outcome {
    if (_invalidNumber(_from) || (!_isNew && !_isTop && _invalidNumber(_to))) {
      return const GradeEditOutcome(
        error:
            'Use a number from 0 to 100. Grades are a percent of the '
            'section’s marks.',
      );
    }
    final from = _whole(_from);
    if (_isNew) {
      return GradeEditor.add(
        grades: widget.grading.grades,
        name: _gradeName,
        from: from,
        remark: _remarkValue,
        isPass: _isPass,
        sectionName: widget.grading.sectionName,
      );
    }
    return GradeEditor.edit(
      grades: widget.grading.grades,
      original: _saved!,
      name: _gradeName,
      from: from,
      to: _isTop ? 100 : _whole(_to),
      remark: _remarkValue,
      isPass: _isPass,
      sectionName: widget.grading.sectionName,
    );
  }

  String? get _remarkValue {
    final value = _remark.text.trim();
    return value.isEmpty ? null : value;
  }

  bool get _hasChanges {
    final saved = _saved;
    if (saved == null) return _outcome.canSave;
    return _gradeName != saved.grade ||
        _whole(_from) != saved.minPercent ||
        (_isTop ? 100 : _whole(_to)) != saved.maxPercent ||
        _remarkValue != saved.remark ||
        _isPass != saved.isPass;
  }

  void _revealNameError() {
    _nameTimer?.cancel();
    if (mounted && !_showNameError) setState(() => _showNameError = true);
  }

  void _nameChanged() {
    _nameTimer?.cancel();
    _nameTimer = Timer(_nameDelay, _revealNameError);
    setState(() {
      _error = null;
      _showNameError = false;
    });
  }

  void _fieldChanged() {
    setState(() {
      _error = null;
      if (_isNew && !_passTouched) {
        _isPass = widget.grading.defaultIsPass(_from.text);
      }
    });
    _refreshDerivedTo();
  }

  Future<void> _save() async {
    final outcome = _outcome;
    if (_nameProblem != null) {
      _revealNameError();
      return;
    }
    final grades = outcome.grades;
    if (grades == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final error = await widget.onSave(grades);
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
    final saved = _saved;
    final outcome = _outcome;
    final error = _nameProblem == null ? outcome.error : null;
    final canSave =
        !_saving &&
        _gradeName.isNotEmpty &&
        _nameProblem == null &&
        outcome.canSave &&
        _hasChanges;
    final title = _isNew
        ? (widget.initialFrom == '0'
              ? 'Add a grade from 0'
              : 'Add a grade to ${widget.grading.sectionName}')
        : 'Edit grade ${saved!.grade}';
    final marks = widget.grading.marksLabel;
    final subtitle = _isNew
        ? 'Percent of its $marks. Only ${widget.grading.sectionName} gets '
              'it.'
        : widget.grading.totalIsHundred
        ? 'In ${widget.grading.sectionName}. Percent of its 100 marks: 85 '
              'out of 100 is 85%.'
        : 'In ${widget.grading.sectionName}. Percent of its $marks.';

    return AppSheet(
      title: title,
      subtitle: subtitle,
      bodyPadding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            label: 'Grade',
            hintText: 'e.g. A',
            controller: _name,
            focusNode: _nameFocus,
            errorText: _nameError,
            textCapitalization: TextCapitalization.characters,
            textInputAction: TextInputAction.next,
            inputFormatters: [LengthLimitingTextInputFormatter(10)],
            onChanged: (_) => _nameChanged(),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AppTextField(
                  label: 'From',
                  hintText: 'e.g. 60',
                  controller: _from,
                  readOnly: _isBottom,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(3),
                  ],
                  suffixIcon: _isBottom
                      ? const AppIcon(
                          AppIcons.lock,
                          size: 16,
                          color: LightColors.textMuted,
                        )
                      : null,
                  onChanged: (_) => _fieldChanged(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 48, 10, 0),
                child: AppText(
                  'to',
                  style: AppTypography.body.copyWith(
                    fontSize: 14,
                    height: 20 / 14,
                    color: LightColors.textMuted,
                  ),
                ),
              ),
              Expanded(
                child: AppTextField(
                  label: 'To',
                  hintText: 'e.g. 69',
                  controller: _to,
                  readOnly: _isNew || _isTop,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(3),
                  ],
                  suffixIcon: _isTop
                      ? const AppIcon(
                          AppIcons.lock,
                          size: 16,
                          color: LightColors.textMuted,
                        )
                      : null,
                  onChanged: (_) => _fieldChanged(),
                ),
              ),
            ],
          ),
          if (_isTop) ...[
            const SizedBox(height: 8),
            GradingNoteLine(
              message:
                  '${saved!.grade} is the top grade, so it always goes up to '
                  '100.',
            ),
          ] else if (_isBottom) ...[
            const SizedBox(height: 8),
            GradingNoteLine(
              message:
                  '${saved!.grade} is the lowest grade, so it always starts '
                  'at 0.',
            ),
          ],
          if (error != null) ...[
            const SizedBox(height: 10),
            GradingErrorLine(message: error),
          ],
          if (error == null && outcome.changes.isNotEmpty) ...[
            const SizedBox(height: 20),
            GradingChangesBlock(changes: outcome.changes),
          ],
          const SizedBox(height: 20),
          AppTextField(
            label: 'Remark',
            isOptional: true,
            hintText: 'e.g. Very Good',
            controller: _remark,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            inputFormatters: [LengthLimitingTextInputFormatter(40)],
            onChanged: (_) => setState(() => _error = null),
          ),
          const SizedBox(height: 20),
          _PassToggle(
            value: _isPass,
            onChanged: (value) => setState(() {
              _isPass = value;
              _passTouched = true;
              _error = null;
            }),
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
            loadingText: 'Saving…',
            isDisabled: !canSave,
            onPressed: _save,
            child: Text(_isNew ? 'Add grade' : 'Save grade'),
          ),
          if (saved != null && widget.onRemove != null) ...[
            const SizedBox(height: AppSpacing.md),
            AppSheetLinkAction(
              icon: AppIcons.trash2,
              label: 'Remove grade',
              isDestructive: true,
              onPressed: _saving
                  ? null
                  : () {
                      Navigator.of(context).pop();
                      widget.onRemove!();
                    },
            ),
          ],
        ],
      ),
    );
  }
}

/// "Pass grade" with its switch; the whole card toggles it.
class _PassToggle extends StatelessWidget {
  const _PassToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => BouncyButton(
    pressedScale: 0.98,
    onPressed: () => onChanged(!value),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppPalette.stone50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  'Pass grade',
                  style: AppTypography.subtitle.copyWith(
                    fontSize: 15,
                    color: LightColors.textStrong,
                  ),
                ),
                const SizedBox(height: 2),
                AppText(
                  value
                      ? 'Marks the subject as passed.'
                      : 'Off, so a subject in this range is failed.',
                  style: AppTypography.body.copyWith(
                    fontSize: 13,
                    height: 18 / 13,
                    color: LightColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          AppSwitch(value: value),
        ],
      ),
    ),
  );
}
