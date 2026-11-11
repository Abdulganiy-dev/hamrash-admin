import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/students/student_filter.dart';
import 'package:hamrash_admin/core/bottomSheets/app_sheet.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_variants.dart';
import 'package:hamrash_admin/core/widgets/button/bouncy_button.dart';
import 'package:hamrash_admin/core/widgets/selection/app_selection_controls.dart';

/// 9.21 · Change a student's status: in school, graduated, transferred or
/// withdrawn. Pops the chosen status, or null when closed.
class StudentStatusSheet extends StatefulWidget {
  const StudentStatusSheet({super.key, required this.current});

  final StudentStatusFilter current;

  static Future<StudentStatusFilter?> show(
    BuildContext context, {
    required StudentStatusFilter current,
  }) => Navigator.of(context).push<StudentStatusFilter>(
    AppSheetRoute<StudentStatusFilter>(
      size: AppSheetSize.floating,
      child: StudentStatusSheet(current: current),
    ),
  );

  /// The line under each status.
  static const descriptions = {
    StudentStatusFilter.active: 'In school now',
    StudentStatusFilter.graduated: 'Finished their last class here',
    StudentStatusFilter.transferred: 'Moved to another school',
    StudentStatusFilter.withdrawn: 'Left for another reason',
  };

  @override
  State<StudentStatusSheet> createState() => _StudentStatusSheetState();
}

class _StudentStatusSheetState extends State<StudentStatusSheet> {
  late StudentStatusFilter _selected = widget.current;

  @override
  Widget build(BuildContext context) => AppSheet(
    title: 'Change status',
    subtitle: 'Leavers stay on record with their results, and come off class '
        'lists.',
    bodyPadding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (index, status) in StudentStatusFilter.values.indexed) ...[
          if (index > 0) const SizedBox(height: AppSpacing.xs),
          _Row(
            key: ValueKey('student-status-${status.value}'),
            status: status,
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
      onPressed: _selected == widget.current
          ? null
          : () => Navigator.of(context).pop(_selected),
      child: Text(
        _selected == StudentStatusFilter.active
            ? 'Mark as active'
            : 'Mark as ${_selected.label.toLowerCase()}',
      ),
    ),
  );
}

class _Row extends StatelessWidget {
  const _Row({
    super.key,
    required this.status,
    required this.selected,
    required this.onTap,
  });

  final StudentStatusFilter status;
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
                        fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                        color: LightColors.textStrong,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    AppText(
                      StudentStatusSheet.descriptions[status]!,
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
              AppRadio<StudentStatusFilter>(
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
