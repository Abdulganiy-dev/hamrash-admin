import 'package:flutter/material.dart';
import 'package:hamrash_admin/widgets/button/app_button.dart';
import 'package:hamrash_admin/widgets/button/app_button_types.dart';

/// Primary call-to-action — solid brand fill; use [child] for label (e.g. bold white [Text]).
class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    super.key,
    required this.child,
    this.onPressed,
    this.isDisabled = false,
    this.isLoading = false,
    this.width,
    this.height,
    this.padding,
    this.enableHaptic = true,
    this.haveGradient = false,
    this.gradient,
    this.loadingIndicatorSize,
    this.loadingIndicatorColor,
    this.textStyle,
    this.backgroundColor,
    this.backgroundColorType,
    this.foregroundColor,
    this.foregroundColorType,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final bool isDisabled;
  final bool isLoading;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final bool enableHaptic;
  final bool haveGradient;
  final LinearGradient? gradient;
  final double? loadingIndicatorSize;
  final Color? loadingIndicatorColor;
  final TextStyle? textStyle;
  final Color? backgroundColor;
  final AppButtonBackgroundColor? backgroundColorType;
  final Color? foregroundColor;
  final AppButtonForegroundColor? foregroundColorType;

  @override
  Widget build(BuildContext context) {
    return AppButton(
      type: AppButtonType.primary,
      text: '',
      onPressed: onPressed,
      isDisabled: isDisabled,
      isLoading: isLoading,
      width: width,
      height: height ?? 52,
      padding: padding,
      enableHaptic: enableHaptic,
      haveGradient: haveGradient,
      gradient: gradient,
      loadingIndicatorSize: loadingIndicatorSize,
      loadingIndicatorColor: loadingIndicatorColor,
      textStyle: textStyle,
      backgroundColor: backgroundColor,
      backgroundColorType: backgroundColorType,
      foregroundColor: foregroundColor,
      foregroundColorType: foregroundColorType,
      child: child,
    );
  }
}

