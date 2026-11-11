import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/radius_containers.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/widgets/app_cards.dart';
import 'package:hamrash_admin/core/widgets/app_section_card.dart';
import 'package:hamrash_admin/core/widgets/app_shimmer.dart';
import 'package:hamrash_admin/core/widgets/default_scaffold.dart';

/// The shape of one row inside a skeleton card, with the height of the real
/// row it stands for.
enum SkeletonRow {
  /// A details row (`StaffInfoRow`): 20 icon, a label and a value. 52 tall.
  info(52),

  /// A teaching / class row (`StaffTeachingRow`): a 36 tile over two lines.
  tile(60),

  /// A person row (a parent or a child): a 40 picture over two lines. 68.
  person(68),

  /// An Access card app row: 20 icon, a label and a value. 52 tall.
  access(52),

  /// An Access card action: a 20 icon over a title and a caption. 64 tall.
  action(64);

  const SkeletonRow(this.height);

  final double height;
}

/// One titled card on the page: its header and [rows] rows of one [kind].
class SkeletonSection {
  const SkeletonSection({
    required this.kind,
    required this.rows,
    this.action = false,
    this.caption = false,
    this.gap = AppSpacing.lg,
  });

  final SkeletonRow kind;
  final int rows;

  /// The header carries an action, so it is the 44 tall one with no gap.
  final bool action;

  /// The header has a small caption on the right.
  final bool caption;

  /// Space above this section.
  final double gap;
}

/// A person's page while it loads (staff, student or parent): the centred
/// hero, optional round action buttons, then the same cards the finished
/// page draws, with their real row heights and spacing so nothing jumps
/// when the content arrives.
class PersonDetailSkeleton extends StatelessWidget {
  const PersonDetailSkeleton({
    super.key,
    required this.sections,
    this.pill = true,
    this.actionCircles = false,
  });

  /// The cards under the hero, top to bottom.
  final List<SkeletonSection> sections;

  /// The status pill under the name.
  final bool pill;

  /// Call, Message and Email under the pill (staff).
  final bool actionCircles;

  /// Gap above the first card: wider than between cards.
  static const double firstGap = AppSpacing.lg + AppSpacing.xs;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const SizedBox(height: AppSpacing.sm),
      AppShimmer(
        onPage: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(child: ShimmerBox.circle(size: 80)),
            const SizedBox(height: 14),
            const Center(child: ShimmerBox(width: 170, height: 28, radius: 8)),
            const SizedBox(height: AppSpacing.xs),
            const Center(child: ShimmerBox(width: 130, height: 16, radius: 8)),
            if (pill) ...[
              const SizedBox(height: 10),
              const Center(
                child: ShimmerBox(width: 92, height: 26, radius: 13),
              ),
            ],
            if (actionCircles) ...[
              const SizedBox(height: 22),
              const _ActionCircles(),
            ],
          ],
        ),
      ),
      for (final (i, section) in sections.indexed)
        Padding(
          padding: EdgeInsets.only(top: i == 0 ? firstGap : section.gap),
          child: _SectionSkeleton(section: section),
        ),
    ],
  );
}

/// The page's skeleton where its content starts, below the app bar.
class PersonDetailLoading extends StatelessWidget {
  const PersonDetailLoading({super.key, required this.skeleton});

  final Widget skeleton;

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
        child: skeleton,
      ),
    ),
  );
}

/// 9.29 · A staff page: Teaching, Details, Personal and Access, as a leader
/// sees them.
class StaffDetailSkeleton extends StatelessWidget {
  const StaffDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) => const PersonDetailSkeleton(
    actionCircles: true,
    sections: [
      SkeletonSection(kind: SkeletonRow.tile, rows: 2, caption: true),
      SkeletonSection(kind: SkeletonRow.info, rows: 6, action: true),
      SkeletonSection(kind: SkeletonRow.info, rows: 5, caption: true),
      ..._access,
    ],
  );
}

/// 9.12 · A student page: Class, Parents, Details, Personal and Access.
/// Personal and Access are for leaders only, so [leader] shows or hides them.
class StudentDetailSkeleton extends StatelessWidget {
  const StudentDetailSkeleton({super.key, this.leader = true});

  final bool leader;

  @override
  Widget build(BuildContext context) => PersonDetailSkeleton(
    sections: [
      const SkeletonSection(kind: SkeletonRow.tile, rows: 2, caption: true),
      SkeletonSection(kind: SkeletonRow.person, rows: 2, action: leader),
      SkeletonSection(kind: SkeletonRow.info, rows: 4, action: leader),
      if (leader) ...[
        const SkeletonSection(kind: SkeletonRow.info, rows: 6, caption: true),
        ..._access,
      ],
    ],
  );
}

/// 9.18 · A parent's page: Children, Details and, for leaders, Access.
class ParentDetailSkeleton extends StatelessWidget {
  const ParentDetailSkeleton({super.key, this.leader = true});

  final bool leader;

  @override
  Widget build(BuildContext context) => PersonDetailSkeleton(
    sections: [
      const SkeletonSection(kind: SkeletonRow.person, rows: 2),
      SkeletonSection(kind: SkeletonRow.info, rows: 4, action: leader),
      if (leader) ..._access,
    ],
  );
}

/// The Access card: a header with the date, the app card, then the Actions.
const _access = [
  SkeletonSection(kind: SkeletonRow.access, rows: 2, caption: true),
];

