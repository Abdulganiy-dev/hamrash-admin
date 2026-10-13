import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/organization_models/member_school.dart';
import 'package:hamrash_admin/api/models/organization_models/setup_progress.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/widgets/app_cards.dart';
import 'package:hamrash_admin/core/widgets/app_list_row.dart';
import 'package:hamrash_admin/core/widgets/app_refresh_scroll_view.dart';
import 'package:hamrash_admin/core/widgets/app_spinner.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/app_toast.dart';
import 'package:hamrash_admin/core/widgets/button/bouncy_button.dart';
import 'package:hamrash_admin/core/widgets/default_scaffold.dart';
import 'package:hamrash_admin/core/widgets/load_error_view.dart';
import 'package:hamrash_admin/core/widgets/navigation/app_nav_metrics.dart';
import 'package:hamrash_admin/services/navigation_service.dart';
import 'package:hamrash_admin/views/home/home_view_model.dart';
import 'package:hamrash_admin/views/academic_calendar/create_session/create_session_screen.dart';
import 'package:hamrash_admin/views/schools/widgets/school_logo.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:stacked/stacked.dart';

/// Home tab: school header and, while the school is being set up, the setup
/// card (11 for owners, admins, principals and VPs; 12 for bursars).
class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.school,
    required this.userName,
    required this.onAvatarTap,
    this.userImageUrl,
    this.onOpenSchoolDetails,
  });

  final MemberSchool school;

  /// From the sign-in account, until their staff record loads.
  final String userName;
  final String? userImageUrl;

  /// Gets the name and photo shown in the header.
  final void Function(String name, String? photoUrl) onAvatarTap;
  final VoidCallback? onOpenSchoolDetails;

  @override
  Widget build(BuildContext context) =>
      ViewModelBuilder<HomeViewModel>.reactive(
        viewModelBuilder: () => HomeViewModel(
          school: school,
          signedInName: userName,
          signedInImageUrl: userImageUrl,
          onOpenSchoolDetails: onOpenSchoolDetails,
        ),
        onViewModelReady: (model) => model.load(),
        builder: (context, model, _) => DefaultScaffold(
          backgroundColor: AppPalette.linen,

          customAppBar: _Header(
            model: model,
            onSchoolLogoTapped:onOpenSchoolDetails,
            onAvatarTap: () => onAvatarTap(model.displayName, model.photoUrl),
          ),
          body: AppRefreshScrollView.children(
            onRefresh: model.refresh,
            children: [
              if (model.error != null)
                LoadErrorView(onRetry: model.load)
              else if (model.progress case final progress?)
                _SetupCard(model: model, progress: progress)
              else
                const Padding(
                  padding: EdgeInsets.only(top: AppSpacing.xxl),
                  child: Center(child: AppSpinner()),
                ),
            ],
          ),
        ),
      );
}

class _Header extends StatelessWidget {
  const _Header({required this.model, required this.onAvatarTap,required this.onSchoolLogoTapped});

  final HomeViewModel model;
  final VoidCallback onAvatarTap;
  final VoidCallback? onSchoolLogoTapped;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: AppNavMetrics.appBarSideInset,
    ),
    child: Row(
      children: [
        BouncyButton(
          onPressed: onSchoolLogoTapped,
          child: SchoolLogo(
            logoUrl: model.school.organization.logoUrl,
            size: 44,
            radius: 22,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                model.school.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.heading(
                  16,
                  lineHeight: 22,
                ).copyWith(letterSpacing: -0.16, color: AppPalette.stone900),
              ),
              AppText(
                model.statusLine,
                variant: AppTextVariant.label,
                colorType: AppTextColor.textMuted,
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        _RoundButton(
          label: 'Notifications',
          onTap: () => AppToast.show('Notifications are coming soon'),
          child: const Icon(
            LucideIcons.bell,
            size: 20,
            color: AppPalette.stone700,
          ),
        ),
        const SizedBox(width: 10),
        _RoundButton(
          label: 'Your account',
          onTap: onAvatarTap,
          child: AppLeadingPicture(
            leading: AppListLeading.network(
              model.photoUrl ?? '',
              name: model.displayName,
            ),
            size: 44,
          ),
        ),
      ],
    ),
  );
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.label,
    required this.onTap,
    required this.child,
  });

  final String label;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: BouncyButton(
      onPressed: onTap,
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: AppPalette.white,
          shape: BoxShape.circle,
          boxShadow: AppShadows.floating,
        ),
        child: child,
      ),
    ),
  );
}

class _SetupCard extends StatelessWidget {
  const _SetupCard({required this.model, required this.progress});

  final HomeViewModel model;
  final SetupProgress progress;

