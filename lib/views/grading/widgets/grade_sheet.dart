import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hamrash_admin/api/models/grading/grade_boundary.dart';
import 'package:hamrash_admin/api/models/grading/grading_numbers.dart';
import 'package:hamrash_admin/api/models/grading/grading_setup.dart';
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

/// 9.5 · Add a grade, 9.6 · Edit one: its name, where it starts, a remark
/// and whether it is a pass grade. Shows what saving changes in the scale.
/// Pops `true` once saved.
///
/// [setup] is the scale being edited: the school default or a section's own.
class GradeSheet extends StatefulWidget {
  const GradeSheet({
    super.key,
    required this.setup,
    required this.onSave,
    this.boundary,
    this.initialPercent,
    this.onRemove,
  });

  final GradingSetup setup;

  /// Null to add a new grade.
  final GradeBoundary? boundary;

  /// Starting point filled in for a new grade, e.g. "0" for the one the
  /// scale is missing.
  final String? initialPercent;

  /// Saves what was typed; returns the reason it wasn't saved, or null.
  final Future<String?> Function(
    String grade,
    String percent,
    String remark,
    bool isPass,
  )
  onSave;

  /// Run after this sheet closes, to ask for confirmation. Null for a new
  /// grade.
  final VoidCallback? onRemove;

  @override
  State<GradeSheet> createState() => _GradeSheetState();
}

class _GradeSheetState extends State<GradeSheet> {
  late final GradeBoundary? _saved = widget.boundary;
  late final _grade = TextEditingController(text: _saved?.grade ?? '');
  late final _percent = TextEditingController(
    text: _saved == null
        ? widget.initialPercent ?? ''
        : GradingNumbers.format(_saved.minPercent),
  );
  late final _remark = TextEditingController(text: _saved?.remark ?? '');
  late bool _isPass =
      _saved?.isPass ?? widget.setup.defaultIsPass(widget.initialPercent ?? '');
  final _gradeFocus = FocusNode();

  /// Once the person flips the switch, typing the start no longer moves it.
  bool _passTouched = false;

  /// A taken name shows on blur, shortly after typing stops, and on Save,
  /// not on every keystroke.
  bool _showNameError = false;
  Timer? _nameTimer;
  static const _nameDelay = Duration(milliseconds: 500);
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _gradeFocus.addListener(() {
      if (!_gradeFocus.hasFocus) _revealNameError();
    });
  }

  @override
  void dispose() {
    _nameTimer?.cancel();
    _gradeFocus.dispose();
    _grade.dispose();
    _percent.dispose();
    _remark.dispose();
    super.dispose();
  }

  String get _gradeName => _grade.text.trim();

  String? get _gradeProblem =>
      widget.setup.gradeNameProblem(_gradeName, except: _saved);
  String? get _gradeNameError => _showNameError ? _gradeProblem : null;
  String? get _percentProblem =>
      widget.setup.percentProblem(_percent.text, except: _saved);
  double? get _minPercent =>
      widget.setup.percent(_percent.text, except: _saved);

  bool get _hasChanges {
    final saved = _saved;
    return saved == null ||
        _gradeName != saved.grade ||
        _minPercent != saved.minPercent ||
        _remark.text.trim() != (saved.remark ?? '') ||
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

  void _percentChanged() => setState(() {
    _error = null;
    if (_saved == null && !_passTouched) {
      _isPass = widget.setup.defaultIsPass(_percent.text);
    }
  });

  Future<void> _save() async {
    if (_gradeProblem != null) {
      _revealNameError();
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final error = await widget.onSave(
      _gradeName,
      _percent.text,
      _remark.text,
      _isPass,
    );
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
    final canSave =
        !_saving && _gradeName.isNotEmpty && _minPercent != null && _hasChanges;
    final changes = widget.setup.gradeChanges(
      name: _grade.text,
      percentText: _percent.text,
      except: _saved,
    );
    final warning = widget.setup.gradeOrderWarning(
      name: _grade.text,
      percentText: _percent.text,
      except: _saved,
    );

    return AppSheet(
      title: saved == null ? 'Add a grade' : 'Edit grade ${saved.grade}',
      subtitle:
          'Scores from this point up get this grade, until the next grade '
          'starts.',
      bodyPadding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            label: 'Grade',
            hintText: 'e.g. A',
            controller: _grade,
            focusNode: _gradeFocus,
            errorText: _gradeNameError,
            textCapitalization: TextCapitalization.characters,
            textInputAction: TextInputAction.next,
            inputFormatters: [LengthLimitingTextInputFormatter(10)],
            onChanged: (_) => _nameChanged(),
          ),
          const SizedBox(height: 20),
          AppTextField(
            label: 'Starts at',
            hintText: 'e.g. 65',
            controller: _percent,
            errorText: _percentProblem,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.next,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp('[0-9.,]')),
              LengthLimitingTextInputFormatter(6),
            ],
            suffixIcon: AppText(
              '%',
              style: AppTypography.bodyLarge.copyWith(
                color: LightColors.textMuted,
              ),
            ),
            onChanged: (_) => _percentChanged(),
          ),
          const SizedBox(height: 20),
          if (changes.isNotEmpty) ...[
            GradingChangesBlock(changes: changes),
            if (warning != null) ...[
              const SizedBox(height: 8),
              GradingWarningLine(message: warning),
            ],
            const SizedBox(height: 20),
          ],
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
            child: const Text('Save grade'),
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
                  'Marks the subject as passed.',
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
