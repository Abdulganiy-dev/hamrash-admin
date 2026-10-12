import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/bottomSheets/app_sheet.dart';
import 'package:hamrash_admin/core/bottomSheets/paginated_list_controller.dart';
import 'package:hamrash_admin/core/bottomSheets/paginated_list_cache.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/widgets/app_empty_state.dart';
import 'package:hamrash_admin/core/widgets/app_scroll_fade.dart';
import 'package:hamrash_admin/core/widgets/app_search_field.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/button/app_button.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_types.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_variants.dart';
import 'package:hamrash_admin/core/widgets/load_error_view.dart';
import 'package:hamrash_admin/core/widgets/selection/app_selection_controls.dart';
import 'package:hamrash_admin/core/widgets/selection/app_selection_rows.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

export 'paginated_list_controller.dart';

/// Searchable counterpart of ListBottomSheet for API-backed selectors: a
/// full sheet with the search field pinned under the title and results that
/// load more as you scroll.
///
/// With [closeOnSelected] (the default) rows show radios and a tap picks and
/// closes. Set it false to pick many: rows show checkboxes and a Done button
/// is pinned at the bottom.
abstract final class PaginatedListBottomSheet {
  static Future<void> showSelectable<I>({
    required BuildContext context,
    required String title,
    required PaginatedListLoader<I> loadPage,
    required String Function(I) idBuilder,
    required String Function(I) labelBuilder,
    required ValueChanged<I> onSelected,
    required Object cacheKey,
    I? currentValue,
    bool Function(I)? isSelected,
    ValueChanged<I>? onDeselected,
    bool closeOnSelected = true,
    String doneLabel = 'Done',
    String Function(I)? subtitleBuilder,
    bool Function(I, String)? matchesSearch,
    String searchHint = 'Search…',
    VoidCallback? onCleared,
    String clearLabel = 'Clear selection',
  }) => Navigator.of(context).push<void>(
    AppSheetRoute<void>(
      child: _PaginatedSelectionBody<I>(
        title: title,
        loadPage: loadPage,
        cache: PaginatedListCache.forKey<I>(cacheKey),
        idBuilder: idBuilder,
        labelBuilder: labelBuilder,
        subtitleBuilder: subtitleBuilder,
        matchesSearch: matchesSearch,
        currentValue: currentValue,
        isSelected: isSelected,
        onDeselected: onDeselected,
        closeOnSelected: closeOnSelected,
        doneLabel: doneLabel,
        onSelected: onSelected,
        searchHint: searchHint,
        onCleared: onCleared,
        clearLabel: clearLabel,
      ),
    ),
  );
}

class _PaginatedSelectionBody<I> extends StatefulWidget {
  const _PaginatedSelectionBody({
    required this.title,
    required this.loadPage,
    required this.cache,
    required this.idBuilder,
    required this.labelBuilder,
    required this.currentValue,
    required this.isSelected,
    required this.onDeselected,
    required this.closeOnSelected,
    required this.doneLabel,
    required this.onSelected,
    required this.searchHint,
    required this.clearLabel,
    this.subtitleBuilder,
    this.matchesSearch,
    this.onCleared,
  });
  final String title;
  final PaginatedListLoader<I> loadPage;
  final PaginatedListCache<I> cache;
  final String Function(I) idBuilder, labelBuilder;
  final String Function(I)? subtitleBuilder;
  final bool Function(I, String)? matchesSearch;
  final I? currentValue;
  final bool Function(I)? isSelected;
  final ValueChanged<I>? onDeselected;
  final bool closeOnSelected;
  final String doneLabel;
  final ValueChanged<I> onSelected;
  final String searchHint, clearLabel;
  final VoidCallback? onCleared;
  @override
  State<_PaginatedSelectionBody<I>> createState() =>
      _PaginatedSelectionBodyState<I>();
}

