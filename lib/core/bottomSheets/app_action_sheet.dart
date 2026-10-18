import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/bottomSheets/app_sheet.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/widgets/app_badge.dart';
import 'package:hamrash_admin/core/widgets/button/bouncy_button.dart';
import 'package:hamrash_admin/core/widgets/app_svg_icon.dart';

/// A big square shortcut at the top of an [AppActionSheet].
class AppSheetTile {
  const AppSheetTile({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final AppSvgIconData icon;

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
    this.disabledReason,
  });

  final String label;
  final AppSvgIconData icon;

  /// Runs after the sheet closes, so it can open another sheet or page.
  final VoidCallback onTap;

  /// Red text and icon. A group made only of destructive actions also gets
  /// a pale red background — keep those in their own group, last.
  final bool isDestructive;

  /// Greys the row out and shows this under the label, e.g. why something
  /// can't be removed yet. The row can't be tapped.
  final String? disabledReason;
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
///     AppSheetTile(label: 'Record fee', icon: AppSvgIcons.wallet, onTap: recordFee),
///   ],
///   groups: [
///     [
///       AppSheetAction(label: 'Edit details', icon: AppSvgIcons.pencil, onTap: edit),
///     ],
///     [
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
            color: AppPalette.stone50,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppSvgIcon(
                tile.icon,
                size: 22,
                color: LightColors.primaryPrimaryDefault,
              ),
              const SizedBox(height: 6),
              AppText(
                tile.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.label.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: LightColors.textStrong,
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
    final danger = actions.every(
      (a) => a.isDestructive && a.disabledReason == null,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: ColoredBox(
        color: danger ? AppBadgeTone.error.mute : AppPalette.stone50,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < actions.length; i++) ...[
              if (i > 0)
                Container(
                  height: 1,
                  // Line up with the label, past the icon.
                  margin: const EdgeInsets.only(left: 50, right: 16),
                  color: danger ? AppBadgeTone.error.thin : AppPalette.stone200,
                ),
              _ActionRow(
                action: actions[i],
                onTap: () => onTap(actions[i].onTap),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.action, required this.onTap});

  final AppSheetAction action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final reason = action.disabledReason;
    final color = reason != null
        ? AppPalette.stone400
        : action.isDestructive
        ? AppBadgeTone.error.strong
        : LightColors.textStrong;
    final iconColor = reason != null || action.isDestructive
        ? color
        : AppPalette.stone600;

    return Semantics(
      button: true,
      enabled: reason == null,
      label: reason == null ? action.label : '${action.label}. $reason',
      excludeSemantics: true,
      // Shrinks a touch while pressed, like every other button; no tint.
      child: BouncyButton(
        onPressed: reason == null ? onTap : null,
        isDisabled: reason != null,
        pressedScale: 0.98,
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: reason == null ? 0 : 12,
          ),
          color: Colors.transparent,
          child: Row(
            crossAxisAlignment: reason == null
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start,
            children: [
              AppSvgIcon(action.icon, size: 20, color: iconColor),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppText(
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
                    if (reason != null) ...[
                      const SizedBox(height: 2),
                      AppText(
                        reason,
                        style: AppTypography.caption.copyWith(
                          fontSize: 13,
                          height: 18 / 13,
                          color: AppPalette.stone500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
