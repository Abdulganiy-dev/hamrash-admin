import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/organization_models/member_school.dart';
import 'package:hamrash_admin/api/models/organization_models/school_area.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/widgets/app_cards.dart';
import 'package:hamrash_admin/core/widgets/app_list_row.dart';
import 'package:hamrash_admin/core/widgets/app_refresh_scroll_view.dart';
import 'package:hamrash_admin/core/widgets/app_spinner.dart';
import 'package:hamrash_admin/core/widgets/app_toast.dart';
import 'package:hamrash_admin/core/widgets/default_scaffold.dart';
import 'package:hamrash_admin/core/widgets/load_error_view.dart';
import 'package:hamrash_admin/core/widgets/navigation/app_nav_button.dart';
import 'package:hamrash_admin/services/navigation_service.dart';
import 'package:hamrash_admin/views/academic_calendar/create_session/create_session_screen.dart';
import 'package:hamrash_admin/views/more/more_view_model.dart';
import 'package:hamrash_admin/views/more/widgets/more_account_card.dart';
import 'package:hamrash_admin/views/more/widgets/more_school_card.dart';
import 'package:hamrash_admin/views/more/widgets/school_area_grid.dart';
import 'package:stacked/stacked.dart';

/// 5.1 · More tab: the school card, the areas that run it (shown and opened
/// by role), and help and sign out.
class MoreScreen extends StatelessWidget {
  const MoreScreen({
    super.key,
    required this.school,
    required this.userName,
    required this.onAvatarTap,
    required this.onSignOut,
    required this.onOpenSchoolDetails,
    this.userImageUrl,
    this.onSwitchSchool,
  });

  final MemberSchool school;
  final String userName;
  final String? userImageUrl;
  final VoidCallback onAvatarTap;
  final VoidCallback onSignOut;
  final VoidCallback onOpenSchoolDetails;

  /// Null when this is their only school.
  final VoidCallback? onSwitchSchool;

  @override
  Widget build(BuildContext context) =>
      ViewModelBuilder<MoreViewModel>.reactive(
        viewModelBuilder: () => MoreViewModel(school: school),
        onViewModelReady: (model) => model.load(),
        builder: (context, model, _) => DefaultScaffold(
          backgroundColor: AppPalette.linen,
          title: 'More',
          subtitle: '${school.name} · ${school.rolesLabel}',
          actions: [
            AppNavPicture(
              picture: AppListLeading.network(
                userImageUrl ?? '',
                name: userName,
              ),
              onPressed: onAvatarTap,
            ),
          ],
          body: AppRefreshScrollView.children(
            onRefresh: model.refresh,
            children: [
              MoreSchoolCard(
                school: school,
                onTap: () => _open(context, model, SchoolArea.schoolDetails),
                onSwitch: onSwitchSchool,
              ),
              const SizedBox(height: AppSpacing.lg),
              const AppSectionHeader(title: 'Run your school'),
              const SizedBox(height: AppSpacing.ms),
              if (model.error != null)
                LoadErrorView(onRetry: model.load)
              else if (model.loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                  child: Center(child: AppSpinner()),
                )
              else
                SchoolAreaGrid(
                  model: model,
                  onOpen: (area) => _open(context, model, area),
                ),
              const SizedBox(height: AppSpacing.lg),
              MoreAccountCard(onSignOut: onSignOut),
            ],
          ),
        ),
      );

  Future<void> _open(
    BuildContext context,
    MoreViewModel model,
    SchoolArea area,
  ) async {
    if (model.blockedReason(area) case final reason?) {
      AppToast.show(reason);
      return;
    }
    switch (area) {
      case SchoolArea.schoolDetails:
        onOpenSchoolDetails();
      case SchoolArea.academicCalendar when !model.calendarSetUp:
        final created = await NavigationService.animatedNavigation<bool>(
          screen: CreateSessionScreen(organizationId: school.id),
        );
        if (created == true && context.mounted) {
          await model.refresh().catchError((_) {});
        }
      case SchoolArea.academicCalendar:
        AppToast.show('Academic sessions are coming next');
      default:
        AppToast.show('${area.title} is coming soon');
    }
  }
}
