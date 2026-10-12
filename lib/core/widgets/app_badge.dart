import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/constants/radius_containers.dart';
import 'package:hamrash_admin/core/widgets/button/bouncy_button.dart';

/// What a badge means. Colour follows meaning, never decoration.
enum AppBadgeTone {
  /// Done, paid, on track.
  success,

  /// Needs attention soon.
  warning,

  /// Missed, failed, blocked.
  error,

  /// Noted, in progress. Uses the brand blue.
  info,

  /// Not started, plain labels.
  neutral,

  /// New and highlights only.
  accent;

  /// Pale fill behind subtle badges.
  Color get mute => switch (this) {
    success => LightColors.successSuccessMute,
    warning => LightColors.warningWarningMute,
    error => LightColors.errorErrorMute,
    info => LightColors.primaryPrimaryMute,
    neutral => AppPalette.slate100,
    accent => LightColors.extraExtraMute,
  };

  /// Border of subtle badges.
  Color get thin => switch (this) {
    success => LightColors.successSuccessThin,
    warning => LightColors.warningWarningThin,
    error => LightColors.errorErrorThin,
    info => LightColors.primaryPrimaryThin,
    neutral => AppPalette.slate200,
    accent => LightColors.extraExtraThin,
  };

  /// Dot colour.
  Color get base => switch (this) {
    success => LightColors.successSuccessDefault,
    warning => LightColors.warningWarningDefault,
    error => LightColors.errorErrorDefault,
    info => LightColors.primaryPrimaryDefault,
    neutral => AppPalette.slate400,
    accent => LightColors.extraExtraDefault,
  };

  /// Text on subtle badges, and the fill of solid ones.
  Color get strong => switch (this) {
    success => LightColors.successSuccessText,
    warning => LightColors.warningWarningText,
    error => LightColors.errorErrorText,
    info => LightColors.primaryPrimaryText,
    neutral => AppPalette.slate600,
    accent => LightColors.extraExtraText,
  };
}

enum AppBadgeStyle {
  /// Pale fill, thin border, dark text. The default.
  subtle,

  /// Strong fill, white text. For the rare status that must stand out.
  solid,

  /// Coloured dot beside plain text. For dense tables.
  dot,
}

/// Anything that can be shown as a badge (see `school_status.dart`).
abstract interface class BadgeStatus {
  String get label;
  AppBadgeTone get tone;
}

/// Read-only status label. Not tappable — use [AppFilterChip] to filter.
///
/// ```dart
/// const AppBadge('Late', tone: AppBadgeTone.warning)
/// AppBadge.status(AttendanceStatus.absent)
/// ```
class AppBadge extends StatelessWidget {
  const AppBadge(
    this.label, {
    super.key,
    this.tone = AppBadgeTone.neutral,
    this.style = AppBadgeStyle.subtle,
    this.icon,
  });

  AppBadge.status(
    BadgeStatus status, {
    Key? key,
    AppBadgeStyle style = AppBadgeStyle.subtle,
    IconData? icon,
  }) : this(
         status.label,
         key: key,
         tone: status.tone,
         style: style,
         icon: icon,
       );

  final String label;
  final AppBadgeTone tone;
  final AppBadgeStyle style;

  /// Optional 12px leading icon (subtle and solid only).
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    if (style == AppBadgeStyle.dot) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: tone.base, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTypography.body.copyWith(
              fontWeight: FontWeight.w600,
              color: AppPalette.slate700,
            ),
          ),
        ],
      );
    }

    final solid = style == AppBadgeStyle.solid;
    final foreground = solid ? AppPalette.white : tone.strong;

    return Container(
      height: 24,
      padding: EdgeInsets.only(left: icon == null ? 10 : 8, right: 10),
      decoration: BoxDecoration(
        color: solid ? tone.strong : tone.mute,
        borderRadius: AppRadius.brBadge,
        border: Border.all(color: solid ? tone.strong : tone.thin),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: foreground),
            const SizedBox(width: 4),
          ],
          Text(label, style: AppTypography.label.copyWith(color: foreground)),
        ],
      ),
    );
  }
}

