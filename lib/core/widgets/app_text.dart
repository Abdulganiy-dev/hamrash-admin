import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

/// A reusable text widget that automatically uses light/dark color variants
/// based on the current theme.
///
/// Usage examples:
/// ```dart
/// // Simple usage with color type (automatically switches light/dark)
/// AppText(
///   'Hello World',
///   colorType: AppTextColor.primary,
///   fontSize: 16,
///   fontWeight: FontWeight.bold,
/// )
///
/// // With custom color (overrides colorType)
/// AppText(
///   'Custom Color',
///   color: Colors.blue,
///   fontSize: 14,
/// )
///
/// // With text overflow and max lines
/// AppText(
///   'Long text that might overflow...',
///   colorType: AppTextColor.textPrimary,
///   fontSize: 14,
///   maxLines: 2,
///   overflow: TextOverflow.ellipsis,
///   softWrap: true,
/// )
///
/// // With alignment
/// AppText(
///   'Centered Text',
///   colorType: AppTextColor.textPrimary,
///   textAlign: TextAlign.center,
///   fontSize: 18,
/// )
///
/// // With decoration
/// AppText(
///   'Underlined Text',
///   colorType: AppTextColor.error,
///   decoration: TextDecoration.underline,
///   fontSize: 16,
/// )
/// ```

/// Color type enum for AppText widget
enum AppTextColor {
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
  iconDisabled,
  extra,
  extraMute,
  extraThin,
}

/// A reusable text widget that automatically uses light/dark color variants
/// based on the current theme
class AppText extends StatelessWidget {
  /// The text to display
  final String text;

  /// Color type to use (automatically switches between light/dark)
  final AppTextColor? colorType;

  /// Custom color (overrides colorType if provided)
  final Color? color;

  /// Font size
  final double? fontSize;

  /// Font weight
  final FontWeight? fontWeight;

  /// Text alignment
  final TextAlign? textAlign;

  /// Whether text should wrap at soft line breaks
  final bool? softWrap;

  /// How visual overflow should be handled
  final TextOverflow? overflow;

  /// Maximum number of lines
  final int? maxLines;

  /// Text style to merge with
  final TextStyle? style;

  /// Text scale factor
  final double? textScaleFactor;

  /// Text direction
  final TextDirection? textDirection;

  /// Locale for the text
  final Locale? locale;

  /// How the width of the text should be measured
  final TextWidthBasis? textWidthBasis;

  /// Selection color
  final Color? selectionColor;

  /// Text height
  final double? height;

  /// Letter spacing
  final double? letterSpacing;

  /// Word spacing
  final double? wordSpacing;

  /// Text decoration
  final TextDecoration? decoration;

  /// Text decoration color
  final Color? decorationColor;

  /// Text decoration style
  final TextDecorationStyle? decorationStyle;

  /// Text decoration thickness
  final double? decorationThickness;

  /// Font family
  final String? fontFamily;

  /// Font family fallback
  final List<String>? fontFamilyFallback;

  /// Font style
  final FontStyle? fontStyle;

  /// Text shadows
  final List<Shadow>? shadows;

  /// Text baseline
  final TextBaseline? textBaseline;

  /// Text leading distribution
  final TextLeadingDistribution? leadingDistribution;

  const AppText(
    this.text, {
    super.key,
    this.colorType,
    this.color,
    this.fontSize,
    this.fontWeight,
    this.textAlign,
    this.softWrap,
    this.overflow,
    this.maxLines,
    this.style,
    this.textScaleFactor,
    this.textDirection,
    this.locale,
    this.textWidthBasis,
    this.selectionColor,
    this.height,
    this.letterSpacing,
    this.wordSpacing,
    this.decoration,
    this.decorationColor,
    this.decorationStyle,
    this.decorationThickness,
    this.fontFamily,
    this.fontFamilyFallback,
    this.fontStyle,
    this.shadows,
    this.textBaseline,
    this.leadingDistribution,
  }) : assert(
          colorType == null || color == null,
          'Cannot provide both colorType and color. Use one or the other.',
        );

