import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/haptic_helper.dart';
import 'package:hamrash_admin/core/utils/view_util.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/button/bouncy_button.dart';
import 'package:motor/motor.dart';
import 'package:hamrash_admin/core/widgets/app_svg_icon.dart';

/// What a toast is about. Picks its icon and colour.
enum AppToastType {
  success(AppSvgIcons.circleCheck500, Color(0xFF22C55E)),
  error(AppSvgIcons.circleX500, Color(0xFFF87171)),
  warning(AppSvgIcons.triangleAlert500, Color(0xFFFBBF24)),

  /// Neutral note, e.g. "You're offline". Pass your own `icon`.
  info(AppSvgIcons.info, AppPalette.stone300);

  const AppToastType(this.icon, this.color);

  final AppSvgIconData icon;

  /// Bright tones that read on the dark espresso toast.
  final Color color;
}

/// Short note that confirms something just happened, without stopping work:
/// a dark pill that drops in from the top, under the status bar. It blurs and
/// fades in on a spring, and leaves on its own.
///
/// - One at a time: a new toast replaces the one showing. Showing the same
///   toast again while it is still up shakes it and restarts its timer.
/// - 4 seconds, or 6 when it has an action. Swipe up to dismiss early.
/// - Not for decisions — if someone must read or act, use [AppResultSheet].
///
/// Works without a [BuildContext] (it uses the app's root navigator), so
/// view models can call it after an async gap.
///
/// ```dart
/// AppToast.show(
///   'Attendance saved for JSS 2 Gold',
///   type: AppToastType.success,
///   actionLabel: 'Undo',
///   onAction: model.undoAttendance,
/// );
/// AppToast.show('You’re offline. Changes will sync later.', icon: AppSvgIcons.wifiOff);
/// ```
abstract final class AppToast {
  AppToast._();

  static OverlayEntry? _entry;
  static GlobalKey<_ToastHostState>? _hostKey;

  /// What the showing toast says, to spot a repeat of it.
  static String? _signature;

  static void show(
    String message, {
    AppToastType type = AppToastType.info,
    AppSvgIconData? icon,
    String? actionLabel,
    VoidCallback? onAction,
    Duration? duration,
    BuildContext? context,
  }) {
    final overlay =
        (context == null
            ? null
            : Overlay.maybeOf(context, rootOverlay: true)) ??
        ViewUtil.navigatorKey.currentState?.overlay;
    if (overlay == null || message.trim().isEmpty) return;

    // The same toast again while it's up: shake it rather than replace it.
    final signature = '${type.name}|${icon?.assetPath}|$message|$actionLabel';
    if (signature == _signature && (_hostKey?.currentState?.shake() ?? false)) {
      return;
    }

    // One at a time.
    _removeCurrent();

    final hostKey = GlobalKey<_ToastHostState>();
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _ToastHost(
        key: hostKey,
        message: message,
        type: type,
        icon: icon ?? type.icon,
        actionLabel: actionLabel,
        onAction: onAction,
        duration:
            duration ??
            (actionLabel == null
                ? const Duration(seconds: 4)
                : const Duration(seconds: 6)),
        onGone: () {
          if (_entry == entry) {
            _entry = null;
            _hostKey = null;
            _signature = null;
          }
          if (entry.mounted) entry.remove();
        },
      ),
    );
    _entry = entry;
    _hostKey = hostKey;
    _signature = signature;
    overlay.insert(entry);
  }

  /// Removes the toast that is showing, straight away.
  static void hide() => _removeCurrent();

  static void _removeCurrent() {
    final current = _entry;
    _entry = null;
    _hostKey = null;
    _signature = null;
    if (current != null && current.mounted) current.remove();
  }
}

class _ToastHost extends StatefulWidget {
  const _ToastHost({
    super.key,
    required this.message,
    required this.type,
    required this.icon,
    required this.actionLabel,
    required this.onAction,
    required this.duration,
    required this.onGone,
  });

  final String message;
  final AppToastType type;
  final AppSvgIconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Duration duration;
  final VoidCallback onGone;

  @override
  State<_ToastHost> createState() => _ToastHostState();
}

