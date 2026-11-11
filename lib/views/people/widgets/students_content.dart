import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/students/student_summary.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/widgets/animated_section_content.dart';
import 'package:hamrash_admin/core/widgets/app_empty_state.dart';
import 'package:hamrash_admin/core/widgets/app_icons.dart';
import 'package:hamrash_admin/core/widgets/app_list_row.dart';
import 'package:hamrash_admin/core/widgets/app_refresh_scroll_view.dart';
import 'package:hamrash_admin/core/widgets/app_section_card.dart';
import 'package:hamrash_admin/core/widgets/app_spinner.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/button/bouncy_button.dart';
import 'package:hamrash_admin/core/widgets/default_scaffold.dart';
import 'package:hamrash_admin/core/widgets/load_error_view.dart';
import 'package:hamrash_admin/views/people/students_view_model.dart';
import 'package:hamrash_admin/views/people/widgets/applied_filters.dart';
import 'package:hamrash_admin/views/team/widgets/team_skeleton.dart';

/// 9.1 / 9.1a–c · What the Students side shows for [model]: the error view,
/// the skeleton, "No students yet", or the list grouped by class and arm
/// with its applied filters, the next page loading as you scroll.
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

class _List extends StatefulWidget {
  const _List({super.key, required this.model, required this.onOpen});

  final StudentsViewModel model;
  final ValueChanged<StudentSummary> onOpen;

  @override
  State<_List> createState() => _ListState();
}

class _ListState extends State<_List> {
  /// Start the next page this far before the end of the list.
  static const _loadMoreExtent = 300.0;

  final _controller = ScrollController();

  StudentsViewModel get model => widget.model;

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
          SliverToBoxAdapter(
            child: AppliedFilters(
              labels: [for (final chip in filter.chips) chip.label],
              onRemove: (index) => model.removeChip(filter.chips[index]),
              countText:
                  '${model.total} ${model.total == 1 ? 'student' : 'students'}',
            ),
          ),
        if (model.showNoResults)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _NoResults(model: model),
          )
        else ...[
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
            sliver: SliverList.list(
              children: [
                for (final (index, group) in model.groups.indexed) ...[
                  if (index > 0) const SizedBox(height: AppSpacing.md),
                  AppSectionCard(
                    title: group.title,
                    trailing: AppText(
                      group.countLabel,
                      style: AppTypography.caption.copyWith(
                        fontWeight: FontWeight.w600,
                        color: LightColors.textMuted,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xs + AppSpacing.xxs,
                    ),
                    dividerIndent: 72,
                    dividerEndIndent: 16,
                    children: [
                      for (final student in group.students)
                        _StudentRow(
                          student: student,
                          subtitle: model.subtitleFor(student),
                          onTap: () => widget.onOpen(student),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          SliverToBoxAdapter(child: _MoreFooter(model: model)),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
        ],
      ],
    );
  }
}

/// 9.1c · A search or filters that match no student.
class _NoResults extends StatelessWidget {
  const _NoResults({required this.model});

  final StudentsViewModel model;

  @override
  Widget build(BuildContext context) {
    final filter = model.filter;
    final subject = filter.subject?.label;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screen,
        vertical: AppSpacing.md,
      ),
      child: AppEmptyState(
        icon: AppIcons.search,
        compact: true,
        title: subject == null
            ? 'No students match'
            : 'No students take $subject here',
        subtitle: subject == null
            ? 'Try removing a filter or checking the spelling.'
            : 'Try another class, or remove a filter.',
        actionLabel: 'Clear filters',
        onAction: model.clearFilters,
        topPadding: AppSpacing.none,
      ),
    );
  }
}

/// Under the list: a spinner while the next page loads, or a retry row when
/// it didn't.
class _MoreFooter extends StatelessWidget {
  const _MoreFooter({required this.model});

  final StudentsViewModel model;

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

class _StudentRow extends StatelessWidget {
  const _StudentRow({
    required this.student,
    required this.subtitle,
    required this.onTap,
  });

  final StudentSummary student;

  /// The admission number, or "Mathematics · Teacher: Mr. John" while a
  /// subject is picked.
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: '${student.fullName}. $subtitle.',
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
                    subtitle,
                    maxLines: 2,
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
