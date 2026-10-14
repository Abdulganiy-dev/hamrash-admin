import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/organization_models/school_area.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/widgets/app_cards.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/views/more/more_view_model.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The areas this person can see, two tiles per row. A lock marks the ones
/// they can only view.
class SchoolAreaGrid extends StatelessWidget {
  const SchoolAreaGrid({super.key, required this.model, required this.onOpen});

  final MoreViewModel model;
  final ValueChanged<SchoolArea> onOpen;

  @override
  Widget build(BuildContext context) {
    final areas = model.areas;
    return Column(
      children: [
        for (var i = 0; i < areas.length; i += 2) ...[
          if (i > 0) const SizedBox(height: 10),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _tile(areas[i])),
                const SizedBox(width: 10),
                Expanded(
                  child: i + 1 < areas.length
                      ? _tile(areas[i + 1])
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _tile(SchoolArea area) => _AreaTile(
    area: area,
    status: model.statusFor(area),
    viewOnly: model.accessTo(area) == AreaAccess.view,
    onTap: () => onOpen(area),
  );
}

class _AreaTile extends StatelessWidget {
  const _AreaTile({
    required this.area,
    required this.status,
    required this.viewOnly,
    required this.onTap,
  });

  final SchoolArea area;
  final String status;
  final bool viewOnly;
  final VoidCallback onTap;

  static (IconData, Color, Color) _look(SchoolArea area) => switch (area) {
    SchoolArea.academicCalendar => (
      LucideIcons.calendar,
      LightColors.primaryPrimaryMute,
      AppPalette.aubergine500,
    ),
    SchoolArea.classes => (
      LucideIcons.layers,
      AppPalette.tangerineMute,
      AppPalette.tangerineText,
    ),
    SchoolArea.subjects => (
      LucideIcons.bookOpen,
      AppPalette.honeyMute,
      AppPalette.honeyText,
    ),
    SchoolArea.grading => (
      LucideIcons.award,
      AppPalette.chartreuseMute,
      AppPalette.chartreuseText,
    ),
    SchoolArea.team => (
      LucideIcons.userPlus,
      AppPalette.tealMute,
      AppPalette.tealText,
    ),
    SchoolArea.schoolDetails => (
      LucideIcons.school,
      AppPalette.stone100,
      AppPalette.stone700,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final (icon, fill, ink) = _look(area);
    return Semantics(
      button: true,
      label: viewOnly ? '${area.title}, view only' : area.title,
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: fill,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icon, size: 20, color: ink),
                ),
                const Spacer(),
                if (viewOnly)
                  const Icon(
                    LucideIcons.lock,
                    size: 14,
                    color: AppPalette.stone400,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.ms),
            AppText(
              area.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              variant: AppTextVariant.subtitle,
              colorType: AppTextColor.textStrong,
              fontSize: 15,
            ),
            const SizedBox(height: AppSpacing.xxs),
            AppText(
              status,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              variant: AppTextVariant.body,
              colorType: AppTextColor.textMuted,
              fontSize: 13,
            ),
          ],
        ),
      ),
    );
  }
}
