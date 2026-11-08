import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/organization_models/organization_member.dart';
import 'package:hamrash_admin/core/bottomSheets/app_sheet.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/widgets/app_cards.dart';
import 'package:hamrash_admin/core/widgets/app_sheet_error.dart';
import 'package:hamrash_admin/core/widgets/app_icons.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_variants.dart';
import 'package:hamrash_admin/core/widgets/button/bouncy_button.dart';
import 'package:hamrash_admin/views/team/widgets/role_picker_sheet.dart';

/// 8.5 · Choose the role for a new invite, then create it. Pops the raw
/// 8-character code once `invite_staff` returns it.
class InviteSheet extends StatefulWidget {
  const InviteSheet({
    super.key,
    required this.fullName,
    required this.initialRole,
    required this.lockAdmin,
    required this.noteFor,
    required this.onCreate,
    this.viewerName,
    this.viewerRole,
  });

  final String fullName;
  final OrganizationMemberRole initialRole;

  /// Principals and VPs can't issue an admin login.
  final bool lockAdmin;

  /// The sentence above the button, adapted to the chosen role.
  final String Function(OrganizationMemberRole role) noteFor;

  /// Creates the invite; returns its raw code, or why it wasn't made.
  final Future<({String? code, String? error})> Function(
    OrganizationMemberRole role,
  )
  onCreate;

  final String? viewerName;
  final OrganizationMemberRole? viewerRole;

  @override
  State<InviteSheet> createState() => _InviteSheetState();
}

class _InviteSheetState extends State<InviteSheet> {
  late OrganizationMemberRole _role = widget.initialRole;
  bool _saving = false;
  String? _error;

  Future<void> _pickRole() async {
    final role = await Navigator.of(context).push<OrganizationMemberRole>(
      AppSheetRoute<OrganizationMemberRole>(
        size: AppSheetSize.floating,
        child: RolePickerSheet(
          selected: _role,
          lockAdmin: widget.lockAdmin,
          viewerName: widget.viewerName,
          viewerRole: widget.viewerRole,
        ),
      ),
    );
    if (role != null && mounted) {
      setState(() {
        _role = role;
        _error = null;
      });
    }
  }

  Future<void> _create() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    final result = await widget.onCreate(_role);
    if (!mounted) return;
    if (result.code case final code?) {
      Navigator.of(context).pop(code);
      return;
    }
    setState(() {
      _saving = false;
      _error = result.error;
    });
  }

  @override
  Widget build(BuildContext context) => AppSheet(
    title: 'Invite to Hamrash',
    subtitle: 'For ${widget.fullName}',
    bodyPadding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.sm),
          child: AppText('Role', variant: AppTextVariant.subtitle),
        ),
        BouncyButton(
          onPressed: _saving ? null : _pickRole,
          child: AppFlatCard(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppText(
                        _role.teamLabel,
                        style: AppTypography.subtitle.copyWith(
                          color: LightColors.textStrong,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      AppText(
                        _role.teamDescription,
                        style: AppTypography.caption.copyWith(
                          color: LightColors.textBody,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                const AppIcon(
                  AppIcons.chevronRight,
                  size: 18,
                  color: AppPalette.stone400,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppText(
          widget.noteFor(_role),
          style: AppTypography.body.copyWith(color: LightColors.textMuted),
        ),
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
          loadingText: 'Creating…',
          onPressed: _saving ? null : _create,
          child: const Text('Create invite'),
        ),
      ],
    ),
  );
}
