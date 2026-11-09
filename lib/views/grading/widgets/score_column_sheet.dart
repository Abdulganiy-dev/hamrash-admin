import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hamrash_admin/api/models/grading/grading_numbers.dart';
import 'package:hamrash_admin/api/models/grading/grading_setup.dart';
import 'package:hamrash_admin/api/models/grading/score_column.dart';
import 'package:hamrash_admin/core/bottomSheets/app_sheet.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/widgets/app_badge.dart';
import 'package:hamrash_admin/core/widgets/app_icons.dart';
import 'package:hamrash_admin/core/widgets/app_sheet_error.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/app_text_field.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_variants.dart';
import 'package:hamrash_admin/core/widgets/button/app_sheet_link_action.dart';
import 'package:hamrash_admin/core/widgets/button/bouncy_button.dart';
import 'package:hamrash_admin/views/grading/widgets/grading_preview_line.dart';

/// 9.3 · Add a score column, 9.4 · Edit one: its name, what it's out of and
/// what that does to the total. Adding offers common names as chips; editing
/// has a Position row to move the column on the report card (9.4b). Pops
/// `true` once saved.
class ScoreColumnSheet extends StatefulWidget {
  const ScoreColumnSheet({
    super.key,
    required this.setup,
    required this.onSave,
    this.column,
    this.onRemove,
    this.onMove,
  });

  final GradingSetup setup;

  /// Null to add a new column.
  final ScoreColumn? column;

  /// Saves what was typed; returns the reason it wasn't saved, or null.
  final Future<String?> Function(String name, String marks) onSave;

  /// Run after this sheet closes, to ask for confirmation. Null for a new
  /// column.
  final VoidCallback? onRemove;

  /// Moves the column up (-1) or down (1) on the report card straight away;
  /// returns the reason it didn't work, or null. Null for a new column.
  final Future<String?> Function(int delta)? onMove;

  @override
  State<ScoreColumnSheet> createState() => _ScoreColumnSheetState();
}

class _ScoreColumnSheetState extends State<ScoreColumnSheet> {
  late final ScoreColumn? _saved = widget.column;
  late final _name = TextEditingController(text: _saved?.name ?? '');
  late final _marks = TextEditingController(
    text: _saved == null ? '' : GradingNumbers.format(_saved.maxScore),
  );
  final _nameFocus = FocusNode();
  final _marksFocus = FocusNode();

  /// A taken name shows on blur, shortly after typing stops, and on Save,
  /// not on every keystroke.
  bool _showNameError = false;
  Timer? _nameTimer;
  static const _nameDelay = Duration(milliseconds: 500);

