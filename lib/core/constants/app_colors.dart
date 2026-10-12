import 'package:flutter/material.dart';

/// Raw color scales. Widgets should use [LightColors] / [DarkColors] tokens;
/// reach for these only when a token doesn't exist for the job.
///
/// Main colors: brand blue (anchored on the app icon, #0168F0), slate gray
/// and white. Supporting colors (success, warning, error, accent) are only
/// used when the color carries meaning.
class AppPalette {
  // Brand blue — 500 is the app icon color.
  static const blue50 = Color(0xFFEEF5FF);
  static const blue100 = Color(0xFFD9E8FE);
  static const blue200 = Color(0xFFB3D1FD);
  static const blue300 = Color(0xFF7AB0F9);
  static const blue400 = Color(0xFF3C8BF5);
  static const blue500 = Color(0xFF0168F0);
  static const blue600 = Color(0xFF0157CC);
  static const blue700 = Color(0xFF0147A6);
  static const blue800 = Color(0xFF053A85);
  static const blue900 = Color(0xFF0A2F66);

  // Slate gray — cool-tinted so it sits well next to the blue.
  static const white = Color(0xFFFFFFFF);
  static const slate50 = Color(0xFFF8FAFC);
  static const slate100 = Color(0xFFF1F5F9);
  static const slate200 = Color(0xFFE2E8F0);
  static const slate300 = Color(0xFFCBD5E1);
  static const slate400 = Color(0xFF94A3B8);
  static const slate500 = Color(0xFF64748B);
  static const slate600 = Color(0xFF475569);
  static const slate700 = Color(0xFF334155);
  static const slate800 = Color(0xFF1E293B);
  static const slate850 = Color(0xFF131C2E);
  static const slate900 = Color(0xFF0F172A);
  static const slate950 = Color(0xFF0B1120);
}

class LightColors {
  // Primary (brand blue)
  static const primaryPrimaryMute = AppPalette.blue50;
  static const primaryPrimaryThin = AppPalette.blue200;
  static const primaryPrimaryDefault = AppPalette.blue500;
  static const primaryPrimaryHover = AppPalette.blue600;
  static const primaryPrimaryPressed = AppPalette.blue700;
  static const primaryPrimaryText = AppPalette.blue700;

  // Success
  static const successSuccessMute = Color(0xFFECFDF3);
  static const successSuccessThin = Color(0xFFABEFC6);
  static const successSuccessDefault = Color(0xFF16A34A);
  static const successSuccessText = Color(0xFF15803D);

  // Warning
  static const warningWarningMute = Color(0xFFFFFAEB);
  static const warningWarningThin = Color(0xFFFEDF89);
  static const warningWarningDefault = Color(0xFFF59E0B);
  static const warningWarningText = Color(0xFFB54708);

  // Error
  static const errorErrorMute = Color(0xFFFEF3F2);
  static const errorErrorThin = Color(0xFFFECDCA);
  static const errorErrorDefault = Color(0xFFDC2626);
  static const errorErrorText = Color(0xFFB42318);

  // Text
  static const textBrand = AppPalette.blue500; // links, brand accents
  static const textStrong = AppPalette.slate900; // headings, titles, labels
  static const textBody = AppPalette.slate600; // running text
  static const textMuted = AppPalette.slate500; // captions, hints, metadata
  static const textDisabled = AppPalette.slate400; // unavailable controls

  // Background
  static const backgroundSurfacePrimaryBG = AppPalette.white;
  static const backgroundSurfaceLayer = AppPalette.slate100;
  static const backgroundSurfaceMute = AppPalette.slate50;
  static const backgroundSurfaceMild = AppPalette.slate200;

  // Stroke (slate-900 at increasing opacity)
  static const strokeColourStrokeSoft = Color(0x0A0F172A);
  static const strokeColourStrokeSubtle = Color(0x140F172A);
  static const strokeColourStrokeMild = Color(0x1F0F172A);
  static const strokeColourStrokeWarm = Color(0x290F172A);
  static const strokeColourStrokeStrong = Color(0x330F172A);
  static const strokeColourStrokePrimary = AppPalette.blue500;

  // On-color / neutral
  static const primaryOncolorBlack = Colors.black;
  static const primaryOncolorWhite = Colors.white;
  static const primaryNeutralWhite = Colors.white;
  static const primaryNeutralBlack = Colors.black;

