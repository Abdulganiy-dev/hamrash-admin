import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/widgets/app_shimmer.dart';
import 'package:flutter/material.dart';

/// Full-screen loading skeleton for list screens whose rows mirror a detail
/// card layout: a muted id line, a title line, and a detail card block.
class DetailCardListShimmer extends StatelessWidget {
  const DetailCardListShimmer({super.key, this.count = 5, this.topInset = 0});

  final int count;
  final double topInset;

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: topInset,
          bottom: AppSpacing.s50,
        ),
        itemCount: count,
        separatorBuilder: (_, _) => SizedBox(height: AppSpacing.md),
        itemBuilder: (_, _) => const DetailCardSkeleton(),
      ),
    );
  }
}

/// Single-row skeleton matching [DetailCardListShimmer]'s list items.
class DetailCardSkeleton extends StatelessWidget {
  const DetailCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: AppSpacing.s5),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            ShimmerBox(width: 80, height: 12),
            ShimmerBox(width: 20, height: 20),
          ],
        ),
        SizedBox(height: AppSpacing.s10),
        Row(
          children: const [
            Expanded(flex: 7, child: ShimmerBox(height: 14)),
            Spacer(flex: 3),
          ],
        ),
        SizedBox(height: AppSpacing.s10),
        const ShimmerBox(width: double.infinity, height: 110, radius: 16),
      ],
    );
  }
}
