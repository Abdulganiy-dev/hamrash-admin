import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/organization_models/member_school.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/widgets/app_badge.dart';
import 'package:hamrash_admin/core/widgets/app_chip_row.dart';
import 'package:hamrash_admin/core/widgets/app_empty_state.dart';
import 'package:hamrash_admin/core/widgets/app_refresh_scroll_view.dart';
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
import 'package:hamrash_admin/views/team/widgets/staff_list_card.dart';
import 'package:hamrash_admin/views/team/widgets/team_skeleton.dart';
import 'package:stacked/stacked.dart';

/// 8.1–8.2 · Staffs: everyone on the staff list, with where their login has
/// got to. Pops `true` when something was saved, so the page behind reloads.
class TeamScreen extends StatelessWidget {
  const TeamScreen({super.key, required this.school});

  final MemberSchool school;

  @override
  Widget build(BuildContext context) =>
      ViewModelBuilder<TeamViewModel>.reactive(
        viewModelBuilder: () => TeamViewModel(school: school),
        onViewModelReady: (model) => model.load(),
        builder:
            (context, model, _) => DefaultScaffold(
              title: 'Staffs',
              showBackButton: true,
              onBackPressed: () => NavigationService.popScreen(model.changed),
              backgroundColor: AppPalette.linen,
              actions: [
                if (model.canAdd && !model.loading && model.error == null)
                  AppNavIconButton(
                    icon: AppIcons.plus,
                    iconSize: 18,
                    iconColor: LightColors.primaryPrimaryDefault,
                    semanticLabel: 'Add staff member',
                    onPressed: () => _addStaff(context, model),
                  ),
              ],
              body:
                  model.error != null
                      ? LoadErrorView(onRetry: model.load)
                      : model.loading
                      ? const _Loading()
                      : model.showEmptyState
                      ? const _Empty()
                      : _List(model: model),
              bottomNavigationBar:
                  !model.loading && model.error == null && model.canAdd
                      ? _AddBar(onPressed: () => _addStaff(context, model))
                      : null,
            ),
      );

  /// The form pops the new person, so this page opens their detail page and
  /// keeps one back stack: Team → Detail.
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

class _List extends StatelessWidget {
  const _List({required this.model});

  final TeamViewModel model;

  @override
  Widget build(BuildContext context) => AppRefreshScrollView.children(
    onRefresh: model.refresh,
    // The chip row runs edge to edge; everything else keeps the page margin.
    padding: EdgeInsets.zero,
    children: [
      AppChipRow(
        children: [
          AppFilterChip(
            label: 'All',
            count: model.allCount,
            selected: model.filter == TeamFilter.all,
            onTap: () => model.pickFilter(TeamFilter.all),
          ),
          AppFilterChip(
            label: 'On app',
            count: model.onAppCount,
            selected: model.filter == TeamFilter.onApp,
            onTap: () => model.pickFilter(TeamFilter.onApp),
          ),
          AppFilterChip(
            label: 'Not on app',
            count: model.notOnAppCount,
            selected: model.filter == TeamFilter.notOnApp,
            onTap: () => model.pickFilter(TeamFilter.notOnApp),
          ),
        ],
      ),
      // The chips carry 4px above and below their 40px pill (a 48px tap
      // area), so 8 here leaves the 16px gap the page draws.
      const SizedBox(height: AppSpacing.sm),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
        child:
            model.visibleStaff.isEmpty
                ? AppEmptyState(
                  icon: AppIcons.users,
                  compact: true,
                  title:
                      model.filter == TeamFilter.onApp
                          ? 'No one on the app yet'
                          : 'No one here yet',
                  subtitle: 'Try another filter.',
                  topPadding: AppSpacing.sm,
                )
                : StaffListCard(
                  staff: model.visibleStaff,
                  subtitleFor: model.subtitleFor,
                  onOpen:
                      (person) =>
                          TeamScreen._openStaff(context, model, person.id),
                ),
      ),
      const SizedBox(height: AppSpacing.md),
    ],
  );
}

/// 8.2 · No one but the owner yet: the tinted tile, one line of explanation
/// and the pinned "Add staff member" bar.
class _Empty extends StatelessWidget {
  const _Empty();

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
        iconColor: LightColors.categoryTealText,
        iconTileColor: LightColors.categoryTealMute,
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
  const _Loading();

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    physics: const NeverScrollableScrollPhysics(),
    child: Builder(
      builder:
          (context) => Padding(
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
