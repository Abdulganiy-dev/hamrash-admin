import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/class_structure/class_structure.dart';
import 'package:hamrash_admin/api/models/grading/section_grading.dart';
import 'package:hamrash_admin/api/models/organization_models/member_school.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/widgets/app_cards.dart';
import 'package:hamrash_admin/core/widgets/app_divider.dart';
import 'package:hamrash_admin/core/widgets/app_icons.dart';
import 'package:hamrash_admin/core/widgets/app_refresh_scroll_view.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/default_scaffold.dart';
import 'package:hamrash_admin/services/navigation_service.dart';
import 'package:hamrash_admin/views/classes/classes_screen.dart';
import 'package:hamrash_admin/views/grading/grading_view_model.dart';
import 'package:hamrash_admin/views/grading/section_grading_screen.dart';
import 'package:hamrash_admin/views/grading/widgets/grading_banner.dart';
import 'package:hamrash_admin/views/grading/widgets/grading_section_row.dart';
import 'package:hamrash_admin/views/grading/widgets/grading_body.dart';
import 'package:hamrash_admin/views/grading/widgets/grading_empty_state.dart';
import 'package:stacked/stacked.dart';

/// 8.20–8.22 · Grading from the More tab or the Home checklist: one row per
/// active section, each with its own grading. Pops `true` when something was
/// saved, so the page behind reloads.
class GradingScreen extends StatelessWidget {
  const GradingScreen({super.key, required this.school});

  final MemberSchool school;

  @override
  Widget build(BuildContext context) =>
      ViewModelBuilder<GradingViewModel>.reactive(
        viewModelBuilder: () => GradingViewModel(school: school),
        onViewModelReady: (model) => model.load(),
        builder: (context, model, _) => DefaultScaffold(
          title: 'Grading',
          showBackButton: true,
          onBackPressed: () => NavigationService.popScreen(model.changed),
          backgroundColor: AppPalette.linen,
          body: GradingBody(
            loading: model.loading,
            error: model.error,
            onRetry: model.load,
            stateKey: () => model.showEmpty ? 'empty' : 'sections',
            content: () => model.showEmpty
                ? _NoSections(model: model)
                : _Sections(model: model),
          ),
        ),
      );
}

/// 8.20 · The active sections, in teaching order.
class _Sections extends StatelessWidget {
  const _Sections({required this.model});

  final GradingViewModel model;

  @override
  Widget build(BuildContext context) => AppRefreshScrollView.children(
    onRefresh: model.refresh,
    children: [
      if (!model.canChange) ...[
        const GradingBanner(
          tone: GradingBannerTone.plain,
          icon: AppIcons.eye,
          title: 'Read only for you',
          message:
              'You can see how each section is graded. Only school leaders '
              'can change it.',
        ),
        const SizedBox(height: 24),
      ],
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText(
              'Grade each section its own way',
              colorType: AppTextColor.textStrong,
              style: AppTypography.heading(
                24,
                lineHeight: 32,
              ).copyWith(letterSpacing: -0.01),
            ),
            const SizedBox(height: 6),
            AppText(
              'Every section has its own score columns and grades. Changing '
              'one never changes another.',
              style: AppTypography.body.copyWith(
                fontSize: 14,
                height: 20 / 14,
                color: LightColors.textBody,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      AppSectionHeader(
        title: 'Sections',
        trailing: AppText(
          '${model.setUpCount} of ${model.sectionCount} set up',
          style: AppTypography.body.copyWith(
            fontSize: 13,
            height: 18 / 13,
            fontWeight: FontWeight.w700,
            color: LightColors.primaryPrimaryText,
          ),
        ),
      ),
      const SizedBox(height: 12),
      AppCard(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          children: [
            for (final (i, grading) in model.sections.indexed) ...[
              if (i > 0) const AppDivider(),
              _SectionRow(grading: grading, model: model),
            ],
          ],
        ),
      ),

      const SizedBox(height: 24),
    ],
  );
}

class _SectionRow extends StatelessWidget {
  const _SectionRow({required this.grading, required this.model});

  final SectionGrading grading;
  final GradingViewModel model;

  @override
  Widget build(BuildContext context) {
    final section = model.activeSections.firstWhere(
      (s) => s.id == grading.sectionId,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GradingSectionRow(
        grading: grading,
        onTap: () => _open(context, section),
      ),
    );
  }

  Future<void> _open(BuildContext context, SchoolSection section) async {
    final changed = await NavigationService.animatedNavigation<bool>(
      screen: SectionGradingScreen(
        school: model.school,
        section: section,
        sections: model.allSections,
      ),
    );
    if (changed == true) await model.markChanged();
  }
}

/// 8.21 · No active section yet.
class _NoSections extends StatelessWidget {
  const _NoSections({required this.model});

  final GradingViewModel model;

  @override
  Widget build(BuildContext context) => GradingEmptyState(
    icon: AppIcons.layers,
    title: model.hasAnySections
        ? 'No active sections'
        : 'Create your sections first',
    subtitle: model.hasAnySections
        ? 'Every section is switched off. Switch one on in Classes and '
              'arms to grade it.'
        : 'Each section, like Nursery or Junior Secondary, gets its own '
              'grading. Sections are made in Classes and arms.',
    actionLabel: model.canChange ? 'Go to Classes and arms' : null,
    onAction: model.canChange
        ? () async {
            final changed = await NavigationService.animatedNavigation<bool>(
              screen: ClassesScreen(school: model.school),
            );
            if (changed == true) await model.refresh().catchError((_) {});
          }
        : null,
  );
}

/// The quiet "everything is already saved" line at the foot of a page.
class SaveNote extends StatelessWidget {
  const SaveNote(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) => Expanded(
    child: AppText(
      message,
      style: AppTypography.body.copyWith(
        fontSize: 13,
        height: 18 / 13,
        color: LightColors.textMuted,
      ),
    ),
  );
}
