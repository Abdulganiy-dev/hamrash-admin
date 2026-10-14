import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/widgets/app_shimmer.dart';

/// Placeholder rows for numbered lists inside a card, like the setup
/// checklist and a session's terms: a 28 mark, a title and a caption.
/// Wrap in an [AppShimmer]; this only draws the shapes.
class AppNumberedRowsSkeleton extends StatelessWidget {
  const AppNumberedRowsSkeleton({super.key, this.rows = 3});

  final int rows;

  static const _factors = [0.55, 0.42, 0.62, 0.38, 0.5, 0.46, 0.58];

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (var i = 0; i < rows; i++)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
          child: Row(
            children: [
              const ShimmerBox.circle(size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(
                      widthFactor: _factors[i % _factors.length],
                      height: 14,
                      radius: 7,
                    ),
                    const SizedBox(height: 7),
                    ShimmerBox(
                      widthFactor: _factors[i % _factors.length] * 0.8,
                      height: 11,
                      radius: 5,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
    ],
  );
}
