import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/team/staff_member.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/constants/radius_containers.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/haptic_helper.dart';
import 'package:hamrash_admin/core/widgets/app_cards.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
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
      // Clip the pressed fill to the card's corners.
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

/// The 1px hairline between two staff rows, inset with the row's text.
class StaffListDivider extends StatelessWidget {
  const StaffListDivider({super.key});

  @override
  Widget build(BuildContext context) => Container(
    height: 1,
    margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
    color: AppPalette.stone200,
  );
}

class _StaffRow extends StatefulWidget {
  const _StaffRow({
    required this.person,
    required this.subtitle,
    required this.onTap,
  });

  final StaffMember person;
  final String subtitle;
  final VoidCallback onTap;

  @override
  State<_StaffRow> createState() => _StaffRowState();
}

class _StaffRowState extends State<_StaffRow> {
  bool _pressed = false;

  static const _pressDuration = Duration(milliseconds: 140);

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  void _tap() {
    HapticHelpers.vibrate(VibrationType.light);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final person = widget.person;

    return Semantics(
      button: true,
      label: '${person.fullName}. ${widget.subtitle}. ${person.access.label}.',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        // onTap (not only onTapUp) so taps work inside the scroll view.
        onTap: _tap,
        child: AnimatedContainer(
          duration: _pressDuration,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.ms,
          ),
          color: _pressed ? AppPalette.stone50 : Colors.transparent,
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
                      widget.subtitle,
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