class _ActionCircles extends StatelessWidget {
  const _ActionCircles();

  @override
  Widget build(BuildContext context) => const Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      _ActionCircle(),
      SizedBox(width: 28),
      _ActionCircle(),
      SizedBox(width: 28),
      _ActionCircle(),
    ],
  );
}

/// A 56 circle with its label under it, in a 64 wide slot.
class _ActionCircle extends StatelessWidget {
  const _ActionCircle();

  @override
  Widget build(BuildContext context) => const SizedBox(
    width: 64,
    child: Column(
      children: [
        ShimmerBox.circle(size: 56),
        SizedBox(height: 6),
        ShimmerBox(width: 36, height: 12, radius: 6),
      ],
    ),
  );
}

class _SectionSkeleton extends StatelessWidget {
  const _SectionSkeleton({required this.section});

  final SkeletonSection section;

  @override
  Widget build(BuildContext context) {
    final isAccess = section.kind == SkeletonRow.access;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _HeaderSkeleton(
          action: section.action,
          caption: section.caption,
        ),
        SizedBox(
          height: section.action
              ? AppSection.gapWithAction
              : AppSection.gapWithoutAction,
        ),
        _CardSkeleton(kind: section.kind, rows: section.rows),
        // The Access card is followed by its Actions card.
        if (isAccess) ...[
          const SizedBox(height: AppSpacing.ms),
          const _CardSkeleton(kind: SkeletonRow.action, rows: 3),
        ],
      ],
    );
  }
}

/// The section header: a 24 tall title row, or the 44 tall one that carries
/// an action.
class _HeaderSkeleton extends StatelessWidget {
  const _HeaderSkeleton({required this.action, required this.caption});

  final bool action;
  final bool caption;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
    child: SizedBox(
      height: action ? 44 : 24,
      child: AppShimmer(
        onPage: true,
        child: Row(
          children: [
            const ShimmerBox(width: 88, height: 16, radius: 8),
            const Spacer(),
            if (action) const ShimmerBox(width: 72, height: 20, radius: 10),
            if (caption) const ShimmerBox(width: 96, height: 12, radius: 6),
          ],
        ),
      ),
    ),
  );
}

class _CardSkeleton extends StatelessWidget {
  const _CardSkeleton({required this.kind, required this.rows});

  final SkeletonRow kind;
  final int rows;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: AppSectionCard.cardPadding,
    child: AppShimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < rows; i++) ...[
            if (i > 0)
              Container(
                height: 1,
                margin: EdgeInsets.only(left: _dividerIndent),
                color: AppPalette.white,
              ),
            SizedBox(height: kind.height, child: _row(i)),
          ],
        ],
      ),
    ),
  );

  /// Dividers start at the text, like the real cards.
  double get _dividerIndent => switch (kind) {
    SkeletonRow.tile => 36 + AppSpacing.ms,
    SkeletonRow.person => 40 + AppSpacing.ms,
    _ => 0,
  };

  Widget _row(int index) => switch (kind) {
    SkeletonRow.info || SkeletonRow.access => _InfoRowSkeleton(index: index),
    SkeletonRow.tile => const _LeadingRowSkeleton(leading: 36),
    SkeletonRow.person => const _LeadingRowSkeleton(leading: 40),
    SkeletonRow.action => const _ActionRowSkeleton(),
  };
}

/// An icon, a label and a right-aligned value.
class _InfoRowSkeleton extends StatelessWidget {
  const _InfoRowSkeleton({required this.index});

  final int index;

  static const _valueFactors = [0.3, 0.4, 0.25, 0.35, 0.45, 0.3];

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const ShimmerBox(width: 20, height: 20, radius: 6),
      const SizedBox(width: AppSpacing.ms),
      const ShimmerBox(width: 84, height: 14, radius: 7),
      const Spacer(),
      Expanded(
        child: Align(
          alignment: Alignment.centerRight,
          child: ShimmerBox(
            widthFactor: _valueFactors[index % _valueFactors.length],
            height: 14,
            radius: 7,
          ),
        ),
      ),
    ],
  );
}

/// A picture or tile over two lines of text.
class _LeadingRowSkeleton extends StatelessWidget {
  const _LeadingRowSkeleton({required this.leading});

  final double leading;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      leading == 40
          ? const ShimmerBox.circle(size: 40)
          : ShimmerBox(width: leading, height: leading, radius: AppRadius.sm),
      const SizedBox(width: AppSpacing.ms),
      const Expanded(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShimmerBox(widthFactor: 0.5, height: 14, radius: 7),
            SizedBox(height: AppSpacing.sm),
            ShimmerBox(widthFactor: 0.7, height: 12, radius: 6),
          ],
        ),
      ),
    ],
  );
}

/// An icon beside a title over a quiet caption.
class _ActionRowSkeleton extends StatelessWidget {
  const _ActionRowSkeleton();

  @override
  Widget build(BuildContext context) => const Row(
    children: [
      ShimmerBox(width: 20, height: 20, radius: 6),
      SizedBox(width: AppSpacing.ms),
      Expanded(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShimmerBox(widthFactor: 0.4, height: 14, radius: 7),
            SizedBox(height: AppSpacing.sm),
            ShimmerBox(widthFactor: 0.7, height: 12, radius: 6),
          ],
        ),
      ),
    ],
  );
}
