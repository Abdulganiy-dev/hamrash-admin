import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/team/staff_member.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/constants/radius_containers.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/widgets/app_cards.dart';
import 'package:hamrash_admin/core/widgets/app_divider.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/button/bouncy_button.dart';
import 'package:hamrash_admin/views/team/widgets/staff_avatar.dart';
import 'package:hamrash_admin/views/team/widgets/staff_status_pill.dart';

/// 8.1 · Everyone on the staff list in one white card: initials, name, the
/// role line and where their login has got to, separated by hairlines.
///
/// [subtitleFor] comes from [TeamViewModel.subtitleFor] so the copy stays in
/// the view model.
class StaffListCard extends StatelessWidget {
  const StaffListCard({
    super.key,
    required this.staff,
    required this.subtitleFor,
    required this.onOpen,
  });

  final List<StaffMember> staff;
  final String Function(StaffMember person) subtitleFor;
  final ValueChanged<StaffMember> onOpen;

  /// Card padding above the first row and below the last (6).
  static const _verticalPadding = AppSpacing.xs + AppSpacing.xxs;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: _verticalPadding),
      child: ClipRRect(
        borderRadius: AppRadius.brCard,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (index, person) in staff.indexed) ...[
              if (index > 0) const StaffListDivider(),
              _StaffRow(
                person: person,
                subtitle: subtitleFor(person),
                onTap: () => onOpen(person),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The 1px hairline between two staff rows, inset to the row's text (16 + 44 avatar + 12).
class StaffListDivider extends StatelessWidget {
  const StaffListDivider({super.key});

  @override
  Widget build(BuildContext context) => const AppDivider(indent: 72);
}

class _StaffRow extends StatelessWidget {
  const _StaffRow({
    required this.person,
    required this.subtitle,
    required this.onTap,
  });

  final StaffMember person;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${person.fullName}. $subtitle. ${person.access.label}.',
      excludeSemantics: true,
      // The app's bouncy press (with its light haptic); a wide row only dips
      // a little, like other large surfaces.
      child: BouncyButton(
        onPressed: onTap,
        pressedScale: 0.98,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.ms,
          ),
          color: Colors.transparent,
          child: Row(
            children: [
              StaffAvatar(person: person),
              const SizedBox(width: AppSpacing.ms),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppText(
                      person.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      variant: AppTextVariant.title,
                      colorType: AppTextColor.textStrong,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    AppText(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(
                        color: LightColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.ms),
              StaffStatusPill(access: person.access, onList: true),
            ],
          ),
        ),
      ),
    );
  }
}
