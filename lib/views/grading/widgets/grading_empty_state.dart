import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/widgets/app_empty_state.dart';
import 'package:hamrash_admin/core/widgets/default_scaffold.dart';

/// The one empty state of the Grading pages, laid out the same everywhere:
/// centred in the page below the app bar, 16px gutters, the Design System's
/// plain icon, title, line and one next step.
class GradingEmptyState extends StatelessWidget {
  const GradingEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
    this.secondaryLabel,
    this.onSecondary,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      AppSpacing.screen,
      ScaffoldInsets.bodyTopInsetOf(context),
      AppSpacing.screen,
      0,
    ),
    child: Center(
      child: AppEmptyState(
        icon: icon,
        title: title,
        subtitle: subtitle,
        actionLabel: actionLabel,
        onAction: onAction,
        secondaryLabel: secondaryLabel,
        onSecondary: onSecondary,
        topPadding: AppSpacing.none,
      ),
    ),
  );
}
