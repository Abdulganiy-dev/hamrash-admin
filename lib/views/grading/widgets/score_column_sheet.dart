import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hamrash_admin/api/models/grading/grading_numbers.dart';
import 'package:hamrash_admin/api/models/grading/grading_setup.dart';
import 'package:hamrash_admin/api/models/grading/score_column.dart';
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
import 'package:hamrash_admin/views/grading/widgets/grading_preview_line.dart';

/// 9.3 · Add a score column, 9.4 · Edit one: its name, what it's out of and
/// what that does to the total. Pops `true` once saved.
class ScoreColumnSheet extends StatefulWidget {
  const ScoreColumnSheet({
    super.key,
    required this.setup,
    required this.onSave,
    this.column,
    this.onRemove,
  });

  final GradingSetup setup;

  /// Null to add a new column.
  final ScoreColumn? column;

  /// Saves what was typed; returns the reason it wasn't saved, or null.
  final Future<String?> Function(String name, String marks) onSave;

  /// Run after this sheet closes, to ask for confirmation. Null for a new
  /// column.
  final VoidCallback? onRemove;

  @override
  State<ScoreColumnSheet> createState() => _ScoreColumnSheetState();
}

class _ScoreColumnSheetState extends State<ScoreColumnSheet> {
  late final ScoreColumn? _saved = widget.column;
  late final _name = TextEditingController(text: _saved?.name ?? '');
  late final _marks = TextEditingController(
    text: _saved == null ? '' : GradingNumbers.format(_saved.maxScore),
  );
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _marks.dispose();
    super.dispose();
  }

  String get _columnName => _name.text.trim();

  String? get _nameProblem =>
      widget.setup.columnNameProblem(_columnName, except: _saved);
  String? get _marksProblem => GradingSetup.marksProblem(_marks.text);

  bool get _hasChanges {
    final saved = _saved;
    return saved == null ||
        _columnName != saved.name ||
        GradingSetup.marks(_marks.text) != saved.maxScore;
  }

  Future<void> _save() async {
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
    final total = widget.setup.totalWith(_marks.text, replacing: saved);
    final canSave =
        !_saving &&
        _columnName.isNotEmpty &&
        _nameProblem == null &&
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
          AppTextField(
            label: 'Name',
            hintText: 'e.g. CA 1',
            controller: _name,
            errorText: _nameProblem,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            inputFormatters: [LengthLimitingTextInputFormatter(30)],
            onChanged: (_) => setState(() => _error = null),
          ),
          const SizedBox(height: 20),
          AppTextField(
            label: 'Out of',
            hintText: 'e.g. 20',
            controller: _marks,
            errorText: _marksProblem,
            helperText: 'Up to 2 decimal places. Must be above 0.',
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
            label: 'Total becomes',
            value: total == null
                ? 'Enter the marks first'
                : '${GradingNumbers.format(total)} marks, from '
                      '${GradingNumbers.format(widget.setup.totalMarks)} now',
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
