import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/widgets/app_cards.dart';
import 'package:hamrash_admin/core/widgets/app_divider.dart';
import 'package:hamrash_admin/core/widgets/app_icons.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/button/bouncy_button.dart';
import 'package:hamrash_admin/views/team/widgets/staff_info_section.dart';

/// Where one app stands for one person. The words are the Access card's.
enum AccessState {
  notOnApp('Not on app'),
  codeReady('Code ready'),
  onApp('On app'),
  suspended('Suspended');

  const AccessState(this.label);

  final String label;
}

/// One app card's content: the app row (its name and [state]) and, once the
/// person has a role there, a display-only Role / Roles row.
class AccessApp {
  const AccessApp({
    required this.appName,
    required this.state,
    this.roles = const [],
    this.onTap,
  });

  /// "Hamrash Admin" or "Hamrash Staff".
  final String appName;
  final AccessState state;

  /// The roles they hold on this app. Empty when they have no login (no
  /// Role row). One role reads "Role"; several read "Roles", joined with
  /// " · ".
  final List<String> roles;

  /// Makes the app row a button with a chevron: the invite, for someone who
  /// isn't on the app.
  final VoidCallback? onTap;
}

/// The colour an action's title takes: neutral for the record's own status,
/// warning for the reversible actions that hold someone back, error for
/// removal, success for restore.
enum AccessActionTone { neutral, warning, success, error }

/// One row of the Actions card.
class AccessAction {
  const AccessAction({
    required this.key,
    required this.icon,
    required this.title,
    required this.caption,
    required this.onTap,
    this.tone = AccessActionTone.neutral,
  });

  final Key key;
  final IconData icon;
  final String title;
  final String caption;
  final VoidCallback? onTap;
  final AccessActionTone tone;
}

/// § 9b · The Access card, shared by every detail page: a header with an
/// optional caption (the join or invite date), one white card per app the
/// person's roles span, then a separate Actions card. A person on both apps
/// gets two app cards; one app with two roles gets one card whose row reads
/// "Roles".
///
/// The pages differ only in what they pass in: [apps] and [actions].
class AccessCards extends StatelessWidget {
  const AccessCards({
    super.key,
    required this.apps,
    required this.actions,
    this.title = 'Access',
    this.caption,
  });

  final String title;

  /// "Joined 3 Sep 2026" or "Invited 8 Nov".
  final String? caption;

  final List<AccessApp> apps;
  final List<AccessAction> actions;

  /// Space between the cards.
  static const double cardGap = AppSpacing.ms;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SizedBox(
        height: StaffInfoSection.headerHeight,
        child: Row(
          children: [
            Expanded(child: StaffSectionTitle(title)),
            if (caption != null)
              AppText(
                caption!,
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: LightColors.textMuted,
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: StaffInfoSection.headerGap),
      for (final app in apps) ...[
        AccessAppCard(app: app),
        const SizedBox(height: cardGap),
      ],
      if (actions.isNotEmpty) AccessActionsCard(actions: actions),
    ],
  );
}

/// The app row, and under it the Role / Roles row.
class AccessAppCard extends StatelessWidget {
  const AccessAppCard({super.key, required this.app});

  final AccessApp app;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: StaffInfoSection.cardPadding,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _AccessRow(
          icon: AppIcons.smartphone,
          label: app.appName,
          value: app.state.label,
          muted: app.state == AccessState.notOnApp,
          onTap: app.onTap,
          semanticLabel: app.onTap == null
              ? '${app.appName}, ${app.state.label}'
              : 'Invite them to ${app.appName}',
        ),
        if (app.roles.isNotEmpty) ...[
          const AppDivider(indent: 0, endIndent: 0),
          _AccessRow(
            icon: AppIcons.shield,
            label: app.roles.length > 1 ? 'Roles' : 'Role',
            value: app.roles.join(' · '),
          ),
        ],
      ],
    ),
  );
}

