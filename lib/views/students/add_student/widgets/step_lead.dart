import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';

/// The top of a wizard step: "STEP 2 OF 5 · PARENTS", the question, and an
/// optional line of help.
class StepLead extends StatelessWidget {
  const StepLead({
    super.key,
    required this.eyebrow,
    required this.title,
    this.body,
  });

  final String eyebrow;
  final String title;
  final String? body;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      AppText(
        eyebrow.toUpperCase(),
        style: AppTypography.overline.copyWith(
          color: LightColors.primaryPrimaryDefault,
        ),
      ),
      const SizedBox(height: 10),
      AppText(
        title,
        style: AppTypography.h1.copyWith(
          fontWeight: FontWeight.w800,
          color: LightColors.textStrong,
        ),
      ),
      if (body case final body?) ...[
        const SizedBox(height: 10),
        AppText(
          body,
          style: AppTypography.bodyLarge.copyWith(color: LightColors.textBody),
        ),
      ],
    ],
  );
}

/// Padding every step page shares: the 16 gutters, 24 under the progress
/// bars, and room for the keyboard at the bottom.
class StepScroll extends StatelessWidget {
  const StepScroll({
    super.key,
    required this.children,
    this.gap = AppSpacing.lg,
  });

  final List<Widget> children;

  /// Between the step's groups.
  final double gap;

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.lg,
        AppSpacing.screen,
        AppSpacing.lg + keyboard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) SizedBox(height: gap),
            children[i],
          ],
        ],
      ),
    );
  }
}
