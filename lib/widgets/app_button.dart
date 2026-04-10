import 'package:flutter/material.dart';
import 'package:hamrash_admin/helpers/haptic_helper.dart';
import 'package:hamrash_admin/resources/app_colors.dart';
import 'package:motor/motor.dart';


/// Enum for button types
///
/// [secondary] — light surface, subtle border, dark label (e.g. social sign-in).
/// [primary] — solid brand fill, inverted label.
/// [tertiary] — soft brand-tinted fill, brand-colored label.
enum AppButtonType { primary, secondary, tertiary, outline, text, icon }

/// Color type enum for AppButton background
enum AppButtonBackgroundColor {
  primary,
  primaryMute,
  primaryThin,
  success,
  successMute,
  successThin,
  warning,
  warningMute,
  warningThin,
  error,
  errorMute,
  errorThin,
  surfacePrimaryBG,
  surfaceLayer,
  surfaceMute,
  surfaceMild,
  extra,
  extraMute,
  extraThin,
  backdropSoft,
  backdropMild,
  backdropWarm,
}

/// Color type enum for AppButton foreground (text/icon)
enum AppButtonForegroundColor {
  primary,
  primaryMute,
  primaryThin,
  success,
  successMute,
  successThin,
  warning,
  warningMute,
  warningThin,
  error,
  errorMute,
  errorThin,
  textPrimary,
  textMute,
  textBrand,
  textInverted,
  textDisabled,
  iconPrimary,
  iconMute,
  iconBrand,
  iconInverted,
  iconDisabled,
  oncolorWhite,
  oncolorBlack,
  extra,
  extraMute,
  extraThin,
}

/// Color type enum for AppButton border
enum AppButtonBorderColor {
  strokeSoft,
  strokeSubtle,
  strokeMild,
  strokeWarm,
  strokeStrong,
  strokePrimary,
  primary,
  primaryMute,
  primaryThin,
  extra,
}

/// A customizable button widget with capsule style and haptic feedback
class AppButton extends StatefulWidget {
  /// The button type
  final AppButtonType type;

  /// Whether the button should use a gradient background.
  ///
  /// When true, you must provide a [gradient].
  final bool haveGradient;

  /// The gradient to use when [haveGradient] is true.
  final LinearGradient? gradient;

  /// The text to display (required for all types except icon)
  final String? text;

  /// The icon to display (required for icon type, optional for others)
  final IconData? icon;

  /// The callback when button is pressed
  final VoidCallback? onPressed;

  /// Whether the button is disabled
  final bool isDisabled;

  /// Custom width for the button
  final double? width;

  /// Custom height for the button
  final double? height;

  /// Custom padding for the button
  final EdgeInsetsGeometry? padding;

  /// Custom text style
  final TextStyle? textStyle;

  /// Custom icon size
  final double? iconSize;

  /// Custom background color (overrides default; cannot be used with backgroundColorType)
  final Color? backgroundColor;

  /// Background color type (automatically switches light/dark; cannot be used with backgroundColor)
  final AppButtonBackgroundColor? backgroundColorType;

  /// Custom foreground color (overrides default; cannot be used with foregroundColorType)
  final Color? foregroundColor;

  /// Foreground color type (automatically switches light/dark; cannot be used with foregroundColor)
  final AppButtonForegroundColor? foregroundColorType;

  /// Custom border color (for outline button; cannot be used with borderColorType)
  final Color? borderColor;

  /// Border color type (automatically switches light/dark; cannot be used with borderColor)
  final AppButtonBorderColor? borderColorType;

  /// Whether to show haptic feedback (default: true)
  final bool enableHaptic;

  /// Whether the button is in loading state
  final bool isLoading;

  /// Custom widget to display as label (overrides text/icon)
  final Widget? customLabel;

  /// Loading indicator size (default: 20)
  final double? loadingIndicatorSize;

  /// Loading indicator color (defaults to foreground color)
  final Color? loadingIndicatorColor;

  /// Optional label widget; if both [child] and [customLabel] are set, [child] wins.
  final Widget? child;