/// Tappable chip for filtering or picking options. 36 tall with a 44 tap
/// area, 8px corners so it never looks like a status badge.
///
/// ```dart
/// AppFilterChip(label: 'JSS 2', selected: isJss2, onTap: () => toggle('JSS 2'))
/// AppFilterChip(label: 'Absent', count: 3, onTap: _showAbsent)
/// AppFilterChip(label: 'Term 2', selected: true, onRemove: _clearTerm)
/// ```
class AppFilterChip extends StatelessWidget {
  const AppFilterChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.onRemove,
    this.count,
    this.enabled = true,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  /// Shows a trailing × that calls this (for applied filters).
  final VoidCallback? onRemove;

  /// Optional count pill after the label.
  final int? count;

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final Color fill;
    final Color border;
    final Color text;
    if (!enabled) {
      fill = AppPalette.slate100;
      border = AppPalette.slate200;
      text = AppPalette.slate400;
    } else if (selected) {
      fill = LightColors.primaryPrimaryMute;
      border = LightColors.primaryPrimaryThin;
      text = LightColors.primaryPrimaryText;
    } else {
      fill = AppPalette.white;
      border = AppPalette.slate200;
      text = AppPalette.slate700;
    }

    final showCheck = selected && onRemove == null && enabled;
    final chip = Container(
      height: 36,
      padding: EdgeInsets.only(
        left: showCheck ? 10 : 14,
        right: onRemove != null
            ? 8
            : (count != null ? 6 : (showCheck ? 12 : 14)),
      ),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: AppRadius.brChip,
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showCheck) ...[
            Icon(Icons.check_rounded, size: 16, color: text),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: AppTypography.body.copyWith(
              fontWeight: FontWeight.w600,
              color: text,
            ),
          ),
          if (count != null) ...[
            const SizedBox(width: 8),
            AppCountBadge(count: count!),
          ],
          if (onRemove != null) ...[
            const SizedBox(width: 6),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: enabled ? onRemove : null,
              child: Icon(Icons.close_rounded, size: 18, color: text),
            ),
          ],
        ],
      ),
    );

    // 44 tall tap area around the 36 tall chip.
    return BouncyButton(
      onPressed: enabled ? (onTap ?? onRemove) : null,
      isDisabled: !enabled,
      child: SizedBox(height: 44, child: Center(widthFactor: 1, child: chip)),
    );
  }
}

enum AppCountTone {
  /// Red, on icons: things that need action.
  alert,

  /// Grey, on tabs, filters and section totals.
  neutral,
}

/// Small number badge. Shows 99+ above 99.
class AppCountBadge extends StatelessWidget {
  const AppCountBadge({
    super.key,
    required this.count,
    this.tone = AppCountTone.neutral,
    this.outlineColor = AppPalette.slate50,
  });

  final int count;
  final AppCountTone tone;

  /// Ring around alert counts so they stand off the icon they sit on.
  /// Match it to whatever is behind the badge.
  final Color outlineColor;

  @override
  Widget build(BuildContext context) {
    final text = count > 99 ? '99+' : '$count';

    if (tone == AppCountTone.alert) {
      return Container(
        constraints: const BoxConstraints(minWidth: 20),
        height: 20,
        padding: const EdgeInsets.symmetric(horizontal: 5),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: LightColors.errorErrorDefault,
          borderRadius: AppRadius.brBadge,
          border: Border.all(color: outlineColor, width: 2),
        ),
        child: Text(
          text,
          style: AppTypography.overline.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
            height: 12 / 11,
            color: AppPalette.white,
          ),
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(minWidth: 22),
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 7),
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppPalette.slate100,
        borderRadius: AppRadius.brBadge,
      ),
      child: Text(
        text,
        style: AppTypography.caption.copyWith(
          fontWeight: FontWeight.w700,
          color: AppPalette.slate600,
        ),
      ),
    );
  }
}

/// 8px blue dot: something new, no number.
class AppUnreadDot extends StatelessWidget {
  const AppUnreadDot({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: LightColors.primaryPrimaryDefault,
        shape: BoxShape.circle,
      ),
    );
  }
}
