import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/students/student_profile.dart';
import 'package:hamrash_admin/core/bottomSheets/app_sheet.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/widgets/app_sheet_error.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_variants.dart';
import 'package:hamrash_admin/core/widgets/button/bouncy_button.dart';
import 'package:hamrash_admin/core/widgets/selection/app_selection_controls.dart';

/// 9.15 · Move a student to another arm of their class. Their current arm is
/// marked "Now"; a switched-off arm is greyed. `onMove` returns how many
/// optional subjects were dropped and the reason it failed; on success the
/// sheet pops that count (0 when none dropped).
class MoveArmSheet extends StatefulWidget {
  const MoveArmSheet({
    super.key,
    required this.className,
    required this.currentArmId,
    required this.arms,
    required this.onMove,
  });

  final String className;
  final String currentArmId;
  final List<ArmChoice> arms;
  final Future<({int dropped, String? error})> Function(String armId) onMove;

  static Future<int?> show(
    BuildContext context, {
    required String className,
    required String currentArmId,
    required List<ArmChoice> arms,
    required Future<({int dropped, String? error})> Function(String armId)
    onMove,
  }) => Navigator.of(context).push<int>(
    AppSheetRoute<int>(
      size: AppSheetSize.floating,
      child: MoveArmSheet(
        className: className,
        currentArmId: currentArmId,
        arms: arms,
        onMove: onMove,
      ),
    ),
  );

  @override
  State<MoveArmSheet> createState() => _MoveArmSheetState();
}

class _MoveArmSheetState extends State<MoveArmSheet> {
  String? _selected;
  bool _saving = false;
  String? _error;

  ArmChoice? get _picked {
    for (final arm in widget.arms) {
      if (arm.armId == _selected) return arm;
    }
    return null;
  }

  Future<void> _move() async {
    final arm = _picked;
    if (arm == null || _saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final result = await widget.onMove(arm.armId);
    if (!mounted) return;
    if (result.error == null) {
      Navigator.of(context).pop(result.dropped);
      return;
    }
    setState(() {
      _saving = false;
      _error = result.error;
    });
  }

  @override
  Widget build(BuildContext context) => AppSheet(
    title: 'Move to another arm',
    subtitle:
        '${widget.className} · Scores already recorded stay with their old '
        'arm.',
    bodyPadding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (index, arm) in widget.arms.indexed) ...[
          if (index > 0) const SizedBox(height: AppSpacing.xs),
          _ArmRow(
            key: ValueKey('arm-row-${arm.armId}'),
            arm: arm,
            isNow: arm.armId == widget.currentArmId,
            selected: _selected == arm.armId,
            onTap: () => setState(() {
              _selected = arm.armId;
              _error = null;
            }),
          ),
        ],
      ],
    ),
    footer: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_error case final message?) AppSheetError(message),
        AppPrimaryButton(
          useGradient: true,
          height: 52,
          isLoading: _saving,
          loadingText: 'Moving…',
          isDisabled: _picked == null,
          onPressed: _picked == null ? null : _move,
          child: Text(
            _picked == null ? 'Move' : 'Move to ${_picked!.label}',
          ),
        ),
      ],
    ),
  );
}

class _ArmRow extends StatelessWidget {
  const _ArmRow({
    super.key,
    required this.arm,
    required this.isNow,
    required this.selected,
    required this.onTap,
  });

  final ArmChoice arm;
  final bool isNow;
  final bool selected;
  final VoidCallback onTap;

  bool get _enabled => !isNow && arm.isActive;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: _enabled,
    selected: selected,
    child: BouncyButton(
      onPressed: _enabled ? onTap : null,
      isDisabled: !_enabled,
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
                      arm.label,
                      style: AppTypography.subtitle.copyWith(
                        fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                        color: _enabled
                            ? LightColors.textStrong
                            : LightColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    AppText(
                      isNow
                          ? 'Now · ${arm.caption}'
                          : arm.isActive
                          ? arm.caption
                          : 'Switched off · takes no new students',
                      style: AppTypography.caption.copyWith(
                        color: LightColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              if (!isNow)
                AppRadio<String>(
                  value: arm.armId,
                  groupValue: selected ? arm.armId : null,
                  onChanged: _enabled ? (_) => onTap() : null,
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