  /// Where the column sits on the report card (1 first), kept here as it
  /// moves, since the setup this sheet was opened with doesn't change.
  late int _position =
      widget.setup.columns.indexWhere((c) => c.id == _saved?.id) + 1;
  bool _moving = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameFocus.addListener(() {
      if (!_nameFocus.hasFocus) _revealNameError();
    });
  }

  @override
  void dispose() {
    _nameTimer?.cancel();
    _nameFocus.dispose();
    _marksFocus.dispose();
    _name.dispose();
    _marks.dispose();
    super.dispose();
  }

  String get _columnName => _name.text.trim();

  String? get _nameProblem =>
      widget.setup.columnNameProblem(_columnName, except: _saved);
  String? get _nameError => _showNameError ? _nameProblem : null;
  String? get _marksProblem => GradingSetup.marksProblem(_marks.text);

  bool get _hasChanges {
    final saved = _saved;
    return saved == null ||
        _columnName != saved.name ||
        GradingSetup.marks(_marks.text) != saved.maxScore;
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

  /// Fills the name from a chip and goes on to the marks.
  void _useSuggestion(String name) {
    _nameTimer?.cancel();
    setState(() {
      _name.value = TextEditingValue(
        text: name,
        selection: TextSelection.collapsed(offset: name.length),
      );
      _showNameError = false;
      _error = null;
    });
    _marksFocus.requestFocus();
  }

  Future<void> _move(int delta) async {
    final onMove = widget.onMove;
    if (onMove == null || _moving) return;
    setState(() {
      _moving = true;
      _error = null;
    });
    final error = await onMove(delta);
    if (!mounted) return;
    setState(() {
      _moving = false;
      if (error == null) {
        _position += delta;
      } else {
        _error = error;
      }
    });
  }

  Future<void> _save() async {
    if (_nameProblem != null) {
      _revealNameError();
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final error = await widget.onSave(_columnName, _marks.text);
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
    final total = widget.setup.totalLine(_marks.text, replacing: saved);
    final count = widget.setup.columns.length;
    final suggestions = saved == null
        ? widget.setup.columnSuggestions
        : const [];
    final canSave =
        !_saving &&
        _columnName.isNotEmpty &&
        GradingSetup.marks(_marks.text) != null &&
        _hasChanges;

    return AppSheet(
      title: saved == null ? 'Add a score column' : 'Edit ${saved.name}',
      subtitle: saved == null
          ? 'A part of each subject’s score, like a test or the exam, and '
                'the most it can earn.'
          : 'A part of each subject’s score, and the most it can earn.',
      bodyPadding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                label: 'Name',
                hintText: 'e.g. CA 1',
                controller: _name,
                focusNode: _nameFocus,
                errorText: _nameError,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                inputFormatters: [LengthLimitingTextInputFormatter(30)],
                onChanged: (_) => _nameChanged(),
              ),
              if (suggestions.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final name in suggestions)
                      AppFilterChip(
                        label: name,
                        suggestion: true,
                        onTap: () => _useSuggestion(name),
                      ),
                  ],
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),
          AppTextField(
            label: 'Out of',
            hintText: 'e.g. 20',
            controller: _marks,
            focusNode: _marksFocus,
            errorText: _marksProblem,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.done,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp('[0-9.,]')),
              LengthLimitingTextInputFormatter(8),
            ],
            suffixIcon: AppText(
              'marks',
              style: AppTypography.bodyLarge.copyWith(
                color: LightColors.textMuted,
              ),
            ),
            onChanged: (_) => setState(() => _error = null),
          ),
          const SizedBox(height: 20),
          GradingPreviewLine(
            label: total.label,
            value: total.value,
            muted: total.muted,
          ),
          if (saved != null && widget.onMove != null && count > 1) ...[
            const SizedBox(height: 20),
            _PositionRow(
              position: _position,
              count: count,
              busy: _moving || _saving,
              onMove: _move,
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
            loadingText: 'Saving…',
            isDisabled: !canSave,
            onPressed: _save,
            child: const Text('Save column'),
          ),
          if (saved != null && widget.onRemove != null) ...[
            const SizedBox(height: AppSpacing.md),
            AppSheetLinkAction(
              icon: AppIcons.trash2,
              label: 'Remove column',
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

/// 9.4b · "Position 2 of 3" with up and down buttons to move the column on
/// the report card. Each button greys out at its end.
class _PositionRow extends StatelessWidget {
  const _PositionRow({
    required this.position,
    required this.count,
    required this.busy,
    required this.onMove,
  });

  final int position;
  final int count;
  final bool busy;
  final ValueChanged<int> onMove;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.only(left: 14, right: 4, top: 4, bottom: 4),
    decoration: BoxDecoration(
      color: AppPalette.stone50,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        AppText(
          'Position',
          style: AppTypography.body.copyWith(
            fontSize: 13,
            height: 18 / 13,
            color: LightColors.textMuted,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: AppText(
            '$position of $count',
            style: AppTypography.subtitle.copyWith(
              color: LightColors.textStrong,
            ),
          ),
        ),
        _MoveButton(
          icon: AppIcons.chevronUp,
          label: 'Move up',
          onPressed: position > 1 && !busy ? () => onMove(-1) : null,
        ),
        _MoveButton(
          icon: AppIcons.chevronDown,
          label: 'Move down',
          onPressed: position < count && !busy ? () => onMove(1) : null,
        ),
      ],
    ),
  );
}

/// Round stone-100 button like the sheet's close button: 36 visible, 44 to
/// tap.
class _MoveButton extends StatelessWidget {
  const _MoveButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: onPressed != null,
    label: label,
    excludeSemantics: true,
    child: BouncyButton(
      isDisabled: onPressed == null,
      onPressed: onPressed,
      child: SizedBox.square(
        dimension: 44,
        child: Center(
          child: Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppPalette.stone100,
              shape: BoxShape.circle,
            ),
            child: AppIcon(
              icon,
              size: 18,
              color: onPressed == null
                  ? AppPalette.stone300
                  : AppPalette.stone700,
            ),
          ),
        ),
      ),
    ),
  );
}
