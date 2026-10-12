import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/bottomSheets/app_sheet.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_variants.dart';
import 'package:hamrash_admin/core/widgets/selection/app_selection_rows.dart';

/// Pick many: a full sheet of checkbox rows with an optional "Select all"
/// row and a pinned Done button showing the count.
///
/// Resolves with the picked items when Done is tapped, or `null` when the
/// sheet is closed any other way (close button, drag, scrim) — treat that
/// as cancel and keep the old selection.
///
/// ```dart
/// final picked = await MultiSelectBottomSheet.show(
///   context: context,
///   title: 'Subjects taught',
///   items: subjects,
///   initiallySelected: teacher.subjects,
///   labelBuilder: (s) => s.name,
/// );
/// if (picked != null) model.setSubjects(picked);
/// ```
abstract final class MultiSelectBottomSheet {
  MultiSelectBottomSheet._();

  static Future<List<I>?> show<I>({
    required BuildContext context,
    required List<I> items,
    required List<I> initiallySelected,
    required String title,
    String Function(I item)? labelBuilder,
    String Function(I item)? subtitleBuilder,
    bool showSelectAll = true,
    String doneLabel = 'Done',
  }) {
    return Navigator.of(context).push<List<I>>(
      AppSheetRoute<List<I>>(
        child: _MultiSelectBody<I>(
          title: title,
          items: items,
          initiallySelected: initiallySelected,
          labelBuilder: labelBuilder,
          subtitleBuilder: subtitleBuilder,
          showSelectAll: showSelectAll,
          doneLabel: doneLabel,
        ),
      ),
    );
  }
}

class _MultiSelectBody<I> extends StatefulWidget {
  const _MultiSelectBody({
    required this.title,
    required this.items,
    required this.initiallySelected,
    required this.labelBuilder,
    required this.subtitleBuilder,
    required this.showSelectAll,
    required this.doneLabel,
  });

  final String title;
  final List<I> items;
  final List<I> initiallySelected;
  final String Function(I item)? labelBuilder;
  final String Function(I item)? subtitleBuilder;
  final bool showSelectAll;
  final String doneLabel;

  @override
  State<_MultiSelectBody<I>> createState() => _MultiSelectBodyState<I>();
}

class _MultiSelectBodyState<I> extends State<_MultiSelectBody<I>> {
  late final Set<I> _selected = {...widget.initiallySelected};

  /// true when everything is picked, false when nothing is, null in between.
  bool? get _allState {
    if (_selected.isEmpty) return false;
    return widget.items.every(_selected.contains) ? true : null;
  }

  void _toggle(I item) => setState(() {
    if (!_selected.add(item)) _selected.remove(item);
  });

  void _toggleAll(bool pickAll) => setState(() {
    pickAll ? _selected.addAll(widget.items) : _selected.clear();
  });

  String _label(I item) => widget.labelBuilder?.call(item) ?? item.toString();

  @override
  Widget build(BuildContext context) {
    final count = _selected.length;

    return AppSheet(
      title: widget.title,
      subtitle: '$count of ${widget.items.length} selected',
      body: AppRowGroup.inset(
        children: [
          if (widget.showSelectAll && widget.items.length > 1)
            AppCheckboxRow(
              title: 'Select all',
              value: _allState,
              onChanged: _toggleAll,
            ),
          for (final item in widget.items)
            AppCheckboxRow(
              title: _label(item),
              subtitle: widget.subtitleBuilder?.call(item),
              value: _selected.contains(item),
              onChanged: (_) => _toggle(item),
            ),
        ],
      ),
      footer: AppPrimaryButton(
        width: double.infinity,
        onPressed: () =>
            Navigator.of(context).pop(_selected.toList(growable: false)),
        child: Text(
          count == 0
              ? widget.doneLabel
              : '${widget.doneLabel} · $count selected',
        ),
      ),
    );
  }
}
