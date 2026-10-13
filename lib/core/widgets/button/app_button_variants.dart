import 'package:hamrash_admin/core/widgets/button/app_button.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_types.dart';
import 'package:flutter/material.dart';

/// Primary call-to-action — lit aubergine gradient; use [child] for the label.
class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    super.key,
    required this.child,
    this.onPressed,
    this.isDisabled = false,
    this.isLoading = false,
    this.loadingText,
    this.width,
    this.height,
    this.size = AppButtonSize.medium,
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
    this.radius,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final bool isDisabled;
  final bool isLoading;

  /// Words beside the spinner while loading, e.g. "Saving…".
  final String? loadingText;
  final double? width;
  final double? height;
  final AppButtonSize size;
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
  final double? radius;

  @override
  Widget build(BuildContext context) {
    return AppButton(
      type: AppButtonType.primary,
      text: '',
      onPressed: onPressed,
      isDisabled: isDisabled,
      isLoading: isLoading,
      loadingText: loadingText,
      width: width,
      height: height,
      size: size,
      padding: padding,
      enableHaptic: enableHaptic,
      haveGradient: haveGradient,
      gradient: gradient,
      loadingIndicatorSize: loadingIndicatorSize,
      loadingIndicatorColor: loadingIndicatorColor,
      textStyle: textStyle,
      backgroundColor: backgroundColor,
      backgroundColorType: backgroundColorType,
      radius: radius,
      foregroundColor: foregroundColor,
      foregroundColorType: foregroundColorType,
      child: child,
    );
  }
}

/// Secondary action — cream-to-stone fill, subtle border; use [child] for icon + text rows (e.g. Google).
class AppSecondaryButton extends StatelessWidget {
  const AppSecondaryButton({
    super.key,
    required this.child,
    this.onPressed,
    this.isDisabled = false,
    this.isLoading = false,
    this.loadingText,
    this.width,
    this.height,
    this.size = AppButtonSize.medium,
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
    this.radius,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final bool isDisabled;
  final bool isLoading;

  /// Words beside the spinner while loading, e.g. "Saving…".
  final String? loadingText;
  final double? width;
  final double? height;
  final AppButtonSize size;
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
  final double? radius;

  @override
  Widget build(BuildContext context) {
    return AppButton(
      type: AppButtonType.secondary,
      text: '',
      onPressed: onPressed,
      isDisabled: isDisabled,
      isLoading: isLoading,
      loadingText: loadingText,
      width: width,
      height: height,
      size: size,
      padding: padding,
      enableHaptic: enableHaptic,
      loadingIndicatorSize: loadingIndicatorSize,
      loadingIndicatorColor: loadingIndicatorColor,
      textStyle: textStyle,
      backgroundColor: backgroundColor,
      backgroundColorType: backgroundColorType,
      radius: radius,
      foregroundColor: foregroundColor,
      foregroundColorType: foregroundColorType,
      borderColor: borderColor,
      borderColorType: borderColorType,
      child: child,
    );
  }
}

/// Tinted action — pale aubergine fill, dark brand text (e.g. “View class”).
class AppTertiaryButton extends StatelessWidget {
  const AppTertiaryButton({
    super.key,
    required this.child,
    this.onPressed,
    this.isDisabled = false,
    this.isLoading = false,
    this.loadingText,
    this.width,
    this.height,
    this.size = AppButtonSize.medium,
    this.padding,
    this.enableHaptic = true,
    this.loadingIndicatorSize,
    this.loadingIndicatorColor,
    this.textStyle,
    this.backgroundColor,
    this.backgroundColorType,
    this.foregroundColor,
    this.foregroundColorType,
    this.radius,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final bool isDisabled;
  final bool isLoading;

  /// Words beside the spinner while loading, e.g. "Saving…".
  final String? loadingText;
  final double? width;
  final double? height;
  final AppButtonSize size;
  final EdgeInsetsGeometry? padding;
  final bool enableHaptic;
  final double? loadingIndicatorSize;
  final Color? loadingIndicatorColor;
  final TextStyle? textStyle;
  final Color? backgroundColor;
  final AppButtonBackgroundColor? backgroundColorType;
  final Color? foregroundColor;
  final AppButtonForegroundColor? foregroundColorType;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    return AppButton(
      type: AppButtonType.tertiary,
      text: '',
      onPressed: onPressed,
      isDisabled: isDisabled,
      isLoading: isLoading,
      loadingText: loadingText,
      width: width,
      height: height,
      size: size,
      padding: padding,
      enableHaptic: enableHaptic,
      loadingIndicatorSize: loadingIndicatorSize,
      loadingIndicatorColor: loadingIndicatorColor,
      textStyle: textStyle,
      backgroundColor: backgroundColor,
      backgroundColorType: backgroundColorType,
      foregroundColor: foregroundColor,
      foregroundColorType: foregroundColorType,
      radius: radius,
      child: child,
    );
  }
}

/// Destructive action — lit red gradient for delete, remove, withdraw.
class AppDestructiveButton extends StatelessWidget {
  const AppDestructiveButton({
    super.key,
    required this.child,
    this.onPressed,
    this.isDisabled = false,
    this.isLoading = false,
    this.loadingText,
    this.width,
    this.height,
    this.size = AppButtonSize.medium,
    this.padding,
    this.enableHaptic = true,
    this.loadingIndicatorSize,
    this.loadingIndicatorColor,
    this.textStyle,
    this.radius,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final bool isDisabled;
  final bool isLoading;

  /// Words beside the spinner while loading, e.g. "Saving…".
  final String? loadingText;
  final double? width;
  final double? height;
  final AppButtonSize size;
  final EdgeInsetsGeometry? padding;
  final bool enableHaptic;
  final double? loadingIndicatorSize;
  final Color? loadingIndicatorColor;
  final TextStyle? textStyle;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    return AppButton(
      type: AppButtonType.destructive,
      text: '',
      onPressed: onPressed,
      isDisabled: isDisabled,
      isLoading: isLoading,
      loadingText: loadingText,
      width: width,
      height: height,
      size: size,
      padding: padding,
      enableHaptic: enableHaptic,
      loadingIndicatorSize: loadingIndicatorSize,
      loadingIndicatorColor: loadingIndicatorColor,
      textStyle: textStyle,
      radius: radius,
      child: child,
    );
  }
}

/// Icon-only control with Hugeicons stroke glyph and the same press scale as [AppButton].
class AppHugeIconButton extends StatelessWidget {
  const AppHugeIconButton({
    super.key,
    required this.lucidIcon,
    this.onPressed,
    this.isDisabled = false,
    this.isLoading = false,
    this.width,
    this.height,
    this.iconSize,
    this.lucidIconSize,
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

  final IconData lucidIcon;
  final VoidCallback? onPressed;
  final bool isDisabled;
  final bool isLoading;
  final double? width;
  final double? height;
  final double? iconSize;

  final double? lucidIconSize;
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
      lucidIcon: lucidIcon,
      lucidIconSize: lucidIconSize,
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
