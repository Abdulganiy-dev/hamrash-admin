import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_types.dart';

/// Fill and border colors for a button variant.
@immutable
class AppButtonFill {
  const AppButtonFill({
    required this.color,
    required this.border,
    this.gradient,
  });

  final Color color;
  final Color border;
  final LinearGradient? gradient;

  /// Adds the older subtle highlight-to-rim treatment for sheets and alerts.
  AppButtonFill withGradient() {
    if (color == Colors.transparent) return this;
    return AppButtonFill(
      color: color,
      border: border,
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color.lerp(color, Colors.white, 0.08)!,
          color,
          Color.lerp(color, Colors.black, 0.10)!,
        ],
        stops: const [0, 0.45, 1],
      ),
    );
  }

  /// Default fill for a button type. Unfilled types stay transparent.
  static AppButtonFill forType(AppButtonType type, {required bool isLight}) {
    switch (type) {
      case AppButtonType.primary:
        return AppButtonFill(
          color: LightColors.primaryPrimaryDefault,
          border: LightColors.primaryPrimaryHover,
        );
      case AppButtonType.destructive:
        return AppButtonFill(
          color: LightColors.errorErrorDefault,
          border: LightColors.errorErrorText,
        );
      case AppButtonType.secondary:
        return AppButtonFill(
          color:
              isLight
                  ? LightColors.backgroundSurfacePrimaryBG
                  : DarkColors.backgroundSurfaceLayer,
          border: isLight ? AppPalette.stone300 : AppPalette.stone700,
        );
      case AppButtonType.tertiary:
        return AppButtonFill(
          color:
              isLight
                  ? LightColors.primaryPrimaryMute
                  : DarkColors.primaryPrimaryMute,
          border:
              isLight
                  ? LightColors.primaryPrimaryThin
                  : DarkColors.primaryPrimaryThin,
        );
      case AppButtonType.outline:
      case AppButtonType.text:
      case AppButtonType.icon:
        return const AppButtonFill(
          color: Colors.transparent,
          border: Colors.transparent,
        );
    }
  }

  /// Flat, shadowless fill for disabled buttons.
  static AppButtonFill disabled({required bool isLight}) {
    final color =
        isLight
            ? LightColors.backgroundSurfaceMild
            : DarkColors.backgroundSurfaceMild;
    return AppButtonFill(color: color, border: color);
  }

  /// A caller-supplied solid color.
  static AppButtonFill flat(Color color) {
    return AppButtonFill(color: color, border: Colors.transparent);
  }

  /// Blends two fills for a seamless change between button looks.
  ///
  /// A transparent fill fades to or from the *other* fill's colour (at zero
  /// alpha), never through transparent black, which would show a dark fringe
  /// mid-transition. A fill with a gradient blends with a flat one by treating
  /// the flat colour as a gradient of one colour.
  static AppButtonFill lerp(AppButtonFill a, AppButtonFill b, double t) {
    if (t <= 0) return a;
    if (t >= 1) return b;
    final aGradient = a.gradient ?? _flatGradient(a.color);
    final bGradient = b.gradient ?? _flatGradient(b.color);
    final hasGradient = a.gradient != null || b.gradient != null;
    return AppButtonFill(
      color: _lerpColor(a.color, b.color, t),
      border: _lerpColor(a.border, b.border, t),
      gradient:
          hasGradient ? LinearGradient.lerp(aGradient, bGradient, t) : null,
    );
  }

  static LinearGradient _flatGradient(Color color) {
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [color, color, color],
      stops: const [0, 0.45, 1],
    );
  }

  static Color _lerpColor(Color a, Color b, double t) {
    if (a.a == 0 && b.a != 0) a = b.withValues(alpha: 0);
    if (b.a == 0 && a.a != 0) b = a.withValues(alpha: 0);
    return Color.lerp(a, b, t)!;
  }
}

class _FillTween extends Tween<AppButtonFill> {
  _FillTween({super.end});

  @override
  AppButtonFill lerp(double t) => AppButtonFill.lerp(begin!, end!, t);
}

/// Paints a simple solid button surface behind [child]. When [fill] changes it
/// blends from the old look to the new one, so primary, secondary, outline
/// and disabled states swap without a pop.
class AppButtonSurface extends StatelessWidget {
  const AppButtonSurface({
    super.key,
    required this.fill,
    required this.borderRadius,
    required this.height,
    required this.padding,
    required this.child,
    this.width,
  });

  final AppButtonFill fill;
  final BorderRadius borderRadius;
  final double height;
  final EdgeInsetsGeometry padding;
  final Widget child;
  final double? width;

  static const Duration duration = Duration(milliseconds: 160);

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<AppButtonFill>(
      tween: _FillTween(end: fill),
      duration: duration,
      curve: Curves.easeOut,
      builder: (context, fill, child) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: fill.gradient == null ? fill.color : null,
            gradient: fill.gradient,
            borderRadius: borderRadius,
            border: Border.all(color: fill.border),
          ),
          child: Padding(padding: padding, child: child),
        );
      },
      child: child,
    );
  }
}
