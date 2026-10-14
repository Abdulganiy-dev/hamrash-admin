import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/widgets/app_cards.dart';
import 'package:hamrash_admin/core/widgets/app_shimmer.dart';

/// The More tab's first load: three rows of two area tiles.
class SchoolAreaGridSkeleton extends StatelessWidget {
  const SchoolAreaGridSkeleton({super.key, this.tiles = 6});

  final int tiles;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (var i = 0; i < tiles; i += 2) ...[
        if (i > 0) const SizedBox(height: 10),
        Row(
          children: [
            const Expanded(child: _Tile(titleFactor: 0.78)),
            const SizedBox(width: 10),
            Expanded(
              child: i + 1 < tiles
                  ? const _Tile(titleFactor: 0.62)
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ],
    ],
  );
}

class _Tile extends StatelessWidget {
  const _Tile({required this.titleFactor});

  final double titleFactor;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.all(14),
    child: AppShimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ShimmerBox(width: 36, height: 36, radius: 11),
          const SizedBox(height: 14),
          ShimmerBox(widthFactor: titleFactor, height: 14, radius: 7),
          const SizedBox(height: 7),
          ShimmerBox(widthFactor: titleFactor * 0.7, height: 11, radius: 5),
        ],
      ),
    ),
  );
}
