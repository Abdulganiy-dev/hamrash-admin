import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/bottomSheets/app_sheet.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/radius_containers.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/widgets/app_divider.dart';
import 'package:hamrash_admin/core/widgets/app_search_field.dart';
import 'package:hamrash_admin/core/widgets/selection/app_selection_controls.dart';
import 'package:hamrash_admin/core/widgets/selection/app_selection_rows.dart';

/// A searchable, single-choice list in a floating sheet: 56px radio rows
/// with hairlines, a close X and the selected row scrolled into view. Used
/// for the staff residence state and LGA.
class ChoiceListSheet<T> extends StatefulWidget {
  const ChoiceListSheet({
    super.key,
    required this.title,
    required this.searchHint,
    required this.items,
    required this.labelBuilder,
    this.subtitle,
    this.selected,
  });

  final String title;

  /// "For Chinedu Obi" while editing a staff member.
  final String? subtitle;
  final String searchHint;
  final List<T> items;
  final String Function(T item) labelBuilder;
  final T? selected;

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required String searchHint,
    required List<T> items,
    required String Function(T item) labelBuilder,
    T? selected,
    String? subtitle,
  }) => Navigator.of(context).push<T>(
    AppSheetRoute<T>(
      size: AppSheetSize.floating,
      child: ChoiceListSheet<T>(
        title: title,
        subtitle: subtitle,
        searchHint: searchHint,
        items: items,
        labelBuilder: labelBuilder,
        selected: selected,
      ),
    ),
  );

  @override
  State<ChoiceListSheet<T>> createState() => _ChoiceListSheetState<T>();
}

class _ChoiceListSheetState<T> extends State<ChoiceListSheet<T>> {
  static const _rowExtent = 57.0;

  final _scrollController = ScrollController();
  String _query = '';

  List<T> get _visible {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return widget.items;
    return [
      for (final item in widget.items)
        if (widget.labelBuilder(item).toLowerCase().contains(query)) item,
    ];
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _revealSelected());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _revealSelected() {
    final selected = widget.selected;
    if (selected == null || !_scrollController.hasClients) return;
    final index = widget.items.indexOf(selected);
    if (index < 0) return;
    final max = _scrollController.position.maxScrollExtent;
    _scrollController.jumpTo(math.min(index * _rowExtent, max));
  }

  void _search(String value) {
    setState(() => _query = value);
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visible;
    final listHeight = math.min(392.0, MediaQuery.sizeOf(context).height * 0.5);

    return AppSheet(
      title: widget.title,
      subtitle: widget.subtitle,
      scrollableBody: false,
      bodyPadding: const EdgeInsets.fromLTRB(
        AppSpacing.ml,
        AppSpacing.ms,
        AppSpacing.ml,
        AppSpacing.ml,
      ),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSearchField(hintText: widget.searchHint, onChanged: _search),
          const SizedBox(height: AppSpacing.ms),
          SizedBox(
            height: listHeight,
            child: ClipRRect(
              borderRadius: AppRadius.brLg,
              child: ColoredBox(
                color: AppPalette.stone50,
                child: ListView.separated(
                  controller: _scrollController,
                  padding: EdgeInsets.zero,
                  itemCount: visible.length,
                  separatorBuilder: (context, index) => const AppDivider(),
                  itemBuilder: (context, index) {
                    final item = visible[index];
                    return AppSelectionRow(
                      title: widget.labelBuilder(item),
                      control: AppRadio<T>(
                        value: item,
                        groupValue: widget.selected,
                      ),
                      onTap: () => Navigator.of(context).pop(item),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
