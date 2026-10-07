import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Wraps [child] in a theme-aware shimmer sweep. Compose skeletons from
/// [ShimmerBox]es as the child; their opaque pixels are recolored by the
/// animated gradient.
class AppShimmer extends StatelessWidget {
  const AppShimmer({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Shimmer.fromColors(
      baseColor: isLight ? const Color(0xFFE4E4E4) : const Color(0xFF333333),
      highlightColor:
          isLight ? const Color(0xFFF6F6F6) : const Color(0xFF444444),
      child: child,
    );
  }
}

/// A single opaque rounded rectangle skeleton piece. With [width] null it
/// stretches to fill its parent (e.g. inside an Expanded), keeping bars
/// responsive and overflow-proof. Its fill is recolored by an ancestor
/// [AppShimmer]'s gradient, so the color here only needs to be opaque.
class ShimmerBox extends StatelessWidget {
  const ShimmerBox({
    super.key,
    this.width,
    required this.height,
    this.radius = 6,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Skeleton placeholder shown inside a dashboard section's surface card while
/// its data loads. Renders [count] rows that echo the real
/// "title + subtitle / trailing chip" item layout used across the home
/// dashboard sections, wrapped in a single shimmer sweep.
class DashboardSectionShimmer extends StatelessWidget {
  const DashboardSectionShimmer({super.key, this.count = 3});

  /// Number of placeholder rows to render — matches the 3 items each section
  /// shows once loaded.
  final int count;

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < count; i++) ...[
            if (i > 0) SizedBox(height: AppSpacing.sm),
            const _SectionShimmerRow(),
          ],
        ],
      ),
    );
  }
}

class _SectionShimmerRow extends StatelessWidget {
  const _SectionShimmerRow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title line — fills ~half the available width.
                Row(
                  children: const [
                    Expanded(flex: 1, child: ShimmerBox(height: 13)),
                    Spacer(flex: 1),
                  ],
                ),
                SizedBox(height: AppSpacing.xs),
                // Subtitle line — fills ~80% of the available width.
                Row(
                  children: const [
                    Expanded(flex: 4, child: ShimmerBox(height: 11)),
                    Spacer(flex: 1),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: AppSpacing.sm),
          const ShimmerBox(width: 64, height: 28, radius: 14),
        ],
      ),
    );
  }
}