  const AppButton({
    super.key,
    required this.type,
    this.haveGradient = false,
    this.gradient,
    this.text,
    this.icon,
    this.onPressed,
    this.isDisabled = false,
    this.width = 50,
    this.height = 50,
    this.padding,
    this.textStyle,
    this.iconSize,
    this.backgroundColor,
    this.backgroundColorType,
    this.foregroundColor,
    this.foregroundColorType,
    this.borderColor,
    this.borderColorType,
    this.enableHaptic = true,
    this.isLoading = false,
    this.customLabel,
    this.loadingIndicatorSize,
    this.loadingIndicatorColor,
    this.child,
  }) : assert(
         !haveGradient || gradient != null,
         'When haveGradient is true, a LinearGradient must be provided.',
       ),
       assert(
         type == AppButtonType.icon
             ? (icon != null || customLabel != null || child != null)
             : (text != null || customLabel != null || child != null),
         'Text, child, or customLabel is required for non-icon buttons; icon, child, or customLabel for icon button',
       ),
       assert(
         backgroundColor == null || backgroundColorType == null,
         'Cannot provide both backgroundColor and backgroundColorType. Use one or the other.',
       ),
       assert(
         foregroundColor == null || foregroundColorType == null,
         'Cannot provide both foregroundColor and foregroundColorType. Use one or the other.',
       ),
       assert(
         borderColor == null || borderColorType == null,
         'Cannot provide both borderColor and borderColorType. Use one or the other.',
       );

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  /// Target scale; [SingleMotionBuilder] animates toward this when it changes.
  double _scaleTarget = 1.0;

  // Scale factor when pressed (0.95 = 5% smaller)
  static const double _pressedScale = 0.95;

  static const Motion _scaleMotion = Motion.snappySpring();

  @override
  void didUpdateWidget(AppButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    final blocked = widget.isDisabled || widget.isLoading;
    final wasBlocked = oldWidget.isDisabled || oldWidget.isLoading;
    if (blocked && !wasBlocked && _scaleTarget != 1.0) {
      setState(() => _scaleTarget = 1.0);
    }
  }

  /// Get background color based on colorType or explicit color
  Color getBackgroundColor(BuildContext context) {
    if (widget.backgroundColor != null) return widget.backgroundColor!;

    final isLight = Theme.of(context).brightness == Brightness.light;

    if (widget.backgroundColorType != null) {
      switch (widget.backgroundColorType!) {
        case AppButtonBackgroundColor.primary:
          return isLight ? LightColors.primaryPrimaryDefault : DarkColors.primaryPrimaryDefault;
        case AppButtonBackgroundColor.primaryMute:
          return isLight ? LightColors.primaryPrimaryMute : DarkColors.primaryPrimaryMute;
        case AppButtonBackgroundColor.primaryThin:
          return isLight ? LightColors.primaryPrimaryThin : DarkColors.primaryPrimaryThin;
        case AppButtonBackgroundColor.success:
          return isLight ? LightColors.successSuccessDefault : DarkColors.successSuccessDefault;
        case AppButtonBackgroundColor.successMute:
          return isLight ? LightColors.successSuccessMute : DarkColors.successSuccessMute;
        case AppButtonBackgroundColor.successThin:
          return isLight ? LightColors.successSuccessThin : DarkColors.successSuccessThin;
        case AppButtonBackgroundColor.warning:
          return isLight ? LightColors.warningWarningDefault : DarkColors.warningWarningDefault;
        case AppButtonBackgroundColor.warningMute:
          return isLight ? LightColors.warningWarningMute : DarkColors.warningWarningMute;
        case AppButtonBackgroundColor.warningThin:
          return isLight ? LightColors.warningWarningThin : DarkColors.warningWarningThin;
        case AppButtonBackgroundColor.error:
          return isLight ? LightColors.errorErrorDefault : DarkColors.errorErrorDefault;
        case AppButtonBackgroundColor.errorMute:
          return isLight ? LightColors.errorErrorMute : DarkColors.errorErrorMute;
        case AppButtonBackgroundColor.errorThin:
          return isLight ? LightColors.errorErrorThin : DarkColors.errorErrorThin;
        case AppButtonBackgroundColor.surfacePrimaryBG:
          return isLight ? LightColors.backgroundSurfacePrimaryBG : DarkColors.backgroundSurfacePrimaryBG;
        case AppButtonBackgroundColor.surfaceLayer:
          return isLight ? LightColors.backgroundSurfaceLayer : DarkColors.backgroundSurfaceLayer;
        case AppButtonBackgroundColor.surfaceMute:
          return isLight ? LightColors.backgroundSurfaceMute : DarkColors.backgroundSurfaceMute;
        case AppButtonBackgroundColor.surfaceMild:
          return isLight ? LightColors.backgroundSurfaceMild : DarkColors.backgroundSurfaceMild;
        case AppButtonBackgroundColor.extra:
          return isLight ? LightColors.extraExtraDefault : DarkColors.extraExtraDefault;
        case AppButtonBackgroundColor.extraMute:
          return isLight ? LightColors.extraExtraMute : DarkColors.extraExtraMute;
        case AppButtonBackgroundColor.extraThin:
          return isLight ? LightColors.extraExtraThin : DarkColors.extraExtraThin;
        case AppButtonBackgroundColor.backdropSoft:
          return isLight ? LightColors.backgroundBackdropSoft : DarkColors.backgroundBackdropSoft;
        case AppButtonBackgroundColor.backdropMild:
          return isLight ? LightColors.backgroundBackdropMild : DarkColors.backgroundBackdropMild;
        case AppButtonBackgroundColor.backdropWarm:
          return isLight ? LightColors.backgroundBackdropWarm : DarkColors.backgroundBackdropWarm;
      }
    }

    if (widget.isDisabled || widget.isLoading) {
      return isLight ? LightColors.backgroundSurfaceMild : DarkColors.backgroundSurfaceMild;
    }

    switch (widget.type) {
      case AppButtonType.primary:
        return isLight ? LightColors.primaryPrimaryDefault : DarkColors.primaryPrimaryDefault;
      case AppButtonType.secondary:
        return isLight ? LightColors.backgroundSurfaceMute : DarkColors.backgroundSurfaceMute;
      case AppButtonType.tertiary:
        return isLight ? LightColors.primaryPrimaryMute : DarkColors.primaryPrimaryMute;
      case AppButtonType.outline:
      case AppButtonType.text:
      case AppButtonType.icon:
        return Colors.transparent;
    }
  }

