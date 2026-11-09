import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/radius_containers.dart';

/// Where a multi-step flow is: one 6 tall bar per step, 6 apart. Steps up
/// to and including [current] are aubergine, the rest stone-200. [complete]
/// turns every bar green once the flow has finished.
///
/// ```dart
/// AppStepSegments(current: 1, count: 5) // step 2 of 5
/// ```
class AppStepSegments extends StatelessWidget {
  const AppStepSegments({
    super.key,
    required this.current,
    required this.count,
    this.complete = false,
  }) : assert(count > 0),
       assert(current >= 0 && current < count);

  /// Zero-based index of the step on screen.
  final int current;
  final int count;
  final bool complete;

  static const double height = 6;
  static const double gap = 6;

  @override
  Widget build(BuildContext context) => Semantics(
    label: complete ? 'All steps done' : 'Step ${current + 1} of $count',
    child: SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < count; i++) ...[
            if (i > 0) const SizedBox(width: gap),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: complete
                      ? LightColors.successSuccessDefault
                      : i <= current
                      ? LightColors.primaryPrimaryDefault
                      : AppPalette.stone200,
                  borderRadius: AppRadius.brPill,
                ),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}
