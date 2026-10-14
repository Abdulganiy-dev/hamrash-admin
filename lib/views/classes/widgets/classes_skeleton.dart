import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/widgets/app_cards.dart';
import 'package:hamrash_admin/core/widgets/app_shimmer.dart';

/// 6.2 · The classes page while it loads: two sections of three classes.
class ClassesSkeleton extends StatelessWidget {
  const ClassesSkeleton({super.key});

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _Section(titleWidth: 76, rows: [0.34, 0.36, 0.32]),
      SizedBox(height: 16),
      _Section(titleWidth: 68, rows: [0.36, 0.34, 0.36]),
    ],
  );
}

class _Section extends StatelessWidget {
  const _Section({required this.titleWidth, required this.rows});

  final double titleWidth;
  final List<double> rows;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: AppShimmer(
          onPage: true,
          child: Row(
            children: [
              ShimmerBox(width: titleWidth, height: 16),
              const SizedBox(width: 8),
              const ShimmerBox(width: 52, height: 12, radius: 6),
            ],
          ),
        ),
      ),
      const SizedBox(height: 10),
      AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: AppShimmer(
          child: Column(
            children: [
              for (final factor in rows)
                SizedBox(
                  height: 56,
                  child: Row(
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: ShimmerBox(
                            widthFactor: factor,
                            height: 14,
                            radius: 7,
                          ),
                        ),
                      ),
                      const ShimmerBox(width: 28, height: 26, radius: 8),
                      const SizedBox(width: 6),
                      const ShimmerBox(width: 28, height: 26, radius: 8),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    ],
  );
}
