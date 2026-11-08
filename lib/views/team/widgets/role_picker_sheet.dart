import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/organization_models/organization_member.dart';
import 'package:hamrash_admin/core/bottomSheets/app_sheet.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/widgets/app_badge.dart';
import 'package:hamrash_admin/core/widgets/app_icons.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_variants.dart';
import 'package:hamrash_admin/core/widgets/button/bouncy_button.dart';

/// 8.6 / 8.7 · Pick the role an invite gives, or the role a login changes
/// to. Pops the chosen [OrganizationMemberRole].
///
/// Rows sit straight on the white sheet: no fill, no radius, no dividers.
/// The radio and the title's weight carry the choice. The roles a principal
/// or vice principal can't issue (admin) are greyed and locked, with the
/// reason and who's looking.
class RolePickerSheet extends StatefulWidget {
  const RolePickerSheet({
    super.key,
    required this.selected,
    this.title = 'Role',
    this.lockAdmin = false,
    this.viewerName,
    this.viewerRole,
  });

  final OrganizationMemberRole selected;
  final String title;

  /// True when the viewer may not invite admins (principal or VP).
  final bool lockAdmin;

  /// The person being invited, for the locked row's line.
  final String? viewerName;

  /// The signed-in person's role, for "you're a principal".
  final OrganizationMemberRole? viewerRole;

  static const roles = [
    OrganizationMemberRole.admin,
    OrganizationMemberRole.principal,
    OrganizationMemberRole.vicePrincipal,
    OrganizationMemberRole.bursar,
    OrganizationMemberRole.teacher,
    OrganizationMemberRole.staff,
  ];

  @override
  State<RolePickerSheet> createState() => _RolePickerSheetState();
}

class _RolePickerSheetState extends State<RolePickerSheet> {
  late OrganizationMemberRole _selected =
      widget.lockAdmin && widget.selected == OrganizationMemberRole.admin
          ? OrganizationMemberRole.principal
          : widget.selected;

  bool get _canUse =>
      !(widget.lockAdmin && _selected == OrganizationMemberRole.admin);

  @override
  Widget build(BuildContext context) => AppSheet(
    title: widget.title,
    bodyPadding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (index, role) in RolePickerSheet.roles.indexed) ...[
          if (index > 0) const SizedBox(height: AppSpacing.xs),
          _RoleRow(
            key: ValueKey('role-row-${role.value}'),
            role: role,
            selected: _selected == role,
            locked: widget.lockAdmin && role == OrganizationMemberRole.admin,
            lockedLine:
                widget.lockAdmin && role == OrganizationMemberRole.admin
                    ? 'Only the owner or an admin can invite admins'
                    : null,
            lockedCaption:
                widget.lockAdmin && role == OrganizationMemberRole.admin
                    ? _viewerLine
                    : null,
            onTap: () => setState(() => _selected = role),
          ),
        ],
      ],
    ),
    footer: AppPrimaryButton(
      useGradient: true,
      height: 52,
      isDisabled: !_canUse,
      onPressed: _canUse ? () => Navigator.of(context).pop(_selected) : null,
      child: Text('Use ${_selected.teamLabel}'),
    ),
  );

  String? get _viewerLine {
    final name = widget.viewerName;
    final role = widget.viewerRole;
    if (name == null || role == null) return null;
    return "For $name · you're a ${role.teamLabel.toLowerCase()}";
  }
}

class _RoleRow extends StatelessWidget {
  const _RoleRow({
    super.key,
    required this.role,
    required this.selected,
    required this.locked,
    required this.onTap,
    this.lockedLine,
    this.lockedCaption,
  });

  final OrganizationMemberRole role;
  final bool selected;
  final bool locked;
  final VoidCallback onTap;
  final String? lockedLine;
  final String? lockedCaption;

  /// 66 tall with 12 of air above and below the title and its line.
  static const double _height = 66;

  @override
  Widget build(BuildContext context) {
    final enabled = !locked;
    final row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: _height),
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
                    role.teamLabel,
                    style: AppTypography.subtitle.copyWith(
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                      color:
                          enabled
                              ? LightColors.textStrong
                              : LightColors.textDisabled,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  AppText(
                    locked ? _lockedText : role.teamDescription,
                    style: AppTypography.caption.copyWith(
                      color:
                          enabled
                              ? (selected
                                  ? LightColors.textBody
                                  : LightColors.textMuted)
                              : LightColors.textMuted,
                    ),
                  ),
                  if (locked && lockedCaption != null) ...[
                    const SizedBox(height: AppSpacing.xxs),
                    AppText(
                      lockedCaption!,
                      style: AppTypography.caption.copyWith(
                        color: AppPalette.stone400,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            if (role.isStaffAppRole) ...[
              const AppBadge('Staff app', tone: AppBadgeTone.neutral),
              const SizedBox(width: AppSpacing.sm),
            ],
            if (locked)
              const AppIcon(AppIcons.lock, size: 20, color: AppPalette.stone400)
            else
              _RoleRadio(selected: selected),
          ],
        ),
      ),
    );

    return Semantics(
      button: true,
      enabled: enabled,
      selected: selected,
      child: BouncyButton(
        onPressed: enabled ? onTap : null,
        isDisabled: !enabled,
        pressedScale: 0.98,
        child: row,
      ),
    );
  }

  String get _lockedText =>
      lockedLine ?? "The owner or an admin can invite this role";
}

/// The row's only decoration: a filled aubergine circle with a white check
/// when picked, otherwise an empty stone ring. The shared [AppRadio] keeps
/// its dot for every other picker.
class _RoleRadio extends StatelessWidget {
  const _RoleRadio({required this.selected});

  final bool selected;

  static const double _size = 22;
  static const _duration = Duration(milliseconds: 140);

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: _duration,
    width: _size,
    height: _size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: selected ? LightColors.primaryPrimaryDefault : AppPalette.white,
      border: Border.all(
        color:
            selected ? LightColors.primaryPrimaryDefault : AppPalette.stone300,
        width: 1.5,
      ),
    ),
    child: AnimatedScale(
      duration: _duration,
      curve: Curves.easeOutBack,
      scale: selected ? 1 : 0,
      child: const AppIcon(AppIcons.check, size: 14, color: AppPalette.white),
    ),
  );
}
