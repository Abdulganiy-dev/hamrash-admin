import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/haptic_helper.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/constants/radius_containers.dart';
import 'package:hamrash_admin/core/widgets/app_icons.dart';

/// What a badge means. Colour follows meaning, never decoration.
enum AppBadgeTone {
  /// Done, paid, on track.
  success,

  /// Needs attention soon.
  warning,

  /// Missed, failed, blocked.
  error,

  /// Noted, in progress. Uses the aubergine.
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
    neutral => AppPalette.stone100,
    accent => LightColors.extraExtraMute,
  };

  /// Border of subtle badges.
  Color get thin => switch (this) {
    success => LightColors.successSuccessThin,
    warning => LightColors.warningWarningThin,
    error => LightColors.errorErrorThin,
    info => LightColors.primaryPrimaryThin,
    neutral => AppPalette.stone200,
    accent => LightColors.extraExtraThin,
  };

  /// Dot colour.
  Color get base => switch (this) {
    success => LightColors.successSuccessDefault,
    warning => LightColors.warningWarningDefault,
    error => LightColors.errorErrorDefault,
    info => LightColors.primaryPrimaryDefault,
    neutral => AppPalette.stone400,
    accent => LightColors.extraExtraDefault,
  };

  /// Text on subtle badges, and the fill of solid ones.
  Color get strong => switch (this) {
    success => LightColors.successSuccessText,
    warning => LightColors.warningWarningText,
    error => LightColors.errorErrorText,
    info => LightColors.primaryPrimaryText,
    neutral => AppPalette.stone600,
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
    this.showBorder = true,
    this.labelStyle,
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

  /// Off for the flat pill used on the staff list, which has a fill only.
  final bool showBorder;

  /// Overrides the label style. Its colour is always [tone]'s foreground.
  final TextStyle? labelStyle;

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
          AppText(
            label,
            style: AppTypography.body.copyWith(
              fontWeight: FontWeight.w600,
              color: AppPalette.stone700,
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
        border: showBorder
            ? Border.all(color: solid ? tone.strong : tone.thin)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            AppIcon(icon, size: 12, color: foreground),
            const SizedBox(width: 4),
          ],
          AppText(
            label,
            style: (labelStyle ?? AppTypography.label).copyWith(
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tappable chip for filtering or picking options. A 40 tall pill with
/// 999px corners — never a status badge — inside a 48 tall tap area.
///
/// ```dart
/// AppFilterChip(label: 'JSS 2', selected: isJss2, onTap: () => toggle('JSS 2'))
/// AppFilterChip(label: 'Absent', count: 3, onTap: _showAbsent)
/// AppFilterChip(label: 'Term 2', selected: true, onRemove: _clearTerm)
/// AppFilterChip(label: 'Gold', suggestion: true, onTap: _addGold)
/// AppFilterChip(label: 'Primary 1A', selected: true, locked: true, onTap: _whyLocked)
/// ```
class AppFilterChip extends StatefulWidget {
  const AppFilterChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.onRemove,
    this.count,
    this.enabled = true,
    this.locked = false,
    this.suggestion = false,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  /// Shows a trailing × that calls this (for applied filters).
  final VoidCallback? onRemove;

  /// Count shown inline after the label as " · 3".
  final int? count;

  final bool enabled;

  /// In use elsewhere: shows a trailing lock instead of the ×.
  final bool locked;

  /// A name that can be added: shows a leading +.
  final bool suggestion;

  @override
  State<AppFilterChip> createState() => _AppFilterChipState();
}

class _AppFilterChipState extends State<AppFilterChip> {
  bool _pressed = false;

  bool get _interactive =>
      widget.enabled && (widget.onTap != null || widget.onRemove != null);

  void _pressDown(TapDownDetails _) {
    if (_interactive && !_pressed) setState(() => _pressed = true);
  }

  void _pressUp([TapUpDetails? _]) {
    if (_pressed) setState(() => _pressed = false);
  }

  void _tap() {
    if (!widget.enabled) return;
    HapticHelpers.vibrate(VibrationType.light);
    (widget.onTap ?? widget.onRemove)?.call();
  }

  void _remove() {
    if (!widget.enabled) return;
    HapticHelpers.vibrate(VibrationType.light);
    widget.onRemove?.call();
  }

  @override
  Widget build(BuildContext context) {
    final pressed = _pressed && _interactive;

    final Color fill;
    final Color border;
    final Color labelColor;
    final Color countColor;
    if (!widget.enabled) {
      fill = AppPalette.stone100;
      border = AppPalette.stone200;
      labelColor = LightColors.textDisabled;
      countColor = LightColors.textDisabled;
    } else if (widget.selected) {
      // Light aubergine tint. Selection reads from the fill, the aubergine
      // border and the aubergine label. Flat fill, no check mark.
      fill = pressed ? AppPalette.aubergine100 : LightColors.primaryPrimaryMute;
      border = LightColors.primaryPrimaryDefault;
      labelColor = LightColors.primaryPrimaryText;
      countColor = AppPalette.aubergine400;
    } else {
      fill = pressed ? AppPalette.stone100 : AppPalette.white;
      border = LightColors.textMuted;
      labelColor = LightColors.textStrong;
      countColor = LightColors.textBody;
    }

    // Selected chips never get a leading icon, so they keep the 16 side
    // padding. Only a suggestion leads with a +.
    final leading = widget.suggestion ? AppIcons.plus : null;
    final trailing = widget.locked
        ? AppIcons.lock
        : (widget.onRemove != null ? AppIcons.x : null);

    final textStyle = AppTypography.body.copyWith(
      fontSize: 14,
      height: 20 / 14,
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
    );

    final label = Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: widget.label,
            style: textStyle.copyWith(color: labelColor),
          ),
          if (widget.count case final count?)
            TextSpan(
              text: ' · $count',
              style: textStyle.copyWith(color: countColor),
            ),
        ],
      ),
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.ellipsis,
    );

    final Color? leadingColor = leading == null
        ? null
        : (leading == AppIcons.plus && !widget.selected
              ? LightColors.textBody
              : labelColor);

    final chip = Container(
      height: 40,
      constraints: const BoxConstraints(minWidth: 48),
      padding: EdgeInsets.only(
        left: leading == null ? 16 : 12,
        right: trailing == null ? 16 : 12,
      ),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: AppRadius.brPill,
        border: Border.all(color: border),
      ),
      child: Center(
        widthFactor: 1,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null) ...[
              AppIcon(leading, size: 14, color: leadingColor),
              const SizedBox(width: 6),
            ],
            label,
            if (trailing != null) ...[
              const SizedBox(width: 6),
              if (widget.onRemove != null && !widget.locked)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _remove,
                  child: AppIcon(trailing, size: 14, color: labelColor),
                )
              else
                AppIcon(trailing, size: 14, color: labelColor),
            ],
          ],
        ),
      ),
    );

    // 48 tall tap area around the 40 tall chip.
    return Semantics(
      button: _interactive,
      selected: widget.selected,
      enabled: widget.enabled,
      label: widget.count == null
          ? widget.label
          : '${widget.label}, ${widget.count}',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _pressDown,
        onTapUp: _pressUp,
        onTapCancel: _pressUp,
        onTap: _interactive ? _tap : null,
        child: SizedBox(height: 48, child: Center(widthFactor: 1, child: chip)),
      ),
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
    this.outlineColor = AppPalette.stone50,
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
        child: AppText(
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
        color: AppPalette.stone100,
        borderRadius: AppRadius.brBadge,
      ),
      child: AppText(
        text,
        style: AppTypography.caption.copyWith(
          fontWeight: FontWeight.w700,
          color: AppPalette.stone600,
        ),
      ),
    );
  }
}

/// 8px aubergine dot: something new, no number.
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
