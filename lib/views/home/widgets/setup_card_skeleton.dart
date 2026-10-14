import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/widgets/app_cards.dart';
import 'package:hamrash_admin/core/widgets/app_numbered_rows_skeleton.dart';
import 'package:hamrash_admin/core/widgets/app_shimmer.dart';

/// Home's first load: the setup card's header, progress bar and seven steps.
class SetupCardSkeleton extends StatelessWidget {
  const SetupCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) => const AppCard(
    padding: EdgeInsets.zero,
    child: AppShimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(width: 96, height: 11, radius: 5),
                SizedBox(height: 14),
                ShimmerBox(widthFactor: 0.72, height: 24, radius: 8),
                SizedBox(height: 16),
                ShimmerBox(height: 6, radius: 3),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: AppNumberedRowsSkeleton(rows: 7),
          ),
        ],
      ),
    ),
  );
}