/// Secondary action — light surface, subtle border; use [child] for icon + text rows (e.g. Google).
class AppSecondaryButton extends StatelessWidget {
  const AppSecondaryButton({
    super.key,
    required this.child,
    this.onPressed,
    this.isDisabled = false,
    this.isLoading = false,
    this.width,
    this.height,
    this.padding,
    this.enableHaptic = true,
    this.loadingIndicatorSize,
    this.loadingIndicatorColor,
    this.textStyle,
    this.backgroundColor,
    this.backgroundColorType,
    this.foregroundColor,
    this.foregroundColorType,
    this.borderColor,
    this.borderColorType,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final bool isDisabled;
  final bool isLoading;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final bool enableHaptic;
  final double? loadingIndicatorSize;
  final Color? loadingIndicatorColor;
  final TextStyle? textStyle;
  final Color? backgroundColor;
  final AppButtonBackgroundColor? backgroundColorType;
  final Color? foregroundColor;
  final AppButtonForegroundColor? foregroundColorType;
  final Color? borderColor;
  final AppButtonBorderColor? borderColorType;

  @override
  Widget build(BuildContext context) {
    return AppButton(
      type: AppButtonType.secondary,
      text: '',
      onPressed: onPressed,
      isDisabled: isDisabled,
      isLoading: isLoading,
      width: width,
      height: height ?? 52,
      padding: padding,
      enableHaptic: enableHaptic,
      loadingIndicatorSize: loadingIndicatorSize,
      loadingIndicatorColor: loadingIndicatorColor,
      textStyle: textStyle,
      backgroundColor: backgroundColor,
      backgroundColorType: backgroundColorType,
      foregroundColor: foregroundColor,
      foregroundColorType: foregroundColorType,
      borderColor: borderColor,
      borderColorType: borderColorType,
      child: child,
    );
  }
}

/// Tertiary action — soft brand-tinted fill, brand text (e.g. “I already have an account”).
class AppTertiaryButton extends StatelessWidget {
  const AppTertiaryButton({
    super.key,
    required this.child,
    this.onPressed,
    this.isDisabled = false,
    this.isLoading = false,
    this.width,
    this.height,
    this.padding,
    this.enableHaptic = true,
    this.loadingIndicatorSize,
    this.loadingIndicatorColor,
    this.textStyle,
    this.backgroundColor,
    this.backgroundColorType,
    this.foregroundColor,
    this.foregroundColorType,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final bool isDisabled;
  final bool isLoading;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final bool enableHaptic;
  final double? loadingIndicatorSize;
  final Color? loadingIndicatorColor;
  final TextStyle? textStyle;
  final Color? backgroundColor;
  final AppButtonBackgroundColor? backgroundColorType;
  final Color? foregroundColor;
  final AppButtonForegroundColor? foregroundColorType;

  @override
  Widget build(BuildContext context) {
    return AppButton(
      type: AppButtonType.tertiary,
      text: '',
      onPressed: onPressed,
      isDisabled: isDisabled,
      isLoading: isLoading,
      width: width,
      height: height ?? 52,
      padding: padding,
      enableHaptic: enableHaptic,
      loadingIndicatorSize: loadingIndicatorSize,
      loadingIndicatorColor: loadingIndicatorColor,
      textStyle: textStyle,
      backgroundColor: backgroundColor,
      backgroundColorType: backgroundColorType,
      foregroundColor: foregroundColor,
      foregroundColorType: foregroundColorType,
      child: child,
    );
  }
}

/// Icon-only control with Hugeicons stroke glyph and the same press scale as [AppButton].
class AppHugeIconButton extends StatelessWidget {
  const AppHugeIconButton({
    super.key,
    required this.hugeIcon,
    this.onPressed,
    this.isDisabled = false,
    this.isLoading = false,
    this.width,
    this.height,
    this.iconSize,
    this.hugeIconStrokeWidth,
    this.hugeIconRasterSize,
    this.padding,
    this.enableHaptic = true,
    this.haveGradient = false,
    this.gradient,
    this.loadingIndicatorSize,
    this.loadingIndicatorColor,
    this.backgroundColor,
    this.backgroundColorType,
    this.foregroundColor,
    this.foregroundColorType,
  });

  final List<List<dynamic>> hugeIcon;
  final VoidCallback? onPressed;
  final bool isDisabled;
  final bool isLoading;
  final double? width;
  final double? height;
  final double? iconSize;
  final double? hugeIconStrokeWidth;
  final double? hugeIconRasterSize;
  final EdgeInsetsGeometry? padding;
  final bool enableHaptic;
  final bool haveGradient;
  final LinearGradient? gradient;
  final double? loadingIndicatorSize;
  final Color? loadingIndicatorColor;
  final Color? backgroundColor;
  final AppButtonBackgroundColor? backgroundColorType;
  final Color? foregroundColor;
  final AppButtonForegroundColor? foregroundColorType;

  @override
  Widget build(BuildContext context) {
    return AppButton(
      type: AppButtonType.icon,
      text: '',
      hugeIcon: hugeIcon,
      hugeIconStrokeWidth: hugeIconStrokeWidth,
      hugeIconRasterSize: hugeIconRasterSize,
      onPressed: onPressed,
      isDisabled: isDisabled,
      isLoading: isLoading,
      width: width,
      height: height,
      padding: padding,
      iconSize: iconSize,
      enableHaptic: enableHaptic,
      haveGradient: haveGradient,
      gradient: gradient,
      loadingIndicatorSize: loadingIndicatorSize,
      loadingIndicatorColor: loadingIndicatorColor,
      backgroundColor: backgroundColor,
      backgroundColorType: backgroundColorType,
      foregroundColor: foregroundColor,
      foregroundColorType: foregroundColorType,
    );
  }
}
