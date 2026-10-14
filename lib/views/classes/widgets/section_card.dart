import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/class_structure/class_structure.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/widgets/app_badge.dart';
import 'package:hamrash_admin/core/widgets/app_cards.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/button/bouncy_button.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// 6.2 · A section's header (name, class count, Edit) and a card with a
/// row per class showing its arms.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.section,
    this.onEdit,
    this.onOpenClass,
    this.onAddClass,
  });

  final SchoolSection section;

  /// All null for people who can't change classes.
  final VoidCallback? onEdit;
  final ValueChanged<SchoolClass>? onOpenClass;

  /// Offered inside the card while the section has no classes.
  final VoidCallback? onAddClass;

  @override
  Widget build(BuildContext context) {
    final classes = section.classes;
    final count = classes.length == 1 ? '1 class' : '${classes.length} classes';
    // Classes are added from the app bar's +; an empty section offers it here.
    final showAdd = onAddClass != null && section.isActive && classes.isEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionHeader(
          title: section.name,
          caption: section.isActive ? count : 'Switched off · $count',
          actionLabel: onEdit == null ? null : 'Edit',
          onAction: onEdit,
        ),
        const SizedBox(height: 10),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            children: [
              for (var i = 0; i < classes.length; i++)
                _ClassRow(
                  schoolClass: classes[i],
                  showDivider: i < classes.length - 1,
                  onTap: onOpenClass == null
                      ? null
                      : () => onOpenClass!(classes[i]),
                ),
              if (showAdd)
                _AddClassRow(onTap: onAddClass!)
              else if (classes.isEmpty)
                const _NoClassesRow(),
            ],
          ),
        ),
      ],
    );
  }
}

/// The class name with its arms on one line under it ("A, B, Gold", cut
/// off with … when long), and the arm count on the right.
class _ClassRow extends StatelessWidget {
  const _ClassRow({
    required this.schoolClass,
    required this.showDivider,
    this.onTap,
  });

  final SchoolClass schoolClass;
  final bool showDivider;
  final VoidCallback? onTap;

  /// "A, B, Gold · Graduating", or null when there's nothing to say.
  String? get _details {
    final parts = [
      if (schoolClass.hasArms)
        schoolClass.arms.map((arm) => arm.name).join(', '),
      if (schoolClass.isGraduating) 'Graduating',
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final active = schoolClass.isActive;
    final arms = schoolClass.arms.length;
    final details = _details;
    final row = Container(
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(bottom: BorderSide(color: AppPalette.stone100))
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AppText(
                  schoolClass.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.subtitle.copyWith(
                    fontSize: 15,
                    color: active
                        ? LightColors.textStrong
                        : LightColors.textMuted,
                  ),
                ),
                if (details != null) ...[
                  const SizedBox(height: 2),
                  AppText(
                    details,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body.copyWith(
                      fontSize: 13,
                      height: 18 / 13,
                      color: LightColors.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (!active)
            const AppBadge('Switched off')
          else
            AppText(
              arms == 0
                  ? 'No arms yet'
                  : arms == 1
                  ? '1 arm'
                  : '$arms arms',
              style: AppTypography.label.copyWith(
                fontSize: 13,
                height: 18 / 13,
                color: arms == 0
                    ? LightColors.warningWarningText
                    : LightColors.textMuted,
              ),
            ),
          if (onTap != null) ...[
            const SizedBox(width: 8),
            const Icon(
              LucideIcons.chevronRight,
              size: 18,
              color: AppPalette.stone400,
            ),
          ],
        ],
      ),
    );
    if (onTap == null) return row;
    return BouncyButton(pressedScale: 0.98, onPressed: onTap, child: row);
  }
}

class _AddClassRow extends StatelessWidget {
  const _AddClassRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => BouncyButton(
    pressedScale: 0.98,
    onPressed: onTap,
    child: SizedBox(
      height: 52,
      child: Row(
        children: [
          const Icon(
            LucideIcons.plus,
            size: 18,
            color: LightColors.primaryPrimaryDefault,
          ),
          const SizedBox(width: 8),
          AppText(
            'Add a class',
            style: AppTypography.button.copyWith(color: LightColors.textBrand),
          ),
        ],
      ),
    ),
  );
}

class _NoClassesRow extends StatelessWidget {
  const _NoClassesRow();

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 52,
    child: Align(
      alignment: Alignment.centerLeft,
      child: AppText(
        'No classes yet',
        style: AppTypography.body.copyWith(color: LightColors.textMuted),
      ),
    ),
  );
}
