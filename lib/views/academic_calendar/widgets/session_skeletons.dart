import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/widgets/app_cards.dart';
import 'package:hamrash_admin/core/widgets/app_numbered_rows_skeleton.dart';
import 'package:hamrash_admin/core/widgets/app_shimmer.dart';

/// A session card while it loads: label, big name and a caption, with the
/// pill on the right.
class SessionCardSkeleton extends StatelessWidget {
  const SessionCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) => const AppCard(
    child: AppShimmer(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(width: 110, height: 11, radius: 5),
                SizedBox(height: 10),
                ShimmerBox(width: 140, height: 30, radius: 8),
                SizedBox(height: 10),
                ShimmerBox(width: 120, height: 12, radius: 6),
              ],
            ),
          ),
          ShimmerBox(width: 52, height: 32, radius: 16),
        ],
      ),
    ),
  );
}

/// A section title sitting on the page, e.g. "Terms".
class _HeaderSkeleton extends StatelessWidget {
  const _HeaderSkeleton({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: AppShimmer(
      onPage: true,
      child: Row(children: [ShimmerBox(width: width, height: 16)]),
    ),
  );
}

/// 4.0 · The sessions list while it loads.
class SessionsListSkeleton extends StatelessWidget {
  const SessionsListSkeleton({super.key});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const _HeaderSkeleton(width: 130),
      const SizedBox(height: 12),
      const SessionCardSkeleton(),
      const SizedBox(height: 24),
      const _HeaderSkeleton(width: 120),
      const SizedBox(height: 12),
      for (final factor in const [0.42, 0.36]) ...[
        AppCard(
          padding: const EdgeInsets.all(16),
          child: AppShimmer(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerBox(widthFactor: factor, height: 15, radius: 7),
                      const SizedBox(height: 8),
                      const ShimmerBox(widthFactor: 0.7, height: 11, radius: 5),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                const ShimmerBox(width: 64, height: 24, radius: 12),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    ],
  );
}

/// 4.1 · A session's details while they load: its card, then its terms.
class SessionDetailsSkeleton extends StatelessWidget {
  const SessionDetailsSkeleton({super.key});

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SessionCardSkeleton(),
      SizedBox(height: 20),
      _HeaderSkeleton(width: 64),
      SizedBox(height: 12),
      AppCard(
        padding: EdgeInsets.all(8),
        child: AppShimmer(child: AppNumberedRowsSkeleton()),
      ),
    ],
  );
}
