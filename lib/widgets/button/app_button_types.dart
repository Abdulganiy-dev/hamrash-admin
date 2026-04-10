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