  /// Get the color based on colorType and theme
  Color? _getColor(BuildContext context) {
    if (color != null) return color;

    if (colorType == null) return null;

    final isLight = Theme.of(context).brightness == Brightness.light;

    switch (colorType!) {
      case AppTextColor.primary:
        return isLight
            ? LightColors.primaryPrimaryDefault
            : DarkColors.primaryPrimaryDefault;
      case AppTextColor.primaryMute:
        return isLight
            ? LightColors.primaryPrimaryMute
            : DarkColors.primaryPrimaryMute;
      case AppTextColor.primaryThin:
        return isLight
            ? LightColors.primaryPrimaryThin
            : DarkColors.primaryPrimaryThin;
      case AppTextColor.success:
        return isLight
            ? LightColors.successSuccessDefault
            : DarkColors.successSuccessDefault;
      case AppTextColor.successMute:
        return isLight
            ? LightColors.successSuccessMute
            : DarkColors.successSuccessMute;
      case AppTextColor.successThin:
        return isLight
            ? LightColors.successSuccessThin
            : DarkColors.successSuccessThin;
      case AppTextColor.warning:
        return isLight
            ? LightColors.warningWarningDefault
            : DarkColors.warningWarningDefault;
      case AppTextColor.warningMute:
        return isLight
            ? LightColors.warningWarningMute
            : DarkColors.warningWarningMute;
      case AppTextColor.warningThin:
        return isLight
            ? LightColors.warningWarningThin
            : DarkColors.warningWarningThin;
      case AppTextColor.error:
        return isLight
            ? LightColors.errorErrorDefault
            : DarkColors.errorErrorDefault;
      case AppTextColor.errorMute:
        return isLight
            ? LightColors.errorErrorMute
            : DarkColors.errorErrorMute;
      case AppTextColor.errorThin:
        return isLight
            ? LightColors.errorErrorThin
            : DarkColors.errorErrorThin;
      case AppTextColor.textPrimary:
        return isLight
            ? LightColors.textTextPrimary
            : DarkColors.textTextPrimary;
      case AppTextColor.textMute:
        return isLight ? LightColors.textTextMute : DarkColors.textTextMute;
      case AppTextColor.textBrand:
        return isLight ? LightColors.textTextBrand : DarkColors.textTextBrand;
      case AppTextColor.textInverted:
        return isLight
            ? LightColors.textTextInverted
            : DarkColors.textTextInverted;
      case AppTextColor.textDisabled:
        return isLight
            ? LightColors.textTextDisabled
            : DarkColors.textTextDisabled;
      case AppTextColor.iconPrimary:
        return isLight
            ? LightColors.iconIconPrimary
            : DarkColors.iconIconPrimary;
      case AppTextColor.iconMute:
        return isLight ? LightColors.iconIconMute : DarkColors.iconIconMute;
      case AppTextColor.iconBrand:
        return isLight ? LightColors.iconIconBrand : DarkColors.iconIconBrand;
      case AppTextColor.iconDisabled:
        return isLight
            ? LightColors.iconIconDisabled
            : DarkColors.iconIconDisabled;
      case AppTextColor.extra:
        return isLight
            ? LightColors.extraExtraDefault
            : DarkColors.extraExtraDefault;
      case AppTextColor.extraMute:
        return isLight ? LightColors.extraExtraMute : DarkColors.extraExtraMute;
      case AppTextColor.extraThin:
        return isLight ? LightColors.extraExtraThin : DarkColors.extraExtraThin;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = _getColor(context);

    final textStyle = TextStyle(
      color: textColor,
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height,
      letterSpacing: letterSpacing,
      wordSpacing: wordSpacing,
      decoration: decoration,
      decorationColor: decorationColor,
      decorationStyle: decorationStyle,
      decorationThickness: decorationThickness,
      fontFamily: fontFamily,
      fontFamilyFallback: fontFamilyFallback,
      fontStyle: fontStyle,
      shadows: shadows,
      textBaseline: textBaseline,
      leadingDistribution: leadingDistribution,
    ).merge(style);

    return Text(
      text,
      style: textStyle,
      textAlign: textAlign,
      softWrap: softWrap,
      overflow: overflow,
      maxLines: maxLines,
      textScaleFactor: textScaleFactor,
      textDirection: textDirection,
      locale: locale,
      textWidthBasis: textWidthBasis,
      selectionColor: selectionColor,
    );
  }
}
