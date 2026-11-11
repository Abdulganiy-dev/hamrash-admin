import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/organization_models/member_school.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/constants/radius_containers.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/widgets/app_spinner.dart';
import 'package:hamrash_admin/core/widgets/button/bouncy_button.dart';
import 'package:hamrash_admin/core/widgets/app_empty_state.dart';
import 'package:hamrash_admin/core/widgets/app_refresh_scroll_view.dart';
import 'package:hamrash_admin/core/widgets/animated_section_content.dart';
import 'package:hamrash_admin/core/widgets/app_icons.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_types.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_variants.dart';
import 'package:hamrash_admin/core/widgets/default_scaffold.dart';
import 'package:hamrash_admin/core/widgets/load_error_view.dart';
import 'package:hamrash_admin/core/widgets/navigation/app_nav_button.dart';
import 'package:hamrash_admin/services/navigation_service.dart';
import 'package:hamrash_admin/views/team/add_staff/add_staff_screen.dart';
import 'package:hamrash_admin/views/team/staff_detail/staff_detail_screen.dart';
import 'package:hamrash_admin/views/team/team_view_model.dart';
import 'package:hamrash_admin/views/team/widgets/staff_filter_sheet.dart';
import 'package:hamrash_admin/views/team/widgets/staff_list_card.dart';
import 'package:hamrash_admin/views/team/widgets/team_skeleton.dart';
import 'package:stacked/stacked.dart';

/// 9.3–9.3c · Staffs: everyone on the staff list, with where their login has
/// got to. Pops `true` when something was saved, so the page behind reloads.
class TeamScreen extends StatelessWidget {
  const TeamScreen({super.key, required this.school});

  final MemberSchool school;

  @override
  Widget build(BuildContext context) =>
      ViewModelBuilder<TeamViewModel>.reactive(
        viewModelBuilder: () => TeamViewModel(school: school),
        onViewModelReady: (model) => model.load(),
        builder: (context, model, _) => DefaultScaffold(
          title: 'Staffs',
          showBackButton: true,
          onBackPressed: () => NavigationService.popScreen(model.changed),
          backgroundColor: AppPalette.linen,
          actions: [
            if (model.ready && !model.showEmptyState)
              AppNavIconButton(
                icon: AppIcons.slidersHorizontal,
                iconColor: LightColors.primaryPrimaryDefault,
                appliedCount: model.filter.activeCount,
                semanticLabel: model.filter.activeCount == 0
                    ? 'Filter staff'
                    : 'Filter staff, ${model.filter.activeCount} applied',
                onPressed: () => _openFilter(context, model),
              ),
            if (model.canAdd && model.ready)
              AppNavIconButton(
                icon: AppIcons.plus,
                iconSize: 18,
                iconColor: LightColors.primaryPrimaryDefault,
                semanticLabel: 'Add staff member',
                onPressed: () => _addStaff(context, model),
              ),
          ],
          body: AnimatedSectionContent(
            morphHeight: false,
            child: model.error != null
                ? LoadErrorView(
                    key: const ValueKey('error'),
                    onRetry: model.load,
                  )
                : model.loading
                ? const _Loading(key: ValueKey('loading'))
                : model.showEmptyState
                ? const _Empty(key: ValueKey('empty'))
                : _List(key: const ValueKey('content'), model: model),
          ),
          bottomNavigationBar: model.ready && model.canAdd
              ? _AddBar(onPressed: () => _addStaff(context, model))
              : null,
        ),
      );

  static Future<void> _openFilter(
    BuildContext context,
    TeamViewModel model,
  ) async {
    final next = await StaffFilterSheet.show(context, initial: model.filter);
    if (next != null) await model.applyFilter(next);
  }

  static Future<void> _addStaff(
    BuildContext context,
    TeamViewModel model,
  ) async {
    final outcome = await NavigationService.animatedNavigation<AddStaffOutcome>(
      screen: AddStaffScreen(school: model.school),
    );
    if (outcome == null) return;
    await model.reload();
    if (!context.mounted) return;
    if (outcome.created case final staff?) {
      await _openStaff(context, model, staff.id);
    }
  }

  static Future<void> _openStaff(
    BuildContext context,
    TeamViewModel model,
    String staffId,
  ) async {
    final changed = await NavigationService.animatedNavigation<bool>(
      screen: StaffDetailScreen(school: model.school, staffId: staffId),
    );
    if (changed == true) await model.reload();
  }
}

class _List extends StatefulWidget {
  const _List({super.key, required this.model});

  final TeamViewModel model;

  @override
  State<_List> createState() => _ListState();
}

class _ListState extends State<_List> {
  /// Start the next page this far before the end of the list.
  static const _loadMoreExtent = 300.0;

  final _controller = ScrollController();

  TeamViewModel get model => widget.model;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_loadMoreNearEnd);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _loadMoreNearEnd() {
    if (!_controller.hasClients || !model.hasMore) return;
    if (_controller.position.extentAfter < _loadMoreExtent) model.loadMore();
  }

  @override
  Widget build(BuildContext context) {
    // A short page can leave the end in view with nothing to scroll.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadMoreNearEnd();
    });

    final filter = model.filter;
    return AppRefreshScrollView(
      controller: _controller,
      onRefresh: model.refresh,
      padding: EdgeInsets.zero,
      slivers: [
        if (!filter.isDefault)
          SliverToBoxAdapter(child: _AppliedFilters(model: model)),
        if (model.showNoResults)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _NoResults(model: model),
          )
        else ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screen,
              ),
              child: StaffListCard(
                staff: model.staff,
                subtitleFor: model.subtitleFor,
                onOpen: (person) =>
                    TeamScreen._openStaff(context, model, person.id),
              ),
            ),
          ),
          SliverToBoxAdapter(child: _MoreFooter(model: model)),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
        ],
      ],
    );
  }
}

