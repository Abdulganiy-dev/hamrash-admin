import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/widgets/app_cards.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/button/bouncy_button.dart';
import 'package:hamrash_admin/views/academic_calendar/session_draft_model.dart';
import 'package:hamrash_admin/core/widgets/app_svg_icon.dart';

/// The session at the top of the page: its label (e.g. CURRENT SESSION),
/// name, and how many terms and weeks it has. [onEdit] shows the Edit pill;
/// [readOnly] shows a Read-only badge instead.
class SessionSummaryCard extends StatelessWidget {
  const SessionSummaryCard({
    super.key,
    required this.label,
    required this.model,
    this.caption,
    this.onEdit,
    this.readOnly = false,
  });

  final String label;
  final SessionDraftModel model;

  /// Replaces the terms and weeks line, e.g. "Closed 20 Jul 2026".
  final String? caption;
  final VoidCallback? onEdit;
  final bool readOnly;

  @override
  Widget build(BuildContext context) => AppCard(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                label.toUpperCase(),
                style: AppTypography.overline.copyWith(
                  color: AppPalette.aubergine500,
                ),
              ),
              const SizedBox(height: 2),
              AppText(
                model.draft.name,
                style: AppTypography.heading(
                  32,
                  lineHeight: 36,
                ).copyWith(color: AppPalette.stone900),
              ),
              const SizedBox(height: 2),
              AppText(
                caption ??
                    '${model.draft.terms.length} terms · ${model.teachingWeeks} weeks',
                variant: AppTextVariant.body,
                colorType: AppTextColor.textMuted,
              ),
            ],
          ),
        ),
        if (readOnly)
          const _Pill(icon: AppSvgIcons.lock, label: 'Read-only')
        else if (onEdit != null)
          BouncyButton(
            onPressed: onEdit,
            child: const _Pill(label: 'Edit'),
          ),
      ],
    ),
  );
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, this.icon});

  final String label;
  final AppSvgIconData? icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: AppPalette.stone100,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          AppSvgIcon(icon, size: 14, color: AppPalette.stone700),
          const SizedBox(width: 6),
        ],
        AppText(
          label,
          style: AppTypography.label.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: icon == null ? AppPalette.stone900 : AppPalette.stone700,
          ),
        ),
      ],
    ),
  );
}