  /// Get foreground color based on colorType or explicit color
  Color getForegroundColor(BuildContext context) {
    if (widget.foregroundColor != null) return widget.foregroundColor!;

    final isLight = Theme.of(context).brightness == Brightness.light;

    if (widget.foregroundColorType != null) {
      switch (widget.foregroundColorType!) {
        case AppButtonForegroundColor.primary:
          return isLight ? LightColors.primaryPrimaryDefault : DarkColors.primaryPrimaryDefault;
        case AppButtonForegroundColor.primaryMute:
          return isLight ? LightColors.primaryPrimaryMute : DarkColors.primaryPrimaryMute;
        case AppButtonForegroundColor.primaryThin:
          return isLight ? LightColors.primaryPrimaryThin : DarkColors.primaryPrimaryThin;
        case AppButtonForegroundColor.success:
          return isLight ? LightColors.successSuccessDefault : DarkColors.successSuccessDefault;
        case AppButtonForegroundColor.successMute:
          return isLight ? LightColors.successSuccessMute : DarkColors.successSuccessMute;
        case AppButtonForegroundColor.successThin:
          return isLight ? LightColors.successSuccessThin : DarkColors.successSuccessThin;
        case AppButtonForegroundColor.warning:
          return isLight ? LightColors.warningWarningDefault : DarkColors.warningWarningDefault;
        case AppButtonForegroundColor.warningMute:
          return isLight ? LightColors.warningWarningMute : DarkColors.warningWarningMute;
        case AppButtonForegroundColor.warningThin:
          return isLight ? LightColors.warningWarningThin : DarkColors.warningWarningThin;
        case AppButtonForegroundColor.error:
          return isLight ? LightColors.errorErrorDefault : DarkColors.errorErrorDefault;
        case AppButtonForegroundColor.errorMute:
          return isLight ? LightColors.errorErrorMute : DarkColors.errorErrorMute;
        case AppButtonForegroundColor.errorThin:
          return isLight ? LightColors.errorErrorThin : DarkColors.errorErrorThin;
        case AppButtonForegroundColor.textPrimary:
          return isLight ? LightColors.textTextPrimary : DarkColors.textTextPrimary;
        case AppButtonForegroundColor.textMute:
          return isLight ? LightColors.textTextMute : DarkColors.textTextMute;
        case AppButtonForegroundColor.textBrand:
          return isLight ? LightColors.textTextBrand : DarkColors.textTextBrand;
        case AppButtonForegroundColor.textInverted:
          return isLight ? LightColors.textTextInverted : DarkColors.textTextInverted;
        case AppButtonForegroundColor.textDisabled:
          return isLight ? LightColors.textTextDisabled : DarkColors.textTextDisabled;
        case AppButtonForegroundColor.iconPrimary:
          return isLight ? LightColors.iconIconPrimary : DarkColors.iconIconPrimary;
        case AppButtonForegroundColor.iconMute:
          return isLight ? LightColors.iconIconMute : DarkColors.iconIconMute;
        case AppButtonForegroundColor.iconBrand:
          return isLight ? LightColors.iconIconBrand : DarkColors.iconIconBrand;
        case AppButtonForegroundColor.iconInverted:
          return isLight ? LightColors.iconIconInverted : DarkColors.iconIconInverted;
        case AppButtonForegroundColor.iconDisabled:
          return isLight ? LightColors.iconIconDisabled : DarkColors.iconIconDisabled;
        case AppButtonForegroundColor.oncolorWhite:
          return isLight ? LightColors.primaryOncolorWhite : DarkColors.primaryOncolorWhite;
        case AppButtonForegroundColor.oncolorBlack:
          return isLight ? LightColors.primaryOncolorBlack : DarkColors.primaryOncolorBlack;
        case AppButtonForegroundColor.extra:
          return isLight ? LightColors.extraExtraDefault : DarkColors.extraExtraDefault;
        case AppButtonForegroundColor.extraMute:
          return isLight ? LightColors.extraExtraMute : DarkColors.extraExtraMute;
        case AppButtonForegroundColor.extraThin:
          return isLight ? LightColors.extraExtraThin : DarkColors.extraExtraThin;
      }
    }

    if (widget.isDisabled || widget.isLoading) {
      return isLight ? LightColors.textTextDisabled : DarkColors.textTextDisabled;
    }

    switch (widget.type) {
      case AppButtonType.primary:
        return isLight ? LightColors.primaryOncolorWhite : DarkColors.primaryOncolorBlack;
      case AppButtonType.secondary:
        return isLight ? LightColors.textTextPrimary : DarkColors.textTextPrimary;
      case AppButtonType.tertiary:
        return isLight ? LightColors.textTextBrand : DarkColors.textTextBrand;
      case AppButtonType.outline:
      case AppButtonType.text:
        return isLight ? LightColors.primaryPrimaryDefault : DarkColors.primaryPrimaryDefault;
      case AppButtonType.icon:
        return isLight ? LightColors.iconIconPrimary : DarkColors.iconIconPrimary;
    }
  }

