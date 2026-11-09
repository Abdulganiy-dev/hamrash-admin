import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hamrash_admin/api/models/grading/grading_numbers.dart';
import 'package:hamrash_admin/api/models/grading/score_column.dart';
import 'package:hamrash_admin/api/models/grading/section_grading.dart';
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

/// 9.28–9.30 · Add or edit a score column: its name, what it is out of, where
/// it sits on the report card, and what saving does to the total. Pops `true`
/// once saved.
class ScoreColumnSheet extends StatefulWidget {
  const ScoreColumnSheet({
    super.key,
    required this.grading,
    required this.sectionName,
    required this.position,
    required this.count,
    required this.onSave,
    this.column,
    this.onRemove,
    this.onMove,
  });

  final SectionGrading grading;
  final String sectionName;

  /// 1 first. For a new column this is where it will be put.
  final int position;

  /// Columns already in the set.
  final int count;

  /// Saves what was typed; returns the reason it wasn't saved, or null.
  final Future<String?> Function(String name, String marks, int position)
  onSave;

  /// Null to add a new column.
  final ScoreColumn? column;

  /// Run after this sheet closes, to ask for confirmation. Null for a new
  /// column.
  final VoidCallback? onRemove;

  /// Moves an existing column up (-1) or down (1) straight away; returns the
  /// reason it didn't work, or null. Null for a new column.
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

  bool _showNameError = false;
  Timer? _nameTimer;
  static const _nameDelay = Duration(milliseconds: 500);

  late int _position = widget.position;
  bool _moving = false;
  bool _saving = false;
  String? _error;

  bool get _isNew => _saved == null;
  int get _maxPosition => _isNew ? widget.count + 1 : widget.count;

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
      widget.grading.columnNameProblem(_columnName, except: _saved);
  String? get _nameError => _showNameError ? _nameProblem : null;
  String? get _marksProblem => SectionGrading.marksProblem(_marks.text);

  bool get _hasChanges {
    final saved = _saved;
    return saved == null ||
        _columnName != saved.name ||
        SectionGrading.marks(_marks.text) != saved.maxScore ||
        _position != widget.position;
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
    final target = _position + delta;
    if (target < 1 || target > _maxPosition) return;
    if (_isNew) {
      setState(() => _position = target);
      return;
    }
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
        _position = target;
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
    final error = await widget.onSave(_columnName, _marks.text, _position);
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

  String get _positionLabel {
    if (_isNew) {
      if (_position > widget.count) {
        return '$_position of ${widget.count + 1}, last';
      }
      final before = widget.grading.columns[_position - 1].name;
      return '$_position of ${widget.count + 1}, before $before';
    }
    return '$_position of ${widget.count}';
  }

  @override
  Widget build(BuildContext context) {
    final saved = _saved;
    final total = widget.grading.totalLine(_marks.text, replacing: saved);
    final suggestions = saved == null
        ? widget.grading.columnSuggestions
        : const [];
    final canSave =
        !_saving &&
        _columnName.isNotEmpty &&
        SectionGrading.marks(_marks.text) != null &&
        _hasChanges;
    final showPosition = _isNew ? widget.count > 0 : widget.count > 1;

    return AppSheet(
      title: saved == null
          ? 'Add a column to ${widget.sectionName}'
          : 'Edit ${saved.name}',
      subtitle: saved == null
          ? 'A part of each subject’s score and the most it can earn. '
                'Only ${widget.sectionName} gets it.'
          : 'In ${widget.sectionName}. A part of each subject’s score and '
                'the most it can earn.',
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
          if (showPosition) ...[
            const SizedBox(height: 20),
            _PositionRow(
              label: _positionLabel,
              position: _position,
              maxPosition: _maxPosition,
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
            child: Text(saved == null ? 'Add column' : 'Save column'),
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

/// "Position 2 of 3" with up and down buttons. Greyed at each end.
class _PositionRow extends StatelessWidget {
  const _PositionRow({
    required this.label,
    required this.position,
    required this.maxPosition,
    required this.busy,
    required this.onMove,
  });

  final String label;
  final int position;
  final int maxPosition;
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
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.subtitle.copyWith(
              fontSize: 14,
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
          onPressed: position < maxPosition && !busy ? () => onMove(1) : null,
        ),
      ],
    ),
  );
}

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
