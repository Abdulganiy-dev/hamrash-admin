import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/widgets/app_cards.dart';
import 'package:shimmer/shimmer.dart';

/// Sweeps a soft light across [child]. Build skeletons from [ShimmerBox]es
/// inside it; their opaque pixels take the slate-100 → slate-50 sweep.
///
/// Wrap only the placeholder shapes, not the card around them, so the card
/// itself stays white.
class AppShimmer extends StatelessWidget {
  const AppShimmer({super.key, required this.child, this.onPage = false});

  final Widget child;

  /// Shapes sitting straight on the blue mist page (not inside a card) use
  /// a deeper mist so they show: mist-deep → a lighter mist.
  final bool onPage;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: onPage ? AppPalette.mistDeep : AppPalette.slate100,
      highlightColor: onPage ? const Color(0xFFE2EAF6) : AppPalette.slate50,
      period: const Duration(milliseconds: 1400),
      child: child,
    );
  }
}

/// One placeholder shape. With [width] null it fills its parent; use
/// [widthFactor] for "about this much of the line".
class ShimmerBox extends StatelessWidget {
  const ShimmerBox({
    super.key,
    this.width,
    this.widthFactor,
    required this.height,
    this.radius = 6,
  });

  /// Circle placeholder, e.g. for an avatar.
  const ShimmerBox.circle({super.key, required double size})
    : width = size,
      widthFactor = null,
      height = size,
      radius = size / 2;

  final double? width;

  /// Fraction of the available width, from the left.
  final double? widthFactor;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final box = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        // Recoloured by the surrounding AppShimmer; only needs to be opaque.
        color: AppPalette.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
    if (widthFactor == null) return box;
    return FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: widthFactor,
      child: box,
    );
  }
}

/// Placeholder for one [AppListRow]: picture, two lines and a pill.
class AppListRowSkeleton extends StatelessWidget {
  const AppListRowSkeleton({super.key, this.titleFactor = 0.6});

  /// How much of the line the title bar fills; vary it between rows.
  final double titleFactor;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: AppShimmer(
        child: Row(
          children: [
            const ShimmerBox.circle(size: 52),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBox(widthFactor: titleFactor, height: 14, radius: 7),
                  const SizedBox(height: 8),
                  ShimmerBox(
                    widthFactor: titleFactor * 0.65,
                    height: 12,
                    radius: 6,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            const ShimmerBox(width: 56, height: 24, radius: 12),
          ],
        ),
      ),
    );
  }
}

/// A stack of [AppListRowSkeleton]s, spaced like the real list.
class AppListSkeleton extends StatelessWidget {
  const AppListSkeleton({super.key, this.count = 5});

  final int count;

  static const _factors = [0.62, 0.52, 0.7, 0.48, 0.66];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < count; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          AppListRowSkeleton(titleFactor: _factors[i % _factors.length]),
        ],
      ],
    );
  }
}

/// Placeholder for an [AppCompactList]: a header bar and rows in one card.
class AppCompactListSkeleton extends StatelessWidget {
  const AppCompactListSkeleton({
    super.key,
    this.rows = 3,
    this.showTitle = true,
  });

  final int rows;
  final bool showTitle;

  static const _factors = [0.58, 0.48, 0.64, 0.52];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showTitle) ...[
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: AppShimmer(
              onPage: true,
              child: Row(children: [ShimmerBox(width: 160, height: 16)]),
            ),
          ),
          const SizedBox(height: 12),
        ],
        AppCard(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: AppShimmer(
            child: Column(
              children: [
                for (var i = 0; i < rows; i++) ...[
                  if (i > 0)
                    Container(
                      height: 1,
                      margin: const EdgeInsets.only(left: 68, right: 16),
                      color: AppPalette.white,
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        const ShimmerBox.circle(size: 40),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ShimmerBox(
                                widthFactor: _factors[i % _factors.length],
                                height: 12,
                              ),
                              const SizedBox(height: 7),
                              ShimmerBox(
                                widthFactor:
                                    _factors[i % _factors.length] * 0.6,
                                height: 10,
                                radius: 5,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Placeholder for a stat card: a big number, a caption and a progress bar.
class AppStatCardSkeleton extends StatelessWidget {
  const AppStatCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppCard(
      child: AppShimmer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShimmerBox(width: 110, height: 36, radius: 10),
            SizedBox(height: 14),
            ShimmerBox(widthFactor: 0.6, height: 12),
            SizedBox(height: 14),
            ShimmerBox(height: 8, radius: 4),
          ],
        ),
      ),
    );
  }
}