  @override
  Widget build(BuildContext context) {
    final manage = model.school.canRunSetup;
    final current = progress.current;
    final steps = manage
        ? SetupStep.values
        : [...SetupStep.values.where(progress.isDone), ?current];

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Expanded(
                      child: AppText(
                        'SCHOOL SETUP',
                        style: AppTypography.overline.copyWith(
                          color: AppPalette.aubergine500,
                        ),
                      ),
                    ),
                    AppText(
                      '${progress.doneCount} of ${progress.total} done',
                      variant: AppTextVariant.caption,
                      colorType: AppTextColor.textMuted,
                      fontWeight: FontWeight.w700,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.ms),
                AppText(
                  progress.isComplete
                      ? '${model.school.name} is ready'
                      : manage
                      ? 'Get ${model.school.name} ready'
                      : 'Your school is being set up',
                  style: AppTypography.heading(
                    24,
                    lineHeight: 30,
                  ).copyWith(letterSpacing: -0.24, color: AppPalette.stone900),
                ),
                if (!manage && !progress.isComplete) ...[
                  const SizedBox(height: 6),
                  AppText(
                    model.beingSetUpMessage,
                    variant: AppTextVariant.body,
                    colorType: AppTextColor.textBody,
                  ),
                ],
                const SizedBox(height: AppSpacing.ms),
                _ProgressBar(done: progress.doneCount, total: progress.total),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Column(
              children: [
                for (final step in steps) ...[
                  _StepRow(
                    number: step.index + 1,
                    title: step.title,
                    subtitle: progress.isDone(step)
                        ? null
                        : manage
                        ? model.hintFor(step)
                        : 'In progress · ${_moreSteps(progress.remainingAfterCurrent)}',
                    state: progress.isDone(step)
                        ? _StepState.done
                        : step == current
                        ? _StepState.current
                        : _StepState.todo,
                    showChevronWhenDone: !progress.isDone(step),
                    onTap: model.canOpen(step) && !progress.isDone(step)
                        ? () => _openStep(context, step)
                        : null,
                  ),
                  const SizedBox(height: 2),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openStep(BuildContext context, SetupStep step) async {
    if (step != SetupStep.academicCalendar) {
      model.openStep(step);
      return;
    }

    final created = await NavigationService.animatedNavigation<bool>(
      screen: CreateSessionScreen(organizationId: model.school.organization.id),
    );
    if (created != true || !context.mounted) return;

    try {
      await model.refreshSetupProgress();
    } catch (_) {
      AppToast.show(
        'Calendar saved. Pull to refresh setup progress.',
        type: AppToastType.error,
      );
    }
  }

  static String _moreSteps(int count) => switch (count) {
    0 => 'last step',
    1 => '1 more step after this',
    _ => '$count more steps after this',
  };
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.done, required this.total});

  final int done;
  final int total;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$done of $total setup steps done',
    child: SizedBox(
      height: 6,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < total; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: i < done
                      ? AppPalette.aubergine500
                      : AppPalette.stone200,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

enum _StepState { done, current, todo }

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.number,
    required this.title,
    required this.state,
    this.subtitle,
    this.showChevronWhenDone = false,
    this.onTap,
  });

  final int number;
  final String title;
  final String? subtitle;
  final _StepState state;
  final bool showChevronWhenDone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final current = state == _StepState.current;
    final done = state == _StepState.done;
    final showChevron = onTap != null && (!done || showChevronWhenDone);

    final row = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: current ? LightColors.primaryPrimaryMute : null,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _StepMarker(number: number, state: state),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  title,
                  style: AppTypography.title.copyWith(
                    fontSize: 15,
                    height: 22 / 15,
                    color: done ? AppPalette.stone500 : AppPalette.stone900,
                  ),
                ),
                if (subtitle != null)
                  AppText(
                    subtitle!,
                    style: AppTypography.body.copyWith(
                      fontSize: 13,
                      height: 18 / 13,
                      color: current
                          ? AppPalette.stone600
                          : AppPalette.stone500,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox.square(
            dimension: 24,
            child: showChevron
                ? Icon(
                    LucideIcons.chevronRight,
                    size: 20,
                    color: current
                        ? AppPalette.aubergine500
                        : AppPalette.stone400,
                  )
                : null,
          ),
        ],
      ),
    );

    if (onTap == null) return row;
    return BouncyButton(onPressed: onTap, pressedScale: 0.98, child: row);
  }
}

class _StepMarker extends StatelessWidget {
  const _StepMarker({required this.number, required this.state});

  final int number;
  final _StepState state;

  @override
  Widget build(BuildContext context) {
    final numberStyle = AppTypography.body.copyWith(
      fontSize: 13,
      height: 16 / 13,
      fontWeight: FontWeight.w800,
    );
    return switch (state) {
      _StepState.done => Container(
        width: 28,
        height: 28,
        decoration: const BoxDecoration(
          color: LightColors.successSuccessDefault,
          shape: BoxShape.circle,
        ),
        child: const Icon(LucideIcons.check, size: 14, color: AppPalette.white),
      ),
      _StepState.current => Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: AppPalette.aubergine500,
          shape: BoxShape.circle,
        ),
        child: AppText(
          '$number',
          style: numberStyle.copyWith(color: AppPalette.white),
        ),
      ),
      _StepState.todo => Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppPalette.stone300, width: 1.5),
        ),
        child: AppText(
          '$number',
          style: numberStyle.copyWith(color: AppPalette.stone500),
        ),
      ),
    };
  }
}
