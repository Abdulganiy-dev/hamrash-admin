import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/radius_containers.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/widgets/app_cards.dart';
import 'package:hamrash_admin/core/widgets/app_shimmer.dart';

/// 9.3 · The team list while it loads: one card of hairline-separated rows,
/// the same shape as the finished page.
class TeamSkeleton extends StatelessWidget {
  const TeamSkeleton({super.key});

  static const _titleFactors = [0.55, 0.44, 0.62, 0.5, 0.58];

  /// Card padding above the first row and below the last (6).
  static const _verticalPadding = AppSpacing.xs + AppSpacing.xxs;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      AppCard(
        padding: const EdgeInsets.symmetric(vertical: _verticalPadding),
        child: AppShimmer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < _titleFactors.length; i++) ...[
                if (i > 0)
                  Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    color: AppPalette.white,
                  ),
                _RowSkeleton(titleFactor: _titleFactors[i]),
              ],
            ],
          ),
        ),
      ),
    ],
  );
}

class _RowSkeleton extends StatelessWidget {
  const _RowSkeleton({required this.titleFactor});

  final double titleFactor;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.ms,
    ),
    child: Row(
      children: [
        const ShimmerBox.circle(size: 44),
        const SizedBox(width: AppSpacing.ms),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShimmerBox(widthFactor: titleFactor, height: 14, radius: 7),
              const SizedBox(height: AppSpacing.sm),
              ShimmerBox(widthFactor: titleFactor * 0.8, height: 12, radius: 6),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.ms),
        const ShimmerBox(width: 56, height: 24, radius: AppRadius.pill),
      ],
    ),
  );
}