class _PaginatedSelectionBodyState<I>
    extends State<_PaginatedSelectionBody<I>> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  late final PaginatedListController<I> _model;

  @override
  void initState() {
    super.initState();
    _model = PaginatedListController<I>(
      loadPage: widget.loadPage,
      cache: widget.cache,
      idBuilder: widget.idBuilder,
      matchesSearch:
          widget.matchesSearch ??
          (item, query) =>
              '${widget.labelBuilder(item)} ${widget.subtitleBuilder?.call(item) ?? ''}'
                  .toLowerCase()
                  .contains(query.toLowerCase()),
    );
    _scrollController.addListener(_onScroll);
    _model.load();
  }

  void _onScroll() {
    if (_scrollController.hasClients &&
        _scrollController.position.extentAfter < 160 &&
        _model.error == null) {
      _model.load(more: true);
    }
  }

  void _search(String value, {bool immediately = false}) {
    _model.search(value, immediately: immediately);
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _model.dispose();
    super.dispose();
  }

  bool get _multi => !widget.closeOnSelected;

  @override
  Widget build(BuildContext context) => AppSheet(
    title: widget.title,
    scrollableBody: false,
    bodyPadding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
    footer: _multi
        ? AppPrimaryButton(
            width: double.infinity,
            onPressed: () => Navigator.of(context).pop(),
            child: Text(widget.doneLabel),
          )
        : null,
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSearchField(
          controller: _searchController,
          hintText: widget.searchHint,
          onChanged: _search,
          onSubmitted: (value) => _search(value, immediately: true),
        ),
        if (widget.onCleared != null)
          Align(
            alignment: Alignment.centerRight,
            child: AppButton(
              type: AppButtonType.text,
              size: AppButtonSize.small,
              text: widget.clearLabel,
              onPressed: () {
                widget.onCleared!();
                Navigator.of(context).pop();
              },
            ),
          )
        else
          const SizedBox(height: AppSpacing.sm),
        Expanded(
          // Results fade out under the search field once scrolled.
          child: AppScrollFade(
            child: ListenableBuilder(
              listenable: _model,
              builder: (context, _) => _results(),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _results() {
    final items = _model.visibleItems;
    final showStatusRow =
        items.isNotEmpty &&
        (_model.loading || _model.hasMore || _model.error != null);
    final bottomGap = _multi
        ? AppSpacing.md
        : MediaQuery.paddingOf(context).bottom + AppSpacing.md;

    if (items.isEmpty) {
      return ListView(
        controller: _scrollController,
        physics: const ClampingScrollPhysics(),
        padding: EdgeInsets.only(bottom: bottomGap),
        children: [_emptyStatus()],
      );
    }

    return ListView.separated(
      controller: _scrollController,
      physics: const ClampingScrollPhysics(),
      padding: EdgeInsets.only(bottom: bottomGap),
      itemCount: items.length + (showStatusRow ? 1 : 0),
      separatorBuilder: (_, index) => index >= items.length - 1
          ? const SizedBox.shrink()
          : Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              color: AppPalette.slate100,
            ),
      itemBuilder: (context, index) {
        if (index == items.length) return _moreStatus();
        return _row(items[index]);
      },
    );
  }

  Widget _row(I item) {
    final selected =
        widget.isSelected?.call(item) ??
        (widget.currentValue != null &&
            widget.idBuilder(widget.currentValue as I) ==
                widget.idBuilder(item));

    return AppSelectionRow(
      title: widget.labelBuilder(item),
      subtitle: widget.subtitleBuilder?.call(item),
      control: _multi
          ? AppCheckbox(value: selected)
          : AppRadio<bool>(value: true, groupValue: selected),
      onTap: () {
        if (selected && widget.onDeselected != null) {
          widget.onDeselected!(item);
        } else if (!selected) {
          widget.onSelected(item);
        }
        if (widget.closeOnSelected) {
          Navigator.of(context).pop();
        } else {
          setState(() {});
        }
      },
    );
  }

  /// Shown instead of the list when there is nothing to show yet.
  Widget _emptyStatus() {
    if (_model.loading) return const _LoadingRow(label: 'Loading…');
    if (_model.error != null) {
      return LoadErrorView(
        title: "Couldn't load options",
        message: _model.error,
        onRetry: _model.retry,
      );
    }
    return const AppEmptyState(
      icon: LucideIcons.search,
      title: 'No options found',
      subtitle: 'Try a different search.',
    );
  }

  /// Last row of the list: loading, retry, or a manual "Load more".
  Widget _moreStatus() {
    if (_model.loading) return const _LoadingRow(label: 'Loading more…');
    if (_model.error != null) {
      return LoadErrorView(
        title: "Couldn't load more",
        message: _model.error,
        onRetry: _model.retry,
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: AppSecondaryButton(
        width: double.infinity,
        onPressed: () => _model.load(more: true),
        child: const AppText('Load more'),
      ),
    );
  }
}

class _LoadingRow extends StatelessWidget {
  const _LoadingRow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: LightColors.primaryPrimaryDefault,
              backgroundColor: AppPalette.slate200,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: LightColors.textTextMute,
            ),
          ),
        ],
      ),
    );
  }
}
