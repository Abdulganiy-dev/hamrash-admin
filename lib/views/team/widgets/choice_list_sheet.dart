import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/bottomSheets/app_sheet.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/radius_containers.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/widgets/app_divider.dart';
import 'package:hamrash_admin/core/widgets/app_empty_state.dart';
import 'package:hamrash_admin/core/widgets/app_icons.dart';
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
    this.captionBuilder,
    this.subtitle,
    this.selected,
    this.emptyTitle = 'Nothing to choose yet',
    this.emptySubtitle,
    this.emptyIcon = AppIcons.search,
  });

  final String title;

  /// "For Chinedu Obi" while editing a staff member.
  final String? subtitle;
  final String searchHint;
  final List<T> items;
  final String Function(T item) labelBuilder;

  /// A quiet line under the label, e.g. "3 arms" or "Compulsory".
  final String Function(T item)? captionBuilder;
  final T? selected;

  /// What the sheet says when [items] is empty, e.g. "No arms yet". Say
  /// what is missing and what to do about it.
  final String emptyTitle;
  final String? emptySubtitle;
  final IconData emptyIcon;

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required String searchHint,
    required List<T> items,
    required String Function(T item) labelBuilder,
    String Function(T item)? captionBuilder,
    T? selected,
    String? subtitle,
    String emptyTitle = 'Nothing to choose yet',
    String? emptySubtitle,
    IconData emptyIcon = AppIcons.search,
  }) => Navigator.of(context).push<T>(
    AppSheetRoute<T>(
      size: AppSheetSize.floating,
      child: ChoiceListSheet<T>(
        title: title,
        subtitle: subtitle,
        searchHint: searchHint,
        items: items,
        labelBuilder: labelBuilder,
        captionBuilder: captionBuilder,
        selected: selected,
        emptyTitle: emptyTitle,
        emptySubtitle: emptySubtitle,
        emptyIcon: emptyIcon,
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

  /// Nothing to choose from at all, or a search that matches nothing.
  Widget _empty(bool noItems) => Center(
    child: SingleChildScrollView(
      child: noItems
          ? AppEmptyState(
              compact: true,
              icon: widget.emptyIcon,
              title: widget.emptyTitle,
              subtitle: widget.emptySubtitle,
              topPadding: AppSpacing.none,
            )
          : AppEmptyState(
              compact: true,
              icon: AppIcons.search,
              title: 'No results for “${_query.trim()}”',
              subtitle: 'Check the spelling and try again.',
              topPadding: AppSpacing.none,
            ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final visible = _visible;
    final noItems = widget.items.isEmpty;
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
          if (!noItems) ...[
            AppSearchField(hintText: widget.searchHint, onChanged: _search),
            const SizedBox(height: AppSpacing.ms),
          ],
          // Flexible so the list gives up a pixel or two when the sheet's own
          // chrome leaves less room than [listHeight] on a short screen.
          Flexible(
            child: SizedBox(
              height: visible.isEmpty ? math.min(listHeight, 240) : listHeight,
              child: visible.isEmpty
                  ? _empty(noItems)
                  : ClipRRect(
                      borderRadius: AppRadius.brLg,
                      child: ColoredBox(
                        color: AppPalette.stone50,
                        child: ListView.separated(
                          controller: _scrollController,
                          padding: EdgeInsets.zero,
                          itemCount: visible.length,
                          separatorBuilder: (context, index) =>
                              const AppDivider(),
                          itemBuilder: (context, index) {
                            final item = visible[index];
                            return AppSelectionRow(
                              title: widget.labelBuilder(item),
                              subtitle: widget.captionBuilder?.call(item),
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
          ),
        ],
      ),
    );
  }
}