/// 9.3a · What the list is narrowed by, each with a × to take it off, and
/// how many of the school's people that leaves.
class _AppliedFilters extends StatelessWidget {
  const _AppliedFilters({required this.model});

  final TeamViewModel model;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.screen,
      AppSpacing.none,
      AppSpacing.screen,
      AppSpacing.md,
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final chip in model.filter.chips)
                _AppliedChip(
                  label: chip.label,
                  onRemove: () => model.removeChip(chip),
                ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        // Lines up with the chips' 32px height.
        SizedBox(
          height: 32,
          child: Center(
            child: AppText(
              '${model.total} of ${model.counts.all}',
              style: AppTypography.body.copyWith(
                fontSize: 13,
                height: 18 / 13,
                fontWeight: FontWeight.w600,
                color: LightColors.textMuted,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

/// A removable applied filter: 32 tall, tinted, with a small ×.
class _AppliedChip extends StatelessWidget {
  const _AppliedChip({required this.label, required this.onRemove});

  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Remove $label filter',
    excludeSemantics: true,
    child: BouncyButton(
      onPressed: onRemove,
      child: Container(
        height: 32,
        padding: const EdgeInsets.only(left: 12, right: 10),
        decoration: BoxDecoration(
          color: LightColors.primaryPrimaryMute,
          borderRadius: AppRadius.brPill,
          border: Border.all(color: LightColors.primaryPrimaryDefault),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppText(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.body.copyWith(
                fontSize: 13,
                height: 18 / 13,
                fontWeight: FontWeight.w600,
                color: LightColors.primaryPrimaryText,
              ),
            ),
            const SizedBox(width: 6),
            const AppIcon(
              AppIcons.x,
              size: 12,
              color: LightColors.primaryPrimaryDefault,
            ),
          ],
        ),
      ),
    ),
  );
}

/// 9.3b · A search or filters that match no one.
class _NoResults extends StatelessWidget {
  const _NoResults({required this.model});

  final TeamViewModel model;

  @override
  Widget build(BuildContext context) {
    final filter = model.filter;
    final search = filter.trimmedSearch;
    final hasSearch = search.isNotEmpty;
    final hasFilters = filter.chips.length > (hasSearch ? 1 : 0);

    final String title;
    final String subtitle;
    final String action;
    final VoidCallback onAction;
    if (hasSearch && hasFilters) {
      title = 'No staff match';
      subtitle =
          'Nothing matches “$search” with these filters. Try fewer filters '
          'or a different spelling.';
      action = 'Clear filters';
      onAction = model.clearFilters;
    } else if (hasSearch) {
      title = 'No results for “$search”';
      subtitle = 'Check the spelling, or search by staff number.';
      action = 'Clear search';
      onAction = model.clearSearch;
    } else {
      title = 'No staff match these filters';
      subtitle = 'Try removing a filter.';
      action = 'Clear filters';
      onAction = model.clearFilters;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screen,
        vertical: AppSpacing.md,
      ),
      child: AppEmptyState(
        icon: AppIcons.search,
        compact: true,
        title: title,
        subtitle: subtitle,
        actionLabel: action,
        onAction: onAction,
        topPadding: AppSpacing.none,
      ),
    );
  }
}

/// Under the list: a spinner while the next page loads, or a retry row when
/// it didn't.
class _MoreFooter extends StatelessWidget {
  const _MoreFooter({required this.model});

  final TeamViewModel model;

  @override
  Widget build(BuildContext context) {
    if (model.loadMoreError != null) {
      return Semantics(
        button: true,
        label: 'Couldn’t load more. Tap to retry',
        excludeSemantics: true,
        child: BouncyButton(
          onPressed: model.retryLoadMore,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Center(
              child: AppText(
                'Couldn’t load more. Tap to retry',
                style: AppTypography.subtitle.copyWith(
                  color: LightColors.primaryPrimaryText,
                ),
              ),
            ),
          ),
        ),
      );
    }
    if (model.loadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Center(child: AppSpinner()),
      );
    }
    return const SizedBox.shrink();
  }
}

/// 9.3c · No one but the owner yet: the tinted tile, one line of explanation
/// and the pinned "Add staff member" bar.
class _Empty extends StatelessWidget {
  const _Empty({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      AppSpacing.screen,
      ScaffoldInsets.bodyTopInsetOf(context),
      AppSpacing.screen,
      0,
    ),
    child: const Center(
      child: AppEmptyState(
        icon: AppIcons.userPlus,
        title: 'No staff yet',
        subtitle:
            'Add each person who works at the school. You can invite them '
            'to the app now or later.',
        topPadding: AppSpacing.none,
      ),
    ),
  );
}

class _AddBar extends StatelessWidget {
  const _AddBar({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.sm,
        AppSpacing.screen,
        AppSpacing.sm,
      ),
      child: AppPrimaryButton(
        size: AppButtonSize.large,
        onPressed: onPressed,
        child: const AppText('Add staff member'),
      ),
    ),
  );
}

/// [TeamSkeleton] where the page's content starts.
class _Loading extends StatelessWidget {
  const _Loading({super.key});

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    physics: const NeverScrollableScrollPhysics(),
    child: Builder(
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.screen,
          ScaffoldInsets.bodyTopInsetOf(context),
          AppSpacing.screen,
          0,
        ),
        child: const TeamSkeleton(),
      ),
    ),
  );
}