  /// Get border color based on colorType or explicit color
  Color getBorderColor(BuildContext context) {
    if (widget.borderColor != null) return widget.borderColor!;

    final isLight = Theme.of(context).brightness == Brightness.light;

    if (widget.borderColorType != null) {
      switch (widget.borderColorType!) {
        case AppButtonBorderColor.strokeSoft:
          return isLight ? LightColors.strokeColourStrokeSoft : DarkColors.strokeColourStrokeSoft;
        case AppButtonBorderColor.strokeSubtle:
          return isLight ? LightColors.strokeColourStrokeSubtle : DarkColors.strokeColourStrokeSubtle;
        case AppButtonBorderColor.strokeMild:
          return isLight ? LightColors.strokeColourStrokeMild : DarkColors.strokeColourStrokeMild;
        case AppButtonBorderColor.strokeWarm:
          return isLight ? LightColors.strokeColourStrokeWarm : DarkColors.strokeColourStrokeWarm;
        case AppButtonBorderColor.strokeStrong:
          return isLight ? LightColors.strokeColourStrokeStrong : DarkColors.strokeColourStrokeStrong;
        case AppButtonBorderColor.strokePrimary:
          return isLight ? LightColors.strokeColourStrokePrimary : DarkColors.strokeColourStrokePrimary;
        case AppButtonBorderColor.primary:
          return isLight ? LightColors.primaryPrimaryDefault : DarkColors.primaryPrimaryDefault;
        case AppButtonBorderColor.primaryMute:
          return isLight ? LightColors.primaryPrimaryMute : DarkColors.primaryPrimaryMute;
        case AppButtonBorderColor.primaryThin:
          return isLight ? LightColors.primaryPrimaryThin : DarkColors.primaryPrimaryThin;
        case AppButtonBorderColor.extra:
          return isLight ? LightColors.extraExtraDefault : DarkColors.extraExtraDefault;
      }
    }

    if (widget.isDisabled || widget.isLoading) {
      return isLight ? LightColors.strokeColourStrokeSoft : DarkColors.strokeColourStrokeSoft;
    }

    if (widget.type == AppButtonType.secondary) {
      return isLight ? LightColors.strokeColourStrokeSubtle : DarkColors.strokeColourStrokeSubtle;
    }

    return isLight ? LightColors.strokeColourStrokePrimary : DarkColors.strokeColourStrokePrimary;
  }

