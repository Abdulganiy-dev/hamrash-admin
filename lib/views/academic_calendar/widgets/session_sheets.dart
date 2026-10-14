import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/bottomSheets/app_sheet.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/utils/app_date_format.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/app_text_field.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_variants.dart';
import 'package:hamrash_admin/core/widgets/button/bouncy_button.dart';
import 'package:hamrash_admin/core/widgets/pickers/app_date_fields.dart';
import 'package:hamrash_admin/core/widgets/selection/app_selection_rows.dart';
import 'package:hamrash_admin/views/academic_calendar/session_draft_model.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Edit the session name and dates.
class EditSessionSheet extends StatefulWidget {
  const EditSessionSheet({
    super.key,
    required this.model,
    this.showRemove = false,
    this.removeBlockedReason,
    this.onRemove,
  });

  final SessionDraftModel model;

  /// Saved sessions only; a session being created has nothing to remove.
  final bool showRemove;

  /// Shown under a greyed-out Remove session.
  final String? removeBlockedReason;

  /// Runs after this sheet closes, e.g. to ask for confirmation.
  final VoidCallback? onRemove;

  @override
  State<EditSessionSheet> createState() => _EditSessionSheetState();
}

class _EditSessionSheetState extends State<EditSessionSheet> {
  late final TextEditingController _name = TextEditingController(
    text: widget.model.draft.name,
  );
  late DateTimeRange _dates = widget.model.draft.dates;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  int? get _outsideIndex {
    for (var i = 0; i < widget.model.draft.terms.length; i++) {
      final term = widget.model.draft.terms[i].dates;
      if (term.start.isBefore(_dates.start) || term.end.isAfter(_dates.end)) {
        return i;
      }
    }
    return null;
  }

