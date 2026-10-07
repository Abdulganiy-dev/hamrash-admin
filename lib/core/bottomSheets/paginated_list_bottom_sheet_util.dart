import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/bottomSheets/glass_sheet.dart';
import 'package:hamrash_admin/core/bottomSheets/paginated_list_controller.dart';
import 'package:hamrash_admin/core/bottomSheets/paginated_list_cache.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/widgets/app_empty_state.dart';
import 'package:hamrash_admin/core/widgets/app_search_field.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_variants.dart';
import 'package:hamrash_admin/core/widgets/haptic_list_tile.dart';
import 'package:hamrash_admin/core/widgets/load_error_view.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

export 'paginated_list_controller.dart';

/// Searchable counterpart of ListBottomSheet for API-backed selectors.
abstract final class PaginatedListBottomSheet {
  static Future<void> showSelectable<I>({
    required BuildContext context,
    required String title,
    required IconData headerIcon,
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
  }) => GlassSheet.show<void>(
    context: context,
    title: title,
    leadingIcon: headerIcon,
    size: GlassSheetSize.form,
    scrollableBody: false,
    body: _PaginatedSelectionBody<I>(
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
  );
}

class _PaginatedSelectionBody<I> extends StatefulWidget {
  const _PaginatedSelectionBody({
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

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const SizedBox(height: AppSpacing.sm),
      AppSearchField(
        controller: _searchController,
        hintText: widget.searchHint,
        onChanged: _search,
        onSubmitted: (value) => _search(value, immediately: true),
      ),
      if (widget.onCleared != null) ...[
        const SizedBox(height: AppSpacing.md),
        AppSecondaryButton(
          onPressed: () {
            widget.onCleared!();
            Navigator.of(context).pop();
          },
          child: AppText(widget.clearLabel),
        ),
      ],
      const SizedBox(height: AppSpacing.md),
      Expanded(
        child: ListenableBuilder(
          listenable: _model,
          builder: (context, _) => Column(
            children: [
              SizedBox(
                height: 2,
                child: _model.loading
                    ? const LinearProgressIndicator(
                        minHeight: 2,
                        borderRadius: BorderRadius.all(Radius.circular(2)),
                      )
                    : null,
              ),
              const SizedBox(height: AppSpacing.xs),
              Expanded(child: _results()),
            ],
          ),
        ),
      ),
      if (!widget.closeOnSelected) ...[
        const SizedBox(height: AppSpacing.md),
        AppPrimaryButton(
          onPressed: () => Navigator.of(context).pop(),
          child: AppText(
            widget.doneLabel,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ],
  );

  Widget _results() {
    final items = _model.visibleItems;
    final footer = !_model.loading && (_model.hasMore || _model.error != null);
    return ListView.separated(
      controller: _scrollController,
      physics: const ClampingScrollPhysics(),
      padding: EdgeInsets.only(
        bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.md,
      ),
      itemCount:
          (items.isEmpty ? 1 : items.length) +
          (footer && items.isNotEmpty ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xs),
      itemBuilder: (context, index) {
        if (items.isEmpty || index == items.length) {
          if (_model.loading) return const SizedBox.shrink();
          if (_model.error != null) {
            return LoadErrorView(
              title: "Couldn't load options",
              message: _model.error,
              onRetry: _model.retry,
            );
          }
          if (_model.hasMore) {
            return AppSecondaryButton(
              onPressed: () => _model.load(more: true),
              child: const AppText('Load more'),
            );
          }
          return const AppEmptyState(
            icon: LucideIcons.search,
            title: 'No options found',
            subtitle: 'Try a different search.',
          );
        }
        final item = items[index];
        final selected =
            widget.isSelected?.call(item) ??
            (widget.currentValue != null &&
                widget.idBuilder(widget.currentValue as I) ==
                    widget.idBuilder(item));
        return HapticListTile(
          title: AppText(
            widget.labelBuilder(item),
            colorType: AppTextColor.textInverted,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
          subtitle: widget.subtitleBuilder == null
              ? null
              : AppText(
                  widget.subtitleBuilder!(item),
                  colorType: AppTextColor.textMute,
                  fontSize: 12,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
          trailing: selected
              ? const Icon(
                  LucideIcons.circleCheck,
                  color: LightColors.primaryPrimaryDefault,
                  size: 22,
                )
              : null,
          onTap: () {
            if (selected && widget.onDeselected != null) {
              widget.onDeselected!(item);
            } else {
              widget.onSelected(item);
            }
            if (widget.closeOnSelected) {
              Navigator.of(context).pop();
            } else {
              setState(() {});
            }
          },
        );
      },
    );
  }
}
