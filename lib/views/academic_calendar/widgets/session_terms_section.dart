import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/widgets/app_section_action.dart';
import 'package:hamrash_admin/core/widgets/app_section_card.dart';
import 'package:hamrash_admin/views/academic_calendar/session_draft_model.dart';
import 'package:hamrash_admin/views/academic_calendar/widgets/session_term_row.dart';
import 'package:hamrash_admin/core/widgets/app_icons.dart';

/// "Terms" with its Add a term link, then the terms in one card. Without
/// [onAddTerm] and [onOpenTerm] (read-only) the link and chevrons go.
class SessionTermsSection extends StatelessWidget {
  const SessionTermsSection({
    super.key,
    required this.model,
    this.onAddTerm,
    this.onOpenTerm,
  });

  final SessionDraftModel model;
  final VoidCallback? onAddTerm;
  final ValueChanged<int>? onOpenTerm;

  @override
  Widget build(BuildContext context) => AppSectionCard(
    title: 'Terms',
    action: onAddTerm == null
        ? null
        : AppSectionAction(
            label: 'Add a term',
            icon: AppIcons.plus,
            semanticLabel: 'Add a term',
            onPressed: model.draft.terms.length >= 6 ? null : onAddTerm,
          ),
    padding: const EdgeInsets.all(8),
    children: [
      Column(
        children: [
          for (var i = 0; i < model.draft.terms.length; i++)
            SessionTermRow(
              index: i,
              model: model,
              onTap: onOpenTerm == null ? null : () => onOpenTerm!(i),
            ),
        ],
      ),
    ],
  );
}
