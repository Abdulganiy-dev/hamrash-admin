import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/widgets/app_cards.dart';
import 'package:hamrash_admin/core/widgets/app_divider.dart';
import 'package:hamrash_admin/core/widgets/app_section_action.dart';

/// A section header with the standard gap, then any [child]: the one place
/// the header-to-content spacing is decided.
///  * no [action]: [gapWithoutAction] (12), a plain title over the content;
///  * with an [action]: [gapWithAction] (0), because the action's 44 tall
///    tap box already puts the space between the title line and the content.
///
/// A count or tag passed as [trailing] is not an action, so it keeps the 12.
/// Use [AppSectionCard] when the content is a white card; use this for a
/// bar, a list of separate cards, or a grid.
class AppSection extends StatelessWidget {
  const AppSection({
    super.key,
    required this.title,
    required this.child,
    this.caption,
    this.action,
    this.trailing,
  }) : assert(
         trailing == null || action == null,
         'Provide either trailing or action, not both.',
       );

  final String title;

  /// Muted note right after the title, e.g. "2 added".
  final String? caption;

  /// The section's action (Edit, Add a term). Removes the header gap.
  final AppSectionAction? action;

  /// A non-action widget on the right, e.g. a count or a status tag.
  final Widget? trailing;

  final Widget child;

  /// Space between a plain header and its content.
  static const double gapWithoutAction = AppSpacing.ms;

  /// Space between a header that has an action and its content: none, the
  /// action's tap box provides it.
  static const double gapWithAction = 0;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      AppSectionHeader(
        title: title,
        caption: caption,
        action: action,
        trailing: trailing,
      ),
      SizedBox(height: action == null ? gapWithoutAction : gapWithAction),
      child,
    ],
  );
}

/// A titled section (6.2): the header sits outside the card (title, muted
/// caption, optional action such as Edit), then a white card holding the
/// section's rows.
///
/// The header-to-card gap is [AppSection]'s rule (12 without an action, 0
/// with one), so screens never add a spacer of their own.
///
/// Everything in [children] goes in one card; with [divided] (the default)
/// a faint [AppDivider] sits between them, starting at [dividerIndent] and stopping [dividerEndIndent] short. Pass a single child, a
/// [divided]: false list, or your own [padding] (for example
/// `EdgeInsets.zero` for rows that run edge to edge) when the content isn't
/// a plain list of rows. Use [AppSection] when the content isn't a card.
///
/// ```dart
/// AppSectionCard(
///   title: 'Parents',
///   caption: '2 added',
///   action: AppSectionAction(label: 'Edit', icon: AppIcons.pencil, onPressed: edit),
///   children: [for (final parent in parents) ParentRow(parent)],
/// )
///
/// AppSectionCard(
///   title: 'JSS 1A',
///   trailing: AppText('32 students'),
///   padding: EdgeInsets.zero,
///   children: [StudentRows(...)],
/// )
/// ```
class AppSectionCard extends StatelessWidget {
  const AppSectionCard({
    super.key,
    required this.title,
    required this.children,
    this.caption,
    this.action,
    this.trailing,
    this.divided = true,
    this.dividerIndent = 0,
    this.dividerEndIndent = 0,
    this.padding = cardPadding,
  }) : assert(
         trailing == null || action == null,
         'Provide either trailing or action, not both.',
       );

  final String title;

  /// Muted note right after the title, e.g. "2 added".
  final String? caption;

  /// The section's action (Edit, Add a term). Removes the header gap.
  final AppSectionAction? action;

  /// A non-action widget on the right, e.g. a count or a status tag.
  final Widget? trailing;

  final List<Widget> children;
  final bool divided;

  /// Where the dividers start. 0 runs them edge to edge; use 72 to line them
  /// up with the text of rows that have a leading picture.
  final double dividerIndent;

  /// How far the dividers stop short of the card's right edge.
  final double dividerEndIndent;
  final EdgeInsetsGeometry padding;

  /// The card's padding for rows; rows bring their own height.
  static const EdgeInsets cardPadding = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 4,
  );

  Widget _content() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (var i = 0; i < children.length; i++) ...[
        if (divided && i > 0) AppDivider(indent: dividerIndent, endIndent: dividerEndIndent),
        children[i],
      ],
    ],
  );

  @override
  Widget build(BuildContext context) => AppSection(
    title: title,
    caption: caption,
    action: action,
    trailing: trailing,
    child: AppCard(padding: padding, child: _content()),
  );
}