  void _save() {
    widget.model.editSession(_name.text, _dates);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final terms = widget.model.draft.terms;
    final outsideIndex = _outsideIndex;
    final outside = outsideIndex == null ? null : terms[outsideIndex];
    final outsideDates = outside?.dates;
    final startsBefore = outsideDates?.start.isBefore(_dates.start) ?? false;
    final warning = outside == null
        ? null
        : startsBefore
        ? '${outside.name} starts ${DateFormat('d MMM').format(outsideDates!.start)}, before this date'
        : '${outside.name} ends ${DateFormat('d MMM').format(outsideDates!.end)}, after this date';
    final canSave =
        _name.text.trim().isNotEmpty &&
        _dates.end.isAfter(_dates.start) &&
        outsideIndex == null;
    final firstTerm = terms.first;
    final lastTerm = terms.last;
    final sessionNote =
        _dates.start.isAtSameMomentAs(firstTerm.dates.start) &&
            _dates.end.isAtSameMomentAs(lastTerm.dates.end)
        ? '${AppDateFormat.length(_dates)} · first day of ${firstTerm.name} to last day of ${lastTerm.name}'
        : AppDateFormat.length(_dates);

    return AppSheet(
      title: 'Edit session',
      subtitle: '${widget.model.draft.name} · ${terms.length} terms',
      bodyPadding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            label: 'Name',
            controller: _name,
            onChanged: (_) => setState(() {}),
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 20),
          AppDateRangeField(
            label: 'Session dates',
            animateChanges: true,
            value: _dates,
            valueFormatter: _paperDateRange,
            firstDate: DateTime(_dates.start.year - 1),
            lastDate: DateTime(_dates.end.year + 2, 12, 31),
            helperText: warning == null ? sessionNote : null,
            warningText: warning,
            onChanged: (value) => setState(() => _dates = value),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppPalette.stone50,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  LucideIcons.info,
                  size: 16,
                  color: AppPalette.stone600,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppText(
                    'Every term has to fit inside these dates.',
                    style: AppTypography.caption.copyWith(
                      fontSize: 13,
                      height: 18 / 13,
                      color: AppPalette.stone600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppPrimaryButton(
            height: 52,
            isDisabled: !canSave,
            onPressed: _save,
            child: const Text('Save session'),
          ),
          if (widget.showRemove) ...[
            const SizedBox(height: 16),
            _SheetRemoveAction(
              label: 'Remove session',
              helper: widget.removeBlockedReason,
              onPressed:
                  widget.removeBlockedReason != null || widget.onRemove == null
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

/// Paper's term sheet, with the remove action below its save button.
class EditTermSheet extends StatefulWidget {
  const EditTermSheet({super.key, required this.model, required this.index});

  final SessionDraftModel model;
  final int? index;

  @override
  State<EditTermSheet> createState() => _EditTermSheetState();
}

class _EditTermSheetState extends State<EditTermSheet> {
  late final bool _adding = widget.index == null;
  late final TextEditingController _name = TextEditingController(
    text: _adding ? '' : widget.model.draft.terms[widget.index!].name,
  );
  late DateTimeRange? _dates = _adding
      ? null
      : widget.model.draft.terms[widget.index!].dates;
  late bool _isCurrent = widget.index == widget.model.draft.currentTermIndex;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() {
    final dates = _dates;
    if (dates == null) return;
    if (_adding) {
      widget.model.addTerm(_name.text, dates);
      if (_isCurrent) {
        widget.model.editTerm(
          widget.model.draft.terms.length - 1,
          _name.text,
          dates,
          isCurrent: true,
        );
      }
    } else {
      widget.model.editTerm(
        widget.index!,
        _name.text,
        dates,
        isCurrent: _isCurrent,
      );
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final index = widget.index;
    final dates = _dates;
    final session = widget.model.draft;
    final canSave =
        _name.text.trim().isNotEmpty &&
        dates != null &&
        dates.end.isAfter(dates.start);
    final note = dates == null
        ? null
        : dates.start.isAtSameMomentAs(session.dates.start)
        ? '${AppDateFormat.length(dates)} · starts with the session'
        : AppDateFormat.length(dates);

    return AppSheet(
      title: _adding ? 'Add a term' : session.terms[index!].name,
      subtitle:
          'Term ${(index ?? session.terms.length) + 1} of ${_adding ? session.terms.length + 1 : session.terms.length} in ${session.name}',
      bodyPadding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            label: 'Name',
            controller: _name,
            onChanged: (_) => setState(() {}),
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 20),
          AppDateRangeField(
            label: 'Term dates',
            animateChanges: true,
            value: dates,
            valueFormatter: _paperDateRange,
            firstDate: session.dates.start,
            lastDate: session.dates.end,
            helperText: note,
            onChanged: (value) => setState(() => _dates = value),
          ),
          const SizedBox(height: 20),
          AppRowGroup.inset(
            children: [
              AppSwitchRow(
                title: 'Current term',
                subtitle:
                    'Attendance, fees and results use this term. Only one at a time.',
                value: _isCurrent,
                onChanged: _isCurrent
                    ? null
                    : (value) => setState(() => _isCurrent = value),
              ),
            ],
          ),
        ],
      ),
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppPrimaryButton(
            height: 52,
            isDisabled: !canSave,
            onPressed: _save,
            child: Text(_adding ? 'Add term' : 'Save term'),
          ),
          if (!_adding) ...[
            const SizedBox(height: 16),
            _SheetRemoveAction(
              label: 'Remove term',
              helper: _isCurrent
                  ? 'Make another term current before removing this one.'
                  : null,
              onPressed: _isCurrent
                  ? null
                  : () {
                      widget.model.removeTerm(index!);
                      Navigator.of(context).pop();
                    },
            ),
          ],
        ],
      ),
    );
  }
}

class _SheetRemoveAction extends StatelessWidget {
  const _SheetRemoveAction({required this.label, this.helper, this.onPressed});

  final String label;
  final String? helper;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final color = onPressed == null
        ? AppPalette.stone400
        : LightColors.errorErrorText;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        BouncyButton(
          isDisabled: onPressed == null,
          onPressed: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.trash2, size: 14, color: color),
                const SizedBox(width: 6),
                AppText(
                  label,
                  style: AppTypography.button.copyWith(color: color),
                ),
              ],
            ),
          ),
        ),
        _AnimatedValue(
          value: helper ?? '',
          child: helper == null
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: AppText(
                    helper!,
                    textAlign: TextAlign.center,
                    style: AppTypography.caption.copyWith(
                      color: AppPalette.stone500,
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

String _paperDateRange(DateTimeRange range) {
  final start = DateFormat(
    range.start.year == range.end.year ? 'EEE d MMM' : 'EEE d MMM y',
  ).format(range.start);
  final end = DateFormat('EEE d MMM y').format(range.end);
  return '$start – $end';
}

/// Moves changed values in and out while allowing their height to settle.
class _AnimatedValue extends StatelessWidget {
  const _AnimatedValue({required this.value, required this.child});

  final String value;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 220);
    return AnimatedSize(
      duration: duration,
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: duration,
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        layoutBuilder: (currentChild, previousChildren) => Stack(
          alignment: Alignment.topCenter,
          children: [
            for (final previous in previousChildren)
              IgnorePointer(child: previous),
            ?currentChild,
          ],
        ),
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.08),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        ),
        child: KeyedSubtree(key: ValueKey(value), child: child),
      ),
    );
  }
}
