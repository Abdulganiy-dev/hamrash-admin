import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/radius_containers.dart';

/// Shared look for text inputs ([AppTextField], [AppSearchField]): a soft
/// fill and hairline border at rest, white with a blue border when focused,
/// white with a red border on error. No rings or shadows.
class AppFieldStyle {
  AppFieldStyle._();

  static const double height = 48;
  static const double iconSize = 20;
  static const EdgeInsets contentPadding = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 12,
  );

  static Color fill(
    BuildContext context, {
    required bool enabled,
    required bool active,
  }) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    if (!enabled) {
      return isLight ? AppPalette.slate100 : DarkColors.backgroundSurfaceMute;
    }
    if (active) {
      return isLight ? AppPalette.white : DarkColors.backgroundSurfaceLayer;
    }
    return isLight ? AppPalette.slate50 : DarkColors.backgroundSurfaceLayer;
  }

  static Color restBorder(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light
      ? AppPalette.slate200
      : AppPalette.slate700;

  static Color focusBorder(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light
      ? LightColors.primaryPrimaryDefault
      : DarkColors.strokeColourStrokePrimary;

  static Color errorBorder(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light
      ? LightColors.errorErrorDefault
      : DarkColors.errorErrorDefault;

  static Color text(BuildContext context, {required bool enabled}) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    if (!enabled) {
      return isLight
          ? LightColors.textTextDisabled
          : DarkColors.textTextDisabled;
    }
    return isLight ? LightColors.textTextInverted : DarkColors.textTextInverted;
  }

  static Color placeholder(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light
      ? AppPalette.slate400
      : AppPalette.slate500;

  static Color icon(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light
      ? AppPalette.slate500
      : AppPalette.slate400;

  static OutlineInputBorder border(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: AppRadius.brControl,
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