class _ToastHostState extends State<_ToastHost>
    with SingleTickerProviderStateMixin {
  /// 0 = hidden (blurred, faded, lower), 1 = showing.
  double _target = 0;
  bool _leaving = false;
  Timer? _stay;
  Timer? _leave;

  /// 0 → 1 over one shake.
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 480),
  );

  static const _enter = Motion.bouncySpring();
  static const _exit = Motion.snappySpring();

  @override
  void initState() {
    super.initState();
    // Start hidden, then spring in on the next frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _target = 1);
    });
    _stay = Timer(widget.duration, _dismiss);
  }

  @override
  void dispose() {
    _stay?.cancel();
    _leave?.cancel();
    _shake.dispose();
    super.dispose();
  }

  /// Shakes the toast side to side with a haptic nudge, and gives it its
  /// full time again.
  /// Returns false when it is already leaving, so a fresh one should show.
  bool shake() {
    if (_leaving || !mounted) return false;
    _stay?.cancel();
    _stay = Timer(widget.duration, _dismiss);
    _shake.forward(from: 0);
    // A firm nudge, felt as well as seen. Skipped if the user turned
    // haptics off.
    unawaited(HapticHelpers.vibrate(VibrationType.medium));
    return true;
  }

  void _dismiss() {
    if (_leaving || !mounted) return;
    _stay?.cancel();
    setState(() {
      _leaving = true;
      _target = 0;
    });
    _leave = Timer(const Duration(milliseconds: 320), widget.onGone);
  }

  @override
  Widget build(BuildContext context) {
    // Just under the status bar, over the app bar.
    final top = MediaQuery.viewPaddingOf(context).top + 8;

    return Positioned(
      left: AppSpacing.screen,
      right: AppSpacing.screen,
      top: top,
      child: SingleMotionBuilder(
        motion: _leaving ? _exit : _enter,
        value: _target,
        builder: (context, value, child) {
          final shown = value.clamp(0.0, 1.0);
          final blur = (1 - shown) * 12;
          return IgnorePointer(
            ignoring: _leaving,
            child: Opacity(
              opacity: shown,
              child: Transform.translate(
                // Drops in from above.
                offset: Offset(0, (1 - value) * -28),
                child: Transform.scale(
                  scale: 0.92 + 0.08 * value,
                  child: ImageFiltered(
                    enabled: blur > 0.05,
                    imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                    child: child,
                  ),
                ),
              ),
            ),
          );
        },
        child: AnimatedBuilder(
          animation: _shake,
          // Three quick swings that die away.
          builder: (context, child) {
            final t = _shake.value;
            final dx = math.sin(t * math.pi * 6) * 10 * (1 - t);
            return Transform.translate(offset: Offset(dx, 0), child: child);
          },
          child: Dismissible(
            key: const ValueKey('app-toast'),
            direction: DismissDirection.up,
            onDismissed: (_) => widget.onGone(),
            child: _ToastBody(
              message: widget.message,
              icon: widget.icon,
              iconColor: widget.type.color,
              actionLabel: widget.actionLabel,
              onAction: widget.onAction == null
                  ? null
                  : () {
                      _dismiss();
                      widget.onAction!();
                    },
            ),
          ),
        ),
      ),
    );
  }
}

class _ToastBody extends StatelessWidget {
  const _ToastBody({
    required this.message,
    required this.icon,
    required this.iconColor,
    required this.actionLabel,
    required this.onAction,
  });

  final String message;
  final AppSvgIconData icon;
  final Color iconColor;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final hasAction = actionLabel != null && onAction != null;

    return Material(
      type: MaterialType.transparency,
      child: Semantics(
        liveRegion: true,
        child: Container(
          padding: EdgeInsets.fromLTRB(14, 12, hasAction ? 6 : 14, 12),
          decoration: BoxDecoration(
            color: AppPalette.stone900,
            borderRadius: BorderRadius.circular(16),
            // Lifted well off the page so it reads over any content.
            boxShadow: const [
              BoxShadow(
                color: Color(0x1F2A1712),
                offset: Offset(0, 2),
                blurRadius: 4,
              ),
              BoxShadow(
                color: Color(0x382A1712),
                offset: Offset(0, 14),
                blurRadius: 16,
                spreadRadius: -4,
              ),
            ],
          ),
          child: Row(
            children: [
              AppSvgIcon(icon, size: 22, color: iconColor),
              const SizedBox(width: 12),
              Expanded(
                child: AppText(
                  message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppPalette.white,
                  ),
                ),
              ),
              if (hasAction)
                BouncyButton(
                  onPressed: onAction,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    child: AppText(
                      actionLabel!,
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppPalette.aubergine300,
                      ),
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
