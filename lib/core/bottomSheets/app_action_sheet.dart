import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/bottomSheets/app_sheet.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/haptic_helper.dart';
import 'package:hamrash_admin/core/widgets/app_badge.dart';
import 'package:hamrash_admin/core/widgets/button/bouncy_button.dart';

/// A big square shortcut at the top of an [AppActionSheet].
class AppSheetTile {
  const AppSheetTile({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;

  /// Runs after the sheet closes.
  final VoidCallback onTap;
}

/// One row in an [AppActionSheet] group.
class AppSheetAction {
  const AppSheetAction({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isDestructive = false,
  });

  final String label;
  final IconData icon;

  /// Runs after the sheet closes, so it can open another sheet or page.
  final VoidCallback onTap;

  /// Red text and icon. A group made only of destructive actions also gets
  /// a pale red background — keep those in their own group, last.
  final bool isDestructive;
}

/// Floating menu of things you can do to one item: optional quick [tiles]
/// across the top, then rows in rounded [groups].
///
/// ```dart
/// AppActionSheet.show(
///   context,
///   title: student.name,
///   subtitle: '${student.className} · ${student.admissionNo}',
///   leading: AppLeadingPicture(leading: AppListLeading.initials(student.name), size: 44),
///   tiles: [
///     AppSheetTile(label: 'Call parent', icon: LucideIcons.phone, onTap: callParent),
///     AppSheetTile(label: 'Message', icon: LucideIcons.messageCircle, onTap: message),
///     AppSheetTile(label: 'Record fee', icon: LucideIcons.wallet, onTap: recordFee),
///   ],
///   groups: [
///     [
///       AppSheetAction(label: 'Edit details', icon: LucideIcons.pencil, onTap: edit),
///       AppSheetAction(label: 'Move to another class', icon: LucideIcons.arrowRightLeft, onTap: move),
///     ],
///     [
///       AppSheetAction(label: 'Withdraw student', icon: LucideIcons.userMinus, isDestructive: true, onTap: withdraw),
///     ],
///   ],
/// );
/// ```
abstract final class AppActionSheet {
  AppActionSheet._();

  static Future<void> show(
    BuildContext context, {
    required List<List<AppSheetAction>> groups,
    String? title,
    String? subtitle,
    Widget? leading,
    List<AppSheetTile> tiles = const [],
  }) {
    return AppSheet.show<void>(
      context: context,
      size: AppSheetSize.floating,
      title: title,
      subtitle: subtitle,
      leading: leading,
      bodyPadding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      body: Builder(
        builder: (context) {
          // Close first, then act, so the action can open its own sheet.
          void closeThen(VoidCallback action) {
            Navigator.of(context).pop();
            action();
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (tiles.isNotEmpty)
                Row(
                  children: [
                    for (var i = 0; i < tiles.length; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      Expanded(
                        child: _Tile(
                          tile: tiles[i],
                          onTap: () => closeThen(tiles[i].onTap),
                        ),
                      ),
                    ],
                  ],
                ),
              for (final group in groups)
                if (group.isNotEmpty) ...[
                  if (tiles.isNotEmpty || group != groups.first)
                    const SizedBox(height: 12),
                  _Group(actions: group, onTap: closeThen),
                ],
            ],
          );
        },
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.tile, required this.onTap});

  final AppSheetTile tile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tile.label,
      excludeSemantics: true,
      child: BouncyButton(
        onPressed: onTap,
        child: Container(
          height: 76,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: AppPalette.slate50,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                tile.icon,
                size: 22,
                color: LightColors.primaryPrimaryDefault,
              ),
              const SizedBox(height: 6),
              Text(
                tile.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.label.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: LightColors.textTextInverted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.actions, required this.onTap});

  final List<AppSheetAction> actions;
  final void Function(VoidCallback action) onTap;

  @override
  Widget build(BuildContext context) {
    final danger = actions.every((a) => a.isDestructive);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: ColoredBox(
        color: danger ? AppBadgeTone.error.mute : AppPalette.slate50,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < actions.length; i++) ...[
              if (i > 0)
                Container(
                  height: 1,
                  // Line up with the label, past the icon.
                  margin: const EdgeInsets.only(left: 50, right: 16),
                  color: danger ? AppBadgeTone.error.thin : AppPalette.slate200,
                ),
              _ActionRow(
                action: actions[i],
                inDangerGroup: danger,
                onTap: () => onTap(actions[i].onTap),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActionRow extends StatefulWidget {
  const _ActionRow({
    required this.action,
    required this.inDangerGroup,
    required this.onTap,
  });

  final AppSheetAction action;
  final bool inDangerGroup;
  final VoidCallback onTap;

  @override
  State<_ActionRow> createState() => _ActionRowState();
}

class _ActionRowState extends State<_ActionRow> {
  bool _pressed = false;

  void _setPressed(bool value) => setState(() => _pressed = value);

  @override
  Widget build(BuildContext context) {
    final action = widget.action;
    final color = action.isDestructive
        ? AppBadgeTone.error.strong
        : LightColors.textTextInverted;

    return Semantics(
      button: true,
      label: action.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: () {
          HapticHelpers.vibrate(VibrationType.light);
          widget.onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          color: _pressed
              ? (widget.inDangerGroup
                    ? AppBadgeTone.error.thin.withValues(alpha: 0.5)
                    : AppPalette.slate100)
              : Colors.transparent,
          child: Row(
            children: [
              Icon(
                action.icon,
                size: 20,
                color: action.isDestructive ? color : AppPalette.slate600,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  action.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body.copyWith(
                    fontSize: 15,
                    fontWeight: action.isDestructive
                        ? FontWeight.w700
                        : FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
