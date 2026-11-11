import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/students/student_summary.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/constants/radius_containers.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/widgets/animated_section_content.dart';
import 'package:hamrash_admin/core/widgets/app_cards.dart';
import 'package:hamrash_admin/core/widgets/app_divider.dart';
import 'package:hamrash_admin/core/widgets/app_empty_state.dart';
import 'package:hamrash_admin/core/widgets/app_icons.dart';
import 'package:hamrash_admin/core/widgets/app_list_row.dart';
import 'package:hamrash_admin/core/widgets/app_refresh_scroll_view.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/button/bouncy_button.dart';
import 'package:hamrash_admin/core/widgets/default_scaffold.dart';
import 'package:hamrash_admin/core/widgets/load_error_view.dart';
import 'package:hamrash_admin/views/people/students_view_model.dart';
import 'package:hamrash_admin/views/team/widgets/team_skeleton.dart';

/// 9.1 / 9.1a · What the Students side shows for [model]: the error view,
/// the skeleton, "No students yet" or the list grouped by class and arm.
class StudentsContent extends StatelessWidget {
  const StudentsContent({
    super.key,
    required this.model,
    required this.onOpen,
    this.onAdd,
  });

  final StudentsViewModel model;
  final ValueChanged<StudentSummary> onOpen;

  /// Null hides the "Add student" step in the empty state (a bursar only
  /// looks).
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) => AnimatedSectionContent(
    morphHeight: false,
    child: model.error != null
        ? LoadErrorView(key: const ValueKey('error'), onRetry: model.load)
        : model.loading
        ? const _Loading(key: ValueKey('loading'))
        : model.isEmpty
        ? _Empty(key: const ValueKey('empty'), onAdd: onAdd)
        : _List(key: const ValueKey('content'), model: model, onOpen: onOpen),
  );
}

class _List extends StatelessWidget {
  const _List({super.key, required this.model, required this.onOpen});

  final StudentsViewModel model;
  final ValueChanged<StudentSummary> onOpen;

  @override
  Widget build(BuildContext context) => AppRefreshScrollView.children(
    onRefresh: model.refresh,
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.screen,
      AppSpacing.none,
      AppSpacing.screen,
      AppSpacing.md,
    ),
    children: [
      for (final (index, group) in model.groups.indexed) ...[
        if (index > 0) const SizedBox(height: AppSpacing.md),
        AppSectionHeader(
          title: group.title,
          trailing: AppText(
            group.countLabel,
            style: AppTypography.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: LightColors.textMuted,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.xs + AppSpacing.xxs,
          ),
          child: ClipRRect(
            borderRadius: AppRadius.brCard,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (row, student) in group.students.indexed) ...[
                  if (row > 0) const AppDivider(indent: 72),
                  _StudentRow(student: student, onTap: () => onOpen(student)),
                ],
              ],
            ),
          ),
        ),
      ],
    ],
  );
}

class _StudentRow extends StatelessWidget {
  const _StudentRow({required this.student, required this.onTap});

  final StudentSummary student;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: '${student.fullName}. ${student.admissionNumber}.',
    excludeSemantics: true,
    child: BouncyButton(
      onPressed: onTap,
      pressedScale: 0.98,
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.ms,
        ),
        child: Row(
          children: [
            AppLeadingPicture(
              leading: AppListLeading.network(
                student.photoUrl ?? '',
                name: student.fullName,
              ),
              size: 44,
            ),
            const SizedBox(width: AppSpacing.ms),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppText(
                    student.fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    variant: AppTextVariant.title,
                    colorType: AppTextColor.textStrong,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  AppText(
                    student.admissionNumber,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption.copyWith(
                      color: LightColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            const AppIcon(
              AppIcons.chevronRight,
              size: 18,
              color: AppPalette.stone400,
            ),
          ],
        ),
      ),
    ),
  );
}

/// 9.1a · No students yet.
class _Empty extends StatelessWidget {
  const _Empty({super.key, this.onAdd});

  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      AppSpacing.screen,
      ScaffoldInsets.bodyTopInsetOf(context),
      AppSpacing.screen,
      0,
    ),
    child: Center(
      child: AppEmptyState(
        icon: AppIcons.users,
        title: 'No students yet',
        subtitle: onAdd == null
            ? 'Students show here once the school registers them.'
            : 'Register each student with their class and parents.',
        actionLabel: onAdd == null ? null : 'Add student',
        onAction: onAdd,
        topPadding: AppSpacing.none,
      ),
    ),
  );
}

/// The list's skeleton, where the page's content starts.
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
