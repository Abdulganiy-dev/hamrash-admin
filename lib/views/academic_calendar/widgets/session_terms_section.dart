import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/widgets/app_cards.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/widgets/button/app_button.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_types.dart';
import 'package:hamrash_admin/views/academic_calendar/session_draft_model.dart';
import 'package:hamrash_admin/views/academic_calendar/widgets/session_term_row.dart';
import 'package:hamrash_admin/core/widgets/app_svg_icon.dart';

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
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      AppSectionHeader(
        title: 'Terms',
        trailing: onAddTerm == null
            ? null
            : AppButton(
                type: AppButtonType.text,
                text: 'Add a term',
                isDisabled: model.draft.terms.length >= 6,
                onPressed: onAddTerm,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppSvgIcon(AppSvgIcons.plus, size: 16),
                    SizedBox(width: 4),
                    AppText('Add a term', variant: AppTextVariant.subtitle),
                  ],
                ),
              ),
      ),
      if (onAddTerm == null) const SizedBox(height: 12),
      AppCard(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            for (var i = 0; i < model.draft.terms.length; i++)
              SessionTermRow(
                index: i,
                model: model,
                onTap: onOpenTerm == null ? null : () => onOpenTerm!(i),
              ),
          ],
        ),
      ),
    ],
  );
}
