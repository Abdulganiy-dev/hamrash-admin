import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/team/staff_member.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/constants/radius_containers.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';

/// The staff record in a white 2-column card: job title and staff type, staff
/// number and record status, phone and email. While an invite waits, its role
/// takes the record cell's place so it can be changed from here.
class StaffDetailsCard extends StatelessWidget {
  const StaffDetailsCard({
    super.key,
    required this.jobTitle,
    required this.staffType,
    required this.staffNumber,
    required this.status,
    this.phone,
    this.email,
    this.roleLabel,
    this.onChangeRole,
  });

  final String? jobTitle;

  /// "Teaching" or "Non-teaching".
  final String staffType;

  /// Empty when the record has none: shown as "Not set".
  final String? staffNumber;
  final StaffRecordStatus status;
  final String? phone;
  final String? email;

  /// Set for an invite that is waiting: replaces the record cell with Role.
  final String? roleLabel;
  final VoidCallback? onChangeRole;

  static const _border = AppPalette.stone200;
  static const _rowHeight = 56.0;

  String get _recordLabel => switch (status) {
    StaffRecordStatus.active => 'Active',
    StaffRecordStatus.onLeave => 'On leave',
    StaffRecordStatus.exited => 'Exited',
  };

  Color get _recordDot => switch (status) {
    StaffRecordStatus.active => LightColors.successSuccessDefault,
    StaffRecordStatus.onLeave => LightColors.warningWarningDefault,
    StaffRecordStatus.exited => AppPalette.stone400,
  };

  @override
  Widget build(BuildContext context) {
    final role = roleLabel;
    return ClipRRect(
      borderRadius: AppRadius.brCard,
      child: Container(
        decoration: BoxDecoration(
          color: AppPalette.white,
          border: Border.all(color: _border),
        ),
        child: Column(
          children: [
            _row(
              _Cell(
                label: 'Job title',
                value: jobTitle,
                fallback: 'Not added',
              ),
              _Cell(label: 'Staff type', value: staffType),
            ),
            _hairline(),
            _row(
              _Cell(
                label: 'Staff no.',
                value: staffNumber,
                fallback: 'Not set',
              ),
              role == null
                  ? _Cell(
                      label: 'Record',
                      showValue: false,
                      trailing: _RecordValue(
                        label: _recordLabel,
                        dot: _recordDot,
                      ),
                    )
                  : _Cell(
                      label: 'Role',
                      value: role,
                      trailing: onChangeRole == null
                          ? null
                          : _ChangeAction(onPressed: onChangeRole!),
                    ),
            ),
            _hairline(),
            _row(
              _Cell(label: 'Phone', value: phone, fallback: 'Not added'),
              _Cell(label: 'Email', value: email, fallback: 'Not added'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(Widget left, Widget right) => SizedBox(
    height: _rowHeight,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: left),
        Container(
          key: const ValueKey('details-vertical-divider'),
          width: 1,
          color: _border,
        ),
        Expanded(child: right),
      ],
    ),
  );

  Widget _hairline() => Container(height: 1, color: _border);
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.label,
    this.value,
    this.fallback = 'Not added',
    this.trailing,
    this.showValue = true,
  });

  final String label;
  final String? value;
  final String fallback;
  final Widget? trailing;

  /// False for cells whose value is a custom [trailing] widget, e.g. Record.
  final bool showValue;

  @override
  Widget build(BuildContext context) {
    final text = value?.trim() ?? '';
    final empty = text.isEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppText(
            label,
            style: AppTypography.caption.copyWith(
              fontWeight: FontWeight.w600,
              height: 16 / 12,
              color: LightColors.textMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Row(
            children: [
              if (showValue)
                Expanded(
                  child: AppText(
                    empty ? fallback : text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body.copyWith(
                      fontSize: 16,
                      height: 22 / 16,
                      fontWeight: empty ? FontWeight.w600 : FontWeight.w700,
                      color: empty
                          ? LightColors.textMuted
                          : LightColors.textStrong,
                    ),
                  ),
                )
              else
                const Spacer(),
              if (trailing case final trailing?) ...[
                const SizedBox(width: AppSpacing.sm),
                trailing,
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _RecordValue extends StatelessWidget {
  const _RecordValue({required this.label, required this.dot});

  final String label;
  final Color dot;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
      ),
      const SizedBox(width: 6),
      AppText(
        label,
        style: AppTypography.body.copyWith(
          fontSize: 16,
          height: 22 / 16,
          fontWeight: FontWeight.w700,
          color: LightColors.textStrong,
        ),
      ),
    ],
  );
}

class _ChangeAction extends StatelessWidget {
  const _ChangeAction({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Change role',
    excludeSemantics: true,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: AppText(
          'Change',
          style: AppTypography.button.copyWith(
            color: LightColors.primaryPrimaryText,
          ),
        ),
      ),
    ),
  );
}
