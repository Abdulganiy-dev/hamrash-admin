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
          color: isLight
              ? LightColors.backgroundSurfacePrimaryBG
              : DarkColors.backgroundSurfaceLayer,
          border: isLight ? AppPalette.stone300 : AppPalette.stone700,
        );
      case AppButtonType.tertiary:
        return AppButtonFill(
          color: isLight
              ? LightColors.primaryPrimaryMute
              : DarkColors.primaryPrimaryMute,
          border: isLight
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
    final color = isLight
        ? LightColors.backgroundSurfaceMild
        : DarkColors.backgroundSurfaceMild;
    return AppButtonFill(color: color, border: color);
  }

  /// A caller-supplied solid color.
  static AppButtonFill flat(Color color) {
    return AppButtonFill(color: color, border: Colors.transparent);
  }
}

/// Paints a simple solid button surface behind [child].
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

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
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
  }
}
