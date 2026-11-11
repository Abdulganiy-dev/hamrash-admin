import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/team/staff_member.dart';
import 'package:hamrash_admin/core/bottomSheets/app_sheet.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_variants.dart';
import 'package:hamrash_admin/core/widgets/button/bouncy_button.dart';
import 'package:hamrash_admin/core/widgets/selection/app_selection_controls.dart';

/// 9.29 · Change a staff record's own status — active, on leave or exited.
/// That is separate from their login: suspending a login lives in the Access
/// card beside it. Pops the chosen status, or null when closed.
class StaffStatusSheet extends StatefulWidget {
  const StaffStatusSheet({super.key, required this.current});

  final StaffRecordStatus current;

  static Future<StaffRecordStatus?> show(
    BuildContext context, {
    required StaffRecordStatus current,
  }) => Navigator.of(context).push<StaffRecordStatus>(
    AppSheetRoute<StaffRecordStatus>(
      size: AppSheetSize.floating,
      child: StaffStatusSheet(current: current),
    ),
  );

  @override
  State<StaffStatusSheet> createState() => _StaffStatusSheetState();
}

class _StaffStatusSheetState extends State<StaffStatusSheet> {
  late StaffRecordStatus _selected = widget.current;

  static const _descriptions = {
    StaffRecordStatus.active: 'On the team and working as usual.',
    StaffRecordStatus.onLeave: 'Still on the staff list, away for now.',
    StaffRecordStatus.exited: 'Left the school. They stay in past records.',
  };

  @override
  Widget build(BuildContext context) => AppSheet(
    title: 'Status',
    subtitle: 'Their record, separate from their Hamrash login.',
    bodyPadding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (index, status) in StaffRecordStatus.values.indexed) ...[
          if (index > 0) const SizedBox(height: AppSpacing.xs),
          _StatusRow(
            key: ValueKey('status-row-${status.value}'),
            status: status,
            description: _descriptions[status]!,
            selected: _selected == status,
            onTap: () => setState(() => _selected = status),
          ),
        ],
      ],
    ),
    footer: AppPrimaryButton(
      useGradient: true,
      height: 52,
      isDisabled: _selected == widget.current,
      onPressed:
          _selected == widget.current
              ? null
              : () => Navigator.of(context).pop(_selected),
      child: const Text('Save status'),
    ),
  );
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    super.key,
    required this.status,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  final StaffRecordStatus status;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    child: BouncyButton(
      onPressed: onTap,
      pressedScale: 0.98,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 66),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.ms),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppText(
                      status.label,
                      style: AppTypography.subtitle.copyWith(
                        fontWeight:
                            selected ? FontWeight.w800 : FontWeight.w700,
                        color: LightColors.textStrong,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    AppText(
                      description,
                      style: AppTypography.caption.copyWith(
                        color: selected
                            ? LightColors.textBody
                            : LightColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              AppRadio<StaffRecordStatus>(
                value: status,
                groupValue: selected ? status : null,
                onChanged: (_) => onTap(),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