  /// Handle button press with haptic feedback
  void handlePress() {
    if (widget.enableHaptic && !widget.isDisabled && !widget.isLoading) {
      HapticHelpers.vibrate(VibrationType.light);
    }
    if (!widget.isLoading) {
      widget.onPressed?.call();
    }
  }

  /// Handle press down - scale down
  void handlePressDown() {
    if (!widget.isDisabled && !widget.isLoading) {
      setState(() => _scaleTarget = _pressedScale);
    }
  }

  /// Handle press up - scale back to normal
  void handlePressUp() {
    setState(() => _scaleTarget = 1.0);
  }

  /// Handle press cancel - scale back to normal
  void handlePressCancel() {
    setState(() => _scaleTarget = 1.0);
  }

  /// Get default padding based on button type
  EdgeInsetsGeometry getDefaultPadding() {
    if (widget.padding != null) return widget.padding!;

    switch (widget.type) {
      case AppButtonType.icon:
        return EdgeInsets.zero;
      case AppButtonType.text:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
      default:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 12);
    }
  }

  /// Get default text style
  TextStyle getDefaultTextStyle(BuildContext context) {
    final baseStyle = TextStyle(
      color: getForegroundColor(context),
      fontWeight: FontWeight.w500,
      fontSize: 18,
    );

    return widget.textStyle != null
        ? baseStyle.merge(widget.textStyle)
        : baseStyle;
  }

  /// Build loading indicator
  Widget buildLoadingIndicator(BuildContext context, Color color) {
    return SizedBox(
      width: widget.loadingIndicatorSize ?? 20,
      height: widget.loadingIndicatorSize ?? 20,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(
          widget.loadingIndicatorColor ?? color,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = getBackgroundColor(context);
    final fgColor = getForegroundColor(context);
    final borderColor = getBorderColor(context);
    final defaultPadding = getDefaultPadding();
    final textStyle = getDefaultTextStyle(context);

    // Capsule shape (fully rounded)
    final borderRadius = BorderRadius.circular(
      1000,
    ); // Very large radius for capsule
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(
        1000,
      ), // Very large radius for capsule
      side: widget.type == AppButtonType.outline
          ? BorderSide(color: borderColor, width: 1.5)
          : widget.type == AppButtonType.secondary
          ? BorderSide(color: borderColor, width: 1)
          : BorderSide.none,
    );

    Widget buttonContent;

    if (widget.isLoading) {
      buttonContent = buildLoadingIndicator(context, fgColor);
    } else if (widget.child != null) {
      buttonContent = widget.child!;
    } else if (widget.customLabel != null) {
      buttonContent = widget.customLabel!;
    } else {
      switch (widget.type) {
        case AppButtonType.icon:
          buttonContent = Icon(
            widget.icon,
            size: widget.iconSize ?? 24,
            color: fgColor,
          );
          break;
        case AppButtonType.text:
          buttonContent = Text(widget.text!, style: textStyle);
          break;
        default:
          if (widget.icon != null) {
            buttonContent = Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(widget.icon, size: widget.iconSize ?? 20, color: fgColor),
                const SizedBox(width: 8),
                Text(widget.text!, style: textStyle),
              ],
            );
          } else {
            buttonContent = Text(widget.text!, style: textStyle);
          }
      }
    }

    // Build the appropriate button widget
    Widget button;

    final isEnabled = !widget.isDisabled && !widget.isLoading;
    final showGradient =
        widget.haveGradient && widget.gradient != null && isEnabled;

    switch (widget.type) {
      case AppButtonType.primary:
      case AppButtonType.secondary:
      case AppButtonType.tertiary:
        button = ElevatedButton(
          onPressed: isEnabled
              ? () {}
              : null, // Empty callback to keep button enabled, actual logic in GestureDetector
          style: ElevatedButton.styleFrom(
            backgroundColor: showGradient ? Colors.transparent : bgColor,
            foregroundColor: fgColor,
            elevation: 10,
            shadowColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            padding: defaultPadding,
            shape: shape,
            minimumSize: Size(widget.width ?? 0, widget.height ?? 0),
            fixedSize: widget.width != null || widget.height != null
                ? Size(widget.width ?? double.infinity, widget.height ?? 48)
                : null,
            // Remove splash effect
            splashFactory: NoSplash.splashFactory,
          ),
          child: buttonContent,
        );
        break;
      case AppButtonType.outline:
        button = OutlinedButton(
          onPressed: isEnabled
              ? () {}
              : null, // Empty callback to keep button enabled, actual logic in GestureDetector
          style: OutlinedButton.styleFrom(
            foregroundColor: fgColor,
            side: BorderSide(color: borderColor, width: 1.5),
            padding: defaultPadding,
            shape: shape,
            minimumSize: Size(widget.width ?? 0, widget.height ?? 0),
            fixedSize: widget.width != null || widget.height != null
                ? Size(widget.width ?? double.infinity, widget.height ?? 48)
                : null,
            // Remove splash effect
            splashFactory: NoSplash.splashFactory,
          ),
          child: buttonContent,
        );
        break;
      case AppButtonType.text:
        button = TextButton(
          onPressed: isEnabled
              ? () {}
              : null, // Empty callback to keep button enabled, actual logic in GestureDetector
          style: TextButton.styleFrom(
            foregroundColor: fgColor,
            padding: defaultPadding,
            shape: shape,
            minimumSize: Size(widget.width ?? 0, widget.height ?? 0),
            fixedSize: widget.width != null || widget.height != null
                ? Size(widget.width ?? double.infinity, widget.height ?? 48)
                : null,
            // Remove splash effect
            splashFactory: NoSplash.splashFactory,
          ),
          child: buttonContent,
        );
        break;
      case AppButtonType.icon:
        button = IconButton(
          padding: EdgeInsets.zero,
          onPressed: isEnabled
              ? () {}
              : null, // Empty callback to keep button enabled, actual logic in GestureDetector
          icon: buttonContent,
          style: IconButton.styleFrom(
            backgroundColor: showGradient ? Colors.transparent : bgColor,
            foregroundColor: fgColor,
            padding: defaultPadding,
            shape: shape,
            minimumSize: Size(widget.width ?? 48, widget.height ?? 48),
            fixedSize: widget.width != null || widget.height != null
                ? Size(widget.width ?? 48, widget.height ?? 48)
                : null,
            // Remove splash effect
            splashFactory: NoSplash.splashFactory,
          ),
        );
        break;
    }

    if (showGradient) {
      button = ClipRRect(
        borderRadius: borderRadius,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: widget.gradient,
            borderRadius: borderRadius,
          ),
          child: button,
        ),
      );
    }

    // Wrap button with GestureDetector for scale animation
    // Use IgnorePointer to prevent button from consuming taps, so GestureDetector handles them
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: isEnabled ? (_) => handlePressDown() : null,
      onTapUp: isEnabled
          ? (_) {
              handlePressUp();
              handlePress();
            }
          : null,
      onTapCancel: isEnabled ? handlePressCancel : null,
      child: SingleMotionBuilder(
        motion: _scaleMotion,
        value: _scaleTarget,
        builder: (context, scale, child) {
          return Transform.scale(
            scale: scale,
            child: child,
          );
        },
        child: IgnorePointer(
          ignoring: true, // Prevent button from consuming taps
          child: button,
        ),
      ),
    );
  }
}

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
