import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/constants/radius_containers.dart';
import 'package:hamrash_admin/core/widgets/app_cards.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_variants.dart';
import 'package:hamrash_admin/core/widgets/button/bouncy_button.dart';
import 'package:hamrash_admin/core/widgets/app_icons.dart';

/// Centred message for a screen or list with nothing to show: a plain icon
/// (no background), a title, one line of explanation and one clear next step.
///
/// Say what's missing, not "No data". Use [compact] for small spaces such as
/// "no search results" inside a list or sheet.
///
/// ```dart
/// AppEmptyState(
///   icon: AppIcons.users,
///   title: 'No students in JSS 2 Gold yet',
///   subtitle: 'Add them one by one, or import the class list from a spreadsheet.',
///   actionLabel: 'Add student',
///   onAction: addStudent,
///   secondaryLabel: 'Import class list',
///   onSecondary: importList,
/// )
///
/// AppEmptyState(
///   compact: true,
///   icon: AppIcons.search,
///   title: 'No matches for “$query”',
///   subtitle: 'Check the spelling, or search by admission number.',
///   actionLabel: 'Clear search',
///   onAction: clearSearch,
/// )
/// ```
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.iconColor,
    this.iconTileColor,
    this.actionLabel,
    this.onAction,
    this.secondaryLabel,
    this.onSecondary,
    this.action,
    this.compact = false,
    this.topPadding = AppSpacing.xxl,
  });

  /// Shown on its own, no tile or circle behind it. Large sizes suit these
  /// glyphs; Lucide keeps the same stroke at every size.
  final IconData icon;

  /// What's missing or what failed, e.g. "No payments today".
  final String title;

  /// The likely reason or what to do, in plain words.
  final String? subtitle;

  /// Defaults to aubergine, or stone-400 when [compact].
  final Color? iconColor;

  /// Puts the icon on a 72px rounded tile of this colour and steps the title
  /// up to [AppTypography.h2] (8.2's "No staff yet"). Leave null for the
  /// plain icon every other screen uses.
  final Color? iconTileColor;

  /// The one next step. A filled button, or a text link when [compact].
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Optional real alternative, shown as a text link under the button.
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  /// Any custom widget in place of [actionLabel]'s button.
  final Widget? action;

  /// Smaller icon and type, text-link action.
  final bool compact;

  /// Space above the state.
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    final hasAction = actionLabel != null && onAction != null;
    final hasSecondary = secondaryLabel != null && onSecondary != null;
    final tiled = iconTileColor != null;

    final iconColor =
        this.iconColor ??
        (compact ? AppPalette.stone400 : LightColors.primaryPrimaryDefault);
    final iconWidget = tiled
        ? Container(
            width: 72,
            height: 72,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: iconTileColor,
              borderRadius: BorderRadius.circular(AppRadius.dialog),
            ),
            child: AppIcon(icon, size: 32, color: iconColor),
          )
        : AppIcon(icon, size: compact ? 36 : 56, color: iconColor);

    return Padding(
      padding: EdgeInsets.only(top: topPadding),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              iconWidget,
              SizedBox(height: tiled ? AppSpacing.ms : (compact ? 12 : 20)),
              AppText(
                title,
                textAlign: TextAlign.center,
                colorType: AppTextColor.textStrong,
                style: tiled
                    ? AppTypography.h2
                    : compact
                    ? AppTypography.title.copyWith(fontWeight: FontWeight.w800)
                    : AppTypography.h3,
              ),
              if (subtitle != null) ...[
                SizedBox(height: tiled ? AppSpacing.ms : (compact ? 2 : 6)),
                AppText(
                  subtitle!,
                  textAlign: TextAlign.center,
                  colorType: AppTextColor.textBody,
                  style: tiled
                      ? AppTypography.body
                      : compact
                      ? AppTypography.body
                      : AppTypography.body.copyWith(
                          fontSize: 15,
                          height: 22 / 15,
                        ),
                ),
              ],
              if (action != null) ...[
                SizedBox(height: compact ? 12 : 20),
                _Hug(child: action!),
              ] else if (hasAction) ...[
                SizedBox(height: compact ? 8 : 20),
                compact
                    ? _TextLink(label: actionLabel!, onTap: onAction!)
                    : _Hug(
                        child: AppPrimaryButton(
                          onPressed: onAction,
                          child: AppText(actionLabel!),
                        ),
                      ),
              ],
              if (hasSecondary) ...[
                const SizedBox(height: AppSpacing.xs),
                _TextLink(label: secondaryLabel!, onTap: onSecondary!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A missing or failed piece inside a card, so the rest of the page keeps
/// working: a plain icon, a title, a short line and an optional action on
/// the right. It draws its own card.
///
/// ```dart
/// AppInlineState(
///   icon: AppIcons.wallet,
///   title: 'No payments today',
///   message: 'Payments you record show up here.',
///   actionLabel: 'Record',
///   onAction: recordPayment,
/// )
/// AppInlineState.error(title: 'Couldn’t load fee summary', onRetry: model.retry)
/// ```
class AppInlineState extends StatelessWidget {
  const AppInlineState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.iconColor = AppPalette.stone500,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
  });

  /// Red alert icon with a "Retry" action.
  const AppInlineState.error({
    super.key,
    required this.title,
    this.message = 'The rest of the page still works.',
    VoidCallback? onRetry,
  }) : icon = AppIcons.circleAlert,
       iconColor = LightColors.errorErrorDefault,
       actionLabel = 'Retry',
       actionIcon = AppIcons.refreshCw,
       onAction = onRetry;

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? message;
  final String? actionLabel;

  /// Small icon before [actionLabel], e.g. a refresh arrow.
  final IconData? actionIcon;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          AppIcon(icon, size: 24, color: iconColor),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AppText(
                  title,
                  variant: AppTextVariant.subtitle,
                  colorType: AppTextColor.textStrong,
                ),
                if (message != null)
                  AppText(
                    message!,
                    colorType: AppTextColor.textBody,
                    style: AppTypography.caption.copyWith(
                      fontSize: 13,
                      height: 18 / 13,
                    ),
                  ),
              ],
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(width: 12),
            _TextLink(label: actionLabel!, icon: actionIcon, onTap: onAction!),
          ],
        ],
      ),
    );
  }
}

/// Lets a button size itself to its label. Filled buttons stretch to any
/// bounded width, and a row hands them an unbounded one.
class _Hug extends StatelessWidget {
  const _Hug({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      Row(mainAxisSize: MainAxisSize.min, children: [child]);
}

/// Aubergine text action that shrinks a touch when pressed.
class _TextLink extends StatelessWidget {
  const _TextLink({required this.label, required this.onTap, this.icon});

  final String label;
  final IconData? icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return BouncyButton(
      onPressed: onTap,
      child: Padding(
        // A 44px tap box, centred on the label. A button above it sits 4
        // away, so the label reads 16 from that button.
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.ms,
          horizontal: AppSpacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              AppIcon(
                icon,
                size: 16,
                color: LightColors.primaryPrimaryDefault,
              ),
              const SizedBox(width: 6),
            ],
            AppText(
              label,
              colorType: AppTextColor.primary,
              style: AppTypography.subtitle,
            ),
          ],
        ),
      ),
    );
  }
}
