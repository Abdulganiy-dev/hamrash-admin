import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/widgets/app_cards.dart';
import 'package:hamrash_admin/core/widgets/app_divider.dart';
import 'package:hamrash_admin/core/widgets/app_section_action.dart';

/// A titled section (6.2): the header sits outside the card (title, muted
/// caption, optional action such as Edit), then a white card holding the
/// section's rows.
///
/// With [divided] the card puts a faint [AppDivider] between rows; turn it
/// off when the rows draw their own lines.
///
/// ```dart
/// AppSectionCard(
///   title: 'Parents',
///   caption: '2 added',
///   action: AppSectionAction(label: 'Edit', icon: AppIcons.pencil, onPressed: edit),
///   children: [for (final parent in parents) ParentRow(parent)],
/// )
/// ```
class AppSectionCard extends StatelessWidget {
  const AppSectionCard({
    super.key,
    required this.title,
    required this.children,
    this.caption,
    this.action,
    this.divided = true,
  });

  final String title;
  final String? caption;
  final AppSectionAction? action;
  final List<Widget> children;
  final bool divided;

  /// Space between the header and the card.
  static const double headerGap = 10;

  /// The card's padding; rows bring their own height.
  static const EdgeInsets cardPadding = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 4,
  );

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      AppSectionHeader(title: title, caption: caption, action: action),
      const SizedBox(height: headerGap),
      AppCard(
        padding: cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (divided && i > 0) const AppDivider(indent: 0, endIndent: 0),
              children[i],
            ],
          ],
        ),
      ),
    ],
  );
}
