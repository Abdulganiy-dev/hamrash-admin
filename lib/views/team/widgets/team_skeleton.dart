import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/widgets/app_shimmer.dart';

/// 8.1 · The team list while it loads: three filter chips, then rows.
class TeamSkeleton extends StatelessWidget {
  const TeamSkeleton({super.key});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const AppShimmer(
        onPage: true,
        child: Row(
          children: [
            ShimmerBox(width: 62, height: 36, radius: 8),
            SizedBox(width: AppSpacing.sm),
            ShimmerBox(width: 92, height: 36, radius: 8),
            SizedBox(width: AppSpacing.sm),
            ShimmerBox(width: 108, height: 36, radius: 8),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      const AppListSkeleton(count: 4),
    ],
  );
}

/// 8.4–8.10 · A staff page while it loads: the identity header, a card of
/// details and the page's action.
class StaffDetailSkeleton extends StatelessWidget {
  const StaffDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) => const AppShimmer(
    onPage: true,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            ShimmerBox.circle(size: 72),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ShimmerBox(widthFactor: 0.55, height: 22, radius: 8),
                  SizedBox(height: AppSpacing.sm),
                  ShimmerBox(widthFactor: 0.4, height: 14, radius: 7),
                  SizedBox(height: AppSpacing.ms),
                  ShimmerBox(width: 86, height: 24, radius: 12),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.lg),
        ShimmerBox(height: 18, widthFactor: 0.45),
        SizedBox(height: AppSpacing.stack),
        ShimmerBox(height: 160, radius: 20),
        SizedBox(height: AppSpacing.lg),
        ShimmerBox(height: 52, radius: 12),
      ],
    ),
  );
}
