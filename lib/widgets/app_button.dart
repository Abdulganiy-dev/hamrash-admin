import 'package:flutter/material.dart';
import 'package:hamrash_admin/helpers/haptic_helper.dart';
import 'package:hamrash_admin/resources/app_colors.dart';


/// Enum for button types
enum AppButtonType { primary, secondary, outline, text, icon }

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

  /// Custom background color (overrides default)
  final Color? backgroundColor;

  /// Custom foreground color (overrides default)
  final Color? foregroundColor;

  /// Custom border color (for outline button)
  final Color? borderColor;

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
    this.foregroundColor,
    this.borderColor,
    this.enableHaptic = true,
    this.isLoading = false,
    this.customLabel,
    this.loadingIndicatorSize,
    this.loadingIndicatorColor,
  }) : assert(
         !haveGradient || gradient != null,
         'When haveGradient is true, a LinearGradient must be provided.',
       ),
       assert(
         type == AppButtonType.icon
             ? (icon != null || customLabel != null)
             : (text != null || customLabel != null),
         'Text or customLabel is required for non-icon buttons, icon or customLabel is required for icon button',
       );

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  // Scale factor when pressed (0.95 = 5% smaller)
  static const double _pressedScale = 0.95;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: _pressedScale).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  /// Get colors based on theme
  Color getBackgroundColor(BuildContext context) {
    if (widget.backgroundColor != null) return widget.backgroundColor!;
    if (widget.isDisabled || widget.isLoading) {
      return Theme.of(context).brightness == Brightness.light
          ? LightColors.backgroundSurfaceMild
          : DarkColors.backgroundSurfaceMild;
    }

    switch (widget.type) {
      case AppButtonType.primary:
        return Theme.of(context).brightness == Brightness.light
            ? LightColors.primaryPrimaryDefault
            : DarkColors.primaryPrimaryDefault;
      case AppButtonType.secondary:
        return Theme.of(context).brightness == Brightness.light
            ? LightColors.extraExtraDefault
            : DarkColors.extraExtraDefault;
      case AppButtonType.outline:
      case AppButtonType.text:
      case AppButtonType.icon:
        return Colors.transparent;
    }
  }

  Color getForegroundColor(BuildContext context) {
    if (widget.foregroundColor != null) return widget.foregroundColor!;
    if (widget.isDisabled || widget.isLoading) {
      return Theme.of(context).brightness == Brightness.light
          ? LightColors.textTextDisabled
          : DarkColors.textTextDisabled;
    }

    switch (widget.type) {
      case AppButtonType.primary:
      case AppButtonType.secondary:
        return Theme.of(context).brightness == Brightness.light
            ? LightColors.primaryOncolorWhite
            : DarkColors.primaryOncolorBlack;
      case AppButtonType.outline:
      case AppButtonType.text:
        return Theme.of(context).brightness == Brightness.light
            ? LightColors.primaryPrimaryDefault
            : DarkColors.primaryPrimaryDefault;
      case AppButtonType.icon:
        return Theme.of(context).brightness == Brightness.light
            ? LightColors.iconIconPrimary
            : DarkColors.iconIconPrimary;
    }
  }

  Color getBorderColor(BuildContext context) {
    if (widget.borderColor != null) return widget.borderColor!;
    if (widget.isDisabled || widget.isLoading) {
      return Theme.of(context).brightness == Brightness.light
          ? LightColors.strokeColourStrokeSoft
          : DarkColors.strokeColourStrokeSoft;
    }

    return Theme.of(context).brightness == Brightness.light
        ? LightColors.strokeColourStrokePrimary
        : DarkColors.strokeColourStrokePrimary;
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
      _scaleController.forward();
    }
  }

  /// Handle press up - scale back to normal
  void handlePressUp() {
    _scaleController.reverse();
  }

  /// Handle press cancel - scale back to normal
  void handlePressCancel() {
    _scaleController.reverse();
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
          : BorderSide.none,
    );

    Widget buttonContent;

    // If custom label is provided, use it
    if (widget.customLabel != null) {
      buttonContent = widget.customLabel!;
    }
    // If loading, show loading indicator
    else if (widget.isLoading) {
      buttonContent = buildLoadingIndicator(context, fgColor);
    }
    // Otherwise, build default content
    else {
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
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: IgnorePointer(
              ignoring: true, // Prevent button from consuming taps
              child: button,
            ),
          );
        },
      ),
    );
  }
}