  // Icon
  static const iconIconPrimary = AppPalette.slate600;
  static const iconIconInverted = AppPalette.slate900;
  static const iconIconMute = AppPalette.slate500;
  static const iconIconDisabled = AppPalette.slate400;
  static const iconIconBrand = AppPalette.blue500;

  // Backdrop (brand blue at increasing opacity)
  static const backgroundBackdropSoft = Color(0x520168F0);
  static const backgroundBackdropMild = Color(0xA30168F0);
  static const backgroundBackdropWarm = Color(0xCC0168F0);

  // Extra (violet accent — charts and "new" tags only)
  static const extraExtraDefault = Color(0xFF7C3AED);
  static const extraExtraThin = Color(0xFFD9CCFF);
  static const extraExtraMute = Color(0xFFF3F0FF);
  static const extraExtraText = Color(0xFF6D28D9);
}

class DarkColors {
  // Primary (brand blue). Fills keep the brand blue so white labels stay
  // readable; brand text, icons and strokes use the lighter blue-400.
  static const primaryPrimaryMute = Color(0xFF10264A);
  static const primaryPrimaryThin = AppPalette.blue800;
  static const primaryPrimaryDefault = AppPalette.blue500;
  static const primaryPrimaryHover = AppPalette.blue400;
  static const primaryPrimaryPressed = AppPalette.blue600;
  static const primaryPrimaryText = AppPalette.blue300;

  // Success
  static const successSuccessMute = Color(0xFF0B2A1A);
  static const successSuccessThin = Color(0xFF14532D);
  static const successSuccessDefault = Color(0xFF22C55E);
  static const successSuccessText = Color(0xFF4ADE80);

  // Warning
  static const warningWarningMute = Color(0xFF2A1E05);
  static const warningWarningThin = Color(0xFF713F12);
  static const warningWarningDefault = Color(0xFFF59E0B);
  static const warningWarningText = Color(0xFFFBBF24);

  // Error
  static const errorErrorMute = Color(0xFF2D1212);
  static const errorErrorThin = Color(0xFF7F1D1D);
  static const errorErrorDefault = Color(0xFFEF4444);
  static const errorErrorText = Color(0xFFF87171);

  // Text
  static const textBrand = AppPalette.blue400; // links, brand accents
  static const textStrong = AppPalette.slate100; // headings, titles, labels
  static const textBody = AppPalette.slate300; // running text
  static const textMuted = AppPalette.slate400; // captions, hints, metadata
  static const textDisabled = AppPalette.slate600; // unavailable controls

  // Background
  static const backgroundSurfacePrimaryBG = AppPalette.slate950;
  static const backgroundSurfaceLayer = AppPalette.slate850;
  static const backgroundSurfaceMute = AppPalette.slate800;
  static const backgroundSurfaceMild = AppPalette.slate700;

  // Stroke (white at increasing opacity)
  static const strokeColourStrokeSoft = Color(0x0AFFFFFF);
  static const strokeColourStrokeSubtle = Color(0x14FFFFFF);
  static const strokeColourStrokeMild = Color(0x1FFFFFFF);
  static const strokeColourStrokeWarm = Color(0x29FFFFFF);
  static const strokeColourStrokeStrong = Color(0x33FFFFFF);
  static const strokeColourStrokePrimary = AppPalette.blue400;

  // On-color / neutral
  static const primaryOncolorBlack = Colors.white;
  static const primaryOncolorWhite = Colors.black;
  static const primaryNeutralWhite = Colors.white;
  static const primaryNeutralBlack = Colors.black;

  // Icon
  static const iconIconPrimary = AppPalette.slate300;
  static const iconIconInverted = AppPalette.slate100;
  static const iconIconMute = AppPalette.slate400;
  static const iconIconDisabled = AppPalette.slate600;
  static const iconIconBrand = AppPalette.blue400;

  // Backdrop (brand blue at increasing opacity)
  static const backgroundBackdropSoft = Color(0x520168F0);
  static const backgroundBackdropMild = Color(0xA30168F0);
  static const backgroundBackdropWarm = Color(0xCC0168F0);

  // Extra (violet accent — charts and "new" tags only)
  static const extraExtraDefault = Color(0xFF8B5CF6);
  static const extraExtraThin = Color(0xFF4C1D95);
  static const extraExtraMute = Color(0xFF1E1638);
  static const extraExtraText = Color(0xFFA78BFA);
}

const String primaryColorHex = '#0168F0';