/// A 52 row: 20 icon slot, muted label, right-aligned value at weight 600.
/// With [onTap] it's a button with a chevron. Display only otherwise.
class _AccessRow extends StatelessWidget {
  const _AccessRow({
    required this.icon,
    required this.label,
    required this.value,
    this.muted = false,
    this.onTap,
    this.semanticLabel,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool muted;
  final VoidCallback? onTap;
  final String? semanticLabel;

  static const _evenLeading = TextHeightBehavior(
    leadingDistribution: TextLeadingDistribution.even,
  );

  @override
  Widget build(BuildContext context) {
    final row = SizedBox(
      height: StaffInfoRow.rowHeight,
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: AppIcon(icon, size: 18, color: AppPalette.stone500),
          ),
          const SizedBox(width: AppSpacing.ms),
          Text(
            label,
            maxLines: 1,
            textHeightBehavior: _evenLeading,
            style: AppTypography.body.copyWith(
              fontSize: 14,
              height: 20 / 14,
              fontWeight: FontWeight.w600,
              color: LightColors.textBody,
            ),
          ),
          const SizedBox(width: AppSpacing.ms),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textHeightBehavior: _evenLeading,
              style: AppTypography.body.copyWith(
                fontSize: 15,
                height: 20 / 15,
                fontWeight: FontWeight.w600,
                color: muted ? LightColors.textMuted : LightColors.textStrong,
              ),
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 6),
            const AppIcon(
              AppIcons.chevronRight,
              size: 18,
              color: AppPalette.stone400,
            ),
          ],
        ],
      ),
    );

    if (onTap == null) {
      return Semantics(
        label: semanticLabel ?? '$label, $value',
        excludeSemantics: true,
        child: row,
      );
    }
    return Semantics(
      button: true,
      label: semanticLabel ?? '$label, $value',
      excludeSemantics: true,
      child: BouncyButton(
        onPressed: onTap,
        pressedScale: 0.98,
        child: ColoredBox(color: Colors.transparent, child: row),
      ),
    );
  }
}

/// The Actions card: 64 rows, a tinted title over its quiet explanation.
class AccessActionsCard extends StatelessWidget {
  const AccessActionsCard({super.key, required this.actions});

  final List<AccessAction> actions;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: StaffInfoSection.cardPadding,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < actions.length; i++) ...[
          if (i > 0) const AppDivider(indent: 0, endIndent: 0),
          _AccessActionRow(key: actions[i].key, action: actions[i]),
        ],
      ],
    ),
  );
}

/// A 64 row with a 20 icon slot and the bouncy press every tappable surface
/// uses.
class _AccessActionRow extends StatelessWidget {
  const _AccessActionRow({super.key, required this.action});

  final AccessAction action;

  Color get _color => switch (action.tone) {
    AccessActionTone.neutral => LightColors.textStrong,
    AccessActionTone.warning => LightColors.warningWarningText,
    AccessActionTone.success => LightColors.successSuccessText,
    AccessActionTone.error => LightColors.errorErrorText,
  };

  Color get _iconColor => switch (action.tone) {
    AccessActionTone.neutral => AppPalette.stone600,
    AccessActionTone.warning => LightColors.warningWarningText,
    AccessActionTone.success => LightColors.successSuccessText,
    AccessActionTone.error => LightColors.errorErrorText,
  };

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: action.onTap != null,
    label: '${action.title}. ${action.caption}',
    excludeSemantics: true,
    child: BouncyButton(
      onPressed: action.onTap,
      isDisabled: action.onTap == null,
      child: SizedBox(
        height: 64,
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: AppIcon(action.icon, size: 18, color: _iconColor),
            ),
            const SizedBox(width: AppSpacing.ms),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    action.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body.copyWith(
                      fontSize: 15,
                      height: 20 / 15,
                      fontWeight: FontWeight.w700,
                      color: _color,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  AppText(
                    action.caption,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      color: LightColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
