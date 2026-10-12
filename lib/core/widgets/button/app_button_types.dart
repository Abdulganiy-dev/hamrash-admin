/// Filled types (primary, secondary, tertiary, destructive) use the lit
/// gradient surface; tertiary is the pale brand-blue "tinted" button.
enum AppButtonType {
  primary,
  secondary,
  tertiary,
  destructive,
  outline,
  text,
  icon,
}

/// Button heights. Large for screen-level actions, small for rows and
/// toolbars, medium everywhere else.
enum AppButtonSize {
  small(height: 36, horizontalPadding: 16),
  medium(height: 48, horizontalPadding: 24),
  large(height: 56, horizontalPadding: 24);

  const AppButtonSize({required this.height, required this.horizontalPadding});

  final double height;
  final double horizontalPadding;
}

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
  textBody,
  textMuted,
  textBrand,
  textStrong,
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
